// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import 'adaptive_dialog_helper.dart';

/// Opens the adaptive System Grouping & Connectors dialog.
Future<void> showSystemGroupingDialog(
  BuildContext context, {
  required DocumentCubit notifier,
}) {
  return showSarvAdaptiveModal<void>(
    context: context,
    builder: (ctx, isMobile) => SystemGroupingDialog(notifier: notifier),
  );
}

/// Adaptive modal dialog allowing users to visually inspect, sub-group,
/// assign connectors, and toggle continuous barlines across staves in the document.
class SystemGroupingDialog extends StatefulWidget {
  final DocumentCubit notifier;

  const SystemGroupingDialog({super.key, required this.notifier});

  @override
  State<SystemGroupingDialog> createState() => _SystemGroupingDialogState();
}

class _SystemGroupingDialogState extends State<SystemGroupingDialog> {
  late core.StaffNodeGroup _rootGroup;
  final Set<String> _selectedStaffUids = {};
  core.SystemConnector _newGroupConnector = core.SystemConnector.bracket;

  @override
  void initState() {
    super.initState();
    _rootGroup = widget.notifier.state.config.systemLayout.rootGroup;
  }

  void _applyChanges() {
    final updatedLayout = core.SystemLayout(rootGroup: _rootGroup);
    widget.notifier.execute(
      core.SetSystemLayoutCommand(updatedLayout, 'Update System Grouping'),
    );
    Navigator.of(context).pop();
  }

  void _updateGroup(
    core.StaffNodeGroup targetGroup, {
    core.SystemConnector? connector,
    bool? continuousBarlines,
  }) {
    setState(() {
      _rootGroup = _rootGroup.updateGroup(
        targetGroup,
        connector: connector,
        continuousBarlines: continuousBarlines,
      );
    });
  }

  void _ungroup(core.StaffNodeGroup targetGroup) {
    setState(() {
      _rootGroup = _rootGroup.ungroup(targetGroup);
      _selectedStaffUids.clear();
    });
  }

