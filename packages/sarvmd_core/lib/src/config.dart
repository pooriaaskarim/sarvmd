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

/// Types of vertical connectors joining staves in a system.
enum SystemConnector {
  /// No vertical connector.
  none,

  /// Decorative curly brace (standard for piano, organ, harp).
  brace,

  /// Professional square bracket (standard for instrumental sections).
  bracket;
}

/// Style of barlines drawn through or between staves.
enum BarlineStyle { standard, dashed, none }

/// Represents a single physical staff on the page.
class StaffDefinition {
  const StaffDefinition({
    this.uid = '',
    this.lines = 5,
    this.clef,
    this.scale = 1.0,
    this.instrumentName,
    this.instrumentAbbreviation,
    this.labelVisible = true,
    this.labelHorizontalOffset = 0.0,
    this.labelVerticalOffset = 0.0,
    this.labelFontFamily = 'serif',
    this.labelFontSize = 11.0,
    this.labelItalic = true,
    this.barlineStyle = BarlineStyle.standard,
  });

  final String uid;
  final int lines;
  final ClefConfig? clef;
  final double scale;
  final String? instrumentName;
  final String? instrumentAbbreviation;
  final bool labelVisible;
  final double labelHorizontalOffset;
  final double labelVerticalOffset;
  final String labelFontFamily;
  final double labelFontSize;
  final bool labelItalic;
  final BarlineStyle barlineStyle;

  StaffDefinition copyWith({
    String? uid,
    int? lines,
    ClefConfig? Function()? clef,
    double? scale,
    String? Function()? instrumentName,
    String? Function()? instrumentAbbreviation,
    bool? labelVisible,
    double? labelHorizontalOffset,
    double? labelVerticalOffset,
    String? labelFontFamily,
    double? labelFontSize,
    bool? labelItalic,
    BarlineStyle? barlineStyle,
  }) =>
      StaffDefinition(
        uid: uid ?? this.uid,
        lines: lines ?? this.lines,
        clef: clef != null ? clef() : this.clef,
        scale: scale ?? this.scale,
        instrumentName:
            instrumentName != null ? instrumentName() : this.instrumentName,
        instrumentAbbreviation: instrumentAbbreviation != null
            ? instrumentAbbreviation()
            : this.instrumentAbbreviation,
        labelVisible: labelVisible ?? this.labelVisible,
        labelHorizontalOffset:
            labelHorizontalOffset ?? this.labelHorizontalOffset,
        labelVerticalOffset: labelVerticalOffset ?? this.labelVerticalOffset,
        labelFontFamily: labelFontFamily ?? this.labelFontFamily,
        labelFontSize: labelFontSize ?? this.labelFontSize,
        labelItalic: labelItalic ?? this.labelItalic,
        barlineStyle: barlineStyle ?? this.barlineStyle,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'lines': lines,
        'clef': clef?.toJson(),
        'scale': scale,
        'instrumentName': instrumentName,
        'instrumentAbbreviation': instrumentAbbreviation,
        'labelVisible': labelVisible,
        'labelHorizontalOffset': labelHorizontalOffset,
        'labelVerticalOffset': labelVerticalOffset,
        'labelFontFamily': labelFontFamily,
        'labelFontSize': labelFontSize,
        'labelItalic': labelItalic,
        'barlineStyle': barlineStyle.name,
      };

