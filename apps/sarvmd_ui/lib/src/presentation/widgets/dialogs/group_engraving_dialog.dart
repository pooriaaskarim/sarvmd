// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../logic/document/document_cubit.dart';
import 'adaptive_dialog_helper.dart';

/// Opens the adaptive Group Engraving Options dialog.
Future<void> showGroupEngravingDialog(
  BuildContext context, {
  required core.StaffNodeGroup group,
  required DocumentCubit notifier,
  VoidCallback? onAutoNumberChildStaves,
}) {
  return showSarvAdaptiveModal<void>(
    context: context,
    maxWidth: 560.0,
    builder: (ctx, isMobile) => GroupEngravingDialog(
      group: group,
      notifier: notifier,
      onAutoNumberChildStaves: onAutoNumberChildStaves,
    ),
  );
}

/// Adaptive modal dialog for deep engraving and layout properties of a [StaffNodeGroup].
class GroupEngravingDialog extends StatefulWidget {
  const GroupEngravingDialog({
    super.key,
    required this.group,
    required this.notifier,
    this.onAutoNumberChildStaves,
  });

  final core.StaffNodeGroup group;
  final DocumentCubit notifier;
  final VoidCallback? onAutoNumberChildStaves;

  @override
  State<GroupEngravingDialog> createState() => _GroupEngravingDialogState();
}

class _GroupEngravingDialogState extends State<GroupEngravingDialog> {
  late core.GroupLabelPlacement _labelPlacement;
  late core.GroupNumberingStyle _numberingStyle;
  late core.DescriptorPlacement _descriptorPlacement;
  late core.GroupHeaderVisibility _headerVisibility;
  late TextEditingController _nameController;
  late TextEditingController _abbrevController;
  bool _hasAutoNumbered = false;
  bool _applyToAllGroups = false;