  void _groupSelected() {
    if (_selectedStaffUids.length < 2) return;
    setState(() {
      _rootGroup = _rootGroup.groupSelected(
        _selectedStaffUids,
        _newGroupConnector,
      );
      _selectedStaffUids.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.systemGroupingDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Toolbar for grouping multi-selection and connector choice
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<core.SystemConnector>(
                segments: [
                  ButtonSegment(
                    value: core.SystemConnector.bracket,
                    label: Text(l10n.connectorBracket, style: const TextStyle(fontSize: 10)),
                    icon: const Icon(Icons.reorder, size: 12),
                  ),
                  ButtonSegment(
                    value: core.SystemConnector.subBracket,
                    label: Text(l10n.connectorSubBracket, style: const TextStyle(fontSize: 10)),
                    icon: const Icon(Icons.line_weight, size: 12),
                  ),
                  ButtonSegment(
                    value: core.SystemConnector.brace,
                    label: Text(l10n.connectorBrace, style: const TextStyle(fontSize: 10)),
                    icon: const Icon(Icons.code, size: 12),
                  ),
                ],
                selected: {_newGroupConnector},
                onSelectionChanged: (set) => setState(() => _newGroupConnector = set.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    _selectedStaffUids.length >= 2 ? _groupSelected : null,
                icon: const Icon(Icons.account_tree_outlined, size: 16),
                label: Text(
                  l10n.groupStaves,
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (_selectedStaffUids.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedStaffUids.clear()),
                  child: Text(
                    'Clear (${_selectedStaffUids.length})',
                    style: TextStyle(fontSize: 12, color: cs.secondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Root Tree View
          _GroupNodeCard(
            group: _rootGroup,
            isRoot: true,
            selectedStaffUids: _selectedStaffUids,
            onStaffSelectionChanged: (uid, selected) {
              setState(() {
                if (selected) {
                  _selectedStaffUids.add(uid);
                } else {
                  _selectedStaffUids.remove(uid);
                }
              });
            },
            onUpdateGroup: _updateGroup,
            onUngroup: _ungroup,
          ),
        ],
      ),
    );

    final actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton.icon(
        onPressed: _applyChanges,
        icon: const Icon(Icons.check, size: 16),
        label: Text(MaterialLocalizations.of(context).saveButtonLabel),
      ),
    ];

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Icon(Icons.account_tree, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.systemGrouping,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(child: content),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ),
        ],
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.account_tree, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.systemGrouping,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: content),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupNodeCard extends StatelessWidget {
  final core.StaffNodeGroup group;
  final bool isRoot;
  final Set<String> selectedStaffUids;
  final void Function(String uid, bool selected) onStaffSelectionChanged;
  final void Function(
    core.StaffNodeGroup targetGroup, {
    core.SystemConnector? connector,
    bool? continuousBarlines,
  }) onUpdateGroup;
  final void Function(core.StaffNodeGroup targetGroup) onUngroup;

  const _GroupNodeCard({
    required this.group,
    this.isRoot = false,
    required this.selectedStaffUids,
    required this.onStaffSelectionChanged,
    required this.onUpdateGroup,
    required this.onUngroup,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRoot
            ? cs.surfaceContainerHigh.withValues(alpha: 0.5)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRoot
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.6),
          width: isRoot ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Group Connector & Barlines controls
          Row(
            children: [
              Icon(
                isRoot ? Icons.dashboard : Icons.folder_open,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isRoot ? 'Root System Group' : 'Sub-Group',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              if (!isRoot)
                IconButton(
                  icon: Icon(Icons.layers_clear_outlined,
                      size: 16, color: cs.error),
                  tooltip: l10n.ungroupStaves,
                  onPressed: () => onUngroup(group),
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Connector Picker Segmented Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 460;
              return Row(
                children: [
                  Text(
                    'Connector:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<core.SystemConnector>(
                      segments: [
                        ButtonSegment(
                          value: core.SystemConnector.none,
                          label: isCompact
                              ? null
                              : Text(l10n.connectorNone,
                                  style: const TextStyle(fontSize: 10)),
                          icon: const Icon(Icons.linear_scale, size: 12),
                          tooltip: l10n.connectorNoneTooltip,
                        ),
                        ButtonSegment(
                          value: core.SystemConnector.bracket,
                          label: isCompact
                              ? null
                              : Text(l10n.connectorBracket,
                                  style: const TextStyle(fontSize: 10)),
                          icon: const Icon(Icons.reorder, size: 12),
                          tooltip: l10n.connectorBracketTooltip,
                        ),
                        ButtonSegment(
                          value: core.SystemConnector.subBracket,
                          label: isCompact
                              ? null
                              : Text(l10n.connectorSubBracket,
                                  style: const TextStyle(fontSize: 10)),
                          icon: const Icon(Icons.line_weight, size: 12),
                          tooltip: l10n.connectorSubBracketTooltip,
                        ),
                        ButtonSegment(
                          value: core.SystemConnector.brace,
                          label: isCompact
                              ? null
                              : Text(l10n.connectorBrace,
                                  style: const TextStyle(fontSize: 10)),
                          icon: const Icon(Icons.code, size: 12),
                          tooltip: l10n.connectorBraceTooltip,
                        ),
                      ],
                      selected: {group.connector},
                      onSelectionChanged: (set) => onUpdateGroup(
                        group,
                        connector: set.first,
                      ),
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),

          // Barline continuity toggle
          Row(
            children: [
              Icon(Icons.line_style, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.continuousBarlines,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Switch(
                value: group.continuousBarlines,
                onChanged: (val) => onUpdateGroup(
                  group,
                  continuousBarlines: val,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Children List
          ...group.children.map((child) {
            return switch (child) {
              core.StaffDefinition def => Material(
                  color: Colors.transparent,
                  child: CheckboxListTile(
                    dense: true,
                    value: selectedStaffUids.contains(def.uid),
                    onChanged: (val) =>
                        onStaffSelectionChanged(def.uid, val ?? false),
                    title: Text(
                      def.instrumentName ?? 'Staff (${def.lines} lines)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      def.clef?.symbol.name ?? 'Standard Clef',
                      style: theme.textTheme.bodySmall,
                    ),
                    secondary: const Icon(Icons.music_note, size: 16),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              core.StaffNodeGroup subGroup => Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _GroupNodeCard(
                    group: subGroup,
                    isRoot: false,
                    selectedStaffUids: selectedStaffUids,
                    onStaffSelectionChanged: onStaffSelectionChanged,
                    onUpdateGroup: onUpdateGroup,
                    onUngroup: onUngroup,
                  ),
                ),
            };
          }),
        ],
      ),
    );
  }
}
