// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Section of controls in the inline label editor for group layout options:
/// - Label placement (Margin vs Above Staff / Model C)
/// - Header visibility (1st system, top of page, always)
/// - Numbering style (Model B: None, Arabic, Roman)
/// - Descriptor placement (Anglo-American enclosed vs Continental outside)
/// - Auto-numbering of child staves (Gould non-redundancy)
class GroupNumberingSection extends StatefulWidget {
  const GroupNumberingSection({
    super.key,
    required this.labelPlacement,
    required this.numberingStyle,
    required this.descriptorPlacement,
    required this.headerVisibility,
    required this.onLabelPlacementChanged,
    required this.onNumberingStyleChanged,
    required this.onDescriptorPlacementChanged,
    required this.onHeaderVisibilityChanged,
    this.childStaves,
    this.onAutoNumberChildStaves,
  });

  final core.GroupLabelPlacement labelPlacement;
  final core.GroupNumberingStyle numberingStyle;
  final core.DescriptorPlacement descriptorPlacement;
  final core.GroupHeaderVisibility headerVisibility;
  final ValueChanged<core.GroupLabelPlacement> onLabelPlacementChanged;
  final ValueChanged<core.GroupNumberingStyle> onNumberingStyleChanged;
  final ValueChanged<core.DescriptorPlacement> onDescriptorPlacementChanged;
  final ValueChanged<core.GroupHeaderVisibility> onHeaderVisibilityChanged;
  final List<core.StaffDefinition>? childStaves;
  final VoidCallback? onAutoNumberChildStaves;

  @override
  State<GroupNumberingSection> createState() => _GroupNumberingSectionState();
}

class _GroupNumberingSectionState extends State<GroupNumberingSection> {
  bool _hasAutoNumbered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 270;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Placement Control (Model C)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vertical_align_top_rounded,
                        size: 13, color: cs.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Group Label Placement',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<core.GroupLabelPlacement>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: core.GroupLabelPlacement.margin,
                        tooltip: 'Standard margin label centered vertically outside brackets.',
                        label: Text(isNarrow ? 'Margin' : 'Margin (Left)',
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                      ButtonSegment(
                        value: core.GroupLabelPlacement.aboveStaff,
                        tooltip: 'Model C: Section header rendered above topmost staff, saving 25–35mm printable score width.',
                        label: Text(isNarrow ? 'Above Staff' : 'Above Staff (Header)',
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    selected: {widget.labelPlacement},
                    onSelectionChanged: (set) =>
                        widget.onLabelPlacementChanged(set.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                if (widget.labelPlacement ==
                    core.GroupLabelPlacement.aboveStaff) ...[
                  const SizedBox(height: 8),
                  // Header Visibility Control
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined,
                              size: 13, color: cs.primary),
                          const SizedBox(width: 5),
                          Text(
                            'Header Visibility',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<core.GroupHeaderVisibility>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: core.GroupHeaderVisibility.firstSystemOnly,
                              tooltip: 'Shown only on first system of score (Gould & MOLA default)',
                              label: Text(isNarrow ? '1st Sys' : '1st System',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            ButtonSegment(
                              value: core.GroupHeaderVisibility.firstSystemOfPage,
                              tooltip: 'Shown on first system of each page (Bärenreiter style)',
                              label: Text(isNarrow ? 'Page' : 'Top of Page',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                            const ButtonSegment(
                              value: core.GroupHeaderVisibility.always,
                              tooltip: 'Shown on every system',
                              label: Text('All',
                                  style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                          selected: {widget.headerVisibility},
                          onSelectionChanged: (set) =>
                              widget.onHeaderVisibilityChanged(set.first),
                          style: SegmentedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Numbering Style Control (Model B)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_list_numbered_rounded,
                        size: 13, color: cs.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Child Staff Numbering',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<core.GroupNumberingStyle>(
                    showSelectedIcon: false,
                    segments: [
                      const ButtonSegment(
                        value: core.GroupNumberingStyle.none,
                        tooltip: 'Use original instrument names',
                        label: Text('None',
                            style: TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                      ButtonSegment(
                        value: core.GroupNumberingStyle.arabic,
                        tooltip: 'Model B: Auto-numbers child staves with Arabic numerals (1, 2)',
                        label: Text(isNarrow ? '1, 2' : 'Arabic (1, 2)',
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                      ButtonSegment(
                        value: core.GroupNumberingStyle.roman,
                        tooltip: 'Model B: Auto-numbers child staves with Roman numerals (I, II)',
                        label: Text(isNarrow ? 'I, II' : 'Roman (I, II)',
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    selected: {widget.numberingStyle},
                    onSelectionChanged: (set) =>
                        widget.onNumberingStyleChanged(set.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Descriptor Placement Control (Continental vs Anglo-American)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.space_bar_rounded, size: 13, color: cs.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Descriptor Placement',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<core.DescriptorPlacement>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: core.DescriptorPlacement.enclosedByConnector,
                        tooltip: 'Anglo-American (Gould): Connector displaced outward; descriptors enclosed.',
                        label: Text(isNarrow ? 'Enclosed' : 'Enclosed (Anglo-American)',
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                      ButtonSegment(
                        value: core.DescriptorPlacement.outsideConnector,
                        tooltip: 'Continental (Bärenreiter): Connector flush at barline; descriptors outside.',
                        label: Text(isNarrow ? 'Outside' : 'Outside (Continental)',
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                    selected: {widget.descriptorPlacement},
                    onSelectionChanged: (set) =>
                        widget.onDescriptorPlacementChanged(set.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
        if (widget.childStaves != null && widget.childStaves!.length >= 2) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              widget.onAutoNumberChildStaves?.call();
              setState(() {
                _hasAutoNumbered = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Applied Gould non-redundancy: Renumbered ${widget.childStaves!.length} staves (1..${widget.childStaves!.length})',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _hasAutoNumbered
                    ? cs.primaryContainer.withValues(alpha: 0.45)
                    : cs.secondaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasAutoNumbered
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.secondary.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasAutoNumbered
                        ? Icons.check_circle_outline
                        : Icons.auto_awesome,
                    size: 14,
                    color: _hasAutoNumbered ? cs.primary : cs.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasAutoNumbered
                              ? 'Gould non-redundancy applied: Staves (1..${widget.childStaves!.length})'
                              : 'Apply Gould non-redundancy: Renumber staves (1, 2${widget.childStaves!.length > 2 ? ', ...' : ''})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _hasAutoNumbered
                                ? cs.onPrimaryContainer
                                : cs.onSecondaryContainer,
                          ),
                        ),
                        Text(
                          'Sets child instrument labels to 1, 2... avoiding redundant group name repetition.',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: _hasAutoNumbered
                                ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                                : cs.onSecondaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: _hasAutoNumbered ? cs.primary : cs.secondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  },
);
}
}

