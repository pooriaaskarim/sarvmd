// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/services/sarv_file_service.dart';

class _FakeFilePicker extends FilePicker {
  FilePickerResult? pickResult;
  String? saveResult;

  String? capturedSaveFileName;
  Uint8List? capturedSaveBytes;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = true,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return pickResult;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    capturedSaveFileName = fileName;
    capturedSaveBytes = bytes;
    return saveResult;
  }

  @override
  Future<bool?> clearTemporaryFiles() async => true;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SarvFileService Tests', () {
    late _FakeFilePicker fakePicker;
    late SarvFileService service;
    late Directory tempDir;

    setUp(() {
      fakePicker = _FakeFilePicker();
      service = SarvFileService(filePicker: fakePicker);
      tempDir = Directory.systemTemp.createTempSync('sarv_file_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('openSarvFile returns null when user cancels picker', () async {
      fakePicker.pickResult = null;
      final result = await service.openSarvFile();
      expect(result, isNull);
    });

    test('openSarvFile successfully parses valid .sarv document from bytes', () async {
      const sampleDoc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'Opus 42'),
      );
      final jsonStr = jsonEncode(sampleDoc.toJson());
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      fakePicker.pickResult = FilePickerResult([
        PlatformFile(
          name: 'Opus 42.sarv',
          size: bytes.length,
          bytes: bytes,
        ),
      ]);

      final result = await service.openSarvFile();
      expect(result, isNotNull);
      expect(result!.fileName, equals('Opus 42.sarv'));
      expect(result.document.metadata.title, equals('Opus 42'));
    });

    test('openSarvFile reads from filePath when bytes are null on desktop', () async {
      const sampleDoc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'File On Disk'),
      );
      final testFile = File('${tempDir.path}/test_score.sarv');
      testFile.writeAsStringSync(jsonEncode(sampleDoc.toJson()));

      fakePicker.pickResult = FilePickerResult([
        PlatformFile(
          name: 'test_score.sarv',
          size: testFile.lengthSync(),
          path: testFile.path,
        ),
      ]);

      final result = await service.openSarvFile();
      expect(result, isNotNull);
      expect(result!.filePath, equals(testFile.path));
      expect(result.document.metadata.title, equals('File On Disk'));
    });

    test('openSarvFile throws FormatException on invalid JSON', () async {
      final bytes = Uint8List.fromList(utf8.encode('Not valid JSON {[['));
      fakePicker.pickResult = FilePickerResult([
        PlatformFile(
          name: 'invalid.sarv',
          size: bytes.length,
          bytes: bytes,
        ),
      ]);

      expect(() => service.openSarvFile(), throwsA(isA<FormatException>()));
    });

    test('openSarvFile throws FormatException when format != "sarv"', () async {
      final jsonMap = {'format': 'musicxml', 'version': 1};
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));
      fakePicker.pickResult = FilePickerResult([
        PlatformFile(
          name: 'invalid_format.sarv',
          size: bytes.length,
          bytes: bytes,
        ),
      ]);

      expect(() => service.openSarvFile(), throwsA(isA<FormatException>()));
    });

    test('saveSarvFile directly writes to existing filePath without prompting', () async {
      final targetPath = '${tempDir.path}/direct_save.sarv';
      const doc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'Direct Saved'),
      );

      final savedPath = await service.saveSarvFile(
        document: doc,
        filePath: targetPath,
        defaultFileName: 'direct_save.sarv',
      );

      expect(savedPath, equals(targetPath));
      expect(fakePicker.capturedSaveFileName, isNull); // FilePicker not invoked

      final savedFile = File(targetPath);
      expect(savedFile.existsSync(), isTrue);
      final decoded = jsonDecode(savedFile.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['format'], equals('sarv'));
      expect(decoded['metadata']['title'], equals('Direct Saved'));
    });

    test('saveAsSarvFile prompts picker and normalizes file extension', () async {
      final targetPath = '${tempDir.path}/my_new_score.sarv';
      fakePicker.saveResult = targetPath;

      const doc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'My New Score'),
      );

      final savedPath = await service.saveAsSarvFile(
        document: doc,
        defaultFileName: 'my_new_score',
      );

      expect(fakePicker.capturedSaveFileName, equals('my_new_score.sarv'));
      expect(savedPath, equals(targetPath));

      final savedFile = File(targetPath);
      expect(savedFile.existsSync(), isTrue);
    });

    test('saveAsSarvFile returns null if user cancels dialog', () async {
      fakePicker.saveResult = null;

      const doc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'Cancelled Score'),
      );

      final savedPath = await service.saveAsSarvFile(
        document: doc,
        defaultFileName: 'cancelled.sarv',
      );

      expect(savedPath, isNull);
    });
  });
}
