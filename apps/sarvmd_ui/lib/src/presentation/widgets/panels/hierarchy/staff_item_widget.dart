import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../../l10n/app_localizations.dart';
import '../../../../logic/document/document_cubit.dart';
import '../../dialogs/staff_config_dialog.dart';
import 'hierarchy_models.dart';
import 'hierarchy_selection_scope.dart';
import 'quick_labeling_card.dart';

/// Interactive tree item representing an individual musical staff.
///
/// Supports multi-select, drag-and-drop reordering, in-place label editing,
/// and quick-pick popups for clef, staff lines, and anchor line.
class StaffItemWidget extends StatefulWidget {
  const StaffItemWidget({
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
  State<StaffItemWidget> createState() => _StaffItemWidgetState();
}

class _StaffItemWidgetState extends State<StaffItemWidget> {
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
    required HierarchySelectionScope? scope,
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
        HierarchyDragState.hoveredChildDropPayload = null;
        setState(() => _isDragging = true);
      },
      onDragEnd: (_) {
        HierarchyDragState.hoveredChildDropPayload = null;
        if (mounted) setState(() => _isDragging = false);
      },
      onDraggableCanceled: (_, __) {
        HierarchyDragState.hoveredChildDropPayload = null;
        if (mounted) setState(() => _isDragging = false);
      },
      onDragCompleted: () {
        HierarchyDragState.hoveredChildDropPayload = null;
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
    final scope = HierarchySelectionScope.of(context);
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
              groupContains(data.group, widget.parentGroupHash)) {
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
          HierarchyDragState.hoveredChildDropPayload = null;
          return;
        }
        if (data is GroupDragPayload &&
            (widget.parentGroupHash == data.group.hashCode ||
                groupContains(data.group, widget.parentGroupHash))) {
          if (_hoverRatioY != null) {
            setState(() {
              _hoverRatioY = null;
            });
          }
          HierarchyDragState.hoveredChildDropPayload = null;
          return;
        }
        HierarchyDragState.hoveredChildDropPayload = data;
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
        if (HierarchyDragState.hoveredChildDropPayload == data) {
          HierarchyDragState.hoveredChildDropPayload = null;
        }
        if (_hoverRatioY != null) {
          setState(() {
            _hoverRatioY = null;
          });
        }
      },
      onAcceptWithDetails: (details) {
        HierarchyDragState.hoveredChildDropPayload = null;
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
              final targetIdx = computeTargetIndex(
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
              final targetIdx = computeTargetIndex(
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
              groupContains(data.group, widget.parentGroupHash)) {
            return;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final insertAfter = ratio >= 0.5;
            final targetIdx = computeTargetIndex(
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
                !groupContains(p.group, widget.parentGroupHash);
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

        final cardContainer = LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 280;
            return AnimatedOpacity(
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
                  QuickLabelingCard(
                    title: 'Edit Staff Label',
                    initialName: widget.staff.instrumentName ?? '',
                    initialAbbreviation:
                        widget.staff.instrumentAbbreviation ?? '',
                    initialLabelStyle: widget.staff.labelStyle,
                    onSaveStaffStyle: (style) {
                      widget.notifier.updateStaffConfigDetails(
                        widget.staff.uid,
                        labelStyle: style,
                      );
                    },
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
                                  child: GestureDetector(
                                    onDoubleTap: _startEditingName,
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
                                ),
                                if (widget.staff.labelVisible &&
                                    (widget.staff.instrumentAbbreviation ==
                                            null ||
                                        widget.staff.instrumentAbbreviation!
                                            .trim()
                                            .isEmpty)) ...[
                                  const SizedBox(width: 4),
                                  Tooltip(
                                    message:
                                        'Missing abbreviation (subsequent systems will fall back to full name)',
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Colors.amber,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 4),
                                if (isCompact)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                                minWidth: 28, minHeight: 28),
                                            padding: const EdgeInsets.all(4),
                                            visualDensity:
                                                VisualDensity.compact,
                                            style: IconButton.styleFrom(
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              widget.notifier
                                                  .updateStaffConfigDetails(
                                                widget.staff.uid,
                                                visible:
                                                    !widget.staff.labelVisible,
                                              );
                                            },
                                            icon: Icon(
                                              widget.staff.labelVisible
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
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
                                                minWidth: 28, minHeight: 28),
                                            padding: const EdgeInsets.all(4),
                                            visualDensity:
                                                VisualDensity.compact,
                                            style: IconButton.styleFrom(
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap),
                                          ),
                                          SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: PopupMenuButton<String>(
                                              icon: Icon(
                                                Icons.more_vert,
                                                size: 16,
                                                color: cs.onSurfaceVariant
                                                    .withValues(alpha: 0.7),
                                              ),
                                              tooltip: 'Staff Options',
                                              padding: EdgeInsets.zero,
                                              onSelected: (val) {
                                                if (val == 'config') {
                                                  _openConfigDialog(context);
                                                } else if (val == 'remove') {
                                                  widget.notifier
                                                      .removeStaffByUid(
                                                          widget.staff.uid);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'config',
                                                  height: 32,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          Icons.tune_outlined,
                                                          size: 14,
                                                          color: cs.primary),
                                                      const SizedBox(width: 8),
                                                      Text(l10n.configureStaff,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12)),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'remove',
                                                  height: 32,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .remove_circle_outline,
                                                          size: 14,
                                                          color: cs.error),
                                                      const SizedBox(width: 8),
                                                      Text(l10n.removeStaff,
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: cs.error)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                else
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
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
                                              minWidth: 28, minHeight: 28),
                                          padding: const EdgeInsets.all(4),
                                          visualDensity: VisualDensity.compact,
                                          style: IconButton.styleFrom(
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            widget.notifier
                                                .updateStaffConfigDetails(
                                              widget.staff.uid,
                                              visible:
                                                  !widget.staff.labelVisible,
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
                                              minWidth: 28, minHeight: 28),
                                          padding: const EdgeInsets.all(4),
                                          visualDensity: VisualDensity.compact,
                                          style: IconButton.styleFrom(
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _openConfigDialog(context),
                                          icon: Icon(
                                            Icons.tune_outlined,
                                            size: 16,
                                            color: cs.primary,
                                          ),
                                          tooltip: l10n.configureStaff,
                                          constraints: const BoxConstraints(
                                              minWidth: 28, minHeight: 28),
                                          padding: const EdgeInsets.all(4),
                                          visualDensity: VisualDensity.compact,
                                          style: IconButton.styleFrom(
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap),
                                        ),
                                        IconButton(
                                          onPressed: () => widget.notifier
                                              .removeStaffByUid(
                                                  widget.staff.uid),
                                          icon: Icon(
                                            Icons.remove_circle_outline,
                                            size: 16,
                                            color: cs.error,
                                          ),
                                          tooltip: l10n.removeStaff,
                                          constraints: const BoxConstraints(
                                              minWidth: 28, minHeight: 28),
                                          padding: const EdgeInsets.all(4),
                                          visualDensity: VisualDensity.compact,
                                          style: IconButton.styleFrom(
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap),
                                    ),
                                  ],
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
                                        value: core.Clef.percussion,
                                        child: Row(children: [
                                          if (currentClef is core.PercussionClef)
                                            Icon(Icons.check,
                                                size: 14, color: cs.primary)
                                          else
                                            const Icon(Icons.music_note,
                                                size: 14),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l10n.percussionClef,
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
                                            const Icon(Icons.music_note,
                                                size: 14),
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
                                    ];
                                  },
                                  child: HierarchyBadge(
                                    text: clefLabel,
                                    showChevron: true,
                                  ),
                                ),

                                // 2. Lines Quick-Picker OR Anchor Line Picker
                                if (isAudibleClef)
                                  PopupMenuButton<int>(
                                    tooltip: l10n.clefAnchorLineHeader,
                                    padding: EdgeInsets.zero,
                                    onSelected: (line) {
                                      final updatedClef = staffClef.symbol
                                          .createClef(anchorLine: line);
                                      widget.notifier.updateStaffClef(
                                        widget.staff.uid,
                                        updatedClef,
                                      );
                                    },
                                    itemBuilder: (context) {
                                      final presets =
                                          staffClef.symbol.registerPresets;
                                      final hasCurrentLine = presets.any(
                                          (p) =>
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
                                    child: HierarchyBadge(
                                      text: l10n.clefAnchorLineReadout(
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
                                    child: HierarchyBadge(
                                      text: l10n.linesCount(widget.staff.lines),
                                      showChevron: true,
                                    ),
                                  ),

                                // 3. Resolved Label Badge (Live feedback of Model B numbering)
                                Builder(
                                  builder: (context) {
                                    final resolvedPos = widget
                                        .notifier.layout.systems.firstOrNull?.staves
                                        .where((s) =>
                                            s.definition?.uid ==
                                            widget.staff.uid)
                                        .firstOrNull;
                                    final resolved = resolvedPos?.resolvedLabel;
                                    if (resolved == null ||
                                        resolved.isEmpty ||
                                        resolved == labelText) {
                                      return const SizedBox.shrink();
                                    }
                                    return Tooltip(
                                      message:
                                          'Resolved Engraving Label: "$resolved"',
                                      child: HierarchyBadge(
                                        text: 'Label: $resolved',
                                        color: cs.secondary,
                                      ),
                                    );
                                  },
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
      },
    );

        final itemCard = LongPressDraggable<StaffDragPayload>(
          data: payload,
          feedback: feedbackWidget,
          delay: const Duration(milliseconds: 350),
          maxSimultaneousDrags: _isEditingName ? 0 : 1,
          onDragStarted: () {
            HierarchyDragState.hoveredChildDropPayload = null;
            setState(() => _isDragging = true);
          },
          onDragEnd: (_) {
            HierarchyDragState.hoveredChildDropPayload = null;
            if (mounted) setState(() => _isDragging = false);
          },
          onDraggableCanceled: (_, __) {
            HierarchyDragState.hoveredChildDropPayload = null;
            if (mounted) setState(() => _isDragging = false);
          },
          onDragCompleted: () {
            HierarchyDragState.hoveredChildDropPayload = null;
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
}
