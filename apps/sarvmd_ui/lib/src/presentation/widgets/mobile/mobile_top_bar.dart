// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../layout/sarv_reactive_brand_logo.dart';
import '../layout/top_bar/top_bar_menu_handler.dart';
import '../layout/top_bar/widgets/editable_score_header.dart';

/// Centered-title top bar for SarvMD Mobile Proposal B ("Conductor's Baton").
class MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileTopBar({
    super.key,
    this.height = 40.0,
    this.onOpenDrawer,
  });

  final double height;
  final VoidCallback? onOpenDrawer;

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
                // Left Zone: Conductor Drawer Trigger + Brand Logo
                IconButton(
                  icon: const Icon(Icons.menu, size: 20),
                  tooltip: l10n.appMenuTooltip,
                  onPressed: onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                ),
                const SizedBox(width: 2),
                const SarvReactiveBrandLogo(logoHeight: 18.0),

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

                // Right Zone: Options & Export Dropdown Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  tooltip: l10n.appMenuTooltip,
                  onSelected: (action) {
                    handleTopBarMenuSelection(context, action, docState);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          const Icon(Icons.ios_share, size: 18),
                          const SizedBox(width: 8),
                          Text('${l10n.exportManuscriptTitle}...'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'about',
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.aboutSarvMD),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
