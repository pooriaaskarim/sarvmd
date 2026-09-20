import 'package:flutter/material.dart';
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

class SystemHierarchyPanel extends StatelessWidget {
  const SystemHierarchyPanel({super.key, required this.notifier});

  final DocumentCubit notifier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, docState) {
        final cs = Theme.of(context).colorScheme;
        final layout = docState.config.systemLayout;
        final isPersian = Localizations.localeOf(context).languageCode == 'fa';
        final textDirection = isPersian ? TextDirection.rtl : TextDirection.ltr;

        return Directionality(
          textDirection: textDirection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.systemSettings,
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
                    onPressed: () => showSystemGroupingDialog(context, notifier: notifier),
                    icon: const Icon(Icons.account_tree, size: 16),
                    tooltip: AppLocalizations.of(context)!.systemGrouping,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    onPressed: () => notifier.addStaff(),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    tooltip: AppLocalizations.of(context)!.addStaff,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StaffGroupWidget(
                group: layout.rootGroup,
                isRoot: true,
                notifier: notifier,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const EnsembleSummaryWidget(),
            ],
          ),
        );
      },
    );
  }
}

class _StaffGroupWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DragTarget<StaffDragPayload>(
      onWillAcceptWithDetails: (details) => details.data.parentGroupHash != group.hashCode,
      onAcceptWithDetails: (details) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifier.moveStaffNode(
            sourceGroupHash: details.data.parentGroupHash,
            targetGroupHash: group.hashCode,
            sourceIndex: details.data.index,
            targetIndex: group.children.length,
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
                : cs.surfaceContainerHighest.withValues(alpha: isRoot ? 0.2 : 0.4),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final bool isUltraNarrow = width < 260;
                  final bool isStackedHeader = width >= 260 && width < 340;
                  final bool isCompactSegmented = width < 480;

                  if (isUltraNarrow) {
                    // Stage 3 (< 260px): Single row with 24px PopupMenuButton
                    return Row(
                      children: [
                        if (!isRoot && index != null) ...[
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6.0),
                            child: Icon(
                              Icons.drag_indicator,
                              size: 16,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        Icon(
                          group.connector == core.SystemConnector.brace
                              ? Icons.code
                              : group.connector == core.SystemConnector.bracket
                                  ? Icons.reorder
                                  : Icons.linear_scale,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isRoot ? l10n.mainEnsemble : l10n.subGroup,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => notifier.addStaffToGroup(groupHash: group.hashCode),
                          icon: const Icon(Icons.add_circle_outline, size: 14),
                          tooltip: l10n.addStaff,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: const EdgeInsets.all(2),
                        ),
                        if (!isRoot) ...[
                          IconButton(
                            onPressed: () => notifier.ungroupSubGroup(group.hashCode),
                            icon: Icon(Icons.layers_clear_outlined, size: 14, color: cs.error.withValues(alpha: 0.7)),
                            tooltip: l10n.reset,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            padding: const EdgeInsets.all(2),
                          ),
                        ],
                        const SizedBox(width: 4),
                        _ConnectorMenuButton(
                          value: group.connector,
                          onChanged: (v) => notifier.updateGroupConnector(v,
                              groupHash: group.hashCode),
                        ),
                      ],
                    );
                  } else if (isStackedHeader) {
                    // Stage 2 (260px - 340px): Stacked header (Title on Row 1, SegmentedButton on Row 2)
                    return Column(
                      children: [
                        Row(
                          children: [
                            if (!isRoot && index != null) ...[
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
                              group.connector == core.SystemConnector.brace
                                  ? Icons.code
                                  : group.connector == core.SystemConnector.bracket
                                      ? Icons.reorder
                                      : Icons.linear_scale,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isRoot ? l10n.mainEnsemble : l10n.subGroup,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => notifier.addStaffToGroup(groupHash: group.hashCode),
                              icon: const Icon(Icons.add_circle_outline, size: 14),
                              tooltip: l10n.addStaff,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              padding: const EdgeInsets.all(2),
                            ),
                            if (!isRoot) ...[
                              IconButton(
                                onPressed: () => notifier.ungroupSubGroup(group.hashCode),
                                icon: Icon(Icons.layers_clear_outlined, size: 14, color: cs.error.withValues(alpha: 0.7)),
                                tooltip: l10n.reset,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                padding: const EdgeInsets.all(2),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        _ConnectorPicker(
                          value: group.connector,
                          onChanged: (v) => notifier.updateGroupConnector(v,
                              groupHash: group.hashCode),
                          compact: true,
                        ),
                      ],
                    );
                  } else {
                    // Stage 1 (>= 340px): Single row with SegmentedButton
                    return Row(
                      children: [
                        if (!isRoot && index != null) ...[
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
                          group.connector == core.SystemConnector.brace
                              ? Icons.code
                              : group.connector == core.SystemConnector.bracket
                                  ? Icons.reorder
                                  : Icons.linear_scale,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isRoot ? l10n.mainEnsemble : l10n.subGroup,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => notifier.addStaffToGroup(groupHash: group.hashCode),
                          icon: const Icon(Icons.add_circle_outline, size: 14),
                          tooltip: l10n.addStaff,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: const EdgeInsets.all(2),
                        ),
                        if (!isRoot) ...[
                          IconButton(
                            onPressed: () => notifier.ungroupSubGroup(group.hashCode),
                            icon: Icon(Icons.layers_clear_outlined, size: 14, color: cs.error.withValues(alpha: 0.7)),
                            tooltip: l10n.reset,
                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                            padding: const EdgeInsets.all(2),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _ConnectorPicker(
                          value: group.connector,
                          onChanged: (v) => notifier.updateGroupConnector(v,
                              groupHash: group.hashCode),
                          compact: isCompactSegmented,
                        ),
                      ],
                    );
                  }
                },
              ),
              if (group.children.length > 1)
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
                              value: group.continuousBarlines,
                              onChanged: (v) => notifier
                                  .updateGroupContinuousBarlines(v,
                                      groupHash: group.hashCode),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int idx = 0; idx < group.children.length; idx++)
                    switch (group.children[idx]) {
                      core.StaffDefinition def => _StaffItem(
                          key: ValueKey('staff_${def.uid}'),
                          index: idx,
                          staff: def,
                          parentGroupHash: group.hashCode,
                          notifier: notifier,
                        ),
                      core.StaffNodeGroup subGroup => _StaffGroupWidget(
                          key: ValueKey('group_${subGroup.hashCode}_$idx'),
                          group: subGroup,
                          index: idx,
                          notifier: notifier,
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
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.staff.instrumentName ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditingName) {
        _submitName();
      }
    });
  }

  @override
  void didUpdateWidget(_StaffItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingName && oldWidget.staff.instrumentName != widget.staff.instrumentName) {
      _controller.text = widget.staff.instrumentName ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
      _controller.text = widget.staff.instrumentName ?? '';
    });
    _focusNode.requestFocus();
  }

  void _submitName() {
    if (!_isEditingName) return;
    setState(() {
      _isEditingName = false;
    });
    final trimmed = _controller.text.trim();
    widget.notifier.updateStaffInstrumentName(
      widget.staff.uid,
      trimmed.isEmpty ? null : trimmed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
      onAcceptWithDetails: (details) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.notifier.moveStaffNode(
            sourceGroupHash: details.data.parentGroupHash,
            targetGroupHash: widget.parentGroupHash,
            sourceIndex: details.data.index,
            targetIndex: widget.index,
          );
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isDropHovered = candidateData.isNotEmpty;

        final itemCard = Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDropHovered
                ? cs.primaryContainer.withValues(alpha: 0.35)
                : cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDropHovered
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.3),
              width: isDropHovered ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDropHovered)
                Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Row(
                children: [
                  // Drag Handle with Draggable
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
                      child: Icon(
                        Icons.drag_indicator,
                        size: 18,
                        color: cs.primary,
                      ),
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: Icon(
                          Icons.drag_indicator,
                          size: 18,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),

                  // Index Circle
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and configuration badges
                  Expanded(
                    child: _isEditingName
                        ? SizedBox(
                            height: 28,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onSubmitted: (_) => _submitName(),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onDoubleTap: _startEditingName,
                                      onTap: () => _openConfigDialog(context),
                                      child: Tooltip(
                                        message: labelText,
                                        child: Text(
                                          labelText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _startEditingName,
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 12,
                                      color: cs.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    constraints: const BoxConstraints(
                                        minWidth: 20, minHeight: 20),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _openConfigDialog(context),
                                borderRadius: BorderRadius.circular(4),
                                child: Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    _buildBadge(context,
                                        l10n.linesCount(widget.staff.lines)),
                                    _buildBadge(context, clefLabel),
                                    if (!widget.staff.labelVisible)
                                      _buildBadge(context, l10n.hidden,
                                          color: cs.error),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Actions
                  IconButton(
                    onPressed: () => _openConfigDialog(context),
                    icon: Icon(Icons.tune_outlined,
                        size: 16, color: cs.primary.withValues(alpha: 0.8)),
                    tooltip: l10n.configureStaff,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    onPressed: () =>
                        widget.notifier.removeStaffByUid(widget.staff.uid),
                    icon: Icon(Icons.remove_circle_outline,
                        size: 16, color: cs.error.withValues(alpha: 0.7)),
                    tooltip: l10n.removeStaff,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
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
    required this.compact,
  });

  final core.SystemConnector value;
  final ValueChanged<core.SystemConnector> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<core.SystemConnector>(
      segments: [
        ButtonSegment(
          value: core.SystemConnector.none,
          icon: const Icon(Icons.linear_scale, size: 14),
          label: compact
              ? null
              : Text(l10n.connectorNone, style: const TextStyle(fontSize: 10)),
          tooltip: l10n.connectorNoneTooltip,
        ),
        ButtonSegment(
          value: core.SystemConnector.bracket,
          icon: const Icon(Icons.reorder, size: 14),
          label: compact
              ? null
              : Text(l10n.connectorBracket, style: const TextStyle(fontSize: 10)),
          tooltip: l10n.connectorBracketTooltip,
        ),
        ButtonSegment(
          value: core.SystemConnector.subBracket,
          icon: const Icon(Icons.line_weight, size: 14),
          label: compact
              ? null
              : Text(l10n.connectorSubBracket, style: const TextStyle(fontSize: 10)),
          tooltip: l10n.connectorSubBracketTooltip,
        ),
        ButtonSegment(
          value: core.SystemConnector.brace,
          icon: const Icon(Icons.code, size: 14),
          label: compact
              ? null
              : Text(l10n.connectorBrace, style: const TextStyle(fontSize: 10)),
          tooltip: l10n.connectorBraceTooltip,
        ),
      ],
      selected: {value},
      onSelectionChanged: (set) => onChanged(set.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        padding: const EdgeInsets.symmetric(horizontal: 4),
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

    final (IconData icon, String label) = switch (value) {
      core.SystemConnector.none => (Icons.linear_scale, l10n.connectorNone),
      core.SystemConnector.bracket => (Icons.reorder, l10n.connectorBracket),
      core.SystemConnector.subBracket =>
        (Icons.line_weight, l10n.connectorSubBracket),
      core.SystemConnector.brace => (Icons.code, l10n.connectorBrace),
    };

    return PopupMenuButton<core.SystemConnector>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: label,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 14, color: cs.primary),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: core.SystemConnector.none,
          child: Row(
            children: [
              const Icon(Icons.linear_scale, size: 14),
              const SizedBox(width: 8),
              Text(l10n.connectorNone, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: core.SystemConnector.bracket,
          child: Row(
            children: [
              const Icon(Icons.reorder, size: 14),
              const SizedBox(width: 8),
              Text(l10n.connectorBracket, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: core.SystemConnector.subBracket,
          child: Row(
            children: [
              const Icon(Icons.line_weight, size: 14),
              const SizedBox(width: 8),
              Text(l10n.connectorSubBracket,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: core.SystemConnector.brace,
          child: Row(
            children: [
              const Icon(Icons.code, size: 14),
              const SizedBox(width: 8),
              Text(l10n.connectorBrace, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
