import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../../l10n/app_localizations.dart';
import '../../../../logic/document/document_cubit.dart';
import '../../../../logic/document/document_state.dart';
import '../../../../logic/view/view_cubit.dart';
import '../../common/ensemble_summary_widget.dart';
import 'hierarchy_selection_scope.dart';
import 'staff_group_widget.dart';

class SystemHierarchyPanel extends StatefulWidget {
  const SystemHierarchyPanel({super.key, required this.notifier});

  final DocumentCubit notifier;

  @override
  State<SystemHierarchyPanel> createState() => _SystemHierarchyPanelState();
}

class _SystemHierarchyPanelState extends State<SystemHierarchyPanel> {
  final Set<String> _selectedUids = {};
  String? _lastSelectedUid;
  final Set<int> _collapsedGroupHashes = {};

  ViewCubit? _getViewCubit(BuildContext context) {
    try {
      return context.read<ViewCubit>();
    } catch (_) {
      return null;
    }
  }

  void _toggleSelection(
    String uid, {
    bool isShift = false,
    List<String>? allUidsInOrder,
  }) {
    final viewCubit = _getViewCubit(context);
    final currentSelected = Set<String>.from(
      viewCubit?.state.selectedHierarchyStaffUids ?? _selectedUids,
    );

    if (isShift && _lastSelectedUid != null && allUidsInOrder != null) {
      final startIdx = allUidsInOrder.indexOf(_lastSelectedUid!);
      final endIdx = allUidsInOrder.indexOf(uid);
      if (startIdx != -1 && endIdx != -1) {
        final low = math.min(startIdx, endIdx);
        final high = math.max(startIdx, endIdx);
        for (int i = low; i <= high; i++) {
          currentSelected.add(allUidsInOrder[i]);
        }
      } else {
        currentSelected.add(uid);
      }
    } else {
      if (currentSelected.contains(uid)) {
        currentSelected.remove(uid);
      } else {
        currentSelected.add(uid);
      }
    }
    _lastSelectedUid = uid;
    if (viewCubit != null) {
      viewCubit.setHierarchySelection(currentSelected);
    } else {
      setState(() {
        _selectedUids.clear();
        _selectedUids.addAll(currentSelected);
      });
    }
  }

  void _selectAll(List<String> allUids) {
    final viewCubit = _getViewCubit(context);
    final currentSelected =
        viewCubit?.state.selectedHierarchyStaffUids ?? _selectedUids;
    final Set<String> next;
    if (currentSelected.length == allUids.length) {
      next = {};
    } else {
      next = Set<String>.from(allUids);
    }
    if (viewCubit != null) {
      viewCubit.setHierarchySelection(next);
    } else {
      setState(() {
        _selectedUids.clear();
        _selectedUids.addAll(next);
      });
    }
  }

  void _clearSelection() {
    _lastSelectedUid = null;
    final viewCubit = _getViewCubit(context);
    if (viewCubit != null) {
      viewCubit.clearHierarchySelection();
    } else {
      setState(() {
        _selectedUids.clear();
      });
    }
  }

  void _toggleCollapseGroup(int groupHash) {
    final viewCubit = _getViewCubit(context);
    if (viewCubit != null) {
      viewCubit.toggleHierarchyGroup(groupHash);
    } else {
      setState(() {
        if (_collapsedGroupHashes.contains(groupHash)) {
          _collapsedGroupHashes.remove(groupHash);
        } else {
          _collapsedGroupHashes.add(groupHash);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, docState) {
        final cs = Theme.of(context).colorScheme;
        final layout = docState.config.systemLayout;
        final l10n = AppLocalizations.of(context)!;
        final isPersian = Localizations.localeOf(context).languageCode == 'fa';
        final textDirection = isPersian ? TextDirection.rtl : TextDirection.ltr;
        final allStaves = widget.notifier.allStaves;
        final allUidsInOrder = allStaves.map((s) => s.uid).toList();

        ViewCubit? viewCubit;
        try {
          viewCubit = context.watch<ViewCubit>();
        } catch (_) {}

        final collapsedGroups =
            viewCubit?.state.collapsedHierarchyGroups ?? _collapsedGroupHashes;
        final selectedUids = Set<String>.from(
          viewCubit?.state.selectedHierarchyStaffUids ?? _selectedUids,
        );

        // Prune selected UIDs if staves were deleted externally
        final bool hadDeletedStaves =
            selectedUids.any((uid) => !allUidsInOrder.contains(uid));
        if (hadDeletedStaves) {
          selectedUids.removeWhere((uid) => !allUidsInOrder.contains(uid));
          if (viewCubit != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) viewCubit!.setHierarchySelection(selectedUids);
            });
          }
        }

        return Directionality(
          textDirection: textDirection,
          child: HierarchySelectionScope(
            selectedUids: selectedUids,
            lastSelectedUid: _lastSelectedUid,
            collapsedGroupHashes: collapsedGroups,
            allUidsInOrder: allUidsInOrder,
            onToggleSelection: (uid, {isShift = false}) => _toggleSelection(
              uid,
              isShift: isShift,
              allUidsInOrder: allUidsInOrder,
            ),
            onSelectAll: () => _selectAll(allUidsInOrder),
            onClearSelection: _clearSelection,
            onToggleCollapseGroup: _toggleCollapseGroup,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selectedUids.isEmpty)
                  Row(
                    children: [
                      Icon(Icons.account_tree_outlined,
                          size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.systemSettings,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _selectAll(allUidsInOrder);
                        }),
                        icon: const Icon(Icons.checklist, size: 16),
                        tooltip: 'Multi-Select Mode',
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        onPressed: () => widget.notifier.addStaff(),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        tooltip: l10n.addStaff,
                        constraints:
                            const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  )
                else
                  // Top-Docked Contextual Batch Action Bar (CAB)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left counter badge & select-all toggle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${selectedUids.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              onPressed: () => _selectAll(allUidsInOrder),
                              icon: Icon(
                                selectedUids.length == allUidsInOrder.length
                                    ? Icons.deselect
                                    : Icons.select_all,
                                size: 18,
                                color: cs.primary,
                              ),
                              tooltip:
                                  selectedUids.length == allUidsInOrder.length
                                      ? 'Deselect All'
                                      : 'Select All',
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              padding: const EdgeInsets.all(4),
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                            ),
                          ],
                        ),

