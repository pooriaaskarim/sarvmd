import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../common/ensemble_summary_widget.dart';
import '../dialogs/staff_config_dialog.dart';
import '../../../l10n/app_localizations.dart';

typedef StaffDragPayload = ({
  core.StaffDefinition staff,
  int parentGroupHash,
  int index,
});

typedef GroupDragPayload = ({
  core.StaffNodeGroup group,
  int parentGroupHash,
  int index,
});

Object? _activeDropToken;
Object? _hoveredChildDropPayload;

int _countStaves(core.StaffNodeGroup group) {
  int count = 0;
  for (final child in group.children) {
    if (child is core.StaffDefinition) {
      count++;
    } else if (child is core.StaffNodeGroup) {
      count += _countStaves(child);
    }
  }
  return count;
}

bool _groupContains(core.StaffNodeGroup parent, int targetHash) {
  if (parent.hashCode == targetHash) return true;
  for (final child in parent.children) {
    if (child is core.StaffNodeGroup) {
      if (child.hashCode == targetHash || _groupContains(child, targetHash)) {
        return true;
      }
    }
  }
  return false;
}

int _computeTargetIndex({
  required int sourceGroupHash,
  required int targetGroupHash,
  required int sourceIndex,
  required int targetIndex,
  required bool insertAfter,
}) {
  if (sourceGroupHash == targetGroupHash) {
    if (insertAfter) {
      return sourceIndex < targetIndex ? targetIndex : targetIndex + 1;
    } else {
      return sourceIndex < targetIndex ? targetIndex - 1 : targetIndex;
    }
  } else {
    return insertAfter ? targetIndex + 1 : targetIndex;
  }
}

