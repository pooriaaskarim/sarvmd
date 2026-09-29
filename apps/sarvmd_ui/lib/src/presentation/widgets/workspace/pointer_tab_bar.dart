// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/workspace/document_session.dart';
import '../../../logic/workspace/workspace_cubit.dart';
import '../dialogs/unsaved_changes_dialog.dart';
import 'pointer_tab_item.dart';

/// Desktop IDE-style horizontal tab bar for SarvMD.
///
/// Optimized for pointer interaction with horizontal scrolling, middle-click close,
/// auto-scrolling to active tab, and a portrait/narrow-viewport overflow dropdown.
class PointerTabBar extends StatefulWidget implements PreferredSizeWidget {
  const PointerTabBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(32.0);

  @override
  State<PointerTabBar> createState() => _PointerTabBarState();
}

class _PointerTabBarState extends State<PointerTabBar> {
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _ensureActiveTabVisible(int activeIndex, int totalTabs) {
    if (!_scrollController.hasClients) return;
    // Estimate position: each tab is roughly 140dp
    const tabEstimatedWidth = 140.0;
    final targetOffset = (activeIndex * tabEstimatedWidth) - 40.0;
    final clamped = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<bool> _confirmClose(BuildContext context, DocumentSession session) async {
    if (!session.isDirty) return true;
    final action = await showUnsavedChangesDialog(
      context,
      documentName: session.title,
    );
    if (action == UnsavedChangesAction.save) {
      return await session.cubit.save();
    }
    if (action == UnsavedChangesAction.discard) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final workspaceCubit = context.watch<WorkspaceCubit?>();
    if (workspaceCubit == null) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final state = workspaceCubit.state;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait || screenWidth < 760;
    final barHeight = isPortrait ? 30.0 : 32.0;

    // Check if active index changed and scroll
    if (state.activeIndex != _lastActiveIndex) {
      _lastActiveIndex = state.activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureActiveTabVisible(state.activeIndex, state.tabCount);
      });
    }

    return Container(
      key: const ValueKey('pointer_tab_bar'),
      height: barHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Scrollable tab items strip
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: state.tabCount,
                itemBuilder: (context, index) {
                  final session = state.sessions[index];
                  final isActive = index == state.activeIndex;

                  return PointerTabItem(
                    key: ValueKey('tab_item_${session.id}'),
                    session: session,
                    isActive: isActive,
                    onTap: () => workspaceCubit.switchTab(index),
                    onClose: () => workspaceCubit.closeTab(
                      index,
                      unsavedGuard: (s) => _confirmClose(context, s),
                    ),
                    onMiddleClick: () => workspaceCubit.closeTab(
                      index,
                      unsavedGuard: (s) => _confirmClose(context, s),
                    ),
                  );
                },
              ),
            ),
          ),

          // Action: New Tab Button (+)
          Tooltip(
            message: 'New Tab (Ctrl+T)',
            child: InkWell(
              key: const ValueKey('tab_bar_add_button'),
              borderRadius: BorderRadius.circular(4.0),
              onTap: () => workspaceCubit.openNewTab(),
              child: Container(
                width: 28.0,
                height: barHeight,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: 16.0,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),

          // Action: Portrait / Narrow Viewport Tab Overflow Dropdown Menu [ ▾ ]
          PopupMenuButton<int>(
            key: const ValueKey('tab_bar_overflow_menu'),
            tooltip: 'All Open Tabs',
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.expand_more,
              size: 17.0,
              color: cs.onSurfaceVariant,
            ),
            onSelected: (index) {
              if (index >= 0) {
                workspaceCubit.switchTab(index);
              } else if (index == -1) {
                workspaceCubit.openNewTab();
              } else if (index == -2) {
                workspaceCubit.closeOtherTabs(
                  state.activeIndex,
                  unsavedGuard: (s) => _confirmClose(context, s),
                );
              }
            },
            itemBuilder: (menuContext) {
              final items = <PopupMenuEntry<int>>[];

              for (int i = 0; i < state.tabCount; i++) {
                final s = state.sessions[i];
                final isCurrent = i == state.activeIndex;

                items.add(
                  PopupMenuItem<int>(
                    value: i,
                    height: 36.0,
                    child: Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.check : Icons.description_outlined,
                          size: 16.0,
                          color: isCurrent ? cs.primary : cs.outline,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent ? cs.primary : cs.onSurface,
                            ),
                          ),
                        ),
                        if (s.isDirty) ...[
                          const SizedBox(width: 6.0),
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              items.add(const PopupMenuDivider());

              items.add(
                const PopupMenuItem<int>(
                  value: -1,
                  height: 36.0,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 16.0),
                      SizedBox(width: 8.0),
                      Text('New Tab', style: TextStyle(fontSize: 13.0)),
                    ],
                  ),
                ),
              );

              if (state.tabCount > 1) {
                items.add(
                  const PopupMenuItem<int>(
                    value: -2,
                    height: 36.0,
                    child: Row(
                      children: [
                        Icon(Icons.close_fullscreen, size: 16.0),
                        SizedBox(width: 8.0),
                        Text('Close Other Tabs', style: TextStyle(fontSize: 13.0)),
                      ],
                    ),
                  ),
                );
              }

              return items;
            },
          ),
          const SizedBox(width: 4.0),
        ],
      ),
    );
  }
}
