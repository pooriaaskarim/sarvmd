// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/utils/app_logger.dart';
import 'web_download/web_download.dart';

final _log = AppLogger.export;

/// Result of loading a `.sarv` file from disk or web picker.
class SarvFileLoadResult {
  final core.SarvDocument document;
  final String? filePath;
  final String fileName;

  const SarvFileLoadResult({
    required this.document,
    this.filePath,
    required this.fileName,
  });
}

/// Service managing loading and saving of native `.sarv` JSON manuscript documents across platforms.
class SarvFileService {
  final FilePicker? _customPicker;

  SarvFileService({FilePicker? filePicker}) : _customPicker = filePicker;

  FilePicker get _filePicker => _customPicker ?? FilePicker.platform;

  /// Prompts the user to pick a `.sarv` file and deserializes it into a [core.SarvDocument].
  ///
  /// Returns `null` if the user cancels the picker dialog.
  /// Throws [FormatException] if the selected file is not a valid `.sarv` document.
  Future<SarvFileLoadResult?> openSarvFile() async {
    _log.info('Opening file picker for .sarv document');

    final result = await _filePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['sarv'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      _log.debug('File picking cancelled by user');
      return null;
    }

    final platformFile = result.files.first;
    final fileName = platformFile.name;
    final filePath = platformFile.path;

    String jsonString;
    if (platformFile.bytes != null) {
      jsonString = utf8.decode(platformFile.bytes!);
    } else if (filePath != null && !kIsWeb) {
      final file = File(filePath);
      jsonString = await file.readAsString();
    } else {
      throw const FormatException('Unable to read selected file contents.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw FormatException('File is not valid JSON: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object as root of .sarv document.');
    }

    if (decoded['format'] != 'sarv') {
      throw const FormatException('File is not a valid SarvMD manuscript document (missing format: "sarv").');
    }

    final document = core.SarvDocument.fromJson(decoded);
    _log.info('Successfully loaded .sarv document', context: {
      'fileName': fileName,
      'filePath': filePath ?? 'web',
      'title': document.metadata.title,
    });

    return SarvFileLoadResult(
      document: document,
      filePath: filePath,
      fileName: fileName,
    );
  }

  /// Saves the given [document] to disk.
  ///
  /// If [filePath] is non-null and not running on Web, saves directly to that path without prompting.
  /// Otherwise, opens the platform save-file dialog.
  ///
  /// Returns the saved file path (or file name on Web), or `null` if cancelled by user.
  Future<String?> saveSarvFile({
    required core.SarvDocument document,
    String? filePath,
    required String defaultFileName,
  }) async {
    final sanitizedName = _normalizeExtension(defaultFileName);
    final jsonMap = document.toJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    // Direct desktop save to existing path
    if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
      _log.info('Directly saving .sarv document to existing path', context: {'filePath': filePath});
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    }

    // Otherwise prompt platform save dialog
    return await saveAsSarvFile(
      document: document,
      defaultFileName: sanitizedName,
    );
  }

  /// Always prompts the user for a save destination to save [document].
  ///
  /// Returns the chosen file path (or file name on Web), or `null` if cancelled by user.
  Future<String?> saveAsSarvFile({
    required core.SarvDocument document,
    required String defaultFileName,
  }) async {
    final sanitizedName = _normalizeExtension(defaultFileName);
    final jsonMap = document.toJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));

    _log.info('Prompting saveAs for .sarv document', context: {'defaultFileName': sanitizedName});

    if (kIsWeb) {
      downloadFileWeb(sanitizedName, bytes, 'application/json');
      return sanitizedName;
    }

    final chosenPath = await _filePicker.saveFile(
      dialogTitle: 'Save Manuscript Document',
      fileName: sanitizedName,
      type: FileType.custom,
      allowedExtensions: const ['sarv'],
      bytes: bytes,
    );

    if (chosenPath == null) {
      _log.debug('Save As cancelled by user');
      return null;
    }

    final effectivePath = _normalizeExtension(chosenPath);
    final file = File(effectivePath);
    await file.writeAsBytes(bytes);
    _log.info('Successfully saved .sarv document', context: {'filePath': effectivePath});
    return effectivePath;
  }

  static String _normalizeExtension(String name) {
    if (name.trim().isEmpty) return 'Untitled.sarv';
    if (!name.toLowerCase().endsWith('.sarv')) {
      return '$name.sarv';
    }
    return name;
  }
}
