import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../../l10n/app_localizations.dart';
import '../../../../logic/document/document_cubit.dart';
import '../../dialogs/group_engraving_dialog.dart';
import 'connector_picker_widgets.dart';
import 'hierarchy_models.dart';
import 'hierarchy_selection_scope.dart';
import 'quick_labeling_card.dart';
import 'staff_item_widget.dart';

/// Recursive tree widget representing a score group (e.g. Strings, Woodwinds)
/// containing staves and sub-groups.
class StaffGroupWidget extends StatefulWidget {
  const StaffGroupWidget({
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
  State<StaffGroupWidget> createState() => _StaffGroupWidgetState();
}

class _StaffGroupWidgetState extends State<StaffGroupWidget> {
  bool _isEditingName = false;
  double? _hoverRatioY;
  bool _isDragging = false;

  void _startEditingName() {
    setState(() {
      _isEditingName = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final scope = HierarchySelectionScope.of(context);
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
        ? buildGroupFeedbackWidget(
            cs,
            labelDisplay,
            countStaves(widget.group),
          )
        : null;

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data is StaffDragPayload) return true;
        if (data is GroupDragPayload) {
          if (data.group.hashCode == widget.group.hashCode) return false;
          if (groupContains(data.group, widget.group.hashCode)) return false;
          return true;
        }
        return false;
      },
      onMove: (details) {
        final data = details.data;
        if (data is GroupDragPayload) {
          if (data.group.hashCode == widget.group.hashCode ||
              groupContains(data.group, widget.group.hashCode)) {
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
        if (identical(HierarchyDragState.activeDropToken, details.data) ||
            HierarchyDragState.activeDropToken == details.data) {
          return;
        }
        HierarchyDragState.activeDropToken = details.data;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          HierarchyDragState.activeDropToken = null;
          HierarchyDragState.hoveredChildDropPayload = null;
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
                final targetIdx = computeTargetIndex(
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
                final targetIdx = computeTargetIndex(
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
              groupContains(data.group, widget.group.hashCode)) {
            return;
          }

          if (!widget.isRoot &&
              widget.parentGroupHash != null &&
              widget.index != null) {
            if (ratio < 0.3) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final targetIdx = computeTargetIndex(
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
                final targetIdx = computeTargetIndex(
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
            !groupContains(p.group, widget.group.hashCode));
        final isAnyHovered = (hasStaffCandidate || hasGroupCandidate) &&
            HierarchyDragState.hoveredChildDropPayload == null;

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
                  QuickLabelingCard(
                    title: 'Edit Group Label',
                    initialName: widget.group.label,
                    initialAbbreviation: widget.group.abbreviation,
                    group: widget.group,
                    notifier: widget.notifier,
                    initialLabelPlacement: widget.group.labelPlacement,
                    initialNumberingStyle: widget.group.numberingStyle,
                    initialDescriptorPlacement: widget.group.descriptorPlacement,
                    initialHeaderVisibility: widget.group.headerVisibility,
                    childStaves: widget.group.allStaves,
                    onAutoNumberChildStaves: () {
                      final childUids =
                          widget.group.allStaves.map((s) => s.uid).toList();
                      widget.notifier.batchRenumberStaves(childUids);
                    },
                    onSaveGroup: (name, abbrev, placement, numberingStyle, descriptorPlacement, headerVisibility) {
                      setState(() {
                        _isEditingName = false;
                      });
                      widget.notifier.updateGroupDetails(
                        groupHash: widget.group.hashCode,
                        label: name,
                        abbreviation: abbrev,
                        labelPlacement: placement,
                        numberingStyle: numberingStyle,
                        descriptorPlacement: descriptorPlacement,
                        headerVisibility: headerVisibility,
                      );
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
                  )
                else ...[
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
                            HierarchyBadge(text: l10n.hidden, color: cs.error),
                          ],
                          if (!widget.isRoot && widget.depth == 2) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'Gould & MOLA standard limit: 2 nesting levels recommended',
                              child: HierarchyBadge(text: 'Level 2',
                                  color: cs.primary),
                            ),
                          ] else if (!widget.isRoot && widget.depth >= 3) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'Gould & MOLA emergency ceiling: 3 levels maximum reached',
                              child: HierarchyBadge(text: 'Level 3 (Max)',
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
                          childWhenDragging: Opacity(
                            opacity: 0.35,
                            child: titleWidget,
                          ),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onDoubleTap: _startEditingName,
                            child: titleWidget,
                          ),
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
                          padding: const EdgeInsets.all(2),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: () => widget.notifier.updateGroupDetails(
                            groupHash: widget.group.hashCode,
                            labelVisible: !widget.group.labelVisible,
                          ),
                          icon: Icon(
                            widget.group.labelVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 14,
                            color: widget.group.labelVisible
                                ? cs.onSurfaceVariant.withValues(alpha: 0.7)
                                : cs.error,
                          ),
                          tooltip: widget.group.labelVisible
                              ? 'Hide Label'
                              : 'Show Label',
                          constraints:
                              const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: const EdgeInsets.all(2),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: () {
                            showGroupEngravingDialog(
                              context,
                              group: widget.group,
                              notifier: widget.notifier,
                              onAutoNumberChildStaves: () {
                                final childUids = widget.group.allStaves
                                    .map((s) => s.uid)
                                    .toList();
                                widget.notifier.batchRenumberStaves(childUids);
                              },
                            );
                          },
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                          tooltip: 'Group Engraving Options',
                          constraints:
                              const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: const EdgeInsets.all(2),
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
                            icon: Icon(Icons.close,
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
                            ConnectorMenuButton(
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
                                  } else if (value == 'engraving') {
                                    showGroupEngravingDialog(
                                      context,
                                      group: widget.group,
                                      notifier: widget.notifier,
                                      onAutoNumberChildStaves: () {
                                        final childUids = widget.group.allStaves
                                            .map((s) => s.uid)
                                            .toList();
                                        widget.notifier
                                            .batchRenumberStaves(childUids);
                                      },
                                    );
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
                                  const PopupMenuItem(
                                    value: 'engraving',
                                    height: 32,
                                    child: Text('Engraving Options...',
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
                            ConnectorPicker(
                              value: widget.group.connector,
                              onChanged: (v) =>
                                  widget.notifier.updateGroupConnector(
                                v,
                                groupHash: widget.group.hashCode,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
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
                            Icons.border_left,
                            size: 14,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l10n.initialBarline,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Tooltip(
                            message: l10n.initialBarlineTooltip,
                            child: Transform.scale(
                              scale: 0.75,
                              child: Switch(
                                value: widget.group.initialBarline,
                                onChanged: (v) => widget.notifier
                                    .updateGroupInitialBarline(v,
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
                ],
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
                          core.StaffDefinition def => StaffItemWidget(
                              key: ValueKey('staff_${def.uid}'),
                              index: idx,
                              staff: def,
                              parentGroupHash: widget.group.hashCode,
                              notifier: widget.notifier,
                            ),
                          core.StaffNodeGroup subGroup => StaffGroupWidget(
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
