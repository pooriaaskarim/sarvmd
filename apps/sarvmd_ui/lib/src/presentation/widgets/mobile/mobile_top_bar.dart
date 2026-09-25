// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
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
class MobileTopBar extends StatefulWidget implements PreferredSizeWidget {
  const MobileTopBar({
    super.key,
    this.height = 40.0,
    this.onOpenDrawer,
    this.onOpenMenu,
    this.isPinned = true,
    this.onTogglePin,
    this.isCompactPill = false,
    this.onToggleCompact,
    this.onTitleEditingChanged,
  });

  final double height;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenMenu;
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final bool isCompactPill;
  final VoidCallback? onToggleCompact;
  final ValueChanged<bool>? onTitleEditingChanged;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<MobileTopBar> createState() => _MobileTopBarState();
}

class _MobileTopBarState extends State<MobileTopBar> {
  bool _isEditingTitle = false;
  final GlobalKey<EditableScoreHeaderState> _floatingHeaderKey = GlobalKey<EditableScoreHeaderState>();
  final GlobalKey<EditableScoreHeaderState> _pinnedHeaderKey = GlobalKey<EditableScoreHeaderState>();

  void _handleTitleEditingChanged(bool isEditing) {
    if (_isEditingTitle != isEditing) {
      setState(() {
        _isEditingTitle = isEditing;
      });
    }
    widget.onTitleEditingChanged?.call(isEditing);
  }

