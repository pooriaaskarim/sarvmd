// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';

final _log = AppLogger.export;

/// Service managing the list of recently opened or saved `.sarv` manuscript documents.
class RecentDocumentsService {
  static const String _prefKey = 'sarvmd_recent_documents';
  static const int maxRecentDocuments = 10;

  /// Reactive notifier holding the current cached list of recent file paths.
  static final ValueNotifier<List<String>> recentDocumentsNotifier =
      ValueNotifier<List<String>>([]);

  static bool _initialized = false;

  /// Initializes the service and loads stored recent documents into [recentDocumentsNotifier].
  static Future<List<String>> init() async {
    if (_initialized) return recentDocumentsNotifier.value;
    final docs = await _loadFromPrefs();
    recentDocumentsNotifier.value = docs;
    _initialized = true;
    return docs;
  }

  /// Returns the current list of valid recent document paths.
  static Future<List<String>> getRecentDocuments() async {
    if (!_initialized) {
      return await init();
    }
    return recentDocumentsNotifier.value;
  }

  /// Adds a [filePath] to the top of the recent documents list.
  ///
  /// Deduplicates existing entries and caps the list to [maxRecentDocuments].
  static Future<void> addRecentDocument(String filePath) async {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty) return;

    final current = List<String>.from(recentDocumentsNotifier.value);
    current.remove(trimmed);
    current.insert(0, trimmed);

    if (current.length > maxRecentDocuments) {
      current.removeRange(maxRecentDocuments, current.length);
    }

    recentDocumentsNotifier.value = current;
    await _saveToPrefs(current);
    _log.debug('Added recent document', context: {'path': trimmed, 'count': current.length});
  }

  /// Removes a specific [filePath] from the recent documents list.
  static Future<void> removeRecentDocument(String filePath) async {
    final current = List<String>.from(recentDocumentsNotifier.value);
    final removed = current.remove(filePath.trim());
    if (removed) {
      recentDocumentsNotifier.value = current;
      await _saveToPrefs(current);
      _log.debug('Removed recent document', context: {'path': filePath});
    }
  }

  /// Clears all recent documents from memory and persistent storage.
  static Future<void> clearRecentDocuments() async {
    recentDocumentsNotifier.value = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      _log.info('Cleared recent documents history');
    } catch (e) {
      _log.error('Failed to clear recent documents from SharedPreferences', error: e);
    }
  }

  static Future<List<String>> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKey) ?? [];
      
      // On native desktop/mobile, filter out files that no longer exist on disk
      if (!kIsWeb) {
        final existing = list.where((p) => File(p).existsSync()).toList();
        if (existing.length != list.length) {
          // Prune missing files in prefs asynchronously
          await prefs.setStringList(_prefKey, existing);
        }
        return existing;
      }
      return list;
    } catch (e) {
      _log.error('Failed to load recent documents from SharedPreferences', error: e);
      return [];
    }
  }

  static Future<void> _saveToPrefs(List<String> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, list);
    } catch (e) {
      _log.error('Failed to save recent documents to SharedPreferences', error: e);
    }
  }

  /// Resets internal state (primarily for unit tests).
  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    recentDocumentsNotifier.value = [];
  }
}
