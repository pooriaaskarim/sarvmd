/// Layout engine — computes the vertical positions of all staves on a page.

import 'config.dart';

/// A single 5-line staff with its Y-coordinate (top line) in mm from page top.
class StaffPosition {
  const StaffPosition({required this.topY});

  /// Y-coordinate of the topmost line of this staff, measured from page top
  /// edge in mm.
  final double topY;
}

/// A system is one group of staves: one staff for standard, two for piano.
class StaffSystem {
  const StaffSystem({required this.staves});

  /// The staves in this system (1 for standard, 2 for piano — treble first).
  final List<StaffPosition> staves;

  /// Y of the topmost line of the topmost staff.
  double get topY => staves.first.topY;

  /// Y of the bottommost line of the bottommost staff.
  double bottomY(StaffConfig config) =>
      staves.last.topY + config.staffHeightMm;
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
  // First system takes systemH, each additional takes systemH + gap.
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
  for (var i = 0; i < count; i++) {
    final systemTopY = config.margins.top + i * (systemH + adjustedGap);

    final staves = <StaffPosition>[];
    switch (config.layoutType) {
      case LayoutType.singleLine:
        staves.add(StaffPosition(topY: systemTopY));
      case LayoutType.doubleLine:
        // Treble staff (top).
        staves.add(StaffPosition(topY: systemTopY));
        // Bass staff (below treble + inter-staff gap).
        final bassTopY = systemTopY +
            config.staffConfig.staffHeightMm +
            config.staffConfig.interStaffGapMm;
        staves.add(StaffPosition(topY: bassTopY));
    }

    systems.add(StaffSystem(staves: staves));
  }

  return PageLayout(config: config, systems: systems);
}
