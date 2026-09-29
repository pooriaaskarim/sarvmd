// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/workspace/document_session.dart';
import '../../../logic/workspace/workspace_cubit.dart';
import '../dialogs/unsaved_changes_dialog.dart';

/// Shows the touch-optimized bottom-sheet tab switcher modal.
Future<void> showTouchTabSwitcher(BuildContext context) {
  final workspaceCubit = context.read<WorkspaceCubit?>();
  if (workspaceCubit == null) return Future.value();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (modalContext) {
      return BlocProvider.value(
        value: workspaceCubit,
        child: const TouchTabSwitcherModal(),
      );
    },
  );
}

/// A touch-friendly modal card carousel/list for switching and managing open manuscripts.
class TouchTabSwitcherModal extends StatelessWidget {
  const TouchTabSwitcherModal({super.key});

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
    final workspaceCubit = context.watch<WorkspaceCubit>();
    final state = workspaceCubit.state;
    final cs = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.72;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10.0),
            // Drag Handle Pill
            Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(height: 12.0),

            // Modal Header: Title + "+ New" Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 22.0,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    'Manuscripts (${state.tabCount})',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    key: const ValueKey('touch_tab_modal_new_button'),
                    icon: const Icon(Icons.add, size: 16.0),
                    label: const Text('New'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      workspaceCubit.openNewTab();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            const Divider(height: 1.0),

            // Scrollable List of Document Cards
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                itemCount: state.tabCount,
                separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final session = state.sessions[index];
                  final isActive = index == state.activeIndex;
                  final isDirty = session.isDirty;

                  return Dismissible(
                    key: ValueKey('dismiss_tab_${session.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmClose(context, session),
                    onDismissed: (_) {
                      final isSoleTab = state.tabCount <= 1;
                      final sessionIndex = workspaceCubit.state.sessions.indexWhere((s) => s.id == session.id);
                      if (sessionIndex != -1) {
                        workspaceCubit.closeTab(sessionIndex);
                      }
                      if (isSoleTab && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: cs.onErrorContainer,
                        size: 24.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('touch_tab_card_${session.id}'),
                        borderRadius: BorderRadius.circular(16.0),
                        onTap: () {
                          if (!isActive) {
                            workspaceCubit.switchTab(index);
                          }
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: isActive
                                ? cs.primaryContainer.withValues(alpha: 0.25)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: isActive
                                  ? cs.primary
                                  : cs.outlineVariant.withValues(alpha: 0.35),
                              width: isActive ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Musical Icon Badge
                              Container(
                                width: 38.0,
                                height: 38.0,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? cs.primary.withValues(alpha: 0.15)
                                      : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  size: 20.0,
                                  color: isActive ? cs.primary : cs.outline,
                                ),
                              ),
                              const SizedBox(width: 14.0),

                              // Title and subtitle metadata
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            session.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: isActive
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ),
                                        if (isDirty) ...[
                                          const SizedBox(width: 6.0),
                                          Container(
                                            width: 7.0,
                                            height: 7.0,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: cs.primary,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: cs.primary.withValues(alpha: 0.5),
                                                  blurRadius: 4.0,
                                                  spreadRadius: 1.0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3.0),
                                    Text(
                                      session.filePath != null
                                          ? session.filePath!
                                          : '${session.cubit.state.staffCount} staves',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Active Tab Badge or Close Button
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(right: 6.0),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 3.0),
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary,
                                    ),
                                  ),
                                ),

                              IconButton(
                                key: ValueKey('touch_tab_close_${session.id}'),
                                icon: const Icon(Icons.close, size: 18.0),
                                tooltip: 'Close',
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  final canClose = await _confirmClose(context, session);
                                  if (canClose) {
                                    final isSoleTab = state.tabCount <= 1;
                                    final sessionIndex = workspaceCubit.state.sessions.indexWhere((s) => s.id == session.id);
                                    if (sessionIndex != -1) {
                                      await workspaceCubit.closeTab(sessionIndex);
                                    }
                                    if (isSoleTab && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
