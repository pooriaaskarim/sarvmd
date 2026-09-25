// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../core/theme/layout_policy.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';

import 'sarv_reactive_brand_logo.dart';
import 'top_bar/compact_menu.dart';
import 'top_bar/menus/edit_menu.dart';
import 'top_bar/menus/file_menu.dart';
import 'top_bar/menus/help_menu.dart';
import 'top_bar/menus/view_menu.dart';
import 'top_bar/top_bar_menu_handler.dart';
import 'top_bar/widgets/editable_score_header.dart';
import 'top_bar/widgets/undo_redo_cluster.dart';
import '../common/input_mode_toggle_button.dart';

/// Professional Dorico / Figma-style top control header bar for SarvMD.
class SarvTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SarvTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, documentState) {
        final configState = documentState.config;
        final topPadding = MediaQuery.paddingOf(context).top;
        final totalHeight = 52.0 + topPadding;

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            height: totalHeight,
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding,
              left: 12.0,
              right: 12.0,
            ),
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
                final isCompact = constraints.maxWidth < SarvBreakpoints.desktopTopBarMenuThreshold;

                final undoRedoCluster = UndoRedoCluster(
                  documentState: documentState,
                  onUndo: () => context.read<DocumentCubit>().undo(),
                  onRedo: () => context.read<DocumentCubit>().redo(),
                );

                if (isCompact) {
                  return _CompactLayout(
                    documentState: documentState,
                    configState: configState,
                    undoRedoCluster: undoRedoCluster,
                  );
                }

                return _WideLayout(
                  documentState: documentState,
                  configState: configState,
                  undoRedoCluster: undoRedoCluster,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout variants
// ─────────────────────────────────────────────────────────────────────────────

/// Compact top-bar layout for viewports narrower than [SarvBreakpoints.desktopTopBarMenuThreshold] (760 px).
class _CompactLayout extends StatelessWidget {
  final DocumentState documentState;
  final core.PageConfig configState;
  final Widget undoRedoCluster;

  const _CompactLayout({
    required this.documentState,
    required this.configState,
    required this.undoRedoCluster,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SarvReactiveBrandLogo(isMenuMode: false),
        const SizedBox(width: 4.0),
        TopBarCompactAppMenu(
          documentState: documentState,
          configState: configState,
        ),
        const SizedBox(width: 4.0),
        undoRedoCluster,
        const SizedBox(width: 6.0),
        Expanded(
          child: Center(
            child: EditableScoreHeader(
              score: documentState.score,
              configState: configState,
              isCompact: true,
            ),
          ),
        ),
        const SizedBox(width: 4.0),
        const InputModeToggleButton(),
      ],
    );
  }
}

/// Full wide-mode top-bar layout for viewports at least [SarvBreakpoints.desktopTopBarMenuThreshold] (760 px) wide.
class _WideLayout extends StatelessWidget {
  final DocumentState documentState;
  final core.PageConfig configState;
  final Widget undoRedoCluster;

  const _WideLayout({
    required this.documentState,
    required this.configState,
    required this.undoRedoCluster,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Zone 1: Brand & Desktop Menus ─────────────────────────────────
        const SarvReactiveBrandLogo(isMenuMode: false),
        const SizedBox(width: 8.0),

        TopBarFileMenu(documentState: documentState),
        TopBarEditMenu(documentState: documentState),
        TopBarViewMenu(
          documentState: documentState,
          configState: configState,
          onThemeToggle: () => handleTopBarMenuSelection(context, 'theme', documentState),
        ),
        TopBarHelpMenu(documentState: documentState),

        const SizedBox(width: 4.0),
        undoRedoCluster,
        const SizedBox(width: 6.0),

        // ── Zone 2: Center Metadata ───────────────────────────────────────
        Expanded(
          child: Center(
            child: EditableScoreHeader(
              score: documentState.score,
              configState: configState,
            ),
          ),
        ),
        const SizedBox(width: 4.0),
        const InputModeToggleButton(),
      ],
    );
  }
}
