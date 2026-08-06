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

  /// Returns the default fallback export directory.
  static String getDefaultDirectory() {
    if (isWeb) return 'Browser Downloads';
    return p.join(Directory.current.path, 'output');
  }

  /// Loads the persisted export directory from [SharedPreferences],
  /// or returns the default fallback directory.
  static Future<String> getExportDirectory() async {
    if (isWeb) return 'Browser Downloads';
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

  /// Save a custom export directory path to [SharedPreferences].
  static Future<void> saveExportDirectory(String path) async {
    if (isWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, path);
      _log.info('Export directory preference saved', context: {'path': path});
    } catch (e) {
      _log.error('Failed to save export directory preference', error: e);
    }
  }

  /// Opens the native OS directory picker dialog (Linux/macOS/Windows)
  /// and returns the chosen directory path, or `null` if canceled.
  static Future<String?> pickDirectory({String? dialogTitle}) async {
    if (isWeb) return null;
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle ?? 'Select Manuscript Export Folder',
      );
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        await saveExportDirectory(selectedDirectory);
        return selectedDirectory;
      }
    } catch (e) {
      _log.error('Error opening native directory picker', error: e);
    }
    return null;
  }
}
