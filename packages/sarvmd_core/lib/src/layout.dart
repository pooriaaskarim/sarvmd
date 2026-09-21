/// Layout engine — computes the vertical positions of all staves on a page.

import 'config.dart';

/// A staff with its Y-coordinate (top line) in mm from page top.
class StaffPosition {
  const StaffPosition({
    required this.topY,
    required this.lines,
    required this.lineGapMm,
    this.scale = 1.0,
    this.definition,
  });

  /// The original definition this position was generated from.
  final StaffDefinition? definition;

  /// Y-coordinate of the topmost line of this staff, measured from page top
  /// edge in mm.
  final double topY;

  /// Number of lines in this staff.
  final int lines;

  /// Gap between lines in mm.
  final double lineGapMm;

  /// The visual scale of this staff (e.g., 0.8 for cue staves).
  final double scale;

  /// Total height of this staff in mm.
  double get height => lines > 0 ? (lines - 1) * lineGapMm * scale : 0;
}

/// Physical placement and properties of a staff group in a system.
class GroupPlacement {
  const GroupPlacement({
    required this.startStaffIdx,
    required this.endStaffIdx,
    required this.connector,
    this.continuousBarlines = true,
    this.level = 0,
    this.label = '',
    this.abbreviation = '',
    this.labelVisible = true,
    this.innerStaffLabelWidthMm = 0.0,
    this.groupLabelWidthMm = 0.0,
    this.connectorOffsetMm = 0.0,
  });

  /// Index of the first staff in this group (within the system's flat list).
  final int startStaffIdx;

  /// Index of the last staff in this group.
  final int endStaffIdx;

  /// The visual connector for this group.
  final SystemConnector connector;

  /// Whether barlines should be continuous across all staves in this group.
  final bool continuousBarlines;

  /// The nesting level (0 = root).
  final int level;

  /// Group display label (e.g., "Strings", "Woodwinds").
  final String label;

  /// Short abbreviation for subsequent systems.
  final String abbreviation;

  /// Whether the group label should be rendered.
  final bool labelVisible;

  /// Maximum width of inner staff labels within this group (in mm).
  final double innerStaffLabelWidthMm;

  /// Formatted width of this group label (in mm).
  final double groupLabelWidthMm;

  /// Physical distance in mm from the starting barline to this connector.
  final double connectorOffsetMm;

  /// Copy with updated parameters.
  GroupPlacement copyWith({
    int? startStaffIdx,
    int? endStaffIdx,
    SystemConnector? connector,
    bool? continuousBarlines,
    int? level,
    String? label,
    String? abbreviation,
    bool? labelVisible,
    double? innerStaffLabelWidthMm,
    double? groupLabelWidthMm,
    double? connectorOffsetMm,
  }) {
    return GroupPlacement(
      startStaffIdx: startStaffIdx ?? this.startStaffIdx,
      endStaffIdx: endStaffIdx ?? this.endStaffIdx,
      connector: connector ?? this.connector,
      continuousBarlines: continuousBarlines ?? this.continuousBarlines,
      level: level ?? this.level,
      label: label ?? this.label,
      abbreviation: abbreviation ?? this.abbreviation,
      labelVisible: labelVisible ?? this.labelVisible,
      innerStaffLabelWidthMm:
          innerStaffLabelWidthMm ?? this.innerStaffLabelWidthMm,
      groupLabelWidthMm: groupLabelWidthMm ?? this.groupLabelWidthMm,
      connectorOffsetMm: connectorOffsetMm ?? this.connectorOffsetMm,
    );
  }
}

/// A system is one group of staves on the page.
class StaffSystem {
  const StaffSystem({
    required this.staves,
    this.groupPlacements = const [],
    this.leftIndentMm = 0.0,
    this.maxInnerLabelWidthMm = 0.0,
  });

  /// The physical positioning of all staves in this system.
  final List<StaffPosition> staves;

  /// Hierarchical grouping information for connectors and barlines.
  final List<GroupPlacement> groupPlacements;

  /// Dynamic horizontal indent applied to the left side of this system (in mm).
  final double leftIndentMm;

  /// Maximum width among all inner staff labels across labeled groups in this system (in mm).
  final double maxInnerLabelWidthMm;