  @override
  void initState() {
    super.initState();
    _labelPlacement = widget.group.labelPlacement;
    _numberingStyle = widget.group.numberingStyle;
    _descriptorPlacement = widget.group.descriptorPlacement;
    _headerVisibility = widget.group.headerVisibility;
    _nameController = TextEditingController(text: widget.group.label);
    _abbrevController = TextEditingController(text: widget.group.abbreviation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbrevController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final abbrev = _abbrevController.text.trim();

    widget.notifier.updateGroupDetails(
      groupHash: widget.group.hashCode,
      label: name.isEmpty ? null : name,
      abbreviation: abbrev.isEmpty ? null : abbrev,
      labelPlacement: _labelPlacement,
      numberingStyle: _numberingStyle,
      descriptorPlacement: _descriptorPlacement,
      headerVisibility: _headerVisibility,
    );

    if (_applyToAllGroups) {
      widget.notifier.batchUpdateGroupDetails(
        labelPlacement: _labelPlacement,
        descriptorPlacement: _descriptorPlacement,
        headerVisibility: _headerVisibility,
        numberingStyle: _numberingStyle == core.GroupNumberingStyle.none
            ? null
            : _numberingStyle,
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final childStaves = widget.group.children
        .whereType<core.StaffDefinition>()
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Engraving Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        widget.group.label.isEmpty
                            ? 'Instrument Group'
                            : widget.group.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Section 1: Label Placement & Model C
            Text(
              'LABEL PLACEMENT & LIFECYCLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Placement selector
            SegmentedButton<core.GroupLabelPlacement>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: core.GroupLabelPlacement.margin,
                  icon: Icon(Icons.align_horizontal_left_rounded, size: 16),
                  label: Text('Margin (Left)'),
                  tooltip: 'Standard margin label centered vertically outside brackets.',
                ),
                ButtonSegment(
                  value: core.GroupLabelPlacement.aboveStaff,
                  icon: Icon(Icons.vertical_align_top_rounded, size: 16),
                  label: Text('Above Staff (Model C)'),
                  tooltip: 'Section header rendered above the topmost staff, eliminating left margin waste.',
                ),
              ],
              selected: {_labelPlacement},
              onSelectionChanged: (set) =>
                  setState(() => _labelPlacement = set.first),
            ),
            const SizedBox(height: 8),

            // Header visibility (when above staff)
            if (_labelPlacement == core.GroupLabelPlacement.aboveStaff) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 15, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Header Visibility Across Systems',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<core.GroupHeaderVisibility>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: core.GroupHeaderVisibility.firstSystemOnly,
                          label: Text('1st System'),
                          tooltip: 'Print section header only on the first system of the score (Gould & MOLA default).',
                        ),
                        ButtonSegment(
                          value: core.GroupHeaderVisibility.firstSystemOfPage,
                          label: Text('Top of Page'),
                          tooltip: 'Print section header on the first system of each page (Bärenreiter house style).',
                        ),
                        ButtonSegment(
                          value: core.GroupHeaderVisibility.always,
                          label: Text('All Systems'),
                          tooltip: 'Print section header above staves on every system.',
                        ),
                      ],
                      selected: {_headerVisibility},
                      onSelectionChanged: (set) =>
                          setState(() => _headerVisibility = set.first),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _headerVisibility.description,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 8),
            ],

            // Descriptor Placement (Continental vs Anglo-American)
            Text(
              'CONNECTOR & DESCRIPTOR PLACEMENT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<core.DescriptorPlacement>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: core.DescriptorPlacement.enclosedByConnector,
                  icon: Icon(Icons.view_sidebar_rounded, size: 16),
                  label: Text('Enclosed (Anglo-American)'),
                  tooltip: 'Connector displaced outward; descriptors sit between connector and barline (Gould / Boosey & Hawkes).',
                ),
                ButtonSegment(
                  value: core.DescriptorPlacement.outsideConnector,
                  icon: Icon(Icons.euro_rounded, size: 16),
                  label: Text('Outside (Continental)'),
                  tooltip: 'Connector flush at barline; descriptors sit in the outer column (Bärenreiter / Breitkopf / Henle).',
                ),
              ],
              selected: {_descriptorPlacement},
              onSelectionChanged: (set) =>
                  setState(() => _descriptorPlacement = set.first),
            ),
            const SizedBox(height: 6),
            Text(
              _descriptorPlacement == core.DescriptorPlacement.outsideConnector
                  ? 'Continental European: Bracket flush at barline; voice descriptors placed to the left in outer column.'
                  : 'Anglo-American: Bracket displaced outward enclosing voice descriptors inside.',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Child Staff Numbering (Model B) & Gould Non-redundancy
            Text(
              'CHILD STAFF NUMBERING (MODEL B)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<core.GroupNumberingStyle>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: core.GroupNumberingStyle.none,
                  label: Text('None'),
                  tooltip: 'Use original instrument names without automatic numeral substitution.',
                ),
                ButtonSegment(
                  value: core.GroupNumberingStyle.arabic,
                  label: Text('Arabic (1, 2)'),
                  tooltip: 'Auto-numbers generic child staves with compact numerals (1, 2, 3), pulling brackets flush.',
                ),
                ButtonSegment(
                  value: core.GroupNumberingStyle.roman,
                  label: Text('Roman (I, II)'),
                  tooltip: 'Auto-numbers generic child staves with compact Roman numerals (I, II, III).',
                ),
              ],
              selected: {_numberingStyle},
              onSelectionChanged: (set) =>
                  setState(() => _numberingStyle = set.first),
            ),
            const SizedBox(height: 8),

            // Gould Non-redundancy auto-numbering action
            if (childStaves.length >= 2) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  widget.onAutoNumberChildStaves?.call();
                  setState(() => _hasAutoNumbered = true);
                },
                icon: Icon(
                  _hasAutoNumbered
                      ? Icons.check_circle_outline
                      : Icons.auto_awesome,
                  size: 16,
                  color: _hasAutoNumbered ? cs.primary : cs.secondary,
                ),
                label: Text(
                  _hasAutoNumbered
                      ? 'Gould non-redundancy applied (Staves 1..${childStaves.length})'
                      : 'Apply Gould non-redundancy: Renumber staves (1, 2...)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hasAutoNumbered ? cs.primary : cs.onSurface,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(
                    color: _hasAutoNumbered
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Propagate to all groups toggle
            InkWell(
              onTap: () => setState(() => _applyToAllGroups = !_applyToAllGroups),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _applyToAllGroups,
                        onChanged: (val) =>
                            setState(() => _applyToAllGroups = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply layout style to all groups in score',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            'Propagates placement and connector descriptor rules across all sections.',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Apply Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the adaptive Batch Group Engraving Options dialog.
Future<void> showBatchGroupEngravingDialog(
  BuildContext context, {
  required DocumentCubit notifier,
  Set<int>? targetGroupHashes,
}) {
  return showSarvAdaptiveModal<void>(
    context: context,
    maxWidth: 580.0,
    builder: (ctx, isMobile) => BatchGroupEngravingDialog(
      notifier: notifier,
      targetGroupHashes: targetGroupHashes,
    ),
  );
}

/// Adaptive modal dialog for batch-configuring group engraving properties across the score.
class BatchGroupEngravingDialog extends StatefulWidget {
  const BatchGroupEngravingDialog({
    super.key,
    required this.notifier,
    this.targetGroupHashes,
  });

  final DocumentCubit notifier;
  final Set<int>? targetGroupHashes;

  @override
  State<BatchGroupEngravingDialog> createState() =>
      _BatchGroupEngravingDialogState();
}

class _BatchGroupEngravingDialogState extends State<BatchGroupEngravingDialog> {
  late core.GroupLabelPlacement _labelPlacement;
  late core.DescriptorPlacement _descriptorPlacement;
  late core.GroupHeaderVisibility _headerVisibility;
  late core.GroupNumberingStyle _numberingStyle;
  bool? _labelVisible; // null = keep existing, true = show all, false = hide all
  bool _preserveBraces = true;

  @override
  void initState() {
    super.initState();
    final allGroups = widget
        .notifier.state.config.systemLayout.rootGroup.allGroups
        .where((g) => g.label.isNotEmpty)
        .toList();

    if (allGroups.isNotEmpty) {
      _labelPlacement = allGroups.first.labelPlacement;
      _descriptorPlacement = allGroups.first.descriptorPlacement;
      _headerVisibility = allGroups.first.headerVisibility;
      _numberingStyle = allGroups.first.numberingStyle;
    } else {
      _labelPlacement = core.GroupLabelPlacement.margin;
      _descriptorPlacement = core.DescriptorPlacement.enclosedByConnector;
      _headerVisibility = core.GroupHeaderVisibility.firstSystemOnly;
      _numberingStyle = core.GroupNumberingStyle.none;
    }
  }

  void _applyHouseStyle(core.EngravingHouseStyle style) {
    setState(() {
      switch (style) {
        case core.EngravingHouseStyle.modernHeader:
          _labelPlacement = core.GroupLabelPlacement.aboveStaff;
          _headerVisibility = core.GroupHeaderVisibility.firstSystemOnly;
          break;
        case core.EngravingHouseStyle.continental:
          _labelPlacement = core.GroupLabelPlacement.margin;
          _descriptorPlacement = core.DescriptorPlacement.outsideConnector;
          break;
        case core.EngravingHouseStyle.classicalGould:
        case core.EngravingHouseStyle.custom:
          _labelPlacement = core.GroupLabelPlacement.margin;
          _descriptorPlacement = core.DescriptorPlacement.enclosedByConnector;
          break;
      }
    });
  }

  void _save() {
    widget.notifier.batchUpdateGroupDetails(
      targetGroupHashes: widget.targetGroupHashes,
      labelPlacement: _labelPlacement,
      descriptorPlacement: _descriptorPlacement,
      headerVisibility: _headerVisibility,
      numberingStyle: _numberingStyle == core.GroupNumberingStyle.none
          ? null
          : _numberingStyle,
      labelVisible: _labelVisible,
      preserveBraceOutsideConstraint: _preserveBraces,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allScoreGroups = widget
        .notifier.state.config.systemLayout.rootGroup.allGroups
        .where((g) => g.label.isNotEmpty)
        .toList();

    final isTargeted = widget.targetGroupHashes != null &&
        widget.targetGroupHashes!.isNotEmpty;
    final targetCount =
        isTargeted ? widget.targetGroupHashes!.length : allScoreGroups.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.style_outlined, size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Group Engraving Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        isTargeted
                            ? 'Configuring $targetCount selected groups'
                            : 'Configuring all $targetCount groups in score',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // 1-Click House Style Presets
            Text(
              '1-Click House Style Presets',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.menu_book, size: 14),
                  label: const Text('Classical Gould (Margin)',
                      style: TextStyle(fontSize: 11.5)),
                  onPressed: () =>
                      _applyHouseStyle(core.EngravingHouseStyle.classicalGould),
                ),
                ActionChip(
                  avatar: const Icon(Icons.vertical_align_top, size: 14),
                  label: const Text('Modern Header (Above Staff)',
                      style: TextStyle(fontSize: 11.5)),
                  onPressed: () =>
                      _applyHouseStyle(core.EngravingHouseStyle.modernHeader),
                ),
                ActionChip(
                  avatar: const Icon(Icons.format_indent_decrease, size: 14),
                  label: const Text('Continental (Outside)',
                      style: TextStyle(fontSize: 11.5)),
                  onPressed: () =>
                      _applyHouseStyle(core.EngravingHouseStyle.continental),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Group Label Placement Section
            Text(
              'Group Label Placement',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Controls where instrument section names appear across the systems.',
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SegmentedButton<core.GroupLabelPlacement>(
              segments: const [
                ButtonSegment(
                  value: core.GroupLabelPlacement.margin,
                  label: Text('Margin (Left)'),
                  icon: Icon(Icons.format_align_left, size: 16),
                ),
                ButtonSegment(
                  value: core.GroupLabelPlacement.aboveStaff,
                  label: Text('Above Staff (Header)'),
                  icon: Icon(Icons.vertical_align_top, size: 16),
                ),
              ],
              selected: {_labelPlacement},
              onSelectionChanged: (set) =>
                  setState(() => _labelPlacement = set.first),
            ),
            const SizedBox(height: 14),

            // Header Visibility Lifecycle (if aboveStaff)
            if (_labelPlacement == core.GroupLabelPlacement.aboveStaff) ...[
              Text(
                'Section Header Lifecycle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<core.GroupHeaderVisibility>(
                segments: const [
                  ButtonSegment(
                    value: core.GroupHeaderVisibility.firstSystemOnly,
                    label: Text('First System'),
                    tooltip: 'Gould/MOLA standard: First system of score only.',
                  ),
                  ButtonSegment(
                    value: core.GroupHeaderVisibility.firstSystemOfPage,
                    label: Text('Top of Page'),
                    tooltip: 'Bärenreiter style: Top system of each page.',
                  ),
                  ButtonSegment(
                    value: core.GroupHeaderVisibility.always,
                    label: Text('Every System'),
                  ),
                ],
                selected: {_headerVisibility},
                onSelectionChanged: (set) =>
                    setState(() => _headerVisibility = set.first),
              ),
              const SizedBox(height: 14),
            ],

            // Connector & Descriptors
            Text(
              'Connector & Inner Descriptors',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Spatial positioning of numbers/names relative to brackets.',
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SegmentedButton<core.DescriptorPlacement>(
              segments: const [
                ButtonSegment(
                  value: core.DescriptorPlacement.enclosedByConnector,
                  label: Text('Enclosed (Anglo-American)'),
                  tooltip: 'Bracket displaced outward; descriptors between bracket and barline.',
                ),
                ButtonSegment(
                  value: core.DescriptorPlacement.outsideConnector,
                  label: Text('Outside (Continental)'),
                  tooltip: 'Bracket flush at barline; descriptors outside.',
                ),
              ],
              selected: {_descriptorPlacement},
              onSelectionChanged: (set) =>
                  setState(() => _descriptorPlacement = set.first),
            ),
            const SizedBox(height: 8),

            // Gould universal brace rule note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Universal Rule: Curly braces "{" always maintain descriptors outside connector per Gould engraving standards.',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Numbering Pattern
            Text(
              'Child Staff Numbering',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<core.GroupNumberingStyle>(
              segments: const [
                ButtonSegment(
                  value: core.GroupNumberingStyle.none,
                  label: Text('Keep Names'),
                ),
                ButtonSegment(
                  value: core.GroupNumberingStyle.arabic,
                  label: Text('Arabic (1, 2)'),
                ),
                ButtonSegment(
                  value: core.GroupNumberingStyle.roman,
                  label: Text('Roman (I, II)'),
                ),
              ],
              selected: {_numberingStyle},
              onSelectionChanged: (set) =>
                  setState(() => _numberingStyle = set.first),
            ),
            const SizedBox(height: 14),

            // Group Visibility
            Text(
              'Label Visibility',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(
                  value: null,
                  label: Text('Keep Current'),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Show All'),
                  icon: Icon(Icons.visibility_outlined, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Hide All'),
                  icon: Icon(Icons.visibility_off_outlined, size: 16),
                ),
              ],
              selected: {_labelVisible},
              onSelectionChanged: (set) =>
                  setState(() => _labelVisible = set.first),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    isTargeted ? 'Apply to Selected Groups' : 'Apply to All Groups',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

