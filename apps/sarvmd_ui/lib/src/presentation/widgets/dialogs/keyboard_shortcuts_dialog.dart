// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'adaptive_dialog_helper.dart';

/// Shows the standard SarvMD Keyboard Shortcuts Cheat-Sheet dialog.
Future<void> showKeyboardShortcutsDialog(BuildContext context) {
  return showSarvAdaptiveModal<void>(
    context: context,
    maxWidth: 680.0,
    builder: (ctx, isMobile) => const KeyboardShortcutsDialog(),
  );
}

/// Category identifier for grouping related shortcuts.
enum ShortcutCategory {
  file,
  edit,
  canvas,
  panels,
  general,
}

/// Representation of a single keyboard shortcut entry.
class ShortcutItem {
  final ShortcutCategory category;
  final String Function(AppLocalizations l10n) titleBuilder;
  final List<List<String>> keys;
  final List<List<String>>? macKeys;

  const ShortcutItem({
    required this.category,
    required this.titleBuilder,
    required this.keys,
    this.macKeys,
  });

  List<List<String>> getEffectiveKeys(bool isMac) {
    if (isMac && macKeys != null) return macKeys!;
    return keys;
  }
}

/// Standardized list of all application keyboard shortcuts.
final List<ShortcutItem> appShortcuts = [
  // ── File & Tabs ──────────────────────────────────────────────────────────
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutNewDocument,
    keys: const [
      ['Ctrl', 'N']
    ],
    macKeys: const [
      ['⌘', 'N']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutOpenDocument,
    keys: const [
      ['Ctrl', 'O']
    ],
    macKeys: const [
      ['⌘', 'O']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutSaveDocument,
    keys: const [
      ['Ctrl', 'S']
    ],
    macKeys: const [
      ['⌘', 'S']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutSaveAsDocument,
    keys: const [
      ['Ctrl', 'Shift', 'S']
    ],
    macKeys: const [
      ['⌘', '⇧', 'S']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutExport,
    keys: const [
      ['Ctrl', 'E']
    ],
    macKeys: const [
      ['⌘', 'E']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutDocumentProperties,
    keys: const [
      ['Ctrl', 'I']
    ],
    macKeys: const [
      ['⌘', 'I']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutNewTab,
    keys: const [
      ['Ctrl', 'T']
    ],
    macKeys: const [
      ['⌘', 'T']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutCloseTab,
    keys: const [
      ['Ctrl', 'W']
    ],
    macKeys: const [
      ['⌘', 'W']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutNextTab,
    keys: const [
      ['Ctrl', 'Tab']
    ],
    macKeys: const [
      ['⌘', '⇥']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.file,
    titleBuilder: (l10n) => l10n.shortcutPreviousTab,
    keys: const [
      ['Ctrl', 'Shift', 'Tab']
    ],
    macKeys: const [
      ['⌘', '⇧', '⇥']
    ],
  ),

  // ── Edit & History ───────────────────────────────────────────────────────
  ShortcutItem(
    category: ShortcutCategory.edit,
    titleBuilder: (l10n) => l10n.shortcutUndo,
    keys: const [
      ['Ctrl', 'Z']
    ],
    macKeys: const [
      ['⌘', 'Z']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.edit,
    titleBuilder: (l10n) => l10n.shortcutRedo,
    keys: const [
      ['Ctrl', 'Y'],
      ['Ctrl', 'Shift', 'Z'],
    ],
    macKeys: const [
      ['⌘', '⇧', 'Z'],
    ],
  ),

  // ── Canvas Navigation & Zoom ─────────────────────────────────────────────
  ShortcutItem(
    category: ShortcutCategory.canvas,
    titleBuilder: (l10n) => l10n.shortcutZoomIn,
    keys: const [
      ['Ctrl', '+']
    ],
    macKeys: const [
      ['⌘', '+']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.canvas,
    titleBuilder: (l10n) => l10n.shortcutZoomOut,
    keys: const [
      ['Ctrl', '-']
    ],
    macKeys: const [
      ['⌘', '-']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.canvas,
    titleBuilder: (l10n) => l10n.shortcutZoomReset,
    keys: const [
      ['Ctrl', '0']
    ],
    macKeys: const [
      ['⌘', '0']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.canvas,
    titleBuilder: (l10n) => l10n.shortcutPanCanvas,
    keys: const [
      ['Space', 'Drag']
    ],
    macKeys: const [
      ['␣', 'Drag']
    ],
  ),

  // ── Panels & View ────────────────────────────────────────────────────────
  ShortcutItem(
    category: ShortcutCategory.panels,
    titleBuilder: (l10n) => l10n.shortcutToggleSidebar,
    keys: const [
      ['Ctrl', 'B']
    ],
    macKeys: const [
      ['⌘', 'B']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.panels,
    titleBuilder: (l10n) => l10n.shortcutToggleViewPanel,
    keys: const [
      ['Ctrl', r'\']
    ],
    macKeys: const [
      ['⌘', r'\']
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.panels,
    titleBuilder: (l10n) => l10n.shortcutToggleZenMode,
    keys: const [
      ['F11']
    ],
    macKeys: const [
      ['F11']
    ],
  ),

  // ── General & Dialogs ────────────────────────────────────────────────────
  ShortcutItem(
    category: ShortcutCategory.general,
    titleBuilder: (l10n) => l10n.shortcutHelp,
    keys: const [
      ['F1'],
      ['Ctrl', '/'],
    ],
    macKeys: const [
      ['F1'],
      ['⌘', '/'],
    ],
  ),
  ShortcutItem(
    category: ShortcutCategory.general,
    titleBuilder: (l10n) => l10n.shortcutCloseDialog,
    keys: const [
      ['Esc']
    ],
    macKeys: const [
      ['⎋']
    ],
  ),
];

/// A tactile physical-style keycap badge.
class KeycapBadge extends StatelessWidget {
  final String keyLabel;

  const KeycapBadge({super.key, required this.keyLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.9)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black12,
            offset: const Offset(0, 1.5),
            blurRadius: 1.0,
          ),
        ],
      ),
      child: Text(
        keyLabel,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          color: cs.onSurface,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// A combo of keycaps joined by '+'.
class KeycapCombo extends StatelessWidget {
  final List<String> combo;

  const KeycapCombo({super.key, required this.combo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < combo.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            KeycapBadge(keyLabel: combo[i]),
          ],
        ],
      ),
    );
  }
}

/// Interactive Keyboard Shortcuts Cheat-Sheet modal dialog.
class KeyboardShortcutsDialog extends StatefulWidget {
  const KeyboardShortcutsDialog({super.key});

  @override
  State<KeyboardShortcutsDialog> createState() => _KeyboardShortcutsDialogState();
}

class _KeyboardShortcutsDialogState extends State<KeyboardShortcutsDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isMacOs() {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String _categoryTitle(ShortcutCategory cat, AppLocalizations l10n) {
    switch (cat) {
      case ShortcutCategory.file:
        return l10n.shortcutCategoryFile;
      case ShortcutCategory.edit:
        return l10n.shortcutCategoryEdit;
      case ShortcutCategory.canvas:
        return l10n.shortcutCategoryCanvas;
      case ShortcutCategory.panels:
        return l10n.shortcutCategoryPanels;
      case ShortcutCategory.general:
        return l10n.shortcutCategoryGeneral;
    }
  }

  IconData _categoryIcon(ShortcutCategory cat) {
    switch (cat) {
      case ShortcutCategory.file:
        return Icons.folder_outlined;
      case ShortcutCategory.edit:
        return Icons.edit_note_outlined;
      case ShortcutCategory.canvas:
        return Icons.zoom_in_outlined;
      case ShortcutCategory.panels:
        return Icons.view_sidebar_outlined;
      case ShortcutCategory.general:
        return Icons.tune_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final isMac = _isMacOs();

    final query = _filterQuery.trim().toLowerCase();

    // Filter items based on title, category or key names
    final filtered = appShortcuts.where((item) {
      if (query.isEmpty) return true;
      final title = item.titleBuilder(l10n).toLowerCase();
      if (title.contains(query)) return true;
      final catTitle = _categoryTitle(item.category, l10n).toLowerCase();
      if (catTitle.contains(query)) return true;

      final keys = item.getEffectiveKeys(isMac);
      for (final combo in keys) {
        if (combo.any((k) => k.toLowerCase().contains(query))) return true;
      }
      return false;
    }).toList();

    // Group filtered items by category
    final grouped = <ShortcutCategory, List<ShortcutItem>>{};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header & Close ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(Icons.keyboard_outlined, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.keyboardShortcutsTitle,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.keyboardShortcutsSubtitle,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.shortcutCloseDialog,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Search & Filter Bar ──────────────────────────────────────────
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _filterQuery = val;
              });
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.keyboardShortcutsSearchPlaceholder,
              prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
              suffixIcon: _filterQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _filterQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Shortcuts List View ──────────────────────────────────────────
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 460),
              child: grouped.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 40,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noShortcutsFound,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final cat in ShortcutCategory.values)
                          if (grouped.containsKey(cat)) ...[
                            _buildCategorySection(
                              context: context,
                              category: cat,
                              items: grouped[cat]!,
                              l10n: l10n,
                              isMac: isMac,
                              cs: cs,
                              tt: tt,
                            ),
                            const SizedBox(height: 16),
                          ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required ShortcutCategory category,
    required List<ShortcutItem> items,
    required AppLocalizations l10n,
    required bool isMac,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(_categoryIcon(category), size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  _categoryTitle(category, l10n),
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Shortcut Rows
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 14,
                endIndent: 14,
                color: cs.outlineVariant.withValues(alpha: 0.25),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].titleBuilder(l10n),
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Combos (handle multiple alternatives like Ctrl+Y or Ctrl+Shift+Z)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (int c = 0; c < items[i].getEffectiveKeys(isMac).length; c++) ...[
                        if (c > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Text(
                              '/',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        KeycapCombo(combo: items[i].getEffectiveKeys(isMac)[c]),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