                        // Middle Action Cluster (Group, Hide, Duplicate, Delete)
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final int? firstParentDepth =
                                        selectedUids.isNotEmpty
                                            ? layout.rootGroup
                                                .findStaffParentDepth(
                                                    selectedUids.first)
                                            : null;
                                    final int targetDepth =
                                        firstParentDepth != null
                                            ? firstParentDepth + 1
                                            : 0;
                                    final bool exceedsLimit = targetDepth >
                                        core.GroupPlacementMetrics
                                            .emergencyMaxNestingDepth;
                                    final bool isLevel3 = targetDepth ==
                                        core.GroupPlacementMetrics
                                            .emergencyMaxNestingDepth;

                                    return SizedBox(
                                      width: 32,
                                      height: 32,
                                      child:
                                          PopupMenuButton<core.SystemConnector>(
                                        enabled: !exceedsLimit,
                                        icon: Icon(
                                          exceedsLimit
                                              ? Icons.layers_clear_outlined
                                              : Icons.layers,
                                          size: 18,
                                          color: exceedsLimit
                                              ? cs.outlineVariant
                                              : (isLevel3
                                                  ? cs.error
                                                  : cs.primary),
                                        ),
                                        tooltip: exceedsLimit
                                            ? 'Cannot group: Exceeds Gould & MOLA nesting ceiling (3 levels max)'
                                            : (isLevel3
                                                ? 'Group Selected Staves (Level 3 - standard recommends max 2)'
                                                : 'Group Selected Staves'),
                                        padding: EdgeInsets.zero,
                                        onSelected: (connector) {
                                          widget.notifier.groupSelectedStaves(
                                              selectedUids, connector);
                                          _clearSelection();
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: core.SystemConnector.bracket,
                                            child: Row(
                                              children: [
                                                Icon(Icons.reorder,
                                                    size: 16,
                                                    color: cs.primary),
                                                const SizedBox(width: 8),
                                                const Text(
                                                    'Group with Bracket [',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: core.SystemConnector.brace,
                                            child: Row(
                                              children: [
                                                Icon(Icons.code,
                                                    size: 16,
                                                    color: cs.primary),
                                                const SizedBox(width: 8),
                                                const Text(
                                                    'Group with Brace {',
                                                    style: TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () {
                                    widget.notifier.batchToggleVisibility(
                                        selectedUids, false);
                                    _clearSelection();
                                  },
                                  icon: Icon(Icons.visibility_off_outlined,
                                      size: 18, color: cs.primary),
                                  tooltip: 'Batch Hide Labels',
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () {
                                    widget.notifier
                                        .batchDuplicateStaves(selectedUids);
                                    _clearSelection();
                                  },
                                  icon: Icon(Icons.content_copy_outlined,
                                      size: 18, color: cs.primary),
                                  tooltip: 'Batch Duplicate',
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () {
                                    widget.notifier
                                        .batchDeleteStaves(selectedUids);
                                    _clearSelection();
                                  },
                                  icon: Icon(Icons.delete_outline,
                                      size: 18, color: cs.error),
                                  tooltip: 'Batch Delete',
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Cancel button
                        IconButton(
                          onPressed: _clearSelection,
                          icon: Icon(Icons.close,
                              size: 18, color: cs.onSurfaceVariant),
                          tooltip: 'Cancel Selection',
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                StaffGroupWidget(
                  group: layout.rootGroup,
                  isRoot: true,
                  notifier: widget.notifier,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const EnsembleSummaryWidget(),
              ],
            ),
          ),
        );
      },
    );
  }
}
