/// Configuration models for Sarv manuscript paper generation.

/// Supported page orientations.
enum PageOrientation {
  portrait,
  landscape;

  String get label => switch (this) {
        PageOrientation.portrait => 'Portrait',
        PageOrientation.landscape => 'Landscape',
      };
}

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
  /// Single 5-line stave.
  singleLine,

  /// Grand staff: paired treble + bass staves joined by barline.
  doubleLine;

  /// Human-readable display label.
  String get label => switch (this) {
    LayoutType.singleLine => 'Single Line',
    LayoutType.doubleLine => 'Double Line',
  };
}

/// The type of clef symbol.
enum ClefSymbol {
  /// Treble clef (G clef)
  g('G'),
  /// Alto/Tenor clef (C clef)
  c('C'),
  /// Bass clef (F clef)
  f('F');

  const ClefSymbol(this.label);
  final String label;
}

/// A clef anchored to a specific line on a staff.
class ClefConfig {
  const ClefConfig({required this.symbol, required this.anchorLine});

  /// The symbol character.
  final ClefSymbol symbol;

  /// The anchor line (1 to 5, where 1 is the bottom line).
  final int anchorLine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClefConfig &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          anchorLine == other.anchorLine;

  @override
  int get hashCode => symbol.hashCode ^ anchorLine.hashCode;
}

/// Pragmatic staff size presets based on engraving standards and handwriting
/// legibility research. Sizes are named for their practical use case rather
/// than the abstract Rastral numbering system.
enum StaffSizePreset {
  /// 12.0 mm staff (3.0 mm gap). For children's education and classrooms.
  jumbo(lineGapMm: 3.00),

  /// 8.5 mm staff (2.125 mm gap). Standard for orchestral performance parts.
  large(lineGapMm: 2.125),

  /// 7.2 mm staff (1.8 mm gap). Professional default — piano, solo, sketching.
  medium(lineGapMm: 1.80),

  /// 5.8 mm staff (1.45 mm gap). Dense scores. Lower practical limit for
  /// handwriting; below this, fine details become difficult to notate.
  small(lineGapMm: 1.45);

  const StaffSizePreset({required this.lineGapMm});

  /// The canonical line-gap value for this preset in mm.
  final double lineGapMm;

  /// Total height of a five-line staff (4 × lineGapMm) in mm.
  double get staffHeightMm => lineGapMm * 4;

  /// Human-readable label.
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';

  /// Finds the identifying preset for a given [lineGapMm] based on pragmatic
  /// height ranges. This ensures the UI remains contextually aware even if
  /// values are adjusted slightly from their canonical defaults.
  static StaffSizePreset? fromLineGap(double mm) {
    final h = mm * 4; // Total staff height

    if (h >= 9.5) return jumbo;
    if (h >= 8.0) return large;
    if (h >= 6.8) return medium;
    if (h >= 5.4) return small;
    
    return null; // Below practical handwriting limit
  }
}

/// Dimensional configuration for staff drawing.
class StaffConfig {
  const StaffConfig({
    this.lineThicknessPt = 0.4,
    this.lineGapMm = 1.80,
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
  /// Only relevant for [LayoutType.doubleLine].
  final double interStaffGapMm;

  /// Height of a single 5-line staff in mm.
  /// 4 gaps between 5 lines.
  double get staffHeightMm => lineGapMm * 4;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffConfig &&
          runtimeType == other.runtimeType &&
          lineThicknessPt == other.lineThicknessPt &&
          lineGapMm == other.lineGapMm &&
          systemGapMm == other.systemGapMm &&
          interStaffGapMm == other.interStaffGapMm;

  @override
  int get hashCode =>
      lineThicknessPt.hashCode ^
      lineGapMm.hashCode ^
      systemGapMm.hashCode ^
      interStaffGapMm.hashCode;
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
    this.orientation = PageOrientation.portrait,
    this.layoutType = LayoutType.singleLine,
    this.staffConfig = const StaffConfig(),
    this.margins = const Margins(),
    this.primaryClef,
    this.secondaryClef,
  });

  final PageSize pageSize;
  final PageOrientation orientation;
  final LayoutType layoutType;
  final StaffConfig staffConfig;
  final Margins margins;

  /// The clef to display on standard layouts, or the upper staff of piano layouts.
  final ClefConfig? primaryClef;

  /// The clef to display on the lower staff of piano layouts.
  final ClefConfig? secondaryClef;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageConfig &&
          runtimeType == other.runtimeType &&
          pageSize == other.pageSize &&
          orientation == other.orientation &&
          layoutType == other.layoutType &&
          staffConfig == other.staffConfig &&
          margins == other.margins &&
          primaryClef == other.primaryClef &&
          secondaryClef == other.secondaryClef;

  @override
  int get hashCode =>
      pageSize.hashCode ^
      orientation.hashCode ^
      layoutType.hashCode ^
      staffConfig.hashCode ^
      margins.hashCode ^
      primaryClef.hashCode ^
      secondaryClef.hashCode;

  /// The width of the page in mm, accounting for orientation.
  double get effectiveWidth =>
      orientation == PageOrientation.portrait ? pageSize.width : pageSize.height;

  /// The height of the page in mm, accounting for orientation.
  double get effectiveHeight =>
      orientation == PageOrientation.portrait ? pageSize.height : pageSize.width;

  /// Usable width after subtracting margins, in mm.
  double get usableWidth => effectiveWidth - margins.left - margins.right;

  /// Usable height after subtracting margins, in mm.
  double get usableHeight => effectiveHeight - margins.top - margins.bottom;

  /// Height of one complete system in mm, depending on layout type.
  double get systemHeight {
    final singleStaff = staffConfig.staffHeightMm;
    return switch (layoutType) {
      LayoutType.singleLine => singleStaff,
      LayoutType.doubleLine =>
        singleStaff * 2 + staffConfig.interStaffGapMm,
    };
  }
}