  /// Y of the topmost line of the topmost staff.
  double get topY => staves.first.topY;

  /// Y of the bottommost line of the bottommost staff.
  double bottomY() => staves.last.topY + staves.last.height;
}

/// Complete layout for a page — a list of systems and their positions.
class PageLayout {
  const PageLayout({
    required this.config,
    required this.systems,
  });

  final PageConfig config;
  final List<StaffSystem> systems;

  /// Number of systems that fit on the page.
  int get systemCount => systems.length;
}

/// Compute the layout for a given page configuration.
///
/// Places as many systems as will fit vertically within the usable area,
/// evenly distributing any remaining space by expanding the gap between
/// systems.
PageLayout computeLayout(PageConfig config) {
  final systemH = config.systemHeight;
  final usableH = config.usableHeight;
  final gap = config.staffConfig.systemGapMm;

  // How many systems fit?
  final count = usableH < systemH
      ? 0
      : 1 + ((usableH - systemH) / (systemH + gap)).floor();

  if (count == 0) {
    return PageLayout(config: config, systems: []);
  }

  // Distribute leftover space evenly between systems.
  final totalUsed = count * systemH + (count - 1) * gap;
  final leftover = usableH - totalUsed;
  final adjustedGap = count > 1 ? gap + leftover / (count - 1) : gap;

  final systems = <StaffSystem>[];
  final lineGap = config.staffConfig.lineGapMm;

  for (var i = 0; i < count; i++) {
    final systemTopY = config.margins.top + i * (systemH + adjustedGap);
    final staves = <StaffPosition>[];
    final placements = <GroupPlacement>[];

    double currentTopY = systemTopY;

    int computeActiveChildDepth(StaffNode node) {
      if (node is StaffDefinition) return 0;
      if (node is StaffNodeGroup) {
        int maxChildDepth = 0;
        for (final child in node.children) {
          final childDepth = computeActiveChildDepth(child);
          if (childDepth > maxChildDepth) {
            maxChildDepth = childDepth;
          }
        }
        return (node.connector != SystemConnector.none)
            ? 1 + maxChildDepth
            : maxChildDepth;
      }
      return 0;
    }

    void traverse(StaffNodeGroup group) {
      final startIdx = staves.length;

      for (final child in group.children) {
        switch (child) {
          case StaffDefinition def:
            final sStaff = StaffPosition(
              topY: currentTopY,
              lines: def.lines,
              lineGapMm: lineGap,
              scale: def.scale,
              definition: def,
            );
            staves.add(sStaff);
            currentTopY += sStaff.height + config.staffConfig.interStaffGapMm;
          case StaffNodeGroup subGroup:
            traverse(subGroup);
        }
      }

      final endIdx = staves.length - 1;
      if (endIdx >= startIdx) {
        int maxChildActiveDepth = 0;
        for (final child in group.children) {
          final depth = computeActiveChildDepth(child);
          if (depth > maxChildActiveDepth) {
            maxChildActiveDepth = depth;
          }
        }

        placements.add(GroupPlacement(
          startStaffIdx: startIdx,
          endStaffIdx: endIdx,
          connector: group.connector,
          continuousBarlines: group.continuousBarlines,
          level: maxChildActiveDepth,
          label: group.label,
          abbreviation: group.abbreviation,
          labelVisible: group.labelVisible,
        ));
      }
    }

    traverse(config.systemLayout.rootGroup);

    // Implement Gould/MOLA two-tier hierarchical space-aware indentation
    final bool isFirstSystem = i == 0;

    // 1. Determine which staves belong to an actively labeled group or connected group.
    final Set<int> innerStaffIndices = {};
    for (final group in placements) {
      final String gLabel = isFirstSystem
          ? group.label
          : (group.abbreviation.trim().isNotEmpty
              ? group.abbreviation
              : group.label);
      final bool hasGroupLabel = group.labelVisible && gLabel.trim().isNotEmpty;
      final bool hasConnector = group.connector != SystemConnector.none;
      if (hasGroupLabel || hasConnector) {
        for (int s = group.startStaffIdx; s <= group.endStaffIdx; s++) {
          innerStaffIndices.add(s);
        }
      }
    }

    // 2. Compute inner and outer dimensions per GroupPlacement
    double systemMaxInnerWidthMm = 0.0;
    final initialGroupData = <GroupPlacement>[];

    for (final group in placements) {
      final String gLabel = isFirstSystem
          ? group.label
          : (group.abbreviation.trim().isNotEmpty
              ? group.abbreviation
              : group.label);
      final bool hasGroupLabel = group.labelVisible && gLabel.trim().isNotEmpty;
      final bool hasConnector = group.connector != SystemConnector.none;
      final double gWidthMm = hasGroupLabel
          ? estimateLabelWidthMm(gLabel, fontSizePt: 11.0, isGroup: true)
          : 0.0;

      // Find max inner label width for staves in this group
      double groupInnerWidthMm = 0.0;
      for (int s = group.startStaffIdx; s <= group.endStaffIdx; s++) {
        if (s < staves.length) {
          final def = staves[s].definition;
          if (def != null && def.labelVisible) {
            final sLabel = isFirstSystem
                ? (def.instrumentName ?? '')
                : ((def.instrumentAbbreviation != null &&
                        def.instrumentAbbreviation!.trim().isNotEmpty)
                    ? def.instrumentAbbreviation!
                    : (def.instrumentName ?? ''));
            if (sLabel.trim().isNotEmpty) {
              final w = estimateLabelWidthMm(sLabel,
                  fontSizePt: def.labelFontSize);
              if (w > groupInnerWidthMm) {
                groupInnerWidthMm = w;
              }
            }
          }
        }
      }

      if ((hasGroupLabel || hasConnector) &&
          groupInnerWidthMm > systemMaxInnerWidthMm) {
        systemMaxInnerWidthMm = groupInnerWidthMm;
      }

      initialGroupData.add(group.copyWith(
        innerStaffLabelWidthMm: groupInnerWidthMm,
        groupLabelWidthMm: gWidthMm,
      ));
    }

    // 3. Compute cumulative connector offsets per level across the system
    final int maxLevel = initialGroupData.fold<int>(
      0,
      (prev, g) => g.level > prev ? g.level : prev,
    );

    final Map<int, double> levelOffsets = {};
    // Level 0 sits outside inner staff descriptors (if any).
    // When inner staff descriptors or abbreviations exist, we guarantee
    // clearance between bracket end ticks and label text so ticks do not intersect abbreviations.
    levelOffsets[0] = systemMaxInnerWidthMm > 0
        ? (systemMaxInnerWidthMm +
            GroupPlacementMetrics.staffLabelClearanceMm +
            GroupPlacementMetrics.bracketTickLengthMm +
            GroupPlacementMetrics.staffLabelConnectorClearanceMm)
        : 0.0;

    for (int lvl = 0; lvl < maxLevel; lvl++) {
      double maxLvlGroupLabelExtent = 0.0;
      for (final g in initialGroupData) {
        if (g.level == lvl && g.groupLabelWidthMm > 0.0) {
          final extent =
              GroupPlacementMetrics.groupLabelClearanceMm + g.groupLabelWidthMm;
          if (extent > maxLvlGroupLabelExtent) {
            maxLvlGroupLabelExtent = extent;
          }
        }
      }
      final double step = maxLvlGroupLabelExtent > 0.0
          ? (maxLvlGroupLabelExtent +
              GroupPlacementMetrics.bracketTickLengthMm +
              GroupPlacementMetrics.connectorLevelSpacingMm)
          : GroupPlacementMetrics.connectorLevelSpacingMm;
      levelOffsets[lvl + 1] = (levelOffsets[lvl] ?? 0.0) + step;
    }

    // 4. Update placements with exact physical connectorOffsetMm and calculate required indent
    double maxSystemRequiredIndentMm = 0.0;
    final updatedPlacements = <GroupPlacement>[];

    for (final group in initialGroupData) {
      final double connectorOffset = levelOffsets[group.level] ?? 0.0;
      if (group.groupLabelWidthMm > 0.0) {
        final double groupRequiredIndent = connectorOffset +
            GroupPlacementMetrics.groupLabelClearanceMm +
            group.groupLabelWidthMm;
        if (groupRequiredIndent > maxSystemRequiredIndentMm) {
          maxSystemRequiredIndentMm = groupRequiredIndent;
        }
      } else if (connectorOffset > 0.0) {
        if (connectorOffset > maxSystemRequiredIndentMm) {
          maxSystemRequiredIndentMm = connectorOffset;
        }
      }

      updatedPlacements.add(group.copyWith(
        connectorOffsetMm: connectorOffset,
      ));
    }

    // 5. Check standalone / unlabeled staves (staves not in an actively labeled or connected group)
    for (int s = 0; s < staves.length; s++) {
      if (!innerStaffIndices.contains(s)) {
        final def = staves[s].definition;
        if (def != null && def.labelVisible) {
          final sLabel = isFirstSystem
              ? (def.instrumentName ?? '')
              : ((def.instrumentAbbreviation != null &&
                      def.instrumentAbbreviation!.trim().isNotEmpty)
                  ? def.instrumentAbbreviation!
                  : (def.instrumentName ?? ''));
          if (sLabel.trim().isNotEmpty) {
            final w = estimateLabelWidthMm(sLabel,
                fontSizePt: def.labelFontSize);
            double maxConnectorOffset = 0.0;
            for (final g in updatedPlacements) {
              if (s >= g.startStaffIdx &&
                  s <= g.endStaffIdx &&
                  g.connectorOffsetMm > maxConnectorOffset) {
                maxConnectorOffset = g.connectorOffsetMm;
              }
            }
            final double staffRequiredIndent = w +
                GroupPlacementMetrics.staffLabelClearanceMm +
                maxConnectorOffset;
            if (staffRequiredIndent > maxSystemRequiredIndentMm) {
              maxSystemRequiredIndentMm = staffRequiredIndent;
            }
          }
        }
      }
    }

    final double leftIndentMm = maxSystemRequiredIndentMm > 0.0
        ? maxSystemRequiredIndentMm + 1.0
        : 0.0;

    systems.add(StaffSystem(
      staves: staves,
      groupPlacements: updatedPlacements,
      leftIndentMm: leftIndentMm,
      maxInnerLabelWidthMm: systemMaxInnerWidthMm,
    ));
  }

  return PageLayout(config: config, systems: systems);
}

