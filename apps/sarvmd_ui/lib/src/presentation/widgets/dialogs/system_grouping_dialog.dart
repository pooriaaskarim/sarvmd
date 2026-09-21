// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:math' as math;
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

  void _addStaffToGroup(core.StaffNodeGroup targetGroup) {
    setState(() {
      final newStaff = core.StaffDefinition(
        uid: '${DateTime.now().microsecondsSinceEpoch}',
        lines: 5,
        instrumentName: 'New Staff',
        clef: core.Clef.treble,
      );
      _rootGroup = _addStaffToGroupInTree(_rootGroup, targetGroup, newStaff);
    });
  }

  void _removeStaffFromTree(String uid) {
    setState(() {
      _rootGroup = _removeStaffByUidFromTree(_rootGroup, uid);
      _selectedStaffUids.remove(uid);
    });
  }

  void _updateStaffInTree(
      String uid, core.StaffDefinition Function(core.StaffDefinition) updater) {
    setState(() {
      _rootGroup = _updateStaffByUidInTree(_rootGroup, uid, updater);
    });
  }

  static core.StaffNodeGroup _addStaffToGroupInTree(
      core.StaffNodeGroup parent,
      core.StaffNodeGroup targetGroup,
      core.StaffDefinition newStaff) {
    if (identical(parent, targetGroup)) {
      return parent.copyWith(children: [...parent.children, newStaff]);
    }
    return parent.copyWith(
      children: parent.children.map((child) {
        if (child is core.StaffNodeGroup) {
          return _addStaffToGroupInTree(child, targetGroup, newStaff);
        }
        return child;
      }).toList(),
    );
  }

  static core.StaffNodeGroup _removeStaffByUidFromTree(
      core.StaffNodeGroup parent, String uid) {
    final newChildren = <core.StaffNode>[];
    for (final child in parent.children) {
      if (child is core.StaffDefinition) {
        if (child.uid != uid) newChildren.add(child);
      } else if (child is core.StaffNodeGroup) {
        newChildren.add(_removeStaffByUidFromTree(child, uid));
      }
    }
    return parent.copyWith(children: newChildren);
  }

  static core.StaffNodeGroup _updateStaffByUidInTree(
      core.StaffNodeGroup parent,
      String uid,
      core.StaffDefinition Function(core.StaffDefinition) updater) {
    return parent.copyWith(
      children: parent.children.map((child) {
        if (child is core.StaffDefinition) {
          return child.uid == uid ? updater(child) : child;
        } else if (child is core.StaffNodeGroup) {
          return _updateStaffByUidInTree(child, uid, updater);
        }
        return child;
      }).toList(),
    );
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
                    label: Text(l10n.connectorBracket,
                        style: const TextStyle(fontSize: 10)),
                    icon: const Icon(Icons.reorder, size: 12),
                  ),
                  ButtonSegment(
                    value: core.SystemConnector.subBracket,
                    label: Text(l10n.connectorSubBracket,
                        style: const TextStyle(fontSize: 10)),
                    icon: const Icon(Icons.line_weight, size: 12),
                  ),
                  ButtonSegment(
                    value: core.SystemConnector.brace,
                    label: Text(l10n.connectorBrace,
                        style: const TextStyle(fontSize: 10)),
                    icon: const Icon(Icons.code, size: 12),
                  ),
                ],
                selected: {_newGroupConnector},
                onSelectionChanged: (set) =>
                    setState(() => _newGroupConnector = set.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
              Builder(
                builder: (context) {
                  final firstStaffParentDepth = _selectedStaffUids.isNotEmpty
                      ? _rootGroup.findStaffParentDepth(_selectedStaffUids.first)
                      : null;
                  final targetDepth =
                      firstStaffParentDepth != null ? firstStaffParentDepth + 1 : 0;
                  final exceedsLimit = targetDepth >
                      core.GroupPlacementMetrics.emergencyMaxNestingDepth;
                  final isLevel3 = targetDepth ==
                      core.GroupPlacementMetrics.emergencyMaxNestingDepth;

                  final tooltipMessage = exceedsLimit
                      ? 'Cannot group: Exceeds Gould & MOLA nesting ceiling (3 levels max)'
                      : (isLevel3
                          ? 'Group Staves (Level 3 - standard recommends max 2)'
                          : l10n.groupStaves);

                  return Tooltip(
                    message: tooltipMessage,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedStaffUids.length >= 2 && !exceedsLimit)
                          ? _groupSelected
                          : null,
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
                  );
                },
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
            onAddStaffToGroup: _addStaffToGroup,
            onRemoveStaff: _removeStaffFromTree,
            onUpdateStaff: _updateStaffInTree,
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

    final previewWidget = Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live System Preview',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRect(
              child: CustomPaint(
                size: Size.infinite,
                painter: _MiniSystemPreviewPainter(
                  config: widget.notifier.state.config.copyWith(
                    systemLayout: core.SystemLayout(rootGroup: _rootGroup),
                  ),
                  csSurface: cs.surface,
                  csOnSurface: cs.onSurface,
                  csPrimary: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

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
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 760),
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
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 3, child: content),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 2, child: previewWidget),
                ],
              ),
            ),
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
  final void Function(core.StaffNodeGroup targetGroup) onAddStaffToGroup;
  final void Function(String uid) onRemoveStaff;
  final void Function(
          String uid, core.StaffDefinition Function(core.StaffDefinition) updater)
      onUpdateStaff;

  const _GroupNodeCard({
    required this.group,
    this.isRoot = false,
    required this.selectedStaffUids,
    required this.onStaffSelectionChanged,
    required this.onUpdateGroup,
    required this.onUngroup,
    required this.onAddStaffToGroup,
    required this.onRemoveStaff,
    required this.onUpdateStaff,
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
              IconButton(
                icon: Icon(Icons.add_circle_outline,
                    size: 16, color: cs.primary),
                tooltip: l10n.addStaff,
                onPressed: () => onAddStaffToGroup(group),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
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
              final isVeryCompact = constraints.maxWidth < 320;
              final isCompact = constraints.maxWidth < 460;

              final segmentedBtn = FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
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
              );

              if (isVeryCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connector:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    segmentedBtn,
                  ],
                );
              }

              return Row(
                children: [
                  Text(
                    'Connector:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: segmentedBtn),
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
              core.StaffDefinition def => _DialogStaffRow(
                  key: ValueKey('dialog_staff_${def.uid}'),
                  staff: def,
                  isSelected: selectedStaffUids.contains(def.uid),
                  onSelectionChanged: (val) =>
                      onStaffSelectionChanged(def.uid, val),
                  onRemove: () => onRemoveStaff(def.uid),
                  onUpdate: (updater) => onUpdateStaff(def.uid, updater),
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
                    onAddStaffToGroup: onAddStaffToGroup,
                    onRemoveStaff: onRemoveStaff,
                    onUpdateStaff: onUpdateStaff,
                  ),
                ),
            };
          }),
        ],
      ),
    );
  }
}

