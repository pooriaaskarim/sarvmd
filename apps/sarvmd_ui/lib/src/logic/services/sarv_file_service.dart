// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/utils/app_logger.dart';
import 'native_file_save_service.dart';
import 'recent_documents_service.dart';
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

    // On Web, use native File System Access or FileReader to avoid casting bugs
    if (kIsWeb && _customPicker == null) {
      final webResult = await openFileWeb();
      if (webResult == null) {
        _log.debug('Web file picking cancelled by user');
        return null;
      }
      return _parseJsonDocument(
        webResult.content,
        fileName: webResult.fileName,
        filePath: webResult.fileName,
      );
    }

    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    FilePickerResult? result;

    try {
      result = await _filePicker.pickFiles(
        type: isMobile ? FileType.any : FileType.custom,
        allowedExtensions: isMobile ? null : const ['sarv'],
        allowMultiple: false,
        withData: true,
      );
    } on PlatformException catch (e) {
      // Android MimeTypeMap fails for unregistered custom extensions like .sarv.
      // Gracefully fall back to FileType.any if the platform rejects custom extension filter.
      _log.warning(
        'Platform file picker rejected custom extension filter, falling back to FileType.any',
        error: e,
      );
      result = await _filePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );
    }

    if (result == null || result.files.isEmpty) {
      _log.debug('File picking cancelled by user');
      return null;
    }

    final platformFile = result.files.first;
    final fileName = platformFile.name;
    final isBlobOrWeb = platformFile.path != null &&
        (platformFile.path!.startsWith('blob:') ||
            platformFile.path!.startsWith('http:') ||
            platformFile.path!.startsWith('data:'));
    final filePath = (!kIsWeb && !isBlobOrWeb && platformFile.path != null)
        ? platformFile.path
        : (kIsWeb ? platformFile.name : null);

    String jsonString;
    if (platformFile.bytes != null) {
      jsonString = utf8.decode(platformFile.bytes!);
    } else if (platformFile.readStream != null) {
      final chunks = await platformFile.readStream!.toList();
      final bytes = chunks.expand((c) => c).toList();
      jsonString = utf8.decode(bytes);
    } else if (filePath != null && !kIsWeb) {
      final file = File(filePath);
      jsonString = await file.readAsString();
    } else {
      throw const FormatException('Unable to read selected file contents.');
    }

    return _parseJsonDocument(jsonString, filePath: filePath, fileName: fileName);
  }

  /// Parses raw JSON text into a validated [SarvFileLoadResult].
  SarvFileLoadResult _parseJsonDocument(
    String rawJson, {
    String? filePath,
    required String fileName,
  }) {
    var jsonString = rawJson;
    // Strip UTF-8 Byte Order Mark (BOM) if present
    if (jsonString.startsWith('\uFEFF')) {
      jsonString = jsonString.substring(1);
    }
    jsonString = jsonString.trim();

    dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw FormatException('File is not valid JSON: $e');
    }

    if (decoded is! Map) {
      throw const FormatException('Expected JSON object as root of .sarv document.');
    }

    final map = decoded.cast<String, dynamic>();

    if (map['format'] != 'sarv') {
      throw const FormatException('File is not a valid SarvMD manuscript document (missing format: "sarv").');
    }

    final document = core.SarvDocument.fromJson(map);
    if (filePath != null && filePath.isNotEmpty && !kIsWeb) {
      RecentDocumentsService.addRecentDocument(filePath);
    }
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

  /// Loads and parses a `.sarv` file directly from the filesystem [path].
  Future<SarvFileLoadResult> loadFileFromPath(String path) async {
    if (kIsWeb) {
      throw UnsupportedError('Direct path reading is unsupported on web');
    }
    final file = File(path);
    final jsonString = await file.readAsString();
    return _parseJsonDocument(jsonString, filePath: path, fileName: p.basename(path));
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
      RecentDocumentsService.addRecentDocument(filePath);
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

    if (kIsWeb && _customPicker == null) {
      final savedName = await saveFileWeb(sanitizedName, bytes);
      return savedName;
    }

    if (!kIsWeb && Platform.isAndroid && _customPicker == null) {
      final chosenPath = await NativeFileSaveService.saveFile(
        fileName: sanitizedName,
        bytes: bytes,
        mimeType: 'application/octet-stream',
      );
      if (chosenPath == null) {
        _log.debug('Save As cancelled by user');
        return null;
      }
      final effectivePath = _normalizeExtension(chosenPath);
      RecentDocumentsService.addRecentDocument(effectivePath);
      _log.info('Successfully saved .sarv document via native Android SAF', context: {'filePath': effectivePath});
      return effectivePath;
    }

    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    String? chosenPath;

    try {
      chosenPath = await _filePicker.saveFile(
        dialogTitle: 'Save Manuscript Document',
        fileName: sanitizedName,
        type: isMobile ? FileType.any : FileType.custom,
        allowedExtensions: isMobile ? null : const ['sarv'],
        bytes: bytes,
      );
    } on PlatformException catch (e) {
      _log.warning(
        'Platform save dialog rejected custom extension filter, falling back to FileType.any',
        error: e,
      );
      chosenPath = await _filePicker.saveFile(
        dialogTitle: 'Save Manuscript Document',
        fileName: sanitizedName,
        type: FileType.any,
        bytes: bytes,
      );
    }

    if (chosenPath == null) {
      _log.debug('Save As cancelled by user');
      return null;
    }

    final effectivePath = _normalizeExtension(chosenPath);
    try {
      final file = File(effectivePath);
      await file.writeAsBytes(bytes);
    } catch (e) {
      _log.warning('Could not write directly to effectivePath (may be managed by OS/SAF)', error: e);
    }
    RecentDocumentsService.addRecentDocument(effectivePath);
    _log.info('Successfully saved .sarv document', context: {'filePath': effectivePath});
    return effectivePath;
  }

  static String _normalizeExtension(String name) {
    if (name.trim().isEmpty) return 'Untitled Manuscript.sarv';
    if (!name.toLowerCase().endsWith('.sarv')) {
      final base = core.FileNaming.stripExtension(name);
      return '$base.sarv';
    }
    return name;
  }
}
