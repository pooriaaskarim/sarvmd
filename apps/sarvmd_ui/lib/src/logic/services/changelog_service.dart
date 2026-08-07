// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/services.dart' show rootBundle;
import '../../core/utils/app_logger.dart';

final _log = AppLogger.config;

class ChangelogChange {
  final String category;
  final String text;

  const ChangelogChange({
    required this.category,
    required this.text,
  });
}

class ReleaseEntry {
  final String version;
  final String date;
  final List<ChangelogChange> changes;

  const ReleaseEntry({
    required this.version,
    required this.date,
    required this.changes,
  });
}

/// Dynamic parser and loader service for project [CHANGELOG.md].
class ChangelogService {
  static List<ReleaseEntry>? _cachedEntries;

  /// Loads and parses [CHANGELOG.md] from Flutter asset bundle.
  static Future<List<ReleaseEntry>> loadChangelog() async {
    if (_cachedEntries != null) return _cachedEntries!;

    try {
      final content = await rootBundle.loadString('CHANGELOG.md');
      final entries = parseMarkdown(content);
      _cachedEntries = entries;
      _log.debug('CHANGELOG.md dynamically loaded and parsed',
          context: {'releaseCount': entries.length});
      return entries;
    } catch (e, st) {
      _log.error('Failed to load dynamic CHANGELOG.md asset',
          error: e, stackTrace: st);
      return [];
    }
  }

  /// Parses standard Keep-a-Changelog Markdown format into structured models.
  static List<ReleaseEntry> parseMarkdown(String markdown) {
    final List<ReleaseEntry> entries = [];
    final lines = markdown.split('\n');

    String? currentVersion;
    String? currentDate;
    String? currentCategory;
    List<ChangelogChange> currentChanges = [];

    void commitCurrentEntry() {
      if (currentVersion != null && currentVersion != 'Unreleased') {
        entries.add(ReleaseEntry(
          version: currentVersion,
          date: currentDate ?? '',
          changes: List.unmodifiable(currentChanges),
        ));
      }
      currentChanges = [];
    }

    final versionHeaderRegex = RegExp(r'^##\s*\[([^\]]+)\](?:\s*-\s*(.*))?');
    final categoryHeaderRegex = RegExp(r'^###\s*(.+)');
    final itemRegex = RegExp(r'^\s*-\s*(.+)');

    for (final line in lines) {
      final trimmed = line.trim();

      // Check version header: ## [0.5.1] - 2026-08-07
      final vMatch = versionHeaderRegex.firstMatch(trimmed);
      if (vMatch != null) {
        commitCurrentEntry();
        currentVersion = vMatch.group(1)?.trim();
        currentDate = vMatch.group(2)?.trim() ?? '';
        currentCategory = null;
        continue;
      }

      // Check category header: ### Added
      final cMatch = categoryHeaderRegex.firstMatch(trimmed);
      if (cMatch != null) {
        currentCategory = cMatch.group(1)?.trim();
        continue;
      }

      // Check item line: - **Title**: Description...
      final iMatch = itemRegex.firstMatch(trimmed);
      if (iMatch != null && currentVersion != null) {
        final text = iMatch.group(1)?.trim() ?? '';
        currentChanges.add(ChangelogChange(
          category: currentCategory ?? 'Changed',
          text: text,
        ));
      }
    }

    commitCurrentEntry();
    return entries;
  }
}
