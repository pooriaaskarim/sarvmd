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
    this.resolvedLabel,
  });

  /// The original definition this position was generated from.
  final StaffDefinition? definition;

  /// The dynamically resolved label for this staff in the system
  /// (considering Gould hierarchical rules and group numbering style).
  final String? resolvedLabel;

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

  StaffPosition copyWith({
    double? topY,
    int? lines,
    double? lineGapMm,
    double? scale,
    StaffDefinition? definition,
    String? resolvedLabel,
  }) {
    return StaffPosition(
      topY: topY ?? this.topY,
      lines: lines ?? this.lines,
      lineGapMm: lineGapMm ?? this.lineGapMm,
      scale: scale ?? this.scale,
      definition: definition ?? this.definition,
      resolvedLabel: resolvedLabel ?? this.resolvedLabel,
    );
  }
}

/// Physical placement and properties of a staff group in a system.
class GroupPlacement {
  const GroupPlacement({
    required this.startStaffIdx,
    required this.endStaffIdx,
    required this.connector,
    this.continuousBarlines = true,
    this.initialBarline = true,
    this.level = 0,
    this.label = '',
    this.abbreviation = '',
    this.labelVisible = true,
    this.labelPlacement = GroupLabelPlacement.margin,
    this.numberingStyle = GroupNumberingStyle.none,
    this.innerStaffLabelWidthMm = 0.0,
    this.groupLabelWidthMm = 0.0,
    this.connectorOffsetMm = 0.0,
    this.labelOffsetMm = 0.0,
  });

  /// Index of the first staff in this group (within the system's flat list).
  final int startStaffIdx;

  /// Index of the last staff in this group.
  final int endStaffIdx;

  /// The visual connector for this group.
  final SystemConnector connector;

  /// Whether barlines should be continuous across all staves in this group.
  final bool continuousBarlines;

  /// Whether this group has a vertical starting barline at the system left.
  final bool initialBarline;

  /// The nesting level (0 = root).
  final int level;

  /// Group display label (e.g., "Strings", "Woodwinds").
  final String label;

  /// Short abbreviation for subsequent systems.
  final String abbreviation;

  /// Whether the group label should be rendered.
  final bool labelVisible;

  /// Visual placement for the group label (margin vs above topmost staff).
  final GroupLabelPlacement labelPlacement;

  /// Automatic numbering scheme for child staves.
  final GroupNumberingStyle numberingStyle;

  /// Maximum width of inner staff labels within this group (in mm).
  final double innerStaffLabelWidthMm;

  /// Formatted width of this group label (in mm).
  final double groupLabelWidthMm;

  /// Physical distance in mm from the starting barline to this connector.
  final double connectorOffsetMm;

  /// Physical distance in mm from the starting barline to this group's label right anchor.
  final double labelOffsetMm;

