// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../layout/top_bar/top_bar_menu_handler.dart';
import '../layout/top_bar/widgets/editable_score_header.dart';
import '../common/input_mode_toggle_button.dart';

/// Centered-title top bar for SarvMD Mobile Proposal B ("Conductor's Baton").
class MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileTopBar({
    super.key,
    this.height = 40.0,
    this.onOpenDrawer,
    this.onOpenMenu,
  });

  final double height;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenMenu;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final totalHeight = height + topPadding;

    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, docState) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            height: totalHeight,
            width: double.infinity,
            padding: EdgeInsets.only(
              top: topPadding,
              left: 6.0,
              right: 6.0,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                // Left Zone: Conductor Drawer Trigger
                IconButton(
                  icon: const Icon(Icons.menu, size: 20),
                  tooltip: l10n.appMenuTooltip,
                  onPressed: onOpenMenu ?? onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                ),

                // Center Zone: Centered Document Score Title (Inline Editable)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: EditableScoreHeader(
                        score: docState.score,
                        configState: docState.config,
                        isCompact: true,
                      ),
                    ),
                  ),
                ),

                // Right Zone: Mode Toggle & Export Quick Action
                const InputModeToggleButton(),
                IconButton(
                  icon: const Icon(Icons.ios_share, size: 19),
                  tooltip: l10n.exportManuscriptTitle,
                  onPressed: () => handleTopBarMenuSelection(context, 'export', docState),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
