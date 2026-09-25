// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../layout/top_bar/top_bar_menu_handler.dart';
import '../layout/top_bar/widgets/editable_score_header.dart';
import '../common/input_mode_toggle_button.dart';

/// Adaptive Dynamic Header for SarvMD Touch Mode ("Zen Top Bar").
///
/// Supports three synthesized interaction modes:
/// 1. Pinned: Statically docked at top of viewport.
/// 2. Floating Unpinned: Frosted glassmorphic pill that auto-slides off-screen on canvas pan/zoom.
/// 3. Compact Micro-Pill: Centered title capsule leaving maximum canvas clearance.
class MobileTopBar extends StatelessWidget implements PreferredSizeWidget {
  const MobileTopBar({
    super.key,
    this.height = 40.0,
    this.onOpenDrawer,
    this.onOpenMenu,
    this.isPinned = true,
    this.onTogglePin,
    this.isCompactPill = false,
    this.onToggleCompact,
  });

  final double height;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenMenu;
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final bool isCompactPill;
  final VoidCallback? onToggleCompact;

  @override
  Size get preferredSize => Size.fromHeight(height);

  Widget _buildCompactPill(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    DocumentState docState,
    double topPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding + 4.0),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              key: const ValueKey('top_bar_compact_pill'),
              height: 36.0,
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Menu Trigger
                  IconButton(
                    icon: const Icon(Icons.menu, size: 18),
                    tooltip: l10n.appMenuTooltip,
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: onOpenMenu ?? onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                  ),

                  // 2. Score Title (Tap to expand full bar)
                  InkWell(
                    onTap: onToggleCompact,
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        docState.score.title.trim().isEmpty ? 'Untitled Score' : docState.score.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // 3. Expand Button
                  IconButton(
                    icon: const Icon(Icons.more_horiz, size: 18),
                    tooltip: 'Expand header',
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: onToggleCompact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBar(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    DocumentState docState,
    double topPadding,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding + 4.0,
        left: 12.0,
        right: 12.0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            key: const ValueKey('top_bar_floating_bar'),
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12.0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Menu Trigger
                IconButton(
                  icon: const Icon(Icons.menu, size: 20),
                  tooltip: l10n.appMenuTooltip,
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onOpenMenu ?? onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                ),

                // 2. Score Title Header
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

                // 3. Pin / Unpin Button
                if (onTogglePin != null)
                  IconButton(
                    icon: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: isPinned ? cs.primary : cs.onSurfaceVariant,
                    ),
                    tooltip: isPinned ? 'Unpin toolbar' : 'Pin toolbar',
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onTogglePin,
                  ),

                // 4. Minimize to Pill Button
                if (onToggleCompact != null)
                  IconButton(
                    icon: const Icon(Icons.unfold_less, size: 18),
                    tooltip: 'Minimize to pill',
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: onToggleCompact,
                  ),

                // 5. Input Mode Toggle & Export Quick Action
                const InputModeToggleButton(),
                IconButton(
                  icon: const Icon(Icons.ios_share, size: 19),
                  tooltip: l10n.exportManuscriptTitle,
                  padding: const EdgeInsets.all(4.0),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => handleTopBarMenuSelection(context, 'export', docState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedBar(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    DocumentState docState,
    double topPadding,
    double totalHeight,
  ) {
    return Container(
      key: const ValueKey('top_bar_pinned_bar'),
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

          // Pin / Unpin Button
          if (onTogglePin != null)
            IconButton(
              icon: Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18,
                color: isPinned ? cs.primary : cs.onSurfaceVariant,
              ),
              tooltip: isPinned ? 'Unpin toolbar' : 'Pin toolbar',
              onPressed: onTogglePin,
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
    );
  }

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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isPinned
                ? _buildPinnedBar(context, cs, l10n, docState, topPadding, totalHeight)
                : isCompactPill
                    ? _buildCompactPill(context, cs, l10n, docState, topPadding)
                    : _buildFloatingBar(context, cs, l10n, docState, topPadding),
          ),
        );
      },
    );
  }
}
