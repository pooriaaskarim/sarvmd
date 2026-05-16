import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../config_notifier.dart';
import 'specialized/clef_config_widget.dart';

class SystemHierarchyPanel extends StatelessWidget {
  const SystemHierarchyPanel({super.key, required this.notifier});

  final ConfigNotifier notifier;

  @override
  Widget build(BuildContext context) {
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
              label: const Text('Add Staff', style: TextStyle(fontSize: 12)),
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

class _StaffPropertyRow extends StatelessWidget {
  const _StaffPropertyRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        child,
      ],
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
    required this.notifier,
  });

  final core.StaffGroup group;
  final bool isRoot;
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
              ...group.children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                if (child is core.StaffDefinition) {
                  return _StaffItem(
                    key: ValueKey('staff_${group.hashCode}_$index'),
                    index: index,
                    staff: child,
                    notifier: notifier,
                  );
                } else if (child is core.StaffGroup) {
                  return _StaffGroupWidget(
                    key: ValueKey('group_${child.hashCode}_$index'),
                    group: child,
                    notifier: notifier,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          );
        },
      ),
    );
  }
}

class _StaffItem extends StatefulWidget {
  const _StaffItem({
    super.key,
    required this.index,
    required this.staff,
    required this.notifier,
  });

  final int index;
  final core.StaffDefinition staff;
  final ConfigNotifier notifier;

  @override
  State<_StaffItem> createState() => _StaffItemState();
}

class _StaffItemState extends State<_StaffItem> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.staff.instrumentName);
  }

  @override
  void didUpdateWidget(_StaffItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller if the text actually changed and the user is
    // NOT currently typing in this field. This prevents focus loss and cursor
    // jumping during reactive updates.
    if (!_focusNode.hasFocus &&
        widget.staff.instrumentName != _controller.text) {
      _controller.text = widget.staff.instrumentName ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (v) => widget.notifier.updateStaffInstrumentName(
                      widget.index, v.isEmpty ? null : v),
                  decoration: InputDecoration(
                    hintText: 'Instrument (e.g. Violin I)',
                    hintStyle: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => widget.notifier.removeStaff(widget.index),
                icon: const Icon(Icons.remove_circle_outline, size: 16),
                color: cs.error.withValues(alpha: 0.7),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          _StaffPropertyRow(
            label: 'Lines',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: widget.staff.lines.toDouble(),
                    min: 0,
                    max: 12,
                    divisions: 12,
                    onChanged: (v) =>
                        widget.notifier.updateStaffLines(widget.index, v.toInt()),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${widget.staff.lines}',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClefConfigWidget(
            label: 'Clef',
            value: widget.staff.clef,
            onChanged: (c) => widget.notifier.updateStaffClef(widget.index, c),
            staffLines: widget.staff.lines,
          ),
        ],
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
