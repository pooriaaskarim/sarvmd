// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';

final _log = AppLogger.export;

/// Multiplatform service for managing and selecting output export directories.
class ExportDirectoryService {
  static const String _prefKey = 'sarvmd_export_directory';

  /// Returns true if running on a browser (Web).
  static bool get isWeb => kIsWeb;

  /// Returns the default fallback export directory string synchronously.
  static String getDefaultDirectory() {
    if (isWeb) return 'Browser Downloads';
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return 'System File Picker';
    }
    final currentPath = Directory.current.path;
    if (currentPath == '/' || currentPath.isEmpty) {
      return 'System File Picker';
    }
    return p.join(currentPath, 'output');
  }

  /// Loads the persisted export directory from [SharedPreferences],
  /// or returns the default fallback directory.
  static Future<String> getExportDirectory() async {
    if (isWeb) return 'Browser Downloads';
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return 'System File Picker';
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty && Directory(saved).existsSync()) {
        return saved;
      }
    } catch (e) {
      _log.error('Failed to load export directory preference', error: e);
    }
    return getDefaultDirectory();
  }

  /// Normalizes raw directory path input, expanding `~` to user home directory,
  /// stripping `file://` URI schemes, and removing trailing separators.
  static String normalizeDirectoryPath(String raw) {
    var path = raw.trim();
    if (path.isEmpty) return path;

    // Handle file:// URI scheme
    if (path.startsWith('file://')) {
      try {
        path = Uri.parse(path).toFilePath();
      } catch (_) {
        path = path.replaceFirst('file://', '');
      }
    }

    // Expand ~ / ~/ on non-web platforms
    if (!kIsWeb && (path == '~' || path.startsWith('~/') || path.startsWith(r'~\'))) {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        path = path == '~' ? home : p.join(home, path.substring(2));
      }
    }

    // Clean redundant separators
    path = p.normalize(path);
    return path;
  }

  /// Save a custom export directory path to [SharedPreferences].
  static Future<void> saveExportDirectory(String path) async {
    if (isWeb) return;
    try {
      final normalized = normalizeDirectoryPath(path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, normalized);
      _log.info('Export directory preference saved', context: {'path': normalized});
    } catch (e) {
      _log.error('Failed to save export directory preference', error: e);
    }
  }

  /// Opens the native OS directory picker dialog (Linux/macOS/Windows)
  /// and returns the chosen directory path, or `null` if canceled.
  static Future<String?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
  }) async {
    if (isWeb) return null;
    try {
      final startDir = initialDirectory != null && initialDirectory.isNotEmpty
          ? normalizeDirectoryPath(initialDirectory)
          : await getExportDirectory();
      final effectiveStartDir = Directory(startDir).existsSync() ? startDir : null;

      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle ?? 'Select Manuscript Export Folder',
        initialDirectory: effectiveStartDir,
      );
      if (selectedDirectory != null && selectedDirectory.trim().isNotEmpty) {
        final normalized = normalizeDirectoryPath(selectedDirectory);
        await saveExportDirectory(normalized);
        return normalized;
      }
    } catch (e) {
      _log.error('Error opening native directory picker', error: e);
    }
    return null;
  }
}