Widget _buildGroupFeedbackWidget(
  ColorScheme cs,
  String labelDisplay,
  int staffCount,
) {
  return Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            labelDisplay,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              staffCount == 1 ? '1 staff' : '$staffCount staves',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HierarchySelectionScope extends InheritedWidget {
  const _HierarchySelectionScope({
    required this.selectedUids,
    required this.lastSelectedUid,
    required this.collapsedGroupHashes,
    required this.allUidsInOrder,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onToggleCollapseGroup,
    required super.child,
  });

  final Set<String> selectedUids;
  final String? lastSelectedUid;
  final Set<int> collapsedGroupHashes;
  final List<String> allUidsInOrder;
  final void Function(String uid, {bool isShift}) onToggleSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final void Function(int groupHash) onToggleCollapseGroup;

  static _HierarchySelectionScope? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_HierarchySelectionScope>();
  }

  @override
  bool updateShouldNotify(_HierarchySelectionScope oldWidget) {
    return selectedUids != oldWidget.selectedUids ||
        collapsedGroupHashes != oldWidget.collapsedGroupHashes ||
        lastSelectedUid != oldWidget.lastSelectedUid ||
        allUidsInOrder != oldWidget.allUidsInOrder;
  }
}

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

  void _toggleSelection(String uid,
      {bool isShift = false, List<String>? allUidsInOrder}) {
    setState(() {
      if (isShift && _lastSelectedUid != null && allUidsInOrder != null) {
        final startIdx = allUidsInOrder.indexOf(_lastSelectedUid!);
        final endIdx = allUidsInOrder.indexOf(uid);
        if (startIdx != -1 && endIdx != -1) {
          final low = math.min(startIdx, endIdx);
          final high = math.max(startIdx, endIdx);
          for (int i = low; i <= high; i++) {
            _selectedUids.add(allUidsInOrder[i]);
          }
        } else {
          _selectedUids.add(uid);
        }
      } else {
        if (_selectedUids.contains(uid)) {
          _selectedUids.remove(uid);
        } else {
          _selectedUids.add(uid);
        }
      }
      _lastSelectedUid = uid;
    });
  }

  void _selectAll(List<String> allUids) {
    setState(() {
      if (_selectedUids.length == allUids.length) {
        _selectedUids.clear();
      } else {
        _selectedUids.addAll(allUids);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUids.clear();
      _lastSelectedUid = null;
    });
  }

  void _toggleCollapseGroup(int groupHash) {
    setState(() {
      if (_collapsedGroupHashes.contains(groupHash)) {
        _collapsedGroupHashes.remove(groupHash);
      } else {
        _collapsedGroupHashes.add(groupHash);
      }
    });
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

        // Prune selected UIDs if staves were deleted externally
        _selectedUids.removeWhere((uid) => !allUidsInOrder.contains(uid));

        return Directionality(
          textDirection: textDirection,
          child: _HierarchySelectionScope(
            selectedUids: _selectedUids,
            lastSelectedUid: _lastSelectedUid,
            collapsedGroupHashes: _collapsedGroupHashes,
            allUidsInOrder: allUidsInOrder,
            onToggleSelection: (uid, {isShift = false}) => _toggleSelection(uid,
                isShift: isShift, allUidsInOrder: allUidsInOrder),
            onSelectAll: () => _selectAll(allUidsInOrder),
            onClearSelection: _clearSelection,
            onToggleCollapseGroup: _toggleCollapseGroup,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedUids.isEmpty)
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
                                '${_selectedUids.length}',
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
                                _selectedUids.length == allUidsInOrder.length
                                    ? Icons.deselect
                                    : Icons.select_all,
                                size: 18,
                                color: cs.primary,
                              ),
                              tooltip:
                                  _selectedUids.length == allUidsInOrder.length
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
                                    final int? firstParentDepth = _selectedUids.isNotEmpty
                                        ? layout.rootGroup.findStaffParentDepth(_selectedUids.first)
                                        : null;
                                    final int targetDepth =
                                        firstParentDepth != null ? firstParentDepth + 1 : 0;
                                    final bool exceedsLimit = targetDepth >
                                        core.GroupPlacementMetrics.emergencyMaxNestingDepth;
                                    final bool isLevel3 = targetDepth ==
                                        core.GroupPlacementMetrics.emergencyMaxNestingDepth;

                                    return SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: PopupMenuButton<core.SystemConnector>(
                                        enabled: !exceedsLimit,
                                        icon: Icon(
                                          exceedsLimit ? Icons.layers_clear_outlined : Icons.layers,
                                          size: 18,
                                          color: exceedsLimit
                                              ? cs.outlineVariant
                                              : (isLevel3 ? cs.error : cs.primary),
                                        ),
                                        tooltip: exceedsLimit
                                            ? 'Cannot group: Exceeds Gould & MOLA nesting ceiling (3 levels max)'
                                            : (isLevel3
                                                ? 'Group Selected Staves (Level 3 - standard recommends max 2)'
                                                : 'Group Selected Staves'),
                                        padding: EdgeInsets.zero,
                                        onSelected: (connector) {
                                          widget.notifier.groupSelectedStaves(
                                              _selectedUids, connector);
                                          _clearSelection();
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: core.SystemConnector.bracket,
                                            child: Row(
                                              children: [
                                                Icon(Icons.reorder,
                                                    size: 16, color: cs.primary),
                                                const SizedBox(width: 8),
                                                const Text('Group with Bracket [',
                                                    style: TextStyle(fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: core.SystemConnector.brace,
                                            child: Row(
                                              children: [
                                                Icon(Icons.code,
                                                    size: 16, color: cs.primary),
                                                const SizedBox(width: 8),
                                                const Text('Group with Brace {',
                                                    style: TextStyle(fontSize: 12)),
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
                                        _selectedUids, false);
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
                                        .batchDuplicateStaves(_selectedUids);
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
                                        .batchDeleteStaves(_selectedUids);
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
                _StaffGroupWidget(
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

class _StaffGroupWidget extends StatefulWidget {
  const _StaffGroupWidget({
    super.key,
    required this.group,
    this.isRoot = false,
    this.depth = 0,
    this.index,
    this.parentGroupHash,
    required this.notifier,
  });

  final core.StaffNodeGroup group;
  final bool isRoot;
  final int depth;
  final int? index;
  final int? parentGroupHash;
  final DocumentCubit notifier;

  @override
  State<_StaffGroupWidget> createState() => _StaffGroupWidgetState();
}

class _StaffGroupWidgetState extends State<_StaffGroupWidget> {
  bool _isEditingName = false;
  double? _hoverRatioY;
  bool _isDragging = false;

  void _startEditingName() {
    setState(() {
      _isEditingName = true;
    });
  }

  Widget _buildBadge(BuildContext context, String text, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    final badgeColor = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final scope = _HierarchySelectionScope.of(context);
    final isCollapsed =
        scope?.collapsedGroupHashes.contains(widget.group.hashCode) ?? false;
    final labelDisplay = widget.group.label.isNotEmpty
        ? (widget.group.abbreviation.isNotEmpty
            ? '${widget.group.label} (${widget.group.abbreviation})'
            : widget.group.label)
        : (widget.isRoot ? l10n.mainEnsemble : l10n.subGroup);

    final groupPayload = (!widget.isRoot &&
            widget.parentGroupHash != null &&
            widget.index != null)
        ? (
            group: widget.group,
            parentGroupHash: widget.parentGroupHash!,
            index: widget.index!,
          )
        : null;
    final groupFeedback = groupPayload != null
        ? _buildGroupFeedbackWidget(
            cs,
            labelDisplay,
            _countStaves(widget.group),
          )
        : null;

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data is StaffDragPayload) return true;
        if (data is GroupDragPayload) {
          if (data.group.hashCode == widget.group.hashCode) return false;
          if (_groupContains(data.group, widget.group.hashCode)) return false;
          return true;
        }
        return false;
      },
      onMove: (details) {
        final data = details.data;
        if (data is GroupDragPayload) {
          if (data.group.hashCode == widget.group.hashCode ||
              _groupContains(data.group, widget.group.hashCode)) {
            if (_hoverRatioY != null) setState(() => _hoverRatioY = null);
            return;
          }
        }
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && box.size.height > 0) {
          final localOffset = box.globalToLocal(details.offset);
          final ratio = (localOffset.dy / box.size.height).clamp(0.0, 1.0);
          if (_hoverRatioY != ratio) {
            setState(() => _hoverRatioY = ratio);
          }
        }
      },
      onLeave: (_) {
        if (_hoverRatioY != null) {
          setState(() => _hoverRatioY = null);
        }
      },
      onAcceptWithDetails: (details) {
        if (identical(_activeDropToken, details.data) ||
            _activeDropToken == details.data) {
          return;
        }
        _activeDropToken = details.data;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _activeDropToken = null;
          _hoveredChildDropPayload = null;
        });

        final data = details.data;
        final ratio = _hoverRatioY ?? 0.5;
        setState(() => _hoverRatioY = null);

        if (data is StaffDragPayload) {
          if (!widget.isRoot &&
              widget.parentGroupHash != null &&
              widget.index != null) {
            if (ratio < 0.15) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final targetIdx = _computeTargetIndex(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: widget.index!,
                  insertAfter: false,
                );
                widget.notifier.moveStaffNode(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: targetIdx,
                );
              });
              return;
            } else if (ratio > 0.85) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final targetIdx = _computeTargetIndex(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: widget.index!,
                  insertAfter: true,
                );
                widget.notifier.moveStaffNode(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: targetIdx,
                );
              });
              return;
            }
          }

          if (data.parentGroupHash == widget.group.hashCode) {
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.notifier.moveStaffNode(
              sourceGroupHash: data.parentGroupHash,
              targetGroupHash: widget.group.hashCode,
              sourceIndex: data.index,
              targetIndex: widget.group.children.length,
            );
          });
        } else if (data is GroupDragPayload) {
          if (data.group.hashCode == widget.group.hashCode ||
              _groupContains(data.group, widget.group.hashCode)) {
            return;
          }

          if (!widget.isRoot &&
              widget.parentGroupHash != null &&
              widget.index != null) {
            if (ratio < 0.3) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final targetIdx = _computeTargetIndex(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: widget.index!,
                  insertAfter: false,
                );
                widget.notifier.moveStaffNode(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: targetIdx,
                );
              });
              return;
            } else if (ratio > 0.7) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final targetIdx = _computeTargetIndex(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: widget.index!,
                  insertAfter: true,
                );
                widget.notifier.moveStaffNode(
                  sourceGroupHash: data.parentGroupHash,
                  targetGroupHash: widget.parentGroupHash!,
                  sourceIndex: data.index,
                  targetIndex: targetIdx,
                );
              });
              return;
            }
          }

          if (data.parentGroupHash == widget.group.hashCode) {
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.notifier.moveStaffNode(
              sourceGroupHash: data.parentGroupHash,
              targetGroupHash: widget.group.hashCode,
              sourceIndex: data.index,
              targetIndex: widget.group.children.length,
            );
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        final hasStaffCandidate = candidateData.any((p) =>
            p is StaffDragPayload &&
            p.parentGroupHash != widget.group.hashCode);
        final hasGroupCandidate = candidateData.any((p) =>
            p is GroupDragPayload &&
            p.group.hashCode != widget.group.hashCode &&
            !_groupContains(p.group, widget.group.hashCode));
        final isAnyHovered = (hasStaffCandidate || hasGroupCandidate) &&
            _hoveredChildDropPayload == null;

        final ratio = _hoverRatioY;
        final isTopZone = !widget.isRoot &&
            isAnyHovered &&
            ratio != null &&
            (hasGroupCandidate ? ratio < 0.3 : ratio < 0.15);
        final isBottomZone = !widget.isRoot &&
            isAnyHovered &&
            ratio != null &&
            (hasGroupCandidate ? ratio > 0.7 : ratio > 0.85);
        final isBodyHovered = isAnyHovered && !isTopZone && !isBottomZone;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _isDragging ? 0.35 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(
                horizontal: widget.isRoot ? 12 : 8, vertical: 8),
            decoration: BoxDecoration(
              color: isBodyHovered
                  ? cs.primaryContainer.withValues(alpha: 0.25)
                  : cs.surfaceContainerHighest
                      .withValues(alpha: widget.isRoot ? 0.2 : 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isBodyHovered
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.5),
                width: isBodyHovered ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isTopZone)
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                if (_isEditingName)
                  _QuickLabelingCard(
                    title: 'Edit Group Label',
                    initialName: widget.group.label,
                    initialAbbreviation: widget.group.abbreviation,
                    childStaves: widget.group.allStaves,
                    onAutoNumberChildStaves: () {
                      final childUids =
                          widget.group.allStaves.map((s) => s.uid).toList();
                      widget.notifier.batchRenumberStaves(childUids);
                    },
                    onSave: (name, abbrev) {
                      setState(() {
                        _isEditingName = false;
                      });
                      widget.notifier.updateGroupDetails(
                        groupHash: widget.group.hashCode,
                        label: name,
                        abbreviation: abbrev,
                      );
                    },
                    onCancel: () {
                      setState(() {
                        _isEditingName = false;
                      });
                    },
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    final bool showSegmentedPicker = width >= 380;
                    final bool isCompactActions = width < 250;

                    final foldCaret = !widget.isRoot
                        ? IconButton(
                            onPressed: () => scope
                                ?.onToggleCollapseGroup(widget.group.hashCode),
                            icon: Icon(
                              isCollapsed
                                  ? Icons.keyboard_arrow_right
                                  : Icons.keyboard_arrow_down,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                            tooltip:
                                isCollapsed ? 'Expand Group' : 'Collapse Group',
                            constraints: const BoxConstraints(
                                minWidth: 24, minHeight: 24),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          )
                        : null;

                    Widget titleWidget = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onDoubleTap: _startEditingName,
                            child: Text(
                              labelDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: widget.group.labelVisible
                                    ? cs.onSurfaceVariant
                                    : cs.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (!widget.group.labelVisible) ...[
                          const SizedBox(width: 4),
                          _buildBadge(context, l10n.hidden, color: cs.error),
                        ],
                        if (!widget.isRoot && widget.depth == 2) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Gould & MOLA standard limit: 2 nesting levels recommended',
                            child: _buildBadge(context, 'Level 2',
                                color: cs.primary),
                          ),
                        ] else if (!widget.isRoot && widget.depth >= 3) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Gould & MOLA emergency ceiling: 3 levels maximum reached',
                            child: _buildBadge(context, 'Level 3 (Max)',
                                color: cs.error),
                          ),
                        ],
                      ],
                    );

                    if (groupPayload != null && groupFeedback != null) {
                      titleWidget = LongPressDraggable<GroupDragPayload>(
                        data: groupPayload,
                        feedback: groupFeedback,
                        delay: const Duration(milliseconds: 350),
                        maxSimultaneousDrags: _isEditingName ? 0 : 1,
                        onDragStarted: () =>
                            setState(() => _isDragging = true),
                        onDragEnd: (_) {
                          if (mounted) setState(() => _isDragging = false);
                        },
                        onDraggableCanceled: (_, __) {
                          if (mounted) setState(() => _isDragging = false);
                        },
                        onDragCompleted: () {
                          if (mounted) setState(() => _isDragging = false);
                        },
                        child: titleWidget,
                      );
                    }

                    final labelActionButtons = [
                      IconButton(
                        onPressed: _startEditingName,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        tooltip: 'Edit Group Label',
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: () {
                          widget.notifier.updateGroupDetails(
                            groupHash: widget.group.hashCode,
                            labelVisible: !widget.group.labelVisible,
                          );
                        },
                        icon: Icon(
                          widget.group.labelVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 14,
                          color: widget.group.labelVisible
                              ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                              : cs.error,
                        ),
                        tooltip:
                          widget.group.labelVisible ? l10n.hidden : l10n.hidden,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ];

                    final structureActionButtons = [
                      IconButton(
                        onPressed: () => widget.notifier
                            .addStaffToGroup(groupHash: widget.group.hashCode),
                        icon: const Icon(Icons.add_circle_outline, size: 14),
                        tooltip: l10n.addStaff,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: const EdgeInsets.all(2),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (!widget.isRoot) ...[
                        IconButton(
                          onPressed: () => widget.notifier
                              .ungroupSubGroup(widget.group.hashCode),
                          icon: Icon(Icons.layers_clear_outlined,
                              size: 14, color: cs.error.withValues(alpha: 0.7)),
                          tooltip: l10n.reset,
                          constraints:
                              const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: const EdgeInsets.all(2),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ];

                    return Row(
                      children: [
                        if (foldCaret != null) foldCaret,
                        if (groupPayload != null && groupFeedback != null) ...[
                          Draggable<GroupDragPayload>(
                            data: groupPayload,
                            feedback: groupFeedback,
                            maxSimultaneousDrags: _isEditingName ? 0 : 1,
                            onDragStarted: () =>
                                setState(() => _isDragging = true),
                            onDragEnd: (_) {
                              if (mounted) setState(() => _isDragging = false);
                            },
                            onDraggableCanceled: (_, __) {
                              if (mounted) setState(() => _isDragging = false);
                            },
                            onDragCompleted: () {
                              if (mounted) setState(() => _isDragging = false);
                            },
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(end: 4.0),
                                child: Icon(
                                  Icons.drag_indicator,
                                  size: 16,
                                  color:
                                      cs.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.grab,
                              child: Tooltip(
                                message: 'Drag to reorder group',
                                child: Padding(
                                  padding:
                                      const EdgeInsetsDirectional.only(end: 4.0),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    size: 16,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else if (!widget.isRoot && widget.index != null) ...[
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 4.0),
                            child: Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (!showSegmentedPicker) ...[
                          _ConnectorMenuButton(
                            value: widget.group.connector,
                            onChanged: (v) =>
                                widget.notifier.updateGroupConnector(
                              v,
                              groupHash: widget.group.hashCode,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(child: titleWidget),
                        const SizedBox(width: 4),
                        if (isCompactActions) ...[
                          IconButton(
                            onPressed: () => widget.notifier.addStaffToGroup(
                                groupHash: widget.group.hashCode),
                            icon: const Icon(Icons.add_circle_outline, size: 14),
                            tooltip: l10n.addStaff,
                            constraints:
                                const BoxConstraints(minWidth: 24, minHeight: 24),
                            padding: const EdgeInsets.all(2),
                            visualDensity: VisualDensity.compact,
                          ),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert,
                                  size: 14,
                                  color:
                                      cs.onSurfaceVariant.withValues(alpha: 0.7)),
                              tooltip: 'Group Options',
                              padding: EdgeInsets.zero,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _startEditingName();
                                } else if (value == 'visibility') {
                                  widget.notifier.updateGroupDetails(
                                    groupHash: widget.group.hashCode,
                                    labelVisible: !widget.group.labelVisible,
                                  );
                                } else if (value == 'ungroup') {
                                  widget.notifier
                                      .ungroupSubGroup(widget.group.hashCode);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  height: 32,
                                  child: Text('Edit Label',
                                      style: TextStyle(fontSize: 12)),
                                ),
                                PopupMenuItem(
                                  value: 'visibility',
                                  height: 32,
                                  child: Text(
                                    widget.group.labelVisible
                                        ? 'Hide Label'
                                        : 'Show Label',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                if (!widget.isRoot)
                                  PopupMenuItem(
                                    value: 'ungroup',
                                    height: 32,
                                    child: Text(l10n.reset,
                                        style: TextStyle(
                                            fontSize: 12, color: cs.error)),
                                  ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ...labelActionButtons,
                          const SizedBox(width: 2),
                          ...structureActionButtons,
                        ],
                        if (showSegmentedPicker) ...[
                          const SizedBox(width: 8),
                          _ConnectorPicker(
                            value: widget.group.connector,
                            onChanged: (v) =>
                                widget.notifier.updateGroupConnector(
                              v,
                              groupHash: widget.group.hashCode,
                            ),
                            compact: true,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                if (widget.group.children.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.line_style,
                            size: 14,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.continuousBarlines,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Tooltip(
                          message: l10n.continuousBarlinesTooltip,
                          child: Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: widget.group.continuousBarlines,
                              onChanged: (v) => widget.notifier
                                  .updateGroupContinuousBarlines(v,
                                      groupHash: widget.group.hashCode),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isCollapsed)
                  InkWell(
                    onTap: () => scope
                        ?.onToggleCollapseGroup(widget.group.hashCode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.compress, size: 14, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.group.children.length} staves collapsed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.unfold_more,
                              size: 14, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int idx = 0; idx < widget.group.children.length; idx++)
                        switch (widget.group.children[idx]) {
                          core.StaffDefinition def => _StaffItem(
                              key: ValueKey('staff_${def.uid}'),
                              index: idx,
                              staff: def,
                              parentGroupHash: widget.group.hashCode,
                              notifier: widget.notifier,
                            ),
                          core.StaffNodeGroup subGroup => _StaffGroupWidget(
                              key: ValueKey('group_${subGroup.hashCode}_$idx'),
                              group: subGroup,
                              depth: widget.depth + 1,
                              index: idx,
                              parentGroupHash: widget.group.hashCode,
                              notifier: widget.notifier,
                            ),
                        }
                    ],
                  ),
                if (isBottomZone)
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StaffItem extends StatefulWidget {
  const _StaffItem({
    super.key,
    required this.index,
    required this.staff,
    required this.parentGroupHash,
    required this.notifier,
  });

  final int index;
  final core.StaffDefinition staff;
  final int parentGroupHash;
  final DocumentCubit notifier;

  @override
  State<_StaffItem> createState() => _StaffItemState();
}

class _StaffItemState extends State<_StaffItem> {
  bool _isEditingName = false;
  double? _hoverRatioY;
  bool _isDragging = false;

  void _openConfigDialog(BuildContext context) {
    showStaffConfigDialog(
      context,
      staff: widget.staff,
      notifier: widget.notifier,
    );
  }

  void _startEditingName() {
    setState(() {
      _isEditingName = true;
    });
  }

  Widget _buildFeedbackWidget(ColorScheme cs, String displayName) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_indicator, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftBadge({
    required BuildContext context,
    required ColorScheme cs,
    required bool isSelected,
    required bool isSelectionMode,
    required StaffDragPayload payload,
    required Widget feedbackWidget,
    required _HierarchySelectionScope? scope,
  }) {
    if (isSelectionMode || isSelected) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final isShift = HardwareKeyboard.instance.isShiftPressed;
          scope?.onToggleSelection(widget.staff.uid, isShift: isShift);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked,
                  size: 15,
                  color: isSelected
                      ? cs.onPrimary
                      : cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 3),
                Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? cs.onPrimary : cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Draggable<StaffDragPayload>(
      data: payload,
      feedback: feedbackWidget,
      maxSimultaneousDrags: _isEditingName ? 0 : 1,
      onDragStarted: () {
        _hoveredChildDropPayload = null;
        setState(() => _isDragging = true);
      },
      onDragEnd: (_) {
        _hoveredChildDropPayload = null;
        if (mounted) setState(() => _isDragging = false);
      },
      onDraggableCanceled: (_, __) {
        _hoveredChildDropPayload = null;
        if (mounted) setState(() => _isDragging = false);
      },
      onDragCompleted: () {
        _hoveredChildDropPayload = null;
        if (mounted) setState(() => _isDragging = false);
      },
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildHandleContainer(cs),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: _buildHandleContainer(cs),
      ),
    );
  }

  Widget _buildHandleContainer(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: cs.primary.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.drag_indicator,
            size: 15,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.index + 1}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final scope = _HierarchySelectionScope.of(context);
    final isSelected = scope?.selectedUids.contains(widget.staff.uid) ?? false;
    final isSelectionMode = scope?.selectedUids.isNotEmpty ?? false;

    final String displayName =
        widget.staff.instrumentName ?? l10n.staffNumber(widget.index + 1);
    final String abbrevInfo = widget.staff.instrumentAbbreviation != null &&
            widget.staff.instrumentAbbreviation!.isNotEmpty
        ? ' (${widget.staff.instrumentAbbreviation})'
        : '';
    final String labelText = '$displayName$abbrevInfo';

    String clefLabel = l10n.noClef;
    final staffClef = widget.staff.clef;
    final isAudibleClef =
        staffClef != null && staffClef.symbol.requiresFixedLines;

    if (staffClef != null) {
      final matchingPreset = staffClef.symbol.registerPresets
          .where((p) => p.anchorLine == staffClef.anchorLine)
          .firstOrNull;

      clefLabel = switch (staffClef.symbol) {
        core.ClefSymbol.g => (staffClef.anchorLine == 1)
            ? (matchingPreset?.label.split(' (').first ?? 'French Violin')
            : l10n.trebleClef,
        core.ClefSymbol.c => switch (staffClef.anchorLine) {
            4 => l10n.tenorClef,
            3 => l10n.altoClef,
            _ => (matchingPreset?.label.split(' (').first ?? l10n.altoClef),
          },
        core.ClefSymbol.f => (staffClef.anchorLine == 3)
            ? (matchingPreset?.label.split(' (').first ?? 'Baritone')
            : l10n.bassClef,
        core.ClefSymbol.tab => l10n.categoryTablature,
        core.ClefSymbol.percussion => l10n.categoryPercussion,
      };
    }

    final payload = (
      staff: widget.staff,
      parentGroupHash: widget.parentGroupHash,
      index: widget.index,
    );

    final feedbackWidget = _buildFeedbackWidget(cs, displayName);

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data is StaffDragPayload) return true;
        if (data is GroupDragPayload) {
          if (widget.parentGroupHash == data.group.hashCode ||
              _groupContains(data.group, widget.parentGroupHash)) {
            return false;
          }
          return true;
        }
        return false;
      },
      onMove: (details) {
        final data = details.data;
        if (data is StaffDragPayload && data.staff.uid == widget.staff.uid) {
          if (_hoverRatioY != null) {
            setState(() {
              _hoverRatioY = null;
            });
          }
          _hoveredChildDropPayload = null;
          return;
        }
        if (data is GroupDragPayload &&
            (widget.parentGroupHash == data.group.hashCode ||
                _groupContains(data.group, widget.parentGroupHash))) {
          if (_hoverRatioY != null) {
            setState(() {
              _hoverRatioY = null;
            });
          }
          _hoveredChildDropPayload = null;
          return;
        }
        _hoveredChildDropPayload = data;
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && box.size.height > 0) {
          final localOffset = box.globalToLocal(details.offset);
          final ratio = (localOffset.dy / box.size.height).clamp(0.0, 1.0);
          if (_hoverRatioY != ratio) {
            setState(() {
              _hoverRatioY = ratio;
            });
          }
        }
      },
      onLeave: (data) {
        if (_hoveredChildDropPayload == data) {
          _hoveredChildDropPayload = null;
        }
        if (_hoverRatioY != null) {
          setState(() {
            _hoverRatioY = null;
          });
        }
      },
      onAcceptWithDetails: (details) {
        _hoveredChildDropPayload = null;
        if (identical(_activeDropToken, details.data) ||
            _activeDropToken == details.data) {
          return;
        }
        _activeDropToken = details.data;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _activeDropToken = null;
          _hoveredChildDropPayload = null;
        });

        final data = details.data;
        final ratio = _hoverRatioY ?? 0.5;
        setState(() {
          _hoverRatioY = null;
        });

        if (data is StaffDragPayload) {
          if (data.staff.uid == widget.staff.uid) {
            // Dropping onto itself cancels any ordering or grouping action.
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ratio < 0.25) {
              final targetIdx = _computeTargetIndex(
                sourceGroupHash: data.parentGroupHash,
                targetGroupHash: widget.parentGroupHash,
                sourceIndex: data.index,
                targetIndex: widget.index,
                insertAfter: false,
              );
              widget.notifier.moveStaffNode(
                sourceGroupHash: data.parentGroupHash,
                targetGroupHash: widget.parentGroupHash,
                sourceIndex: data.index,
                targetIndex: targetIdx,
              );
            } else if (ratio > 0.75) {
              final targetIdx = _computeTargetIndex(
                sourceGroupHash: data.parentGroupHash,
                targetGroupHash: widget.parentGroupHash,
                sourceIndex: data.index,
                targetIndex: widget.index,
                insertAfter: true,
              );
              widget.notifier.moveStaffNode(
                sourceGroupHash: data.parentGroupHash,
                targetGroupHash: widget.parentGroupHash,
                sourceIndex: data.index,
                targetIndex: targetIdx,
              );
            } else {
              final rootGroup =
                  widget.notifier.state.config.systemLayout.rootGroup;
              final parentDepth =
                  rootGroup.findGroupDepth(widget.parentGroupHash) ?? 0;
              if (parentDepth >=
                  core.GroupPlacementMetrics.emergencyMaxNestingDepth) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Cannot group staves: Gould & MOLA limit is 3 nesting levels maximum.',
                    ),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                widget.notifier.groupTwoStavesTogether(
                  data.staff.uid,
                  widget.staff.uid,
                );
              }
            }
          });
        } else if (data is GroupDragPayload) {
          if (widget.parentGroupHash == data.group.hashCode ||
              _groupContains(data.group, widget.parentGroupHash)) {
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final insertAfter = ratio >= 0.5;
            final targetIdx = _computeTargetIndex(
              sourceGroupHash: data.parentGroupHash,
              targetGroupHash: widget.parentGroupHash,
              sourceIndex: data.index,
              targetIndex: widget.index,
              insertAfter: insertAfter,
            );
            widget.notifier.moveStaffNode(
              sourceGroupHash: data.parentGroupHash,
              targetGroupHash: widget.parentGroupHash,
              sourceIndex: data.index,
              targetIndex: targetIdx,
            );
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isDropHovered = candidateData.any((p) {
          if (p is StaffDragPayload) return p.staff.uid != widget.staff.uid;
          if (p is GroupDragPayload) {
            return widget.parentGroupHash != p.group.hashCode &&
                !_groupContains(p.group, widget.parentGroupHash);
          }
          return false;
        });
        final isGroupHover = candidateData.any((p) => p is GroupDragPayload);
        final ratio = _hoverRatioY;
        final isTopZone = isDropHovered &&
            ratio != null &&
            (isGroupHover ? ratio < 0.5 : ratio < 0.25);
        final isBottomZone = isDropHovered &&
            ratio != null &&
            (isGroupHover ? ratio >= 0.5 : ratio > 0.75);
        final isCombineZone = !isGroupHover &&
            isDropHovered &&
            (ratio == null || (ratio >= 0.25 && ratio <= 0.75));

        final cardContainer = AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _isDragging ? 0.35 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(
                horizontal: isSelectionMode ? 8 : 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer.withValues(alpha: 0.4)
                  : (isCombineZone
                      ? cs.primaryContainer.withValues(alpha: 0.5)
                      : (isDropHovered
                          ? cs.primaryContainer.withValues(alpha: 0.25)
                          : cs.surface)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : (isDropHovered
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.3)),
                width: isSelected || isDropHovered ? 2.0 : 1.0,
              ),
              boxShadow: (isSelected || isCombineZone)
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isTopZone)
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                if (isCombineZone)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_add, size: 14, color: cs.onPrimary),
                        const SizedBox(width: 6),
                        Text(
                          '+ ${l10n.groupStaves} ($displayName)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isEditingName)
                  _QuickLabelingCard(
                    title: 'Edit Staff Label',
                    initialName: widget.staff.instrumentName ?? '',
                    initialAbbreviation:
                        widget.staff.instrumentAbbreviation ?? '',
                    onSave: (name, abbrev) {
                      setState(() {
                        _isEditingName = false;
                      });
                      widget.notifier.updateStaffConfigDetails(
                        widget.staff.uid,
                        name: () => name.isEmpty ? null : name,
                        abbreviation: () => abbrev.isEmpty ? null : abbrev,
                      );
                    },
                    onCancel: () {
                      setState(() {
                        _isEditingName = false;
                      });
                    },
                  )
                else
                  Row(
                    children: [
                      _buildLeftBadge(
                        context: context,
                        cs: cs,
                        isSelected: isSelected,
                        isSelectionMode: isSelectionMode,
                        payload: payload,
                        feedbackWidget: feedbackWidget,
                        scope: scope,
                      ),
                      const SizedBox(width: 8),

                      // Name, configuration badges, and action cluster
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Tooltip(
                                    message: labelText,
                                    child: Text(
                                      labelText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: widget.staff.labelVisible
                                            ? null
                                            : cs.onSurfaceVariant
                                                .withValues(alpha: 0.5),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: _startEditingName,
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: cs.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                  tooltip: 'Edit Instrument Name',
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                ),
                                IconButton(
                                  onPressed: () {
                                    widget.notifier.updateStaffConfigDetails(
                                      widget.staff.uid,
                                      visible: !widget.staff.labelVisible,
                                    );
                                  },
                                  icon: Icon(
                                    widget.staff.labelVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 16,
                                    color: widget.staff.labelVisible
                                        ? cs.onSurfaceVariant
                                            .withValues(alpha: 0.7)
                                        : cs.error,
                                  ),
                                  tooltip: widget.staff.labelVisible
                                      ? l10n.hidden
                                      : l10n.hidden,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                ),
                                IconButton(
                                  onPressed: () => _openConfigDialog(context),
                                  icon: Icon(
                                    Icons.tune_outlined,
                                    size: 16,
                                    color: cs.primary,
                                  ),
                                  tooltip: l10n.configureStaff,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap),
                                ),
                                IconButton(
                                  onPressed: () => widget.notifier
                                      .removeStaffByUid(widget.staff.uid),
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    size: 16,
                                    color: cs.error,
                                  ),
                                  tooltip: l10n.removeStaff,
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
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                // 1. Clef Badge Quick-Picker
                                PopupMenuButton<core.Clef>(
                                  tooltip: l10n.clefSettingsHeader,
                                  padding: EdgeInsets.zero,
                                  onSelected: (newClef) {
                                    final newLines = newClef
                                            .symbol.requiresFixedLines
                                        ? 5
                                        : (widget.staff.lines == 5
                                            ? newClef.symbol.defaultLines
                                            : widget.staff.lines);
                                    widget.notifier.updateStaffConfigDetails(
                                      widget.staff.uid,
                                      clef: () => newClef,
                                      lines: newLines,
                                    );
                                  },
                                  itemBuilder: (context) {
                                    final currentClef = widget.staff.clef;
                                    return [
                                      PopupMenuItem(
                                        value: core.Clef.treble,
                                        child: Row(children: [
                                          if (currentClef is core.TrebleClef &&
                                              currentClef.anchorLine == 2)
                                            Icon(Icons.check,
                                                size: 14, color: cs.primary)
                                          else
                                            const Icon(Icons.music_note,
                                                size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.trebleClef,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: core.Clef.alto,
                                        child: Row(children: [
                                          if (currentClef is core.AltoClef)
                                            Icon(Icons.check,
                                                size: 14, color: cs.primary)
                                          else
                                            const Icon(Icons.music_note,
                                                size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.altoClef,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: core.Clef.tenor,
                                        child: Row(children: [
                                          if (currentClef is core.TenorClef)
                                            Icon(Icons.check,
                                                size: 14, color: cs.primary)
                                          else
                                            const Icon(Icons.music_note,
                                                size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.tenorClef,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: core.Clef.bass,
                                        child: Row(children: [
                                          if (currentClef is core.BassClef &&
                                              currentClef.anchorLine == 4)
                                            Icon(Icons.check,
                                                size: 14, color: cs.primary)
                                          else
                                            const Icon(Icons.music_note,
                                                size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.bassClef,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: core.Clef.tab,
                                        child: Row(children: [
                                          if (currentClef is core.TabClef)
                                            Icon(Icons.check,
                                                size: 14, color: cs.primary)
                                          else
                                            const Icon(Icons.numbers, size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.categoryTablature,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: core.Clef.percussion,
                                        child: Row(children: [
                                          if (currentClef
                                              is core.PercussionClef)
                                            Icon(Icons.check,
                                                size: 14, color: cs.primary)
                                          else
                                            const Icon(Icons.adjust, size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.categoryPercussion,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ),
                                    ];
                                  },
                                  child: _buildBadge(context, clefLabel,
                                      showChevron: true),
                                ),

                                // 2. Dynamic Modifier Badge:
                                // For Pitched Clefs (G, C, F): Anchor Line Quick-Picker
                                // For Unpitched/Tab Clefs (Tab, Percussion): Line Count Quick-Picker
                                if (isAudibleClef)
                                  PopupMenuButton<int>(
                                    tooltip: l10n.clefAnchorLineHeader,
                                    padding: EdgeInsets.zero,
                                    onSelected: (line) {
                                      final updatedClef = staffClef.symbol
                                          .createClef(anchorLine: line);
                                      widget.notifier.updateStaffClef(
                                          widget.staff.uid, updatedClef);
                                    },
                                    itemBuilder: (context) {
                                      final presets =
                                          staffClef.symbol.registerPresets;
                                      final hasCurrentLine = presets.any((p) =>
                                          p.anchorLine ==
                                          staffClef.anchorLine);
                                      return [
                                        for (final preset in presets)
                                          PopupMenuItem<int>(
                                            value: preset.anchorLine,
                                            child: Row(
                                              children: [
                                                if (staffClef.anchorLine ==
                                                    preset.anchorLine)
                                                  Icon(Icons.check,
                                                      size: 14,
                                                      color: cs.primary)
                                                else
                                                  const SizedBox(width: 14),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    preset.label,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          staffClef.anchorLine ==
                                                                  preset
                                                                      .anchorLine
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (!hasCurrentLine)
                                          PopupMenuItem<int>(
                                            value: staffClef.anchorLine,
                                            child: Row(
                                              children: [
                                                Icon(Icons.check,
                                                    size: 14,
                                                    color: cs.primary),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    l10n.clefAnchorLineReadout(
                                                        staffClef.anchorLine),
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ];
                                    },
                                    child: _buildBadge(
                                      context,
                                      l10n.clefAnchorLineReadout(
                                          staffClef.anchorLine),
                                      showChevron: true,
                                    ),
                                  )
                                else
                                  PopupMenuButton<int>(
                                    tooltip: l10n.numberOfStaffLinesHeader,
                                    padding: EdgeInsets.zero,
                                    onSelected: (lines) {
                                      widget.notifier.updateStaffConfigDetails(
                                        widget.staff.uid,
                                        lines: lines,
                                      );
                                    },
                                    itemBuilder: (context) => [
                                      for (int i = 1; i <= 6; i++)
                                        PopupMenuItem(
                                          value: i,
                                          child: Row(
                                            children: [
                                              if (widget.staff.lines == i)
                                                Icon(Icons.check,
                                                    size: 14,
                                                    color: cs.primary)
                                              else
                                                const SizedBox(width: 14),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  l10n.linesCount(i),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        widget.staff.lines == i
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                    child: _buildBadge(
                                      context,
                                      l10n.linesCount(widget.staff.lines),
                                      showChevron: true,
                                    ),
                                  ),

                                if (!widget.staff.labelVisible)
                                  InkWell(
                                    onTap: () => widget.notifier
                                        .updateStaffConfigDetails(
                                      widget.staff.uid,
                                      visible: true,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    child: _buildBadge(context, l10n.hidden,
                                        color: cs.error),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (isBottomZone)
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        );

        final itemCard = LongPressDraggable<StaffDragPayload>(
          data: payload,
          feedback: feedbackWidget,
          delay: const Duration(milliseconds: 350),
          maxSimultaneousDrags: _isEditingName ? 0 : 1,
          onDragStarted: () {
            _hoveredChildDropPayload = null;
            setState(() => _isDragging = true);
          },
          onDragEnd: (_) {
            _hoveredChildDropPayload = null;
            if (mounted) setState(() => _isDragging = false);
          },
          onDraggableCanceled: (_, __) {
            _hoveredChildDropPayload = null;
            if (mounted) setState(() => _isDragging = false);
          },
          onDragCompleted: () {
            _hoveredChildDropPayload = null;
            if (mounted) setState(() => _isDragging = false);
          },
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: cardContainer,
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_isEditingName) return;
              final isShift = HardwareKeyboard.instance.isShiftPressed;
              scope?.onToggleSelection(widget.staff.uid, isShift: isShift);
            },
            onDoubleTap: () {
              if (_isEditingName) return;
              _startEditingName();
            },
            child: cardContainer,
          ),
        );

        return itemCard;
      },
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String text, {
    Color? color,
    bool showChevron = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final badgeColor = color ?? cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 10,
              color: badgeColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectorPicker extends StatelessWidget {
  const _ConnectorPicker({
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final core.SystemConnector value;
  final ValueChanged<core.SystemConnector> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<core.SystemConnector>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<core.SystemConnector>(
          value: core.SystemConnector.none,
          label: Text(
            l10n.connectorNone,
            style: TextStyle(fontSize: compact ? 9 : 10),
          ),
        ),
        ButtonSegment<core.SystemConnector>(
          value: core.SystemConnector.bracket,
          label: Text(
            l10n.connectorBracket,
            style: TextStyle(fontSize: compact ? 9 : 10),
          ),
        ),
        ButtonSegment<core.SystemConnector>(
          value: core.SystemConnector.brace,
          label: Text(
            l10n.connectorBrace,
            style: TextStyle(fontSize: compact ? 9 : 10),
          ),
        ),
      ],
      selected: {value},
      onSelectionChanged: (set) => onChanged(set.first),
      style: SegmentedButton.styleFrom(
        visualDensity: compact
            ? VisualDensity.compact
            : const VisualDensity(horizontal: -2, vertical: -2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ConnectorMenuButton extends StatelessWidget {
  const _ConnectorMenuButton({
    required this.value,
    required this.onChanged,
  });

  final core.SystemConnector value;
  final ValueChanged<core.SystemConnector> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final IconData iconData = switch (value) {
      core.SystemConnector.brace => Icons.code,
      core.SystemConnector.bracket => Icons.reorder,
      core.SystemConnector.subBracket => Icons.reorder,
      core.SystemConnector.none => Icons.linear_scale,
    };

    return PopupMenuButton<core.SystemConnector>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: l10n.systemGrouping,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 14, color: cs.primary),
            Icon(Icons.arrow_drop_down,
                size: 12, color: cs.primary.withValues(alpha: 0.7)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: core.SystemConnector.none,
          child: Row(
            children: [
              Icon(Icons.linear_scale, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(l10n.connectorNone, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: core.SystemConnector.bracket,
          child: Row(
            children: [
              Icon(Icons.reorder, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.connectorBracket, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: core.SystemConnector.brace,
          child: Row(
            children: [
              Icon(Icons.code, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.connectorBrace, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

String _generateAutoAbbreviation(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';

  final lower = trimmed.toLowerCase();
  if (lower.contains('woodwind')) return 'Ww.';
  if (lower.contains('brass')) return 'Br.';
  if (lower.contains('string')) return 'Str.';
  if (lower.contains('percussion')) return 'Perc.';
  if (lower.contains('choir') || lower.contains('vocal')) return 'Voc.';
  if (lower.contains('violin 1') || lower.contains('violin i')) return 'Vln. I';
  if (lower.contains('violin 2') || lower.contains('violin ii'))
    return 'Vln. II';
  if (lower.contains('violin')) return 'Vln.';
  if (lower.contains('viola')) return 'Vla.';
  if (lower.contains('violoncello') || lower.contains('cello')) return 'Vc.';
  if (lower.contains('double bass') || lower.contains('contrabass'))
    return 'Cb.';
  if (lower.contains('flute')) return 'Fl.';
  if (lower.contains('oboe')) return 'Ob.';
  if (lower.contains('clarinet')) return 'Cl.';
  if (lower.contains('bassoon')) return 'Bsn.';
  if (lower.contains('horn')) return 'Hn.';
  if (lower.contains('trumpet')) return 'Tpt.';
  if (lower.contains('trombone')) return 'Tbn.';
  if (lower.contains('tuba')) return 'Tba.';
  if (lower.contains('piano')) return 'Pno.';

  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length == 1) {
    return words.first.length > 4
        ? '${words.first.substring(0, 3)}.'
        : words.first;
  } else {
    return words
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}.' : '')
        .join('');
  }
}

class _QuickLabelingCard extends StatefulWidget {
  const _QuickLabelingCard({
    required this.title,
    required this.initialName,
    required this.initialAbbreviation,
    required this.onSave,
    required this.onCancel,
    this.childStaves,
    this.onAutoNumberChildStaves,
  });

  final String title;
  final String initialName;
  final String initialAbbreviation;
  final void Function(String name, String abbreviation) onSave;
  final VoidCallback onCancel;
  final List<core.StaffDefinition>? childStaves;
  final VoidCallback? onAutoNumberChildStaves;

  @override
  State<_QuickLabelingCard> createState() => _QuickLabelingCardState();
}

class _QuickLabelingCardState extends State<_QuickLabelingCard> {
  late TextEditingController _nameController;
  late TextEditingController _abbrevController;
  late FocusNode _nameFocusNode;
  late FocusNode _abbrevFocusNode;
  String _suggestedAbbrev = '';
  bool _submitted = false;
  bool _hasAutoNumbered = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _abbrevController = TextEditingController(text: widget.initialAbbreviation);
    _nameFocusNode = FocusNode();
    _abbrevFocusNode = FocusNode();

    _updateSuggestion(_nameController.text);

    _nameController.addListener(() {
      _updateSuggestion(_nameController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
        Scrollable.ensureVisible(
          context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updateSuggestion(String name) {
    final auto = _generateAutoAbbreviation(name);
    if (auto != _suggestedAbbrev) {
      setState(() {
        _suggestedAbbrev = auto;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbrevController.dispose();
    _nameFocusNode.dispose();
    _abbrevFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final name = _nameController.text.trim();
    var abbrev = _abbrevController.text.trim();
    if (abbrev.isEmpty && _suggestedAbbrev.isNotEmpty) {
      abbrev = _suggestedAbbrev;
    }
    widget.onSave(name, abbrev);
  }

  void _cancel() {
    if (_submitted) return;
    _submitted = true;
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _submit();
        }
      },
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _cancel();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TapRegion(
          groupId: 'quick_labeling_${widget.hashCode}',
          onTapOutside: (_) => _submit(),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and compact action buttons
                Row(
                  children: [
                    Icon(Icons.label_outlined, size: 15, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: _cancel,
                      constraints:
                          const BoxConstraints(minWidth: 26, minHeight: 26),
                      padding: EdgeInsets.zero,
                      tooltip: 'Cancel (Esc)',
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Save',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Full Name Field
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Full Name / Instrument',
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                      floatingLabelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                      hintText: 'e.g., Violin I',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.7),
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: cs.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (_abbrevController.text.isNotEmpty ||
                          _suggestedAbbrev.isNotEmpty) {
                        _submit();
                      } else {
                        _abbrevFocusNode.requestFocus();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Abbreviation Field + Auto Chip
                LayoutBuilder(
                  builder: (context, abbrevConstraints) {
                    final isAbbrevNarrow = abbrevConstraints.maxWidth < 250;
                    final chipWidget = (_suggestedAbbrev.isNotEmpty &&
                            _suggestedAbbrev != _abbrevController.text)
                        ? InkWell(
                            onTap: () {
                              setState(() {
                                _abbrevController.text = _suggestedAbbrev;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      size: 11, color: cs.onPrimaryContainer),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _suggestedAbbrev,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onPrimaryContainer,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null;

                    final abbrevField = SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _abbrevController,
                        focusNode: _abbrevFocusNode,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Abbreviation',
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                          floatingLabelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                          hintText: 'e.g., Vln. 1',
                          hintStyle: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: cs.outlineVariant.withValues(alpha: 0.7),
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: cs.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    );

                    if (isAbbrevNarrow && chipWidget != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          abbrevField,
                          const SizedBox(height: 6),
                          chipWidget,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: abbrevField),
                        if (chipWidget != null) ...[
                          const SizedBox(width: 8),
                          chipWidget,
                        ],
                      ],
                    );
                  },
                ),
                if (widget.childStaves != null &&
                    widget.childStaves!.length >= 2) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      widget.onAutoNumberChildStaves?.call();
                      setState(() {
                        _hasAutoNumbered = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Applied Gould non-redundancy: Renumbered ${widget.childStaves!.length} staves (1..${widget.childStaves!.length})',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _hasAutoNumbered
                            ? cs.primaryContainer.withValues(alpha: 0.45)
                            : cs.secondaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _hasAutoNumbered
                              ? cs.primary.withValues(alpha: 0.4)
                              : cs.secondary.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _hasAutoNumbered
                                ? Icons.check_circle_outline
                                : Icons.auto_awesome,
                            size: 14,
                            color: _hasAutoNumbered
                                ? cs.primary
                                : cs.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hasAutoNumbered
                                  ? 'Gould non-redundancy applied: Staves (1..${widget.childStaves!.length})'
                                  : 'Apply Gould non-redundancy: Renumber staves (1, 2${widget.childStaves!.length > 2 ? ', ...' : ''})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _hasAutoNumbered
                                    ? cs.onPrimaryContainer
                                    : cs.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Agile shortcut hint footer
                Row(
                  children: [
                    Icon(
                      Icons.keyboard_return_rounded,
                      size: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Enter to save • Esc to cancel • Click outside to finish',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
