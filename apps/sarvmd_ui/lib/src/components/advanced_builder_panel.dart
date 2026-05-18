import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../config_notifier.dart';
import 'specialized/staff_config_dialog.dart';

class SystemHierarchyPanel extends StatelessWidget {
  const SystemHierarchyPanel({super.key, required this.notifier});

  final ConfigNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        final layout = notifier.config.systemLayout;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'System Layout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => notifier.addStaff(),
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label:
                      const Text('Add Staff', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
            _buildMolaSummary(context),
          ],
        );
      },
    );
  }

  Widget _buildMolaSummary(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final staffCount = notifier.config.staffCount;
    final totalHeight = notifier.config.systemHeight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ensemble Summary',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Total Staves', value: '$staffCount'),
          _SummaryRow(
              label: 'System Height',
              value: '${totalHeight.toStringAsFixed(1)} mm'),
          _SummaryRow(
            label: 'Density',
            value: '${notifier.layout.systemCount} systems/page',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(value,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
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

  final core.StaffGroup group;
  final bool isRoot;
  final int? index;
  final ConfigNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: isRoot ? 0.2 : 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 300;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (!isRoot && index != null) ...[
                    ReorderableDragStartListener(
                      index: index!,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.drag_indicator,
                            size: 18,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
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
                      isRoot ? 'Main Ensemble' : 'Sub Group',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _ConnectorPicker(
                    value: group.connector,
                    onChanged: (v) => notifier.updateGroupConnector(v),
                    compact: isCompact,
                  ),
                  if (!isCompact && group.children.length > 1) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: 'Continuous barlines across staves',
                      child: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: group.continuousBarlines,
                          onChanged: (v) =>
                              notifier.updateGroupContinuousBarlines(v),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isCompact && group.children.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Text('Continuous Barlines',
                          style: TextStyle(fontSize: 10)),
                      const Spacer(),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: group.continuousBarlines,
                          onChanged: (v) =>
                              notifier.updateGroupContinuousBarlines(v),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: group.children.length,
                onReorder: (oldIndex, newIndex) {
                  notifier.reorderGroupChildren(
                      group.hashCode, oldIndex, newIndex);
                },
                itemBuilder: (context, idx) {
                  final child = group.children[idx];
                  if (child is core.StaffDefinition) {
                    return _StaffItem(
                      key: ValueKey('staff_${child.uid}'),
                      index: idx,
                      staff: child,
                      notifier: notifier,
                    );
                  } else if (child is core.StaffGroup) {
                    return _StaffGroupWidget(
                      key: ValueKey('group_${child.hashCode}_$idx'),
                      group: child,
                      index: idx,
                      notifier: notifier,
                    );
                  }
                  return SizedBox(
                    key: ValueKey('empty_${group.hashCode}_$idx'),
                    child: const SizedBox.shrink(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StaffItem extends StatelessWidget {
  const _StaffItem({
    super.key,
    required this.index,
    required this.staff,
    required this.notifier,
  });

  final int index;
  final core.StaffDefinition staff;
  final ConfigNotifier notifier;

  void _openConfigDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StaffConfigDialog(staff: staff, notifier: notifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Build standard instrument label
    final String displayName = staff.instrumentName ?? 'Staff ${index + 1}';
    final String abbrevInfo = staff.instrumentAbbreviation != null &&
            staff.instrumentAbbreviation!.isNotEmpty
        ? ' (${staff.instrumentAbbreviation})'
        : '';
    final String labelText = '$displayName$abbrevInfo';

    // Clef description
    String clefLabel = 'No Clef';
    if (staff.clef != null) {
      clefLabel = switch (staff.clef!.symbol) {
        core.ClefSymbol.g => 'Treble (L${staff.clef!.anchorLine})',
        core.ClefSymbol.c => 'Alto (L${staff.clef!.anchorLine})',
        core.ClefSymbol.f => 'Bass (L${staff.clef!.anchorLine})',
        core.ClefSymbol.tab => 'TAB',
        core.ClefSymbol.percussion => 'Percussion',
      };
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Drag Handle
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
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
              '${index + 1}',
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
            child: InkWell(
              onTap: () => _openConfigDialog(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildBadge(context, '${staff.lines} lines'),
                        _buildBadge(context, clefLabel),
                        if (!staff.labelVisible)
                          _buildBadge(context, 'Hidden', color: cs.error),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          IconButton(
            onPressed: () => _openConfigDialog(context),
            icon: Icon(Icons.tune_outlined,
                size: 16, color: cs.primary.withValues(alpha: 0.8)),
            tooltip: 'Configure Staff',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            onPressed: () => notifier.removeStaff(index),
            icon: Icon(Icons.remove_circle_outline,
                size: 16, color: cs.error.withValues(alpha: 0.7)),
            tooltip: 'Remove Staff',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
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
    return SegmentedButton<core.SystemConnector>(
      segments: [
        ButtonSegment(
          value: core.SystemConnector.none,
          icon: const Icon(Icons.linear_scale, size: 14),
          label: compact
              ? null
              : const Text('None', style: TextStyle(fontSize: 10)),
          tooltip: 'No Connector',
        ),
        ButtonSegment(
          value: core.SystemConnector.bracket,
          icon: const Icon(Icons.reorder, size: 14),
          label: compact
              ? null
              : const Text('Bracket', style: TextStyle(fontSize: 10)),
          tooltip: 'Bracket Connector',
        ),
        ButtonSegment(
          value: core.SystemConnector.brace,
          icon: const Icon(Icons.code, size: 14),
          label: compact
              ? null
              : const Text('Brace', style: TextStyle(fontSize: 10)),
          tooltip: 'Brace Connector',
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