class _DialogStaffRow extends StatefulWidget {
  final core.StaffDefinition staff;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final VoidCallback onRemove;
  final void Function(core.StaffDefinition Function(core.StaffDefinition) updater)
      onUpdate;

  const _DialogStaffRow({
    super.key,
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<_DialogStaffRow> createState() => _DialogStaffRowState();
}

class _DialogStaffRowState extends State<_DialogStaffRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final staff = widget.staff;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: widget.isSelected,
                onChanged: (val) => widget.onSelectionChanged(val ?? false),
                visualDensity: VisualDensity.compact,
              ),
              const Icon(Icons.music_note, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.instrumentName ?? l10n.staffNumber(1),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${staff.lines} lines • ${staff.clef?.symbol.name ?? l10n.noClef}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.tune_outlined,
                  size: 16,
                  color: cs.primary,
                ),
                tooltip: l10n.configureStaff,
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    size: 16, color: cs.error),
                tooltip: l10n.removeStaff,
                onPressed: widget.onRemove,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (_isExpanded)
            _StaffInlineConfigCard(
              staff: staff,
              onUpdate: widget.onUpdate,
            ),
        ],
      ),
    );
  }
}

class _StaffInlineConfigCard extends StatelessWidget {
  final core.StaffDefinition staff;
  final void Function(core.StaffDefinition Function(core.StaffDefinition) updater)
      onUpdate;

