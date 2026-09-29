// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/services/sarv_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFilePicker extends FilePicker {
  FilePickerResult? pickResult;
  String? saveResult;

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
    dynamic bytes,
    bool lockParentWindow = false,
  }) async {
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

  group('Document Persistence & Dirty Tracking Tests', () {
    late _MockFilePicker mockPicker;
    late SarvFileService fileService;
    late DocumentCubit cubit;
    late Directory tempDir;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockPicker = _MockFilePicker();
      fileService = SarvFileService(filePicker: mockPicker);
      cubit = DocumentCubit(null, fileService);
      tempDir = Directory.systemTemp.createTempSync('sarv_doc_persistence_');
    });

    tearDown(() {
      cubit.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Initial document starts not dirty and with default displayName', () {
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.filePath, isNull);
      expect(cubit.state.displayName, equals('Treble_A4_Portrait'));
    });

    test('Mutating score or config marks document as dirty', () {
      expect(cubit.state.isDirty, isFalse);

      cubit.setTitle('Brandenburg Concerto');
      expect(cubit.state.isDirty, isTrue);
      expect(cubit.state.displayName, equals('Brandenburg Concerto'));

      // Undoing returns to saved state and resets isDirty
      cubit.undo();
      expect(cubit.state.isDirty, isFalse);

      // Redoing makes it dirty again
      cubit.redo();
      expect(cubit.state.isDirty, isTrue);
    });

    test('newDocument resets document, history, dirty state, and filePath', () {
      cubit.setTitle('Dirty Score');
      expect(cubit.state.isDirty, isTrue);

      cubit.newDocument(core.StaffProfiles.stringQuartet);

      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.filePath, isNull);
      expect(cubit.state.undoStack, isEmpty);
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.allStaves.length, equals(4));
    });

    test('loadDocument replaces document, sets filePath, and resets dirty state', () {
      const extDoc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'External Score'),
      );

      cubit.loadDocument(extDoc, filePath: '/scores/external.sarv');

      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.filePath, equals('/scores/external.sarv'));
      expect(cubit.state.displayName, equals('external.sarv'));
      expect(cubit.state.metadata.title, equals('External Score'));
    });

    test('save when filePath is null triggers saveAs flow', () async {
      final targetPath = '${tempDir.path}/first_save.sarv';
      mockPicker.saveResult = targetPath;

      cubit.setTitle('My Masterpiece');
      expect(cubit.state.isDirty, isTrue);

      final success = await cubit.save();
      expect(success, isTrue);
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.filePath, equals(targetPath));
      expect(cubit.state.displayName, equals('first_save.sarv'));

      final file = File(targetPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['format'], equals('sarv'));
      expect(json['metadata']['title'], equals('My Masterpiece'));
    });

    test('save when filePath exists updates file in-place without saveAs', () async {
      final targetPath = '${tempDir.path}/in_place.sarv';
      const initialDoc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'Initial Title'),
      );
      cubit.loadDocument(initialDoc, filePath: targetPath);

      cubit.setTitle('Updated Title');
      expect(cubit.state.isDirty, isTrue);

      final success = await cubit.save();
      expect(success, isTrue);
      expect(cubit.state.isDirty, isFalse);
      expect(cubit.state.filePath, equals(targetPath));

      final file = File(targetPath);
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['metadata']['title'], equals('Updated Title'));
    });

    test('saveAs always prompts for destination and updates state', () async {
      final targetPath1 = '${tempDir.path}/v1.sarv';
      final targetPath2 = '${tempDir.path}/v2.sarv';

      mockPicker.saveResult = targetPath1;
      await cubit.save();
      expect(cubit.state.filePath, equals(targetPath1));

      // Now Save As to v2
      mockPicker.saveResult = targetPath2;
      final success = await cubit.saveAs();

      expect(success, isTrue);
      expect(cubit.state.filePath, equals(targetPath2));
      expect(cubit.state.isDirty, isFalse);
      expect(File(targetPath2).existsSync(), isTrue);
    });

    test('openFile loads selected file into cubit', () async {
      const sampleDoc = core.SarvDocument(
        metadata: core.DocumentMetadata(title: 'Opened Symphony'),
      );
      final testFile = File('${tempDir.path}/symphony.sarv');
      testFile.writeAsStringSync(jsonEncode(sampleDoc.toJson()));

      mockPicker.pickResult = FilePickerResult([
        PlatformFile(
          name: 'symphony.sarv',
          size: testFile.lengthSync(),
          path: testFile.path,
        ),
      ]);

      final success = await cubit.openFile();

      expect(success, isTrue);
      expect(cubit.state.filePath, equals(testFile.path));
      expect(cubit.state.displayName, equals('symphony.sarv'));
      expect(cubit.state.metadata.title, equals('Opened Symphony'));
      expect(cubit.state.isDirty, isFalse);
    });
  });
}
