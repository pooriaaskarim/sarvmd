import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../core/utils/unit_formatter.dart';
import '../../../logic/config/config_cubit.dart';
import '../dialogs/staff_config_dialog.dart';
import '../../../l10n/app_localizations.dart';

class SystemHierarchyPanel extends StatelessWidget {
  const SystemHierarchyPanel({super.key, required this.notifier});

  final ConfigCubit notifier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigCubit, core.PageConfig>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final layout = state.systemLayout;

        return Column(
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
                TextButton.icon(
                  onPressed: () => notifier.addStaff(),
                  icon: const Icon(Icons.add_circle_outline, size: 14),
                  label:
                      Text(AppLocalizations.of(context)!.addStaff, style: const TextStyle(fontSize: 12)),
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
            _buildMolaSummary(context, state),
          ],
        );
      },
    );
  }

  Widget _buildMolaSummary(BuildContext context, core.PageConfig state) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final staffCount = state.staffCount;
    final totalHeight = state.systemHeight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ensembleSummary,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
              label: l10n.totalStaves,
              value: '$staffCount'),
          _SummaryRow(
              label: l10n.systemHeight,
              value: UnitFormatter.formatMm(totalHeight)),
          _SummaryRow(
            label: l10n.density,
            value: l10n.systemsCount(notifier.layout.systemCount),
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
          Text(
            value,
            style:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
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
  final ConfigCubit notifier;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
                          padding: const EdgeInsetsDirectional.only(end: 8.0),
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
                  const SizedBox(width: 8),
                  _ConnectorPicker(
                    value: group.connector,
                    onChanged: (v) => notifier.updateGroupConnector(v),
                    compact: isCompact,
                  ),
                ],
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
                              onChanged: (v) =>
                                  notifier.updateGroupContinuousBarlines(v),
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
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: group.children.length,
                onReorderItem: (oldIndex, newIndex) {
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
  final ConfigCubit notifier;

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
    final l10n = AppLocalizations.of(context)!;

    // Build standard instrument label
    final String displayName =
        staff.instrumentName ?? l10n.staffNumber(index + 1);
    final String abbrevInfo = staff.instrumentAbbreviation != null &&
            staff.instrumentAbbreviation!.isNotEmpty
        ? ' (${staff.instrumentAbbreviation})'
        : '';
    final String labelText = '$displayName$abbrevInfo';

    // Clef description
    String clefLabel = l10n.noClef;
    if (staff.clef != null) {
      final name = switch (staff.clef!.symbol) {
        core.ClefSymbol.g => l10n.trebleClef,
        core.ClefSymbol.c => l10n.altoClef,
        core.ClefSymbol.f => l10n.bassClef,
        core.ClefSymbol.tab => l10n.categoryTablature,
        core.ClefSymbol.percussion => l10n.categoryPercussion,
      };
      clefLabel = l10n.clefWithLine(name, staff.clef!.anchorLine);
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
                    Tooltip(
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
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildBadge(context, l10n.linesCount(staff.lines)),
                        _buildBadge(context, clefLabel),
                        if (!staff.labelVisible)
                          _buildBadge(context, l10n.hidden, color: cs.error),
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
            tooltip: l10n.configureStaff,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            onPressed: () => notifier.removeStaff(index),
            icon: Icon(Icons.remove_circle_outline,
                size: 16, color: cs.error.withValues(alpha: 0.7)),
            tooltip: l10n.removeStaff,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: const EdgeInsets.all(4),
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