  const _StaffInlineConfigCard({
    required this.staff,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: TextEditingController(text: staff.instrumentName)
              ..selection = TextSelection.collapsed(
                  offset: staff.instrumentName?.length ?? 0),
            decoration: const InputDecoration(
              labelText: 'Instrument Name',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => onUpdate(
                (s) => s.copyWith(instrumentName: () => val.isEmpty ? null : val)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Clef:',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<core.ClefSymbol?>(
                  segments: [
                    const ButtonSegment(value: null, label: Text('None', style: TextStyle(fontSize: 9))),
                    ButtonSegment(value: core.ClefSymbol.g, label: Text(l10n.trebleClef, style: const TextStyle(fontSize: 9))),
                    ButtonSegment(value: core.ClefSymbol.c, label: Text(l10n.altoClef, style: const TextStyle(fontSize: 9))),
                    ButtonSegment(value: core.ClefSymbol.f, label: Text(l10n.bassClef, style: const TextStyle(fontSize: 9))),
                  ],
                  selected: {staff.clef?.symbol},
                  onSelectionChanged: (set) {
                    final sym = set.first;
                    final newClef = sym == null
                        ? null
                        : switch (sym) {
                            core.ClefSymbol.g => core.Clef.treble,
                            core.ClefSymbol.c => core.Clef.alto,
                            core.ClefSymbol.f => core.Clef.bass,
                            _ => null,
                          };
                    onUpdate((s) => s.copyWith(clef: () => newClef));
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSystemPreviewPainter extends CustomPainter {
  final core.PageConfig config;
  final Color csSurface;
  final Color csOnSurface;
  final Color csPrimary;

  _MiniSystemPreviewPainter({
    required this.config,
    required this.csSurface,
    required this.csOnSurface,
    required this.csPrimary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final layout = core.computeLayout(config);
    final pageW = config.effectiveWidth;
    final pageH = config.effectiveHeight;

    const double padding = 16.0;
    final availW = math.max(10.0, size.width - padding * 2);
    final availH = math.max(10.0, size.height - padding * 2);

    final scale = math.min(availW / pageW, availH / pageH);

    final drawnW = pageW * scale;
    final drawnH = pageH * scale;
    final originX = (size.width - drawnW) / 2;
    final originY = (size.height - drawnH) / 2;

    // Paper card background
    final paperRect = Rect.fromLTWH(originX, originY, drawnW, drawnH);
    final paperPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(paperRect, paperPaint);

    final borderPaint = Paint()
      ..color = csOnSurface.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(paperRect, borderPaint);

    canvas.save();
    canvas.translate(originX, originY);
    canvas.scale(scale);

    final inkPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.staffConfig.lineThicknessPt * (25.4 / 72);

    final lineGapMm = config.staffConfig.lineGapMm;
    final systemLeftMm = config.margins.left;
    final systemRightMm = config.effectiveWidth - config.margins.right;

    for (final system in layout.systems) {
      final leftX = systemLeftMm + system.leftIndentMm;

      // Draw staves
      for (final staff in system.staves) {
        final def = staff.definition;
        final lines = staff.lines;
        for (int i = 0; i < lines; i++) {
          final y = staff.topY + i * lineGapMm * staff.scale;
          canvas.drawLine(
            Offset(leftX, y),
            Offset(systemRightMm, y),
            inkPaint,
          );
        }

        // Draw Instrument Label if present
        final name = def?.instrumentName;
        if (name != null && name.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: name,
              style: TextStyle(
                color: Colors.black,
                fontSize: math.max(3.0, lineGapMm * 1.2),
                fontFamily: 'sans-serif',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(
              leftX - textPainter.width - 2.0,
              staff.topY + (staff.height - textPainter.height) / 2,
            ),
          );
        }
      }

      // Draw Barlines & Group Placements
      final barlinePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      if (system.staves.isNotEmpty) {
        // System initial barline
        canvas.drawLine(
          Offset(leftX, system.topY),
          Offset(leftX, system.bottomY()),
          barlinePaint,
        );
      }

      // Draw Group Placements (Connectors & Continuous Barlines)
      for (final gp in system.groupPlacements) {
        if (gp.startStaffIdx >= system.staves.length ||
            gp.endStaffIdx >= system.staves.length) {
          continue;
        }

        final topStaff = system.staves[gp.startStaffIdx];
        final bottomStaff = system.staves[gp.endStaffIdx];
        final groupTopY = topStaff.topY;
        final groupBottomY = bottomStaff.topY + bottomStaff.height;

        if (gp.continuousBarlines) {
          canvas.drawLine(
            Offset(leftX, groupTopY),
            Offset(leftX, groupBottomY),
            barlinePaint,
          );
        }

        final connectorX = leftX - (gp.level + 1) * 3.0;
        final connPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

        switch (gp.connector) {
          case core.SystemConnector.bracket:
            canvas.drawLine(
                Offset(connectorX, groupTopY), Offset(connectorX, groupBottomY), connPaint..strokeWidth = 1.2);
            canvas.drawLine(
                Offset(connectorX, groupTopY), Offset(connectorX + 2.5, groupTopY), connPaint);
            canvas.drawLine(
                Offset(connectorX, groupBottomY), Offset(connectorX + 2.5, groupBottomY), connPaint);
            break;
          case core.SystemConnector.subBracket:
            canvas.drawLine(
                Offset(connectorX, groupTopY), Offset(connectorX, groupBottomY), connPaint..strokeWidth = 0.8);
            canvas.drawLine(
                Offset(connectorX, groupTopY), Offset(connectorX + 1.8, groupTopY), connPaint);
            canvas.drawLine(
                Offset(connectorX, groupBottomY), Offset(connectorX + 1.8, groupBottomY), connPaint);
            break;
          case core.SystemConnector.brace:
            final midY = (groupTopY + groupBottomY) / 2;
            final path = Path()
              ..moveTo(connectorX + 1.5, groupTopY)
              ..quadraticBezierTo(connectorX - 1.5, groupTopY, connectorX - 1.5, (groupTopY + midY) / 2)
              ..quadraticBezierTo(connectorX - 1.5, midY, connectorX - 3.0, midY)
              ..quadraticBezierTo(connectorX - 1.5, midY, connectorX - 1.5, (midY + groupBottomY) / 2)
              ..quadraticBezierTo(connectorX - 1.5, groupBottomY, connectorX + 1.5, groupBottomY);
            canvas.drawPath(path, connPaint..strokeWidth = 0.8);
            break;
          case core.SystemConnector.none:
            break;
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniSystemPreviewPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.csSurface != csSurface ||
        oldDelegate.csOnSurface != csOnSurface ||
        oldDelegate.csPrimary != csPrimary;
  }
}

