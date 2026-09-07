// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/config/config_cubit.dart';
import '../../../logic/score/score_cubit.dart';
import '../dialogs/export_dialog.dart';

import 'sarv_reactive_brand_logo.dart';
import 'top_bar/compact_menu.dart';
import 'top_bar/menus/edit_menu.dart';
import 'top_bar/menus/file_menu.dart';
import 'top_bar/menus/help_menu.dart';
import 'top_bar/menus/view_menu.dart';
import 'top_bar/top_bar_menu_handler.dart';
import 'top_bar/widgets/editable_score_header.dart';
import 'top_bar/widgets/ensemble_profile_picker.dart';
import 'top_bar/widgets/split_export_button.dart';
import 'top_bar/widgets/undo_redo_cluster.dart';

/// Professional Dorico / Figma-style top control header bar for SarvMD.
///
/// This widget is intentionally thin — it is a **layout orchestrator** only.
/// All interactive logic lives in the specialised modules under `top_bar/`:
///
/// ```
/// top_bar/
///   compact_menu.dart            – flat popup items for < 960 px mode
///   top_bar_menu_handler.dart    – central action dispatcher (switch)
///   top_bar_menu_header.dart     – shared PopupMenuButton shell
///   menus/
///     file_menu.dart             – File ▸ Export
///     edit_menu.dart             – Edit ▸ Undo/Redo, Add/Edit Staff
///     view_menu.dart             – View ▸ Page sizes, orientation, theme
///     help_menu.dart             – Help ▸ About
///   widgets/
///     undo_redo_cluster.dart     – Undo / Redo icon buttons
///     ensemble_profile_picker.dart – Ensemble preset quick-picker
///     editable_score_header.dart – Inline-editable Title & Composer
///     split_export_button.dart   – Split CTA export button
/// ```
///
/// ## Layout Zones
/// - **Left Zone**: Brand Logo → Desktop Menus (File, Edit, View, Help) → Undo/Redo → Ensemble Picker
/// - **Center Zone**: Inline-editable Title • Composer + Layout Status Pill
/// - **Right Zone**: Split Export CTA Button
///
/// ## Responsiveness
/// [LayoutBuilder] switches between wide (≥ 960 px) and compact (< 960 px) layouts.
/// The compact layout collapses all menus into a single logo-triggered popup.
class SarvTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SarvTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeExt = Theme.of(context).extension<SarvThemeExtension>();

    return BlocBuilder<ScoreCubit, ScoreState>(
      builder: (context, scoreState) {
        return BlocBuilder<ConfigCubit, core.PageConfig>(
          builder: (context, configState) {
            final activeProfile = context.read<ConfigCubit>().activeProfile;

            return Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                height: 52.0,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 960;

                    final undoRedoCluster = UndoRedoCluster(
                      scoreState: scoreState,
                      onUndo: () => context.read<ScoreCubit>().undo(),
                      onRedo: () => context.read<ScoreCubit>().redo(),
                    );

                    final exportButton = SplitExportButton(
                      label: l10n.export,
                      onPrimaryPressed: () => showExportDialog(context),
                      onMenuSelected: (value) =>
                          handleTopBarMenuSelection(context, value, scoreState),
                    );

                    if (isCompact) {
                      return _CompactLayout(
                        scoreState: scoreState,
                        configState: configState,
                        l10n: l10n,
                        cs: cs,
                        themeExt: themeExt,
                        undoRedoCluster: undoRedoCluster,
                        exportButton: exportButton,
                      );
                    }

                    return _WideLayout(
                      scoreState: scoreState,
                      configState: configState,
                      activeProfile: activeProfile,
                      undoRedoCluster: undoRedoCluster,
                      exportButton: exportButton,
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout variants
// ─────────────────────────────────────────────────────────────────────────────

/// Compact top-bar layout for viewports narrower than 960 px.
///
/// All menus collapse into a single [PopupMenuButton] triggered by the brand
/// logo. Undo/Redo and the export button remain visible.
class _CompactLayout extends StatelessWidget {
  final ScoreState scoreState;
  final core.PageConfig configState;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final SarvThemeExtension? themeExt;
  final Widget undoRedoCluster;
  final Widget exportButton;

  const _CompactLayout({
    required this.scoreState,
    required this.configState,
    required this.l10n,
    required this.cs,
    required this.themeExt,
    required this.undoRedoCluster,
    required this.exportButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PopupMenuButton<String>(
          tooltip: 'App Menu',
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          color: cs.surfaceContainerHigh,
          onSelected: (value) => handleTopBarMenuSelection(context, value, scoreState),
          itemBuilder: (context) => buildCompactMenuItems(
            context,
            l10n,
            cs,
            themeExt,
            scoreState,
            configState,
          ),
          child: const SarvReactiveBrandLogo(isMenuMode: true),
        ),
        const SizedBox(width: 4.0),
        undoRedoCluster,
        const SizedBox(width: 6.0),
        Expanded(
          child: Center(
            child: EditableScoreHeader(
              score: scoreState.score,
              configState: configState,
              isCompact: true,
            ),
          ),
        ),
        const SizedBox(width: 6.0),
        exportButton,
      ],
    );
  }
}

/// Full wide-mode top-bar layout for viewports at least 960 px wide.
///
/// Shows the brand logo, all four desktop menus, undo/redo, ensemble picker,
/// inline score header, and the export button.
class _WideLayout extends StatelessWidget {
  final ScoreState scoreState;
  final core.PageConfig configState;
  final core.StaffProfile? activeProfile;
  final Widget undoRedoCluster;
  final Widget exportButton;

  const _WideLayout({
    required this.scoreState,
    required this.configState,
    required this.activeProfile,
    required this.undoRedoCluster,
    required this.exportButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Zone 1: Brand, Menus & Ensemble Picker ────────────────────────
        const SarvReactiveBrandLogo(isMenuMode: false),
        const SizedBox(width: 8.0),

        TopBarFileMenu(scoreState: scoreState),
        TopBarEditMenu(scoreState: scoreState),
        TopBarViewMenu(
          scoreState: scoreState,
          configState: configState,
          // Theme toggle is handled inside the handler via a 'theme' key.
          // The view menu fires the same handler; the orchestrator owns nothing.
          onThemeToggle: () => handleTopBarMenuSelection(context, 'theme', scoreState),
        ),
        TopBarHelpMenu(scoreState: scoreState),

        const SizedBox(width: 4.0),
        undoRedoCluster,
        const SizedBox(width: 6.0),

        EnsembleProfilePicker(activeProfile: activeProfile),

        // ── Zone 2: Center Metadata ───────────────────────────────────────
        Expanded(
          child: Center(
            child: EditableScoreHeader(
              score: scoreState.score,
              configState: configState,
            ),
          ),
        ),

        // ── Zone 3: Export CTA ────────────────────────────────────────────
        exportButton,
      ],
    );
  }
}
