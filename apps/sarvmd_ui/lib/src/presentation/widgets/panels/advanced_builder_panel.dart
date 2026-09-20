import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../common/ensemble_summary_widget.dart';
import '../dialogs/staff_config_dialog.dart';
import '../dialogs/system_grouping_dialog.dart';
import '../../../l10n/app_localizations.dart';

typedef StaffDragPayload = ({
  core.StaffDefinition staff,
  int parentGroupHash,
  int index,
});

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
    return context.dependOnInheritedWidgetOfExactType<_HierarchySelectionScope>();
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

  void _toggleSelection(String uid, {bool isShift = false, List<String>? allUidsInOrder}) {
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
            onToggleSelection: (uid, {isShift = false}) =>
                _toggleSelection(uid, isShift: isShift, allUidsInOrder: allUidsInOrder),
            onSelectAll: () => _selectAll(allUidsInOrder),
            onClearSelection: _clearSelection,
            onToggleCollapseGroup: _toggleCollapseGroup,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedUids.isEmpty)
                  Row(
                    children: [
                      Icon(Icons.account_tree_outlined, size: 16, color: cs.primary),
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
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        onPressed: () => showSystemGroupingDialog(context, notifier: widget.notifier),
                        icon: const Icon(Icons.account_tree, size: 16),
                        tooltip: l10n.systemGrouping,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: const EdgeInsets.all(4),
                      ),
                      IconButton(
                        onPressed: () => widget.notifier.addStaff(),
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        tooltip: l10n.addStaff,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        padding: const EdgeInsets.all(4),
                      ),
                    ],
                  )
                else
                  // Top-Docked Contextual Batch Action Bar (CAB)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left counter badge & select-all toggle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                              tooltip: _selectedUids.length == allUidsInOrder.length
                                  ? 'Deselect All'
                                  : 'Select All',
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: const EdgeInsets.all(4),
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: PopupMenuButton<core.SystemConnector>(
                                    icon: Icon(Icons.layers, size: 18, color: cs.primary),
                                    tooltip: 'Group Selected Staves',
                                    padding: EdgeInsets.zero,
                                    onSelected: (connector) {
                                      widget.notifier.groupSelectedStaves(_selectedUids, connector);
                                      _clearSelection();
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: core.SystemConnector.bracket,
                                        child: Row(
                                          children: [
                                            Icon(Icons.reorder, size: 16, color: cs.primary),
                                            const SizedBox(width: 8),
                                            const Text('Group with Bracket [', style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: core.SystemConnector.brace,
                                        child: Row(
                                          children: [
                                            Icon(Icons.code, size: 16, color: cs.primary),
                                            const SizedBox(width: 8),
                                            const Text('Group with Brace {', style: TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () {
                                    widget.notifier.batchToggleVisibility(_selectedUids, false);
                                    _clearSelection();
                                  },
                                  icon: Icon(Icons.visibility_off_outlined, size: 18, color: cs.primary),
                                  tooltip: 'Batch Hide Labels',
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () {
                                    widget.notifier.batchDuplicateStaves(_selectedUids);
                                    _clearSelection();
                                  },
                                  icon: Icon(Icons.content_copy_outlined, size: 18, color: cs.primary),
                                  tooltip: 'Batch Duplicate',
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () {
                                    widget.notifier.batchDeleteStaves(_selectedUids);
                                    _clearSelection();
                                  },
                                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                                  tooltip: 'Batch Delete',
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Right Cancel button
                        IconButton(
                          onPressed: _clearSelection,
                          icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                          tooltip: 'Cancel Selection',
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: const EdgeInsets.all(4),
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
    this.index,
    required this.notifier,
  });

  final core.StaffNodeGroup group;
  final bool isRoot;
  final int? index;
  final DocumentCubit notifier;

  @override
  State<_StaffGroupWidget> createState() => _StaffGroupWidgetState();
}

class _StaffGroupWidgetState extends State<_StaffGroupWidget> {
  bool _isEditingName = false;

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
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.8),
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
    final isCollapsed = scope?.collapsedGroupHashes.contains(widget.group.hashCode) ?? false;
    final labelDisplay = widget.group.label.isNotEmpty
        ? (widget.group.abbreviation.isNotEmpty
            ? '${widget.group.label} (${widget.group.abbreviation})'
            : widget.group.label)
        : (widget.isRoot ? l10n.mainEnsemble : l10n.subGroup);

    return DragTarget<StaffDragPayload>(
      onWillAcceptWithDetails: (details) => details.data.parentGroupHash != widget.group.hashCode,
      onAcceptWithDetails: (details) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.notifier.moveStaffNode(
            sourceGroupHash: details.data.parentGroupHash,
            targetGroupHash: widget.group.hashCode,
            sourceIndex: details.data.index,
            targetIndex: widget.group.children.length,
          );
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovered
                ? cs.primaryContainer.withValues(alpha: 0.25)
                : cs.surfaceContainerHighest.withValues(alpha: widget.isRoot ? 0.2 : 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditingName)
                _QuickLabelingCard(
                  title: 'Edit Group Label',
                  initialName: widget.group.label,
                  initialAbbreviation: widget.group.abbreviation,
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
                  final bool isUltraNarrow = width < 260;
                  final bool isStackedHeader = width >= 260 && width < 340;
                  final bool isCompactSegmented = width < 480;

                  final foldCaret = !widget.isRoot
                      ? IconButton(
                          onPressed: () => scope?.onToggleCollapseGroup(widget.group.hashCode),
                          icon: Icon(
                            isCollapsed
                                ? Icons.keyboard_arrow_right
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          tooltip: isCollapsed ? 'Expand Group' : 'Collapse Group',
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: EdgeInsets.zero,
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
                                  : cs.onSurfaceVariant.withValues(alpha: 0.5),
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
                    ],
                  );

                  final labelActionButtons = [
                    IconButton(
                      onPressed: _startEditingName,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      tooltip: 'Edit Group Label',
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
                      tooltip: widget.group.labelVisible ? l10n.hidden : l10n.hidden,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ];

                  final structureActionButtons = [
                    IconButton(
                      onPressed: () => widget.notifier.addStaffToGroup(groupHash: widget.group.hashCode),
                      icon: const Icon(Icons.add_circle_outline, size: 14),
                      tooltip: l10n.addStaff,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: const EdgeInsets.all(2),
                    ),
                    if (!widget.isRoot) ...[
                      IconButton(
                        onPressed: () => widget.notifier.ungroupSubGroup(widget.group.hashCode),
                        icon: Icon(Icons.layers_clear_outlined, size: 14, color: cs.error.withValues(alpha: 0.7)),
                        tooltip: l10n.reset,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        padding: const EdgeInsets.all(2),
                      ),
                    ],
                  ];

                  if (isUltraNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (foldCaret != null) foldCaret,
                            if (!widget.isRoot && widget.index != null) ...[
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 4.0),
                                child: Icon(
                                  Icons.drag_indicator,
                                  size: 16,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                            Icon(
                              widget.group.connector == core.SystemConnector.brace
                                  ? Icons.code
                                  : widget.group.connector == core.SystemConnector.bracket
                                      ? Icons.reorder
                                      : Icons.linear_scale,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: titleWidget),
                            ...labelActionButtons,
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _ConnectorMenuButton(
                                value: widget.group.connector,
                                onChanged: (v) => widget.notifier.updateGroupConnector(v,
                                    groupHash: widget.group.hashCode),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ...structureActionButtons,
                          ],
                        ),
                      ],
                    );
                  } else if (isStackedHeader) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            if (foldCaret != null) foldCaret,
                            if (!widget.isRoot && widget.index != null) ...[
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 8.0),
                                child: Icon(
                                  Icons.drag_indicator,
                                  size: 18,
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                            Icon(
                              widget.group.connector == core.SystemConnector.brace
                                  ? Icons.code
                                  : widget.group.connector == core.SystemConnector.bracket
                                      ? Icons.reorder
                                      : Icons.linear_scale,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: titleWidget),
                            ...labelActionButtons,
                            const SizedBox(width: 4),
                            ...structureActionButtons,
                          ],
                        ),
                        const SizedBox(height: 6),
                        _ConnectorPicker(
                          value: widget.group.connector,
                          onChanged: (v) => widget.notifier.updateGroupConnector(v,
                              groupHash: widget.group.hashCode),
                          compact: true,
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        if (foldCaret != null) foldCaret,
                        if (!widget.isRoot && widget.index != null) ...[
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8.0),
                            child: Icon(
                              Icons.drag_indicator,
                              size: 18,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        Icon(
                          widget.group.connector == core.SystemConnector.brace
                              ? Icons.code
                              : widget.group.connector == core.SystemConnector.bracket
                                  ? Icons.reorder
                                  : Icons.linear_scale,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: titleWidget),
                        ...labelActionButtons,
                        const SizedBox(width: 4),
                        ...structureActionButtons,
                        const SizedBox(width: 8),
                        _ConnectorPicker(
                          value: widget.group.connector,
                          onChanged: (v) => widget.notifier.updateGroupConnector(v,
                              groupHash: widget.group.hashCode),
                          compact: isCompactSegmented,
                        ),
                      ],
                    );
                  }
                },
              ),
              if (widget.group.children.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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
              const SizedBox(height: 12),
              if (isCollapsed)
                InkWell(
                  onTap: () => scope?.onToggleCollapseGroup(widget.group.hashCode),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        Icon(Icons.unfold_more, size: 14, color: cs.onSurfaceVariant),
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
                            index: idx,
                            notifier: widget.notifier,
                          ),
                      }
                  ],
                ),
            ],
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
    if (widget.staff.clef != null) {
      final name = switch (widget.staff.clef!.symbol) {
        core.ClefSymbol.g => l10n.trebleClef,
        core.ClefSymbol.c => l10n.altoClef,
        core.ClefSymbol.f => l10n.bassClef,
        core.ClefSymbol.tab => l10n.categoryTablature,
        core.ClefSymbol.percussion => l10n.categoryPercussion,
      };
      clefLabel = l10n.clefWithLine(name, widget.staff.clef!.anchorLine);
    }

    final payload = (
      staff: widget.staff,
      parentGroupHash: widget.parentGroupHash,
      index: widget.index,
    );

    return DragTarget<StaffDragPayload>(
      onWillAcceptWithDetails: (details) =>
          details.data.staff.uid != widget.staff.uid,
      onMove: (details) {
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
        if (_hoverRatioY != null) {
          setState(() {
            _hoverRatioY = null;
          });
        }
      },
      onAcceptWithDetails: (details) {
        final ratio = _hoverRatioY ?? 0.5;
        setState(() {
          _hoverRatioY = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ratio < 0.25) {
            widget.notifier.moveStaffNode(
              sourceGroupHash: details.data.parentGroupHash,
              targetGroupHash: widget.parentGroupHash,
              sourceIndex: details.data.index,
              targetIndex: widget.index,
            );
          } else if (ratio > 0.75) {
            widget.notifier.moveStaffNode(
              sourceGroupHash: details.data.parentGroupHash,
              targetGroupHash: widget.parentGroupHash,
              sourceIndex: details.data.index,
              targetIndex: widget.index + 1,
            );
          } else {
            widget.notifier.groupTwoStavesTogether(
              details.data.staff.uid,
              widget.staff.uid,
            );
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isDropHovered = candidateData.isNotEmpty;
        final ratio = _hoverRatioY;
        final isTopZone = isDropHovered && ratio != null && ratio < 0.25;
        final isBottomZone = isDropHovered && ratio != null && ratio > 0.75;
        final isCombineZone = isDropHovered &&
            (ratio == null || (ratio >= 0.25 && ratio <= 0.75));

        final itemCard = GestureDetector(
          onLongPress: () {
            scope?.onToggleSelection(widget.staff.uid);
          },
          onTap: () {
            if (isSelectionMode) {
              final isShift = HardwareKeyboard.instance.isShiftPressed;
              scope?.onToggleSelection(widget.staff.uid, isShift: isShift);
            } else {
              _openConfigDialog(context);
            }
          },
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
                    initialAbbreviation: widget.staff.instrumentAbbreviation ?? '',
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
                      // Checkbox in selection mode or when selected
                      if (isSelectionMode || isSelected)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 4.0),
                          child: InkWell(
                            onTap: () {
                              final isShift = HardwareKeyboard.instance.isShiftPressed;
                              scope?.onToggleSelection(widget.staff.uid, isShift: isShift);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 18,
                              color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                          ),
                        ),

                      // Unified Drag Handle & Order Badge
                      Draggable<StaffDragPayload>(
                        data: payload,
                        feedback: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: cs.primary, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.shadow.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.drag_indicator, size: 15, color: cs.primary),
                                const SizedBox(width: 2),
                                Text(
                                  '${widget.index + 1}',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cs.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 0.8),
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
                          ),
                        ),
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
                                    onTap: () {
                                      if (isSelectionMode) {
                                        final isShift = HardwareKeyboard.instance.isShiftPressed;
                                        scope?.onToggleSelection(widget.staff.uid, isShift: isShift);
                                      } else {
                                        _openConfigDialog(context);
                                      }
                                    },
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
                                const SizedBox(width: 4),
                                if (!isSelectionMode) ...[
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
                                    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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
                                    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  ),
                                ],
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
                                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                                if (!isSelectionMode)
                                  IconButton(
                                    onPressed: () =>
                                        widget.notifier.removeStaffByUid(widget.staff.uid),
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
                                    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                // Line Count Badge Quick-Picker
                                PopupMenuButton<int>(
                                  tooltip: 'Change Line Count',
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
                                        child: Text(l10n.linesCount(i),
                                            style: const TextStyle(fontSize: 12)),
                                      ),
                                  ],
                                  child: _buildBadge(context,
                                      l10n.linesCount(widget.staff.lines)),
                                ),

                                // Clef Badge Quick-Picker
                                PopupMenuButton<core.ClefSymbol>(
                                  tooltip: 'Change Clef',
                                  padding: EdgeInsets.zero,
                                  onSelected: (symbol) {
                                    final newClef = switch (symbol) {
                                      core.ClefSymbol.g => core.Clef.treble,
                                      core.ClefSymbol.c => core.Clef.alto,
                                      core.ClefSymbol.f => core.Clef.bass,
                                      core.ClefSymbol.tab => core.Clef.tab,
                                      core.ClefSymbol.percussion =>
                                        core.Clef.percussion,
                                    };
                                    widget.notifier.updateStaffClef(
                                        widget.staff.uid, newClef);
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: core.ClefSymbol.g,
                                      child: Row(children: [
                                        const Icon(Icons.music_note, size: 14),
                                        const SizedBox(width: 8),
                                        Text(l10n.trebleClef,
                                            style: const TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: core.ClefSymbol.c,
                                      child: Row(children: [
                                        const Icon(Icons.music_note, size: 14),
                                        const SizedBox(width: 8),
                                        Text(l10n.altoClef,
                                            style: const TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: core.ClefSymbol.f,
                                      child: Row(children: [
                                        const Icon(Icons.music_note, size: 14),
                                        const SizedBox(width: 8),
                                        Text(l10n.bassClef,
                                            style: const TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: core.ClefSymbol.tab,
                                      child: Row(children: [
                                        const Icon(Icons.numbers, size: 14),
                                        const SizedBox(width: 8),
                                        Text(l10n.categoryTablature,
                                            style: const TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: core.ClefSymbol.percussion,
                                      child: Row(children: [
                                        const Icon(Icons.adjust, size: 14),
                                        const SizedBox(width: 8),
                                        Text(l10n.categoryPercussion,
                                            style: const TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                  ],
                                  child: _buildBadge(context, clefLabel),
                                ),

                                if (!widget.staff.labelVisible)
                                  InkWell(
                                    onTap: () => widget.notifier.updateStaffConfigDetails(
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

        return itemCard;
      },
    );
  }

  Widget _buildBadge(BuildContext context, String text, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: (color ?? cs.secondaryContainer).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (color ?? cs.secondaryContainer).withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color ?? cs.primary,
        ),
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
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<core.SystemConnector>(
      initialValue: value,
      onSelected: onChanged,
      icon: const Icon(Icons.tune, size: 14),
      tooltip: l10n.systemGrouping,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: core.SystemConnector.none,
          child: Text(l10n.connectorNone, style: const TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: core.SystemConnector.bracket,
          child: Text(l10n.connectorBracket, style: const TextStyle(fontSize: 12)),
        ),
        PopupMenuItem(
          value: core.SystemConnector.brace,
          child: Text(l10n.connectorBrace, style: const TextStyle(fontSize: 12)),
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
  if (lower.contains('violin 2') || lower.contains('violin ii')) return 'Vln. II';
  if (lower.contains('violin')) return 'Vln.';
  if (lower.contains('viola')) return 'Vla.';
  if (lower.contains('violoncello') || lower.contains('cello')) return 'Vc.';
  if (lower.contains('double bass') || lower.contains('contrabass')) return 'Cb.';
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
    return words.first.length > 4 ? '${words.first.substring(0, 3)}.' : words.first;
  } else {
    return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}.' : '').join('');
  }
}

class _QuickLabelingCard extends StatefulWidget {
  const _QuickLabelingCard({
    required this.title,
    required this.initialName,
    required this.initialAbbreviation,
    required this.onSave,
    required this.onCancel,
  });

  final String title;
  final String initialName;
  final String initialAbbreviation;
  final void Function(String name, String abbreviation) onSave;
  final VoidCallback onCancel;

  @override
  State<_QuickLabelingCard> createState() => _QuickLabelingCardState();
}

class _QuickLabelingCardState extends State<_QuickLabelingCard> {
  late TextEditingController _nameController;
  late TextEditingController _abbrevController;
  late FocusNode _nameFocusNode;
  late FocusNode _abbrevFocusNode;
  String _suggestedAbbrev = '';

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
    widget.onSave(_nameController.text.trim(), _abbrevController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.label_outlined, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: widget.onCancel,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: EdgeInsets.zero,
                tooltip: l10n.reset,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Full Name Field
          SizedBox(
            height: 32,
            child: TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Full Name / Label',
                labelStyle: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onSubmitted: (_) => _abbrevFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(height: 8),
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
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 10, color: cs.onPrimaryContainer),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                _suggestedAbbrev,
                                style: TextStyle(
                                  fontSize: 10,
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

              if (isAbbrevNarrow && chipWidget != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _abbrevController,
                        focusNode: _abbrevFocusNode,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Abbreviation',
                          labelStyle: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    chipWidget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _abbrevController,
                        focusNode: _abbrevFocusNode,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Abbreviation',
                          labelStyle: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ),
                  if (chipWidget != null) ...[
                    const SizedBox(width: 6),
                    Flexible(child: chipWidget),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Save / Cancel Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                child: Text('Cancel', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Save', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