/// Estimates formatted text width in millimeters based on font size and character length.
///
/// Uses character-weighted typographic font advance metrics (e.g. Noto Serif/Helvetica
/// standard advance ~0.52 em for lowercase, ~0.68 em for uppercase, ~0.28 em for spaces/punctuation)
/// to accurately measure full multi-word labels and explicit newlines (\n) without
/// under-allocating horizontal margins.
double estimateLabelWidthMm(
  String text, {
  double fontSizePt = 11.0,
  bool isGroup = false,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0.0;
  final lines = trimmed.split('\n');
  double maxLineWidthMm = 0.0;
  final fontFactor = fontSizePt * (25.4 / 72.0);
  final boldMultiplier = isGroup ? 1.08 : 1.0;

  for (final line in lines) {
    final lineTrimmed = line.trim();
    if (lineTrimmed.isEmpty) continue;
    double emSum = 0.0;
    for (final codeUnit in lineTrimmed.codeUnits) {
      if (codeUnit >= 65 && codeUnit <= 90) {
        // Uppercase A-Z
        emSum += 0.68;
      } else if (codeUnit >= 48 && codeUnit <= 57) {
        // Digits 0-9
        emSum += 0.55;
      } else if (codeUnit == 32) {
        // Space
        emSum += 0.28;
      } else if (codeUnit == 109 || codeUnit == 119) {
        // 'm', 'w'
        emSum += 0.78;
      } else if (codeUnit == 105 ||
          codeUnit == 106 ||
          codeUnit == 108 ||
          codeUnit == 116 ||
          codeUnit == 46 ||
          codeUnit == 44 ||
          codeUnit == 58 ||
          codeUnit == 59 ||
          codeUnit == 39 ||
          codeUnit == 33 ||
          codeUnit == 45) {
        // Narrow characters: i, j, l, t, ., ,, :, ;, ', !, -
        emSum += 0.30;
      } else {
        // Standard lowercase and symbols
        emSum += 0.52;
      }
    }
    final widthMm = (emSum * fontFactor * boldMultiplier) + 0.5;
    if (widthMm > maxLineWidthMm) {
      maxLineWidthMm = widthMm;
    }
  }
  return maxLineWidthMm;
}