  /// Copy with updated parameters.
  GroupPlacement copyWith({
    int? startStaffIdx,
    int? endStaffIdx,
    SystemConnector? connector,
    bool? continuousBarlines,
    bool? initialBarline,
    int? level,
    String? label,
    String? abbreviation,
    bool? labelVisible,
    GroupLabelPlacement? labelPlacement,
    GroupNumberingStyle? numberingStyle,
    double? innerStaffLabelWidthMm,
    double? groupLabelWidthMm,
    double? connectorOffsetMm,
    double? labelOffsetMm,
  }) {
    return GroupPlacement(
      startStaffIdx: startStaffIdx ?? this.startStaffIdx,
      endStaffIdx: endStaffIdx ?? this.endStaffIdx,
      connector: connector ?? this.connector,
      continuousBarlines: continuousBarlines ?? this.continuousBarlines,
      initialBarline: initialBarline ?? this.initialBarline,
      level: level ?? this.level,
      label: label ?? this.label,
      abbreviation: abbreviation ?? this.abbreviation,
      labelVisible: labelVisible ?? this.labelVisible,
      labelPlacement: labelPlacement ?? this.labelPlacement,
      numberingStyle: numberingStyle ?? this.numberingStyle,
      innerStaffLabelWidthMm:
          innerStaffLabelWidthMm ?? this.innerStaffLabelWidthMm,
      groupLabelWidthMm: groupLabelWidthMm ?? this.groupLabelWidthMm,
      connectorOffsetMm: connectorOffsetMm ?? this.connectorOffsetMm,
      labelOffsetMm: labelOffsetMm ?? this.labelOffsetMm,
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

/// Checks whether a given string is a valid Roman numeral (e.g. "I", "II", "IV", "VII").
bool isRomanNumeral(String s) {
  final trimmed = s.trim().replaceAll(RegExp(r'\.+$'), '');
  if (trimmed.isEmpty) return false;
  return RegExp(r'^(I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII|XIII|XIV|XV|XVI)$',
          caseSensitive: false)
      .hasMatch(trimmed);
}

/// Checks whether an instrument name is generic or auto-generated, matching either
/// a number, or the group label (singular or plural), or empty.
bool isGenericStaffLabel(String name, String groupLabel) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return true;
  final withoutDot = trimmed.replaceAll(RegExp(r'\.+$'), '');
  if (int.tryParse(withoutDot) != null) return true;
  if (isRomanNumeral(withoutDot)) return true;

  final cleanName = trimmed.toLowerCase();
  if (cleanName == 'staff' || cleanName.startsWith('staff ')) {
    return true;
  }

  // Extract primary instrument stem from group label
  // e.g. "Horns in F" -> "Horns", "Violins I" -> "Violins", "Flutes (1, 2)" -> "Flutes"
  final baseGroup = groupLabel
      .split(RegExp(r'\s+(in|\(|\b(I|II|III|IV|V|VI|VII|VIII)\b)',
          caseSensitive: false))
      .first
      .trim();

  final cleanGroup =
      baseGroup.toLowerCase().replaceAll(RegExp(r's$'), '').trim();

  if (cleanGroup.isNotEmpty) {
    if (cleanName == cleanGroup ||
        cleanName == '${cleanGroup}s' ||
        cleanName.startsWith('$cleanGroup ') ||
        cleanName.startsWith('${cleanGroup}s ') ||
        cleanName.startsWith('$cleanGroup-')) {
      return true;
    }
  }

  final fullCleanGroup =
      groupLabel.toLowerCase().replaceAll(RegExp(r's$'), '').trim();
  if (fullCleanGroup.isNotEmpty && fullCleanGroup != cleanGroup) {
    if (cleanName == fullCleanGroup ||
        cleanName == '${fullCleanGroup}s' ||
        cleanName.startsWith('$fullCleanGroup ') ||
        cleanName.startsWith('${fullCleanGroup}s ') ||
        cleanName.startsWith('$fullCleanGroup-')) {
      return true;
    }
  }

  return false;
}

/// Resolves the effective display label for a staff within a system.
///
/// Takes into account whether this is the first system (full name vs abbreviation),
/// the hierarchical group context, and any [GroupNumberingStyle] assigned to
/// enclosing groups (Model B).
String resolveStaffLabel({
  required StaffDefinition def,
  required int staffIndex,
  required List<GroupPlacement> groupPlacements,
  required bool isFirstSystem,
}) {
  if (!def.labelVisible) return '';

  // Find enclosing groups for this staff
  final enclosingGroups = groupPlacements
      .where((g) =>
          staffIndex >= g.startStaffIdx && staffIndex <= g.endStaffIdx)
      .toList();

  // Find innermost group with an active numberingStyle
  GroupPlacement? numberingGroup;
  for (final g in enclosingGroups) {
    if (g.numberingStyle != GroupNumberingStyle.none) {
      if (numberingGroup == null ||
          (g.endStaffIdx - g.startStaffIdx) <
              (numberingGroup.endStaffIdx - numberingGroup.startStaffIdx)) {
        numberingGroup = g;
      }
    }
  }

  if (numberingGroup != null) {
    final indexInGroup = staffIndex - numberingGroup.startStaffIdx;
    final generatedNum =
        formatGroupStaffNumber(indexInGroup, numberingGroup.numberingStyle);
    final rawName = isFirstSystem
        ? (def.instrumentName ?? '')
        : ((def.instrumentAbbreviation != null &&
                def.instrumentAbbreviation!.trim().isNotEmpty)
            ? def.instrumentAbbreviation!
            : (def.instrumentName ?? ''));

    if (rawName.isEmpty || isGenericStaffLabel(rawName, numberingGroup.label)) {
      return generatedNum;
    }
    // If user provided a specific non-generic name (e.g. "Piccolo"), keep it.
    return rawName;
  }

  // Classical resolution
  return isFirstSystem
      ? (def.instrumentName ?? '')
      : ((def.instrumentAbbreviation != null &&
              def.instrumentAbbreviation!.trim().isNotEmpty)
          ? def.instrumentAbbreviation!
          : (def.instrumentName ?? ''));
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

  final bool hasAboveStaffGroups = config.systemLayout.rootGroup.allGroups
      .any((g) => g.labelPlacement == GroupLabelPlacement.aboveStaff);
  final double aboveStaffHeadroom = hasAboveStaffGroups
      ? GroupPlacementMetrics.aboveStaffHeaderClearanceMm
      : 0.0;
  final effectiveGap = gap + aboveStaffHeadroom;

  // How many systems fit?
  final count = usableH < systemH
      ? 0
      : 1 + ((usableH - systemH) / (systemH + effectiveGap)).floor();

  if (count == 0) {
    return PageLayout(config: config, systems: []);
  }

  // Distribute leftover space evenly between systems.
  final totalUsed = count * systemH + (count - 1) * effectiveGap;
  final leftover = usableH - totalUsed;
  final adjustedGap =
      count > 1 ? effectiveGap + leftover / (count - 1) : effectiveGap;

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
          initialBarline: group.initialBarline,
          level: maxChildActiveDepth,
          label: group.label,
          abbreviation: group.abbreviation,
          labelVisible: group.labelVisible,
          labelPlacement: group.labelPlacement,
          numberingStyle: group.numberingStyle,
        ));
      }
    }

    traverse(config.systemLayout.rootGroup);

    // Implement Gould/MOLA two-tier hierarchical space-aware indentation
    final bool isFirstSystem = i == 0;

    // Resolve effective staff labels for this system (Model B & Gould non-redundancy)
    for (int s = 0; s < staves.length; s++) {
      final def = staves[s].definition;
      if (def != null) {
        final resolved = resolveStaffLabel(
          def: def,
          staffIndex: s,
          groupPlacements: placements,
          isFirstSystem: isFirstSystem,
        );
        staves[s] = staves[s].copyWith(resolvedLabel: resolved);
      }
    }

    // 1. Resolve effective group labels per system
    // Gould (p. 515): Top-level / family names (e.g. Woodwinds, Strings) appear only on System 1.
    // On subsequent systems, if an explicit abbreviation exists, use it; otherwise omit family name.
    // Above-staff headers (Model C) appear only on System 1 (Gould / MOLA standards).
    String resolveGroupLabel(GroupPlacement g) {
      if (!g.labelVisible) return '';
      if (g.labelPlacement == GroupLabelPlacement.aboveStaff) {
        return isFirstSystem ? g.label.trim() : '';
      }
      if (isFirstSystem) return g.label.trim();
      return g.abbreviation.trim();
    }


    // 3. Compute inner descriptor width and group label width per GroupPlacement locally
    final initialGroupData = <GroupPlacement>[];
    double systemMaxInnerWidthMm = 0.0;

    for (final group in placements) {
      final gLabel = resolveGroupLabel(group);
      final bool hasGroupLabel = gLabel.isNotEmpty;
      final bool hasConnector = group.connector != SystemConnector.none;
      final bool isAboveStaff =
          group.labelPlacement == GroupLabelPlacement.aboveStaff;
      final double gWidthMm = (hasGroupLabel && !isAboveStaff)
          ? estimateLabelWidthMm(gLabel, fontSizePt: 11.0, isGroup: true)
          : 0.0;

      final bool hasChildConnectors = placements.any((c) =>
          c.level < group.level &&
          c.startStaffIdx >= group.startStaffIdx &&
          c.endStaffIdx <= group.endStaffIdx &&
          c.connector != SystemConnector.none);

      final bool hasEnclosingGroupLabel = placements.any((p) =>
          p.level > group.level &&
          p.startStaffIdx <= group.startStaffIdx &&
          p.endStaffIdx >= group.endStaffIdx &&
          resolveGroupLabel(p).isNotEmpty);

      double groupInnerWidthMm = 0.0;
      if (hasConnector &&
          !hasChildConnectors &&
          (hasGroupLabel || hasEnclosingGroupLabel)) {
        for (int s = group.startStaffIdx; s <= group.endStaffIdx; s++) {
          if (s < staves.length) {
            final def = staves[s].definition;
            if (def != null && def.labelVisible) {
              final sLabel = staves[s].resolvedLabel ??
                  (isFirstSystem
                      ? (def.instrumentName ?? '')
                      : ((def.instrumentAbbreviation != null &&
                              def.instrumentAbbreviation!.trim().isNotEmpty)
                          ? def.instrumentAbbreviation!
                          : (def.instrumentName ?? '')));
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
      }

      if (groupInnerWidthMm > systemMaxInnerWidthMm) {
        systemMaxInnerWidthMm = groupInnerWidthMm;
      }

      initialGroupData.add(group.copyWith(
        innerStaffLabelWidthMm: groupInnerWidthMm,
        groupLabelWidthMm: gWidthMm,
      ));
    }

    // 4. Compute connector offsets per group locally and hierarchically.
    // Groups are sorted by level ascending so inner/child connectors are resolved first.
    final updatedPlacements = List<GroupPlacement>.from(initialGroupData);
    final groupIndicesByLevel =
        List.generate(updatedPlacements.length, (idx) => idx)
          ..sort((a, b) =>
              updatedPlacements[a].level.compareTo(updatedPlacements[b].level));

    for (final idx in groupIndicesByLevel) {
      final g = updatedPlacements[idx];
      final bool hasConnector = g.connector != SystemConnector.none;
      if (!hasConnector) {
        updatedPlacements[idx] = g.copyWith(connectorOffsetMm: 0.0);
        continue;
      }

      // Check for child groups enclosed within g that have active connectors.
      // In classical engraving (Bärenreiter, Gould), outer connectors cluster
      // immediately outside child connectors, separated only by connectorLevelSpacingMm (3.0mm).
      double maxChildBranchExtent = 0.0;
      for (final otherIdx in groupIndicesByLevel) {
        if (otherIdx == idx) continue;
        final c = updatedPlacements[otherIdx];
        if (c.level < g.level &&
            c.startStaffIdx >= g.startStaffIdx &&
            c.endStaffIdx <= g.endStaffIdx &&
            c.connector != SystemConnector.none) {
          final double cExtent = c.connectorOffsetMm +
              GroupPlacementMetrics.connectorLevelSpacingMm;
          if (cExtent > maxChildBranchExtent) {
            maxChildBranchExtent = cExtent;
          }
        }
      }

      // If g has inner staff labels:
      // it creates an inner zone between its connector and the staves.
      double directInnerExtent = 0.0;
      if (g.innerStaffLabelWidthMm > 0.0) {
        directInnerExtent = g.innerStaffLabelWidthMm +
            GroupPlacementMetrics.staffLabelClearanceMm +
            GroupPlacementMetrics.bracketTickLengthMm +
            GroupPlacementMetrics.staffLabelConnectorClearanceMm;
      }

      final double offset = maxChildBranchExtent > directInnerExtent
          ? maxChildBranchExtent
          : directInnerExtent;

      updatedPlacements[idx] = g.copyWith(connectorOffsetMm: offset);
    }

    // 5. Compute label offsets per group hierarchically.
    // In Gouldian/master engraving, group labels sit in an outer column to the left
    // of all brackets covering the group's staves. If a parent group also has a label,
    // its label sits further to the left outside the child group labels.
    for (final idx in groupIndicesByLevel) {
      final g = updatedPlacements[idx];
      if (g.groupLabelWidthMm == 0.0 ||
          g.labelPlacement == GroupLabelPlacement.aboveStaff) {
        updatedPlacements[idx] = g.copyWith(labelOffsetMm: 0.0);
        continue;
      }

      // Find the outermost connector covering any of this group's staves
      double maxCoveringConnectorOffset = g.connectorOffsetMm;
      for (final other in updatedPlacements) {
        if (other.connector != SystemConnector.none &&
            other.startStaffIdx <= g.endStaffIdx &&
            other.endStaffIdx >= g.startStaffIdx &&
            other.connectorOffsetMm > maxCoveringConnectorOffset) {
          maxCoveringConnectorOffset = other.connectorOffsetMm;
        }
      }

      final double baseLabelOffset = maxCoveringConnectorOffset > 0.0
          ? maxCoveringConnectorOffset + GroupPlacementMetrics.groupLabelClearanceMm
          : GroupPlacementMetrics.groupLabelClearanceMm;

      // Check if any child groups enclosed within g have active group labels
      double maxChildLabelExtent = 0.0;
      for (final otherIdx in groupIndicesByLevel) {
        if (otherIdx == idx) continue;
        final c = updatedPlacements[otherIdx];
        if (c.level < g.level &&
            c.startStaffIdx >= g.startStaffIdx &&
            c.endStaffIdx <= g.endStaffIdx &&
            c.groupLabelWidthMm > 0.0) {
          final extent = c.labelOffsetMm +
              c.groupLabelWidthMm +
              GroupPlacementMetrics.groupLabelClearanceMm;
          if (extent > maxChildLabelExtent) {
            maxChildLabelExtent = extent;
          }
        }
      }

      final double labelOffset = maxChildLabelExtent > baseLabelOffset
          ? maxChildLabelExtent
          : baseLabelOffset;

      updatedPlacements[idx] = g.copyWith(labelOffsetMm: labelOffset);
    }

    // 6. Identify inner staves (staves sitting inside an inner-labeled group)
    final Set<int> innerStaffIndices = {};
    for (final group in updatedPlacements) {
      if (group.connector != SystemConnector.none &&
          group.innerStaffLabelWidthMm > 0.0) {
        for (int s = group.startStaffIdx; s <= group.endStaffIdx; s++) {
          innerStaffIndices.add(s);
        }
      }
    }

    // 7. Compute the required left indent for the system (Row-aware maximum)
    double maxSystemRequiredIndentMm = 0.0;

    // A. Groups:
    for (final group in updatedPlacements) {
      if (group.groupLabelWidthMm > 0.0) {
        final req = group.labelOffsetMm + group.groupLabelWidthMm;
        if (req > maxSystemRequiredIndentMm) {
          maxSystemRequiredIndentMm = req;
        }
      } else if (group.connectorOffsetMm > 0.0) {
        if (group.connectorOffsetMm > maxSystemRequiredIndentMm) {
          maxSystemRequiredIndentMm = group.connectorOffsetMm;
        }
      }
    }

    // B. Staves:
    for (int s = 0; s < staves.length; s++) {
      final def = staves[s].definition;
      if (def != null && def.labelVisible) {
        final sLabel = staves[s].resolvedLabel ??
            (isFirstSystem
                ? (def.instrumentName ?? '')
                : ((def.instrumentAbbreviation != null &&
                        def.instrumentAbbreviation!.trim().isNotEmpty)
                    ? def.instrumentAbbreviation!
                    : (def.instrumentName ?? '')));
        if (sLabel.trim().isNotEmpty) {
          final w = estimateLabelWidthMm(sLabel, fontSizePt: def.labelFontSize);
          if (!innerStaffIndices.contains(s)) {
            // Non-inner staff: sits outside the outermost connector covering this staff
            double maxCoveringConnectorOffset = 0.0;
            for (final g in updatedPlacements) {
              if (s >= g.startStaffIdx &&
                  s <= g.endStaffIdx &&
                  g.connector != SystemConnector.none &&
                  g.connectorOffsetMm > maxCoveringConnectorOffset) {
                maxCoveringConnectorOffset = g.connectorOffsetMm;
              }
            }
            final staffReq = w +
                GroupPlacementMetrics.staffLabelClearanceMm +
                maxCoveringConnectorOffset;
            if (staffReq > maxSystemRequiredIndentMm) {
              maxSystemRequiredIndentMm = staffReq;
            }
          }
        }
      }
    }

    final double leftIndentMm = maxSystemRequiredIndentMm > 0.0
        ? maxSystemRequiredIndentMm + 0.5
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