  factory StaffDefinition.fromJson(Map<String, dynamic> json) =>
      StaffDefinition(
        uid: json['uid'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        lines: json['lines'] as int? ?? 5,
        clef: json['clef'] != null
            ? ClefConfig.fromJson(json['clef'] as Map<String, dynamic>)
            : null,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        instrumentName: json['instrumentName'] as String?,
        instrumentAbbreviation: json['instrumentAbbreviation'] as String?,
        labelVisible: json['labelVisible'] as bool? ?? true,
        labelHorizontalOffset:
            (json['labelHorizontalOffset'] as num?)?.toDouble() ?? 0.0,
        labelVerticalOffset:
            (json['labelVerticalOffset'] as num?)?.toDouble() ?? 0.0,
        labelFontFamily: json['labelFontFamily'] as String? ?? 'serif',
        labelFontSize: (json['labelFontSize'] as num?)?.toDouble() ?? 11.0,
        labelItalic: json['labelItalic'] as bool? ?? true,
        barlineStyle: json['barlineStyle'] != null
            ? BarlineStyle.values.byName(json['barlineStyle'] as String)
            : BarlineStyle.standard,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffDefinition &&
          runtimeType == other.runtimeType &&
          lines == other.lines &&
          clef == other.clef &&
          scale == other.scale &&
          instrumentName == other.instrumentName &&
          instrumentAbbreviation == other.instrumentAbbreviation &&
          labelVisible == other.labelVisible &&
          labelHorizontalOffset == other.labelHorizontalOffset &&
          labelVerticalOffset == other.labelVerticalOffset &&
          labelFontFamily == other.labelFontFamily &&
          labelFontSize == other.labelFontSize &&
          labelItalic == other.labelItalic &&
          barlineStyle == other.barlineStyle;

  @override
  int get hashCode =>
      uid.hashCode ^
      lines.hashCode ^
      clef.hashCode ^
      scale.hashCode ^
      instrumentName.hashCode ^
      instrumentAbbreviation.hashCode ^
      labelVisible.hashCode ^
      labelHorizontalOffset.hashCode ^
      labelVerticalOffset.hashCode ^
      labelFontFamily.hashCode ^
      labelFontSize.hashCode ^
      labelItalic.hashCode ^
      barlineStyle.hashCode;
}

/// A hierarchical grouping of staves.
class StaffGroup {
  const StaffGroup({
    this.connector = SystemConnector.none,
    this.children = const [],
    this.continuousBarlines = true,
  });

  final SystemConnector connector;

  /// Can be StaffDefinition or StaffGroup
  final List<Object> children;
  final bool continuousBarlines;

  StaffGroup copyWith({
    SystemConnector? connector,
    List<Object>? children,
    bool? continuousBarlines,
  }) =>
      StaffGroup(
        connector: connector ?? this.connector,
        children: children ?? this.children,
        continuousBarlines: continuousBarlines ?? this.continuousBarlines,
      );

  Map<String, dynamic> toJson() => {
        'connector': connector.name,
        'children': children.map((c) {
          if (c is StaffDefinition)
            return {'type': 'staff', 'data': c.toJson()};
          if (c is StaffGroup) return {'type': 'group', 'data': c.toJson()};
          throw Exception('Unknown child type in StaffGroup');
        }).toList(),
        'continuousBarlines': continuousBarlines,
      };

  factory StaffGroup.fromJson(Map<String, dynamic> json) => StaffGroup(
        connector: SystemConnector.values
            .byName(json['connector'] as String? ?? 'none'),
        children: (json['children'] as List<dynamic>? ?? []).map((c) {
          final map = c as Map<String, dynamic>;
          final type = map['type'] as String;
          final data = map['data'] as Map<String, dynamic>;
          if (type == 'staff') return StaffDefinition.fromJson(data);
          if (type == 'group') return StaffGroup.fromJson(data);
          throw Exception('Unknown child type in StaffGroup JSON');
        }).toList(),
        continuousBarlines: json['continuousBarlines'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaffGroup ||
        runtimeType != other.runtimeType ||
        connector != other.connector ||
        continuousBarlines != other.continuousBarlines ||
        children.length != other.children.length) {
      return false;
    }
    for (int i = 0; i < children.length; i++) {
      if (children[i] != other.children[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      connector.hashCode ^ children.hashCode ^ continuousBarlines.hashCode;
}

/// The new core layout defining the system hierarchy.
class SystemLayout {
  const SystemLayout({
    this.rootGroup = const StaffGroup(),
  });

  final StaffGroup rootGroup;

  SystemLayout copyWith({
    StaffGroup? rootGroup,
  }) =>
      SystemLayout(
        rootGroup: rootGroup ?? this.rootGroup,
      );

  Map<String, dynamic> toJson() => {
        'rootGroup': rootGroup.toJson(),
      };

  factory SystemLayout.fromJson(Map<String, dynamic> json) => SystemLayout(
        rootGroup: json['rootGroup'] != null
            ? StaffGroup.fromJson(json['rootGroup'] as Map<String, dynamic>)
            : const StaffGroup(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemLayout &&
          runtimeType == other.runtimeType &&
          rootGroup == other.rootGroup;

  @override
  int get hashCode => rootGroup.hashCode;
}

/// The type of clef symbol.
enum ClefSymbol {
  /// Treble clef (G clef)
  g('G',
      displayName: 'Treble',
      requiresFixedLines: true,
      defaultLines: 5,
      supportsAnchorOffset: true),

  /// Alto/Tenor clef (C clef)
  c('C',
      displayName: 'Alto',
      requiresFixedLines: true,
      defaultLines: 5,
      supportsAnchorOffset: true),

  /// Bass clef (F clef)
  f('F',
      displayName: 'Bass',
      requiresFixedLines: true,
      defaultLines: 5,
      supportsAnchorOffset: true),

  /// Guitar Tablature
  tab('TAB',
      displayName: 'TAB',
      requiresFixedLines: false,
      defaultLines: 6,
      supportsAnchorOffset: false),

  /// Percussion staff (thick double bar)
  percussion('PERC',
      displayName: 'Percussion',
      requiresFixedLines: false,
      defaultLines: 1,
      supportsAnchorOffset: false);

  const ClefSymbol(
    this.label, {
    required this.displayName,
    required this.requiresFixedLines,
    required this.defaultLines,
    required this.supportsAnchorOffset,
  });

  /// The character/identifier for the clef.
  final String label;

  /// The human-readable name of the clef.
  final String displayName;

  /// Whether this clef strictly requires a set number of lines (e.g., standard pitched clefs).
  final bool requiresFixedLines;

  /// The standard default number of lines for this clef.
  final int defaultLines;

  /// Whether the anchor line can be shifted (e.g., C clef moving between Alto and Tenor).
  final bool supportsAnchorOffset;
}

/// A clef anchored to a specific line on a staff.
class ClefConfig {
  const ClefConfig({required this.symbol, required this.anchorLine});

  /// The symbol character.
  final ClefSymbol symbol;

  /// The anchor line (1-indexed from bottom).
  final int anchorLine;

  Map<String, dynamic> toJson() => {
        'symbol': symbol.name,
        'anchorLine': anchorLine,
      };

  factory ClefConfig.fromJson(Map<String, dynamic> json) => ClefConfig(
        symbol: ClefSymbol.values.byName(json['symbol'] as String),
        anchorLine: json['anchorLine'] as int,
      );

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

  /// Human-readable label.
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';

  /// Total height of a five-line staff (4 × lineGapMm) in mm.
  double get staffHeightMm => lineGapMm * 4;

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

  Map<String, dynamic> toJson() => {
        'lineThicknessPt': lineThicknessPt,
        'lineGapMm': lineGapMm,
        'systemGapMm': systemGapMm,
        'interStaffGapMm': interStaffGapMm,
      };

  factory StaffConfig.fromJson(Map<String, dynamic> json) => StaffConfig(
        lineThicknessPt: (json['lineThicknessPt'] as num?)?.toDouble() ?? 0.4,
        lineGapMm: (json['lineGapMm'] as num?)?.toDouble() ?? 1.80,
        systemGapMm: (json['systemGapMm'] as num?)?.toDouble() ?? 15.0,
        interStaffGapMm: (json['interStaffGapMm'] as num?)?.toDouble() ?? 8.0,
      );

  /// Returns the height of a staff with [lines] in mm.
  double height(int lines) => lines > 0 ? (lines - 1) * lineGapMm : 0;

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

  Map<String, dynamic> toJson() => {
        'top': top,
        'bottom': bottom,
        'left': left,
        'right': right,
      };

  factory Margins.fromJson(Map<String, dynamic> json) => Margins(
        top: (json['top'] as num?)?.toDouble() ?? 15.0,
        bottom: (json['bottom'] as num?)?.toDouble() ?? 15.0,
        left: (json['left'] as num?)?.toDouble() ?? 15.0,
        right: (json['right'] as num?)?.toDouble() ?? 15.0,
      );

  Margins copyWith({
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) =>
      Margins(
        top: top ?? this.top,
        bottom: bottom ?? this.bottom,
        left: left ?? this.left,
        right: right ?? this.right,
      );
}

/// Complete page configuration combining size, layout, staff, and margins.
class PageConfig {
  const PageConfig({
    this.pageSize = PageSize.a4,
    this.orientation = PageOrientation.portrait,
    this.staffConfig = const StaffConfig(),
    this.margins = const Margins(),
    this.systemLayout = const SystemLayout(
      rootGroup: StaffGroup(
        connector: SystemConnector.none,
        children: [
          StaffDefinition(lines: 5),
        ],
      ),
    ),
  });

  final PageSize pageSize;
  final PageOrientation orientation;
  final StaffConfig staffConfig;
  final Margins margins;

  /// The hierarchical definition of the staves on this page.
  final SystemLayout systemLayout;

  PageConfig copyWith({
    PageSize? pageSize,
    PageOrientation? orientation,
    StaffConfig? staffConfig,
    Margins? margins,
    SystemLayout? systemLayout,
  }) =>
      PageConfig(
        pageSize: pageSize ?? this.pageSize,
        orientation: orientation ?? this.orientation,
        staffConfig: staffConfig ?? this.staffConfig,
        margins: margins ?? this.margins,
        systemLayout: systemLayout ?? this.systemLayout,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageConfig &&
          runtimeType == other.runtimeType &&
          pageSize == other.pageSize &&
          orientation == other.orientation &&
          staffConfig == other.staffConfig &&
          margins == other.margins &&
          systemLayout == other.systemLayout;

  @override
  int get hashCode =>
      pageSize.hashCode ^
      orientation.hashCode ^
      staffConfig.hashCode ^
      margins.hashCode ^
      systemLayout.hashCode;

  /// The width of the page in mm, accounting for orientation.
  double get effectiveWidth => orientation == PageOrientation.portrait
      ? pageSize.width
      : pageSize.height;

  /// The height of the page in mm, accounting for orientation.
  double get effectiveHeight => orientation == PageOrientation.portrait
      ? pageSize.height
      : pageSize.width;

  /// Usable width after subtracting margins, in mm.
  double get usableWidth => effectiveWidth - margins.left - margins.right;

  /// Usable height after subtracting margins, in mm.
  double get usableHeight => effectiveHeight - margins.top - margins.bottom;

  /// Total number of staves in the layout.
  int get staffCount {
    int countStaves(StaffGroup group) {
      int count = 0;
      for (final child in group.children) {
        if (child is StaffDefinition)
          count++;
        else if (child is StaffGroup) count += countStaves(child);
      }
      return count;
    }

    return countStaves(systemLayout.rootGroup);
  }

  /// Height of one complete system in mm, traversing the layout tree.
  double get systemHeight {
    double totalHeight = 0;
    int stavesFound = 0;

    void traverse(StaffGroup group) {
      for (final child in group.children) {
        if (child is StaffDefinition) {
          totalHeight += staffConfig.height(child.lines) * child.scale;
          stavesFound++;
        } else if (child is StaffGroup) {
          traverse(child);
        }
      }
    }

    traverse(systemLayout.rootGroup);

    if (stavesFound > 1) {
      totalHeight += (stavesFound - 1) * staffConfig.interStaffGapMm;
    }
    return totalHeight;
  }

  Map<String, dynamic> toJson() => {
        'pageSize': pageSize.name,
        'orientation': orientation.name,
        'staffConfig': staffConfig.toJson(),
        'margins': margins.toJson(),
        'systemLayout': systemLayout.toJson(),
      };

  factory PageConfig.fromJson(Map<String, dynamic> json) => PageConfig(
        pageSize: PageSize.values.byName(json['pageSize'] as String? ?? 'a4'),
        orientation: PageOrientation.values
            .byName(json['orientation'] as String? ?? 'portrait'),
        staffConfig: json['staffConfig'] != null
            ? StaffConfig.fromJson(json['staffConfig'] as Map<String, dynamic>)
            : const StaffConfig(),
        margins: json['margins'] != null
            ? Margins.fromJson(json['margins'] as Map<String, dynamic>)
            : const Margins(),
        systemLayout: json['systemLayout'] != null
            ? SystemLayout.fromJson(
                json['systemLayout'] as Map<String, dynamic>)
            : const SystemLayout(),
      );
}
