// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/document/document_state.dart';
import '../top_bar_menu_handler.dart';
import '../top_bar_menu_header.dart';

/// `View` desktop menu for the top bar.
///
/// Covers page size presets (via cascading submenu), orientation toggle, theme toggle, and language switch.
/// The [onThemeToggle] callback is provided by the parent so the menu stays decoupled
/// from the concrete theme management implementation (ThemeCubit, etc.).
class TopBarViewMenu extends StatelessWidget {
  final DocumentState documentState;
  final core.PageConfig configState;
  final VoidCallback? onThemeToggle;

  const TopBarViewMenu({
    super.key,
    required this.documentState,
    required this.configState,
    this.onThemeToggle,
  });

  /// Builds the [Widget] entries for the View menu.
  ///
  /// Shared between desktop wide-mode [TopBarViewMenu] and compact [TopBarCompactAppMenu].
  static List<Widget> buildChildren(
    BuildContext context,
    DocumentState documentState,
    core.PageConfig configState, [
    VoidCallback? onThemeToggle,
  ]) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return [
      // ── Score Page Sizes ▸ ───────────────────────────────────────────
      SubmenuButton(
        leadingIcon: Icon(Icons.aspect_ratio_rounded, size: 17, color: cs.onSurface),
        menuChildren: [
          _buildPageSizeItem(context, documentState, configState, core.PageSize.a3, 'A3 (297×420 mm)', cs),
          _buildPageSizeItem(context, documentState, configState, core.PageSize.a4, 'A4 (210×297 mm)', cs),
          _buildPageSizeItem(context, documentState, configState, core.PageSize.a5, 'A5 (148×210 mm)', cs),
          _buildPageSizeItem(context, documentState, configState, core.PageSize.b4, 'B4 (250×353 mm)', cs),
          _buildPageSizeItem(context, documentState, configState, core.PageSize.b5, 'B5 (176×250 mm)', cs),
          _buildPageSizeItem(context, documentState, configState, core.PageSize.letter, 'Letter (216×279 mm)', cs),
        ],
        child: Text(l10n.headerScorePageSizes),
      ),

      // ── Orientation ──────────────────────────────────────────────────
      MenuItemButton(
        leadingIcon: Icon(Icons.screen_rotation_outlined, size: 17, color: cs.onSurface),
        onPressed: () => handleTopBarMenuSelection(context, 'toggle_orientation', documentState),
        child: Text(
          l10n.orientationToggleSummary(
            configState.orientation == core.PageOrientation.portrait
                ? l10n.portrait
                : l10n.landscape,
          ),
        ),
      ),
      const Divider(),

      // ── Theme toggle ─────────────────────────────────────────────────
      MenuItemButton(
        leadingIcon: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 17,
          color: cs.onSurface,
        ),
        onPressed: onThemeToggle ?? () => handleTopBarMenuSelection(context, 'theme', documentState),
        child: Text(isDark ? l10n.lightTheme : l10n.darkTheme),
      ),

      // ── Language toggle ──────────────────────────────────────────────
      MenuItemButton(
        leadingIcon: Icon(Icons.language, size: 17, color: cs.onSurface),
        onPressed: () => handleTopBarMenuSelection(context, 'language', documentState),
        child: Text(l10n.toggleLanguage),
      ),
    ];
  }

  static Widget _buildPageSizeItem(
    BuildContext context,
    DocumentState documentState,
    core.PageConfig configState,
    core.PageSize pageSize,
    String label,
    ColorScheme cs,
  ) {
    final isSelected = configState.pageSize == pageSize;
    return MenuItemButton(
      leadingIcon: Icon(
        isSelected ? Icons.check_rounded : null,
        size: 17,
        color: cs.primary,
      ),
      onPressed: () => handleTopBarMenuSelection(
        context,
        'preset_${pageSize.name}',
        documentState,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? cs.primary : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TopBarMenuHeader(
      label: l10n.menuView,
      menuChildren: buildChildren(context, documentState, configState, onThemeToggle),
    );
  }
}
