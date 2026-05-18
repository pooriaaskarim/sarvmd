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
}

/// A system is one group of staves on the page.
class StaffSystem {
  const StaffSystem({
    required this.staves,
    this.groupPlacements = const [],
  });

  /// The physical positioning of all staves in this system.
  final List<StaffPosition> staves;

  /// Hierarchical grouping information for connectors and barlines.
  final List<GroupPlacement> groupPlacements;

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

    void traverse(StaffGroup group, int level) {
      final startIdx = staves.length;

      for (final child in group.children) {
        if (child is StaffDefinition) {
          final sStaff = StaffPosition(
            topY: currentTopY,
            lines: child.lines,
            lineGapMm: lineGap,
            scale: child.scale,
            definition: child,
          );
          staves.add(sStaff);
          currentTopY += sStaff.height + config.staffConfig.interStaffGapMm;
        } else if (child is StaffGroup) {
          traverse(child, level + 1);
        }
      }

      final endIdx = staves.length - 1;
      if (endIdx >= startIdx) {
        placements.add(GroupPlacement(
          startStaffIdx: startIdx,
          endStaffIdx: endIdx,
          connector: group.connector,
          continuousBarlines: group.continuousBarlines,
          level: level,
        ));
      }
    }

    traverse(config.systemLayout.rootGroup, 0);
    systems.add(StaffSystem(staves: staves, groupPlacements: placements));
  }

  return PageLayout(config: config, systems: systems);
}
