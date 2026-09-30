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

            const SizedBox(height: 24),
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