  Widget _buildCompactPill(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    DocumentState docState,
    double topPadding,
    double leftPadding,
    double rightPadding,
    double screenWidth,
  ) {
    final titleText = core.ScoreCompiler.getEffectiveTitle(docState.score, docState.config);
    const double rulerHeight = 25.0;
    const double minWidth = 120.0;
    final double maxWidth = (screenWidth - leftPadding - rightPadding - 32.0).clamp(minWidth, 340.0);

    return Padding(
      key: const ValueKey('top_bar_compact_pill_wrapper'),
      padding: EdgeInsets.only(top: topPadding + rulerHeight + 6.0),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.transparent,
              child: Tooltip(
                message: 'Expand toolbar',
                child: InkWell(
                  key: const ValueKey('top_bar_compact_pill'),
                  onTap: widget.onToggleCompact,
                  borderRadius: BorderRadius.circular(20.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: widget.height,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    constraints: BoxConstraints(
                      minWidth: minWidth,
                      maxWidth: maxWidth,
                    ),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            titleText,
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    double leftPadding,
    double rightPadding,
    bool isTightOnRoom,
  ) {
    final hideOtherStuff = _isEditingTitle && isTightOnRoom;
    const double rulerHeight = 25.0;
    const double leftRulerWidth = 25.0;

    return Padding(
      key: const ValueKey('top_bar_floating_bar_wrapper'),
      padding: EdgeInsets.only(
        top: topPadding + rulerHeight + 6.0,
        left: leftRulerWidth + 8.0 + leftPadding,
        right: 12.0 + rightPadding,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            key: const ValueKey('top_bar_floating_bar'),
            height: widget.height,
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
                if (!hideOtherStuff)
                  // 1. Menu Trigger
                  IconButton(
                    icon: const Icon(Icons.menu, size: 20),
                    tooltip: l10n.appMenuTooltip,
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: widget.onOpenMenu ?? widget.onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
                  ),

                // 2. Score Title Header (Expands to fill available room)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: EditableScoreHeader(
                        key: _floatingHeaderKey,
                        score: docState.score,
                        configState: docState.config,
                        isCompact: true,
                        expandInEditMode: true,
                        onEditingChanged: _handleTitleEditingChanged,
                      ),
                    ),
                  ),
                ),

                if (hideOtherStuff)
                  IconButton(
                    key: const ValueKey('top_bar_title_edit_done_button'),
                    icon: const Icon(Icons.check, size: 20),
                    tooltip: 'Done',
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    color: cs.primary,
                    onPressed: () {
                      _floatingHeaderKey.currentState?.submitTitle();
                      FocusScope.of(context).unfocus();
                    },
                  )
                else ...[
                  // 3. Pin / Unpin Button
                  if (widget.onTogglePin != null)
                    IconButton(
                      icon: Icon(
                        widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 18,
                        color: widget.isPinned ? cs.primary : cs.onSurfaceVariant,
                      ),
                      tooltip: widget.isPinned ? 'Unpin toolbar' : 'Pin toolbar',
                      padding: const EdgeInsets.all(4.0),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: widget.onTogglePin,
                    ),

                  // 4. Minimize to Pill Button
                  if (widget.onToggleCompact != null)
                    IconButton(
                      icon: const Icon(Icons.expand_less, size: 20),
                      tooltip: 'Collapse to title',
                      padding: const EdgeInsets.all(4.0),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: widget.onToggleCompact,
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
    double leftPadding,
    double rightPadding,
    double totalHeight,
    bool isTightOnRoom,
  ) {
    final hideOtherStuff = _isEditingTitle && isTightOnRoom;

    return Container(
      key: const ValueKey('top_bar_pinned_bar'),
      height: totalHeight,
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding,
        left: 6.0 + leftPadding,
        right: 6.0 + rightPadding,
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
          if (!hideOtherStuff)
            // Left Zone: Conductor Drawer Trigger
            IconButton(
              icon: const Icon(Icons.menu, size: 20),
              tooltip: l10n.appMenuTooltip,
              onPressed: widget.onOpenMenu ?? widget.onOpenDrawer ?? () => Scaffold.of(context).openDrawer(),
            ),

          // Center Zone: Centered Document Score Title (Inline Editable)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: EditableScoreHeader(
                  key: _pinnedHeaderKey,
                  score: docState.score,
                  configState: docState.config,
                  isCompact: true,
                  expandInEditMode: true,
                  onEditingChanged: _handleTitleEditingChanged,
                ),
              ),
            ),
          ),

          if (hideOtherStuff)
            IconButton(
              key: const ValueKey('top_bar_title_edit_done_button_pinned'),
              icon: const Icon(Icons.check, size: 20),
              tooltip: 'Done',
              color: cs.primary,
              onPressed: () {
                _pinnedHeaderKey.currentState?.submitTitle();
                FocusScope.of(context).unfocus();
              },
            )
          else ...[
            // Pin / Unpin Button
            if (widget.onTogglePin != null)
              IconButton(
                icon: Icon(
                  widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 18,
                  color: widget.isPinned ? cs.primary : cs.onSurfaceVariant,
                ),
                tooltip: widget.isPinned ? 'Unpin toolbar' : 'Pin toolbar',
                onPressed: widget.onTogglePin,
              ),

            // Right Zone: Mode Toggle & Export Quick Action
            const InputModeToggleButton(),
            IconButton(
              icon: const Icon(Icons.ios_share, size: 19),
              tooltip: l10n.exportManuscriptTitle,
              onPressed: () => handleTopBarMenuSelection(context, 'export', docState),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final leftPadding = MediaQuery.paddingOf(context).left;
    final rightPadding = MediaQuery.paddingOf(context).right;
    final totalHeight = widget.height + topPadding;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final isTightOnRoom = screenWidth < 560.0 || isPortrait;

    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, docState) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: widget.isPinned
                ? _buildPinnedBar(context, cs, l10n, docState, topPadding, leftPadding, rightPadding, totalHeight, isTightOnRoom)
                : widget.isCompactPill
                    ? _buildCompactPill(context, cs, l10n, docState, topPadding, leftPadding, rightPadding, screenWidth)
                    : _buildFloatingBar(context, cs, l10n, docState, topPadding, leftPadding, rightPadding, isTightOnRoom),
          ),
        );
      },
    );
  }
}
