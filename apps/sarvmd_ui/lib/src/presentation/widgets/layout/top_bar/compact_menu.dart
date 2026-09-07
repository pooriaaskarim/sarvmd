// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../logic/document/document_cubit.dart';
import '../../../../logic/document/document_state.dart';

/// Builds the flat [PopupMenuEntry] list used by the compact (< 960 px) app-menu.
///
/// In compact mode there is no room for separate "File / Edit / View / Help"
/// headers, so everything collapses into a single [PopupMenuButton] triggered
/// by tapping the brand logo. Sections are separated by dividers and non-
/// interactive header rows that mirror the wide-mode menu grouping.
///
/// All labels are fully localised via [AppLocalizations] and the item set is
/// kept in parity with the desktop menus (File, Edit, View, Help).
List<PopupMenuEntry<String>> buildCompactMenuItems(
  BuildContext context,
  AppLocalizations l10n,
  ColorScheme cs,
  SarvThemeExtension? themeExt,
  DocumentState documentState,
  core.PageConfig configState,
) {
  final documentCubit = context.read<DocumentCubit>();
  final allStaves = documentCubit.allStaves;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return [
    // ── Brand header card (non-interactive) ─────────────────────────────────
    PopupMenuItem<String>(
      enabled: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/handwriting/Sarv Handwriting.svg',
              height: 28.0,
              colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
            ),
            const SizedBox(height: 4.0),
            Text(
              l10n.appSubtitle,
              style: themeExt?.brandSubtitleStyle ??
                  TextStyle(
                    fontSize: 13.5,
                    fontFamily: 'IranNastaliq',
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
            ),
          ],
        ),
      ),
    ),

    // ── FILE ─────────────────────────────────────────────────────────────────
    const PopupMenuDivider(),
    _sectionHeader(l10n.menuFile, cs),
    PopupMenuItem<String>(
      value: 'export',
      child: _menuRow(
        icon: Icons.file_upload_outlined,
        label: l10n.export,
        cs: cs,
        iconColor: cs.primary,
        labelColor: cs.primary,
        bold: true,
      ),
    ),

    // ── EDIT ─────────────────────────────────────────────────────────────────
    const PopupMenuDivider(),
    _sectionHeader(l10n.menuEdit, cs),

    // Undo
    PopupMenuItem<String>(
      value: 'undo',
      enabled: documentState.canUndo,
      child: _menuRow(
        icon: Icons.undo_rounded,
        label: documentState.lastUndoLabel != null ? '${l10n.undo} ${documentState.lastUndoLabel}' : l10n.undo,
        cs: cs,
        iconColor: documentState.canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
        labelColor: documentState.canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
        trailing: 'Ctrl+Z',
      ),
    ),

    // Redo
    PopupMenuItem<String>(
      value: 'redo',
      enabled: documentState.canRedo,
      child: _menuRow(
        icon: Icons.redo_rounded,
        label: documentState.lastRedoLabel != null ? '${l10n.redo} ${documentState.lastRedoLabel}' : l10n.redo,
        cs: cs,
        iconColor: documentState.canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
        labelColor: documentState.canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
        trailing: 'Ctrl+Y',
      ),
    ),

    // History info
    PopupMenuItem<String>(
      enabled: false,
      child: _menuRow(
        icon: Icons.history,
        label: l10n.editHistoryCount(documentState.undoStack.length),
        cs: cs,
        iconColor: cs.onSurface.withValues(alpha: 0.55),
        labelColor: cs.onSurface.withValues(alpha: 0.55),
      ),
    ),

    const PopupMenuDivider(),
    // Add Staff sub-section header
    _subSectionHeader(l10n.addStaffToSystem, cs),

    PopupMenuItem<String>(
      value: 'add_staff_5line',
      child: _menuRow(
        icon: Icons.music_note_outlined,
        label: l10n.staffPreset5LineTreble,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'add_staff_5line_bass',
      child: _menuRow(
        icon: Icons.music_note_outlined,
        label: l10n.staffPreset5LineBass,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'add_staff_grand',
      child: _menuRow(
        icon: Icons.piano_outlined,
        label: l10n.staffPresetGrandPair,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'add_staff_tab',
      child: _menuRow(
        icon: Icons.grid_on_outlined,
        label: l10n.staffPreset6LineTab,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'add_staff_rhythm',
      child: _menuRow(
        icon: Icons.horizontal_rule_outlined,
        label: l10n.staffPreset1LineRhythm,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'add_staff_custom',
      child: _menuRow(
        icon: Icons.tune_outlined,
        label: l10n.staffPresetCustomConfigure,
        cs: cs,
        iconColor: cs.primary,
        labelColor: cs.primary,
        bold: true,
      ),
    ),

    // Edit Staff sub-section (only when staves exist)
    if (allStaves.isNotEmpty) ...[
      const PopupMenuDivider(),
      _subSectionHeader(l10n.editStaff, cs),
      for (var i = 0; i < allStaves.length; i++)
        () {
          final staff = allStaves[i];
          final label = staff.instrumentName?.isNotEmpty == true
              ? staff.instrumentName!
              : l10n.staffNumberWithHash(i + 1);
          return PopupMenuItem<String>(
            value: 'edit_staff_$i',
            child: _menuRow(
              icon: Icons.tune_outlined,
              label: l10n.staffMenuSummary(i + 1, label, staff.lines),
              cs: cs,
            ),
          );
        }(),
    ],

    // Remove Staff sub-section (only when more than 1 staff)
    if (allStaves.length > 1) ...[
      const PopupMenuDivider(),
      _subSectionHeader(l10n.removeStaff, cs),
      for (var i = 0; i < allStaves.length; i++)
        () {
          final staff = allStaves[i];
          final label = staff.instrumentName?.isNotEmpty == true
              ? staff.instrumentName!
              : l10n.staffNumberWithHash(i + 1);
          return PopupMenuItem<String>(
            value: 'remove_staff_$i',
            child: _menuRow(
              icon: Icons.remove_circle_outline,
              label: l10n.staffMenuSummary(i + 1, label, staff.lines),
              cs: cs,
              iconColor: cs.error,
              labelColor: cs.error,
            ),
          );
        }(),
    ],

    // ── VIEW ─────────────────────────────────────────────────────────────────
    const PopupMenuDivider(),
    _sectionHeader(l10n.menuView, cs),

    // Page sizes sub-header
    _subSectionHeader(l10n.headerScorePageSizes, cs),
    PopupMenuItem<String>(
      value: 'preset_a3',
      child: _pageSizeRow(
        label: 'A3 (297×420 mm)',
        isActive: configState.pageSize == core.PageSize.a3,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'preset_a4',
      child: _pageSizeRow(
        label: 'A4 (210×297 mm)',
        isActive: configState.pageSize == core.PageSize.a4,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'preset_a5',
      child: _pageSizeRow(
        label: 'A5 (148×210 mm)',
        isActive: configState.pageSize == core.PageSize.a5,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'preset_b4',
      child: _pageSizeRow(
        label: 'B4 (250×353 mm)',
        isActive: configState.pageSize == core.PageSize.b4,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'preset_b5',
      child: _pageSizeRow(
        label: 'B5 (176×250 mm)',
        isActive: configState.pageSize == core.PageSize.b5,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'preset_letter',
      child: _pageSizeRow(
        label: 'Letter (216×279 mm)',
        isActive: configState.pageSize == core.PageSize.letter,
        cs: cs,
      ),
    ),

    const PopupMenuDivider(),
    PopupMenuItem<String>(
      value: 'toggle_orientation',
      child: _menuRow(
        icon: configState.orientation == core.PageOrientation.portrait
            ? Icons.stay_current_portrait_outlined
            : Icons.stay_current_landscape_outlined,
        label: l10n.orientationToggleSummary(
          configState.orientation == core.PageOrientation.portrait
              ? l10n.portrait
              : l10n.landscape,
        ),
        cs: cs,
      ),
    ),

    const PopupMenuDivider(),
    PopupMenuItem<String>(
      value: 'theme',
      child: _menuRow(
        icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        label: isDark ? l10n.lightTheme : l10n.darkTheme,
        cs: cs,
      ),
    ),
    PopupMenuItem<String>(
      value: 'language',
      child: _menuRow(
        icon: Icons.language,
        label: l10n.toggleLanguage,
        cs: cs,
      ),
    ),

    // ── HELP ─────────────────────────────────────────────────────────────────
    const PopupMenuDivider(),
    _sectionHeader(l10n.menuHelp, cs),
    PopupMenuItem<String>(
      value: 'about',
      child: _menuRow(
        icon: Icons.info_outline,
        label: l10n.aboutSarvMD,
        cs: cs,
      ),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Non-interactive section header (mirrors a top-level desktop menu label).
PopupMenuItem<String> _sectionHeader(String label, ColorScheme cs) {
  return PopupMenuItem<String>(
    enabled: false,
    height: 28.0,
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: cs.primary,
      ),
    ),
  );
}

/// Non-interactive sub-section header (mirrors a SubmenuButton label).
PopupMenuItem<String> _subSectionHeader(String label, ColorScheme cs) {
  return PopupMenuItem<String>(
    enabled: false,
    height: 26.0,
    padding: const EdgeInsets.only(left: 28.0, right: 12.0),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: Colors.grey.shade500,
      ),
    ),
  );
}

/// A standard icon + label row with an optional trailing keyboard shortcut hint.
Widget _menuRow({
  required IconData icon,
  required String label,
  required ColorScheme cs,
  Color? iconColor,
  Color? labelColor,
  bool bold = false,
  String? trailing,
}) {
  return Row(
    children: [
      Icon(icon, size: 18, color: iconColor ?? cs.onSurface),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: labelColor ?? cs.onSurface,
          ),
        ),
      ),
      if (trailing != null) ...[
        const SizedBox(width: 8),
        Text(
          trailing,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
      ],
    ],
  );
}

/// A page-size row with a leading checkmark when active.
Widget _pageSizeRow({
  required String label,
  required bool isActive,
  required ColorScheme cs,
}) {
  return Row(
    children: [
      SizedBox(
        width: 18,
        child: isActive
            ? Icon(Icons.check, size: 16, color: cs.primary)
            : const SizedBox.shrink(),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    ],
  );
}
