/// Configuration models for Sarv manuscript paper generation.

/// Supported paper sizes with dimensions in millimeters.
enum PageSize {
  a3(width: 297.0, height: 420.0),
  a4(width: 210.0, height: 297.0),
  a5(width: 148.0, height: 210.0),
  b4(width: 250.0, height: 353.0),
  b5(width: 176.0, height: 250.0),
  letter(width: 215.9, height: 279.4);

  const PageSize({required this.width, required this.height});

  /// Width in mm.
  final double width;

  /// Height in mm.
  final double height;
}

/// Layout types for manuscript paper.
enum LayoutType {
  /// Single 5-line staves.
  standard,

  /// Grand staff: paired treble + bass staves joined by brace.
  piano,
}

/// Dimensional configuration for staff drawing.
class StaffConfig {
  const StaffConfig({
    this.lineThicknessPt = 0.4,
    this.lineGapMm = 2.5,
    this.systemGapMm = 15.0,
    this.interStaffGapMm = 8.0,
  });

  /// Thickness of each staff line in points (1pt = 0.3528mm).
  final double lineThicknessPt;

  /// Vertical gap between adjacent staff lines in mm.
  final double lineGapMm;

  /// Vertical gap between systems (system = one group of staves) in mm.
  final double systemGapMm;

  /// Gap between treble and bass staves within a piano system, in mm.
  /// Only relevant for [LayoutType.piano].
  final double interStaffGapMm;

  /// Height of a single 5-line staff in mm.
  /// 4 gaps between 5 lines.
  double get staffHeightMm => lineGapMm * 4;
}

/// Page margin configuration in mm.
class Margins {
  const Margins({
    this.top = 15.0,
    this.bottom = 15.0,
    this.left = 15.0,
    this.right = 15.0,
  });

  final double top;
  final double bottom;
  final double left;
  final double right;
}

/// Complete page configuration combining size, layout, staff, and margins.
class PageConfig {
  const PageConfig({
    this.pageSize = PageSize.a4,
    this.layoutType = LayoutType.standard,
    this.staffConfig = const StaffConfig(),
    this.margins = const Margins(),
  });

  final PageSize pageSize;
  final LayoutType layoutType;
  final StaffConfig staffConfig;
  final Margins margins;

  /// Usable width after subtracting margins, in mm.
  double get usableWidth => pageSize.width - margins.left - margins.right;

  /// Usable height after subtracting margins, in mm.
  double get usableHeight => pageSize.height - margins.top - margins.bottom;

  /// Height of one complete system in mm, depending on layout type.
  double get systemHeight {
    final singleStaff = staffConfig.staffHeightMm;
    return switch (layoutType) {
      LayoutType.standard => singleStaff,
      LayoutType.piano =>
        singleStaff * 2 + staffConfig.interStaffGapMm,
    };
  }
}
