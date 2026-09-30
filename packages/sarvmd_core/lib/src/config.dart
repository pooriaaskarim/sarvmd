/// Configuration models for Sarv manuscript paper generation.

import 'engraving_config.dart';
import 'domain/clef.dart';

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
  bracket,

  /// Secondary thin bracket for inner instrument-pair groupings
  /// (e.g. Violin I + Violin II within a larger Strings bracket).
  subBracket;
}

/// Style of barlines drawn through or between staves.
enum BarlineStyle { standard, dashed, none }

/// Placement of a group label relative to the score system.
enum GroupLabelPlacement {
  /// Standard engraving: vertically centered in the left margin outside bracket(s).
  margin,

  /// MOLA / Modern orchestral score: placed as a bold section header above the topmost staff of the group.
  aboveStaff;

  String get label => switch (this) {
        GroupLabelPlacement.margin => 'Margin (Left)',
        GroupLabelPlacement.aboveStaff => 'Above Staff (Header)',
      };
}

/// Automatic numbering scheme for child staves within a group.
enum GroupNumberingStyle {
  /// No automatic numbering; uses explicit staff instrument names.
  none,

  /// Inner staves automatically numbered with Arabic numerals (1, 2, 3, ...).
  arabic,

  /// Inner staves automatically numbered with Roman numerals (I, II, III, IV, ...).
  roman;

  String get label => switch (this) {
        GroupNumberingStyle.none => 'None',
        GroupNumberingStyle.arabic => 'Arabic (1, 2)',
        GroupNumberingStyle.roman => 'Roman (I, II)',
      };
}

/// Formats a 0-based staff index inside a group according to [style].
String formatGroupStaffNumber(int index, GroupNumberingStyle style) {
  final num = index + 1;
  return switch (style) {
    GroupNumberingStyle.none => '',
    GroupNumberingStyle.arabic => '$num',
    GroupNumberingStyle.roman => toRomanNumeral(num),
  };
}

/// Converts a positive integer [number] to Roman numerals (e.g. 1 -> I, 4 -> IV).
String toRomanNumeral(int number) {
  if (number <= 0) return '$number';
  const romanLookup = [
    (1000, 'M'),
    (900, 'CM'),
    (500, 'D'),
    (400, 'CD'),
    (100, 'C'),
    (90, 'XC'),
    (50, 'L'),
    (40, 'XL'),
    (10, 'X'),
    (9, 'IX'),
    (5, 'V'),
    (4, 'IV'),
    (1, 'I'),
  ];
  var result = '';
  var rem = number;
  for (final pair in romanLookup) {
    while (rem >= pair.$1) {
      result += pair.$2;
      rem -= pair.$1;
    }
  }
  return result;
}

/// Placement of inner staff descriptors relative to the group's system connector.
enum DescriptorPlacement {
  /// Anglo-American style (Gould/Boosey & Hawkes):
  /// Connector displaced outward; descriptors sit between connector and barline.
  enclosedByConnector,

  /// Continental European style (Bärenreiter/Breitkopf/Henle):
  /// Connector flush at barline; descriptors sit left of connector (outer zone).
  outsideConnector;

  String get label => switch (this) {
        DescriptorPlacement.enclosedByConnector =>
          'Enclosed by Connector (Anglo-American)',
        DescriptorPlacement.outsideConnector =>
          'Outside Connector (Continental)',
      };
}

/// Controls lifecycle visibility for section headers positioned above staves (Model C).
enum GroupHeaderVisibility {
  /// Shown only on the first system of the score (Gould / MOLA default).
  firstSystemOnly,

  /// Shown on the first system of each page (Bärenreiter / classical house style).
  firstSystemOfPage,

  /// Shown on every system.
  always;

  String get label => switch (this) {
        GroupHeaderVisibility.firstSystemOnly => 'First System Only',
        GroupHeaderVisibility.firstSystemOfPage => 'Top of Each Page',
        GroupHeaderVisibility.always => 'Every System',
      };

  String get description => switch (this) {
        GroupHeaderVisibility.firstSystemOnly =>
          'Renders section header once at the start of the score (Gould/MOLA standard).',
        GroupHeaderVisibility.firstSystemOfPage =>
          'Renders section header at the top of every page (Bärenreiter standard).',
        GroupHeaderVisibility.always =>
          'Renders section header above staves on all systems.',
      };
}

/// Monotonically increasing counter ensuring distinct fallback UIDs in single-microsecond executions.
int _uidSequenceCounter = 0;

/// Sealed base class representing a node in the staff layout hierarchy tree.
sealed class StaffNode {
  const StaffNode();

  /// Stamps every [StaffDefinition] in this subtree with a unique UID.
  StaffNode assignUids({int Function()? counter});

  /// Ensures every [StaffDefinition] in this subtree has a unique non-empty UID,
  /// preserving existing valid unique UIDs and only generating fresh ones for empty or duplicate entries.
  StaffNode ensureUniqueUids({Set<String>? seenUids, int Function()? counter});

  /// Returns true if this node structurally matches [other], ignoring transient identifiers like [uid].
  bool matchesStructure(StaffNode other);

  /// Returns true if this node has identical musical and configuration content to [other],
  /// ignoring transient identifiers like [uid].
  bool hasSameContent(StaffNode other);

  Map<String, dynamic> toJson();

  factory StaffNode.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'] != null && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    if (type == 'staff' || type == 'leaf' || json.containsKey('lines') || data.containsKey('lines')) {
      return StaffDefinition.fromJson(data);
    }
    if (type == 'group' || json.containsKey('connector') || json.containsKey('children') || data.containsKey('children')) {
      return StaffNodeGroup.fromJson(data);
    }
    throw FormatException('Unknown StaffNode JSON structure: $json');
  }
}

/// Typographic and positional styling for staff instrument labels.
class StaffLabelStyle {
  const StaffLabelStyle({
    this.fontFamily = 'serif',
    this.fontSizePt = 11.0,
    this.isItalic = true,
    this.isBold = false,
    this.horizontalOffsetMm = 0.0,
    this.verticalOffsetMm = 0.0,
  });

  /// Font family (e.g. 'serif', 'Noto Serif', 'Roboto').
  final String fontFamily;

  /// Font size in typographic points (pt).
  final double fontSizePt;

  /// Whether text is styled in italics (classical Gould standard for instrument names).
  final bool isItalic;

  /// Whether text is styled in boldface (e.g. soloist or principal callouts).
  final bool isBold;

  /// Fine-tuning horizontal offset in mm (positive moves right, negative moves left).
  final double horizontalOffsetMm;

  /// Fine-tuning vertical offset in mm (positive moves down, negative moves up).
  final double verticalOffsetMm;

  /// Default classical engraving style (italic serif, 11pt, zero offset).
  static const StaffLabelStyle defaultStaff = StaffLabelStyle();

  /// Upright bold style for featured callouts or auxiliary sections.
  static const StaffLabelStyle boldUpright =
      StaffLabelStyle(isItalic: false, isBold: true);

  StaffLabelStyle copyWith({
    String? fontFamily,
    double? fontSizePt,
    bool? isItalic,
    bool? isBold,
    double? horizontalOffsetMm,
    double? verticalOffsetMm,
  }) =>
      StaffLabelStyle(
        fontFamily: fontFamily ?? this.fontFamily,
        fontSizePt: fontSizePt ?? this.fontSizePt,
        isItalic: isItalic ?? this.isItalic,
        isBold: isBold ?? this.isBold,
        horizontalOffsetMm: horizontalOffsetMm ?? this.horizontalOffsetMm,
        verticalOffsetMm: verticalOffsetMm ?? this.verticalOffsetMm,
      );

  Map<String, dynamic> toJson() => {
        'fontFamily': fontFamily,
        'fontSizePt': fontSizePt,
        'isItalic': isItalic,
        'isBold': isBold,
        'horizontalOffsetMm': horizontalOffsetMm,
        'verticalOffsetMm': verticalOffsetMm,
      };

  factory StaffLabelStyle.fromJson(Map<String, dynamic> json) =>
      StaffLabelStyle(
        fontFamily: json['fontFamily'] as String? ?? 'serif',
        fontSizePt: (json['fontSizePt'] as num?)?.toDouble() ?? 11.0,
        isItalic: json['isItalic'] as bool? ?? true,
        isBold: json['isBold'] as bool? ?? false,
        horizontalOffsetMm:
            (json['horizontalOffsetMm'] as num?)?.toDouble() ?? 0.0,
        verticalOffsetMm:
            (json['verticalOffsetMm'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffLabelStyle &&
          runtimeType == other.runtimeType &&
          fontFamily == other.fontFamily &&
          fontSizePt == other.fontSizePt &&
          isItalic == other.isItalic &&
          isBold == other.isBold &&
          horizontalOffsetMm == other.horizontalOffsetMm &&
          verticalOffsetMm == other.verticalOffsetMm;

  @override
  int get hashCode => Object.hash(
        fontFamily,
        fontSizePt,
        isItalic,
        isBold,
        horizontalOffsetMm,
        verticalOffsetMm,
      );
}

/// Represents a single physical staff leaf node on the page.
class StaffDefinition extends StaffNode {
  const StaffDefinition({
    this.uid = '',
    this.lines = 5,
    this.clef,
    this.scale = 1.0,
    this.instrumentName,
    this.instrumentAbbreviation,
    this.labelVisible = true,
    this.labelStyle = StaffLabelStyle.defaultStaff,
    this.barlineStyle = BarlineStyle.standard,
  });

  final String uid;
  final int lines;
  final Clef? clef;
  final double scale;
  final String? instrumentName;
  final String? instrumentAbbreviation;
  final bool labelVisible;
  final StaffLabelStyle labelStyle;
  final BarlineStyle barlineStyle;

  /// Backward-compatible accessors delegating to [labelStyle]:
  double get labelHorizontalOffset => labelStyle.horizontalOffsetMm;
  double get labelVerticalOffset => labelStyle.verticalOffsetMm;
  String get labelFontFamily => labelStyle.fontFamily;
  double get labelFontSize => labelStyle.fontSizePt;
  bool get labelItalic => labelStyle.isItalic;
  bool get labelBold => labelStyle.isBold;

  StaffDefinition copyWith({
    String? uid,
    int? lines,
    Clef? Function()? clef,
    double? scale,
    String? Function()? instrumentName,
    String? Function()? instrumentAbbreviation,
    bool? labelVisible,
    StaffLabelStyle? labelStyle,
    double? labelHorizontalOffset,
    double? labelVerticalOffset,
    String? labelFontFamily,
    double? labelFontSize,
    bool? labelItalic,
    bool? labelBold,
    BarlineStyle? barlineStyle,
  }) {
    var effectiveStyle = labelStyle ?? this.labelStyle;
    if (labelFontFamily != null ||
        labelFontSize != null ||
        labelItalic != null ||
        labelBold != null ||
        labelHorizontalOffset != null ||
        labelVerticalOffset != null) {
      effectiveStyle = effectiveStyle.copyWith(
        fontFamily: labelFontFamily,
        fontSizePt: labelFontSize,
        isItalic: labelItalic,
        isBold: labelBold,
        horizontalOffsetMm: labelHorizontalOffset,
        verticalOffsetMm: labelVerticalOffset,
      );
    }
    return StaffDefinition(
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
      labelStyle: effectiveStyle,
      barlineStyle: barlineStyle ?? this.barlineStyle,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'lines': lines,
        'clef': clef?.toJson(),
        'scale': scale,
        'instrumentName': instrumentName,
        'instrumentAbbreviation': instrumentAbbreviation,
        'labelVisible': labelVisible,
        'labelStyle': labelStyle.toJson(),
        'labelHorizontalOffset': labelStyle.horizontalOffsetMm,
        'labelVerticalOffset': labelStyle.verticalOffsetMm,
        'labelFontFamily': labelStyle.fontFamily,
        'labelFontSize': labelStyle.fontSizePt,
        'labelItalic': labelStyle.isItalic,
        'barlineStyle': barlineStyle.name,
      };

  factory StaffDefinition.fromJson(Map<String, dynamic> json) {
    final map = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final StaffLabelStyle style;
    if (map['labelStyle'] != null && map['labelStyle'] is Map<String, dynamic>) {
      style =
          StaffLabelStyle.fromJson(map['labelStyle'] as Map<String, dynamic>);
    } else {
      style = StaffLabelStyle(
        fontFamily: map['labelFontFamily'] as String? ?? 'serif',
        fontSizePt: (map['labelFontSize'] as num?)?.toDouble() ?? 11.0,
        isItalic: map['labelItalic'] as bool? ?? true,
        horizontalOffsetMm:
            (map['labelHorizontalOffset'] as num?)?.toDouble() ?? 0.0,
        verticalOffsetMm:
            (map['labelVerticalOffset'] as num?)?.toDouble() ?? 0.0,
      );
    }

    final rawUid = map['uid'] as String?;
    final uid = rawUid ??
        '${DateTime.now().microsecondsSinceEpoch}_${++_uidSequenceCounter}';

    return StaffDefinition(
      uid: uid,
      lines: map['lines'] as int? ?? 5,
      clef: map['clef'] != null
          ? Clef.fromJson(map['clef'] as Map<String, dynamic>)
          : null,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      instrumentName: map['instrumentName'] as String?,
      instrumentAbbreviation: map['instrumentAbbreviation'] as String?,
      labelVisible: map['labelVisible'] as bool? ?? true,
      labelStyle: style,
      barlineStyle: map['barlineStyle'] != null
          ? BarlineStyle.values.byName(map['barlineStyle'] as String)
          : BarlineStyle.standard,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffDefinition &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          lines == other.lines &&
          clef == other.clef &&
          scale == other.scale &&
          instrumentName == other.instrumentName &&
          instrumentAbbreviation == other.instrumentAbbreviation &&
          labelVisible == other.labelVisible &&
          labelStyle == other.labelStyle &&
          barlineStyle == other.barlineStyle;

  @override
  int get hashCode => Object.hash(
        uid,
        lines,
        clef,
        scale,
        instrumentName,
        instrumentAbbreviation,
        labelVisible,
        labelStyle,
        barlineStyle,
      );

  @override
  StaffDefinition assignUids({int Function()? counter}) {
    final nextId = counter != null
        ? '${DateTime.now().microsecondsSinceEpoch}_${counter()}'
        : '${DateTime.now().microsecondsSinceEpoch}_${++_uidSequenceCounter}';
    return copyWith(uid: nextId);
  }

  @override
  StaffDefinition ensureUniqueUids({
    Set<String>? seenUids,
    int Function()? counter,
  }) {
    final seen = seenUids ?? <String>{};
    if (uid.isEmpty || seen.contains(uid)) {
      final nextId = counter != null
          ? '${DateTime.now().microsecondsSinceEpoch}_${counter()}'
          : '${DateTime.now().microsecondsSinceEpoch}_${++_uidSequenceCounter}';
      seen.add(nextId);
      return copyWith(uid: nextId);
    }
    seen.add(uid);
    return this;
  }

  @override
  bool matchesStructure(StaffNode other) {
    if (other is! StaffDefinition) return false;
    return lines == other.lines && clef == other.clef && scale == other.scale;
  }

  @override
  bool hasSameContent(StaffNode other) {
    if (other is! StaffDefinition) return false;
    return lines == other.lines &&
        clef == other.clef &&
        scale == other.scale &&
        instrumentName == other.instrumentName &&
        instrumentAbbreviation == other.instrumentAbbreviation &&
        labelVisible == other.labelVisible &&
        labelStyle == other.labelStyle &&
        barlineStyle == other.barlineStyle;
  }
}

/// A hierarchical grouping of staves in a system layout tree.
class StaffNodeGroup extends StaffNode {
  const StaffNodeGroup({
    this.connector = SystemConnector.none,
    this.children = const [],
    this.continuousBarlines = true,
    this.initialBarline = true,
    this.label = '',
    this.abbreviation = '',
    this.labelVisible = true,
    this.labelPlacement = GroupLabelPlacement.margin,
    this.numberingStyle = GroupNumberingStyle.none,
    this.descriptorPlacement = DescriptorPlacement.enclosedByConnector,
    this.headerVisibility = GroupHeaderVisibility.firstSystemOnly,
  });

  final SystemConnector connector;

  /// Strongly-typed list of child [StaffNode] elements (staves or sub-groups).
  final List<StaffNode> children;
  final bool continuousBarlines;
  final bool initialBarline;
  final String label;
  final String abbreviation;
  final bool labelVisible;
  final GroupLabelPlacement labelPlacement;
  final GroupNumberingStyle numberingStyle;
  final DescriptorPlacement descriptorPlacement;

  /// Lifecycle visibility control for above-staff headers (Model C).
  final GroupHeaderVisibility headerVisibility;

  StaffNodeGroup copyWith({
    SystemConnector? connector,
    List<StaffNode>? children,
    bool? continuousBarlines,
    bool? initialBarline,
    String? label,
    String? abbreviation,
    bool? labelVisible,
    GroupLabelPlacement? labelPlacement,
    GroupNumberingStyle? numberingStyle,
    DescriptorPlacement? descriptorPlacement,
    GroupHeaderVisibility? headerVisibility,
  }) =>
      StaffNodeGroup(
        connector: connector ?? this.connector,
        children: children ?? this.children,
        continuousBarlines: continuousBarlines ?? this.continuousBarlines,
        initialBarline: initialBarline ?? this.initialBarline,
        label: label ?? this.label,
        abbreviation: abbreviation ?? this.abbreviation,
        labelVisible: labelVisible ?? this.labelVisible,
        labelPlacement: labelPlacement ?? this.labelPlacement,
        numberingStyle: numberingStyle ?? this.numberingStyle,
        descriptorPlacement: descriptorPlacement ?? this.descriptorPlacement,
        headerVisibility: headerVisibility ?? this.headerVisibility,
      );

  @override
  Map<String, dynamic> toJson() => {
        'connector': connector.name,
        'children': children.map((c) {
          if (c is StaffDefinition) {
            return {'type': 'staff', 'data': c.toJson()};
          }
          if (c is StaffNodeGroup) {
            return {'type': 'group', 'data': c.toJson()};
          }
          return c.toJson();
        }).toList(),
        'continuousBarlines': continuousBarlines,
        'initialBarline': initialBarline,
        'label': label,
        'abbreviation': abbreviation,
        'labelVisible': labelVisible,
        'labelPlacement': labelPlacement.name,
        'numberingStyle': numberingStyle.name,
        'descriptorPlacement': descriptorPlacement.name,
        'headerVisibility': headerVisibility.name,
      };

  factory StaffNodeGroup.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return StaffNodeGroup(
      connector: SystemConnector.values
          .byName(data['connector'] as String? ?? 'none'),
      children: (data['children'] as List<dynamic>? ?? []).map((c) {
        return StaffNode.fromJson(c as Map<String, dynamic>);
      }).toList(),
      continuousBarlines: data['continuousBarlines'] as bool? ?? true,
      initialBarline: data['initialBarline'] as bool? ?? true,
      label: data['label'] as String? ?? '',
      abbreviation: data['abbreviation'] as String? ?? '',
      labelVisible: data['labelVisible'] as bool? ?? true,
      labelPlacement: data['labelPlacement'] != null
          ? GroupLabelPlacement.values
              .byName(data['labelPlacement'] as String)
          : GroupLabelPlacement.margin,
      numberingStyle: data['numberingStyle'] != null
          ? GroupNumberingStyle.values
              .byName(data['numberingStyle'] as String)
          : GroupNumberingStyle.none,
      descriptorPlacement: data['descriptorPlacement'] != null
          ? DescriptorPlacement.values
              .byName(data['descriptorPlacement'] as String)
          : DescriptorPlacement.enclosedByConnector,
      headerVisibility: data['headerVisibility'] != null
          ? GroupHeaderVisibility.values
              .byName(data['headerVisibility'] as String)
          : GroupHeaderVisibility.firstSystemOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StaffNodeGroup ||
        runtimeType != other.runtimeType ||
        connector != other.connector ||
        continuousBarlines != other.continuousBarlines ||
        initialBarline != other.initialBarline ||
        label != other.label ||
        abbreviation != other.abbreviation ||
        labelVisible != other.labelVisible ||
        labelPlacement != other.labelPlacement ||
        numberingStyle != other.numberingStyle ||
        descriptorPlacement != other.descriptorPlacement ||
        headerVisibility != other.headerVisibility ||
        children.length != other.children.length) {
      return false;
    }
    for (int i = 0; i < children.length; i++) {
      if (children[i] != other.children[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        connector,
        Object.hashAll(children),
        continuousBarlines,
        initialBarline,
        label,
        abbreviation,
        labelVisible,
        labelPlacement,
        numberingStyle,
        descriptorPlacement,
        headerVisibility,
      );

  @override
  StaffNodeGroup assignUids({int Function()? counter}) {
    int local = 0;
    final cnt = counter ?? () => local++;
    return copyWith(
      children: children.map((c) => c.assignUids(counter: cnt)).toList(),
    );
  }

  @override
  StaffNodeGroup ensureUniqueUids({
    Set<String>? seenUids,
    int Function()? counter,
  }) {
    final seen = seenUids ?? <String>{};
    int local = 0;
    final cnt = counter ?? () => local++;
    return copyWith(
      children: children
          .map((c) => c.ensureUniqueUids(seenUids: seen, counter: cnt))
          .toList(),
    );
  }

  @override
  bool matchesStructure(StaffNode other) {
    if (other is! StaffNodeGroup) return false;
    if (connector != other.connector ||
        continuousBarlines != other.continuousBarlines ||
        children.length != other.children.length) {
      return false;
    }
    for (int i = 0; i < children.length; i++) {
      if (!children[i].matchesStructure(other.children[i])) return false;
    }
    return true;
  }

  @override
  bool hasSameContent(StaffNode other) {
    if (other is! StaffNodeGroup) return false;
    if (connector != other.connector ||
        continuousBarlines != other.continuousBarlines ||
        initialBarline != other.initialBarline ||
        label != other.label ||
        abbreviation != other.abbreviation ||
        labelVisible != other.labelVisible ||
        labelPlacement != other.labelPlacement ||
        numberingStyle != other.numberingStyle ||
        descriptorPlacement != other.descriptorPlacement ||
        headerVisibility != other.headerVisibility ||
        children.length != other.children.length) {
      return false;
    }
    for (int i = 0; i < children.length; i++) {
      if (!children[i].hasSameContent(other.children[i])) return false;
    }
    return true;
  }
}

/// Legacy alias for [StaffNodeGroup].
@Deprecated('Use StaffNodeGroup instead')
typedef StaffGroup = StaffNodeGroup;

/// The new core layout defining the system hierarchy.
class SystemLayout {
  const SystemLayout({
    this.rootGroup = const StaffNodeGroup(),
  });

  final StaffNodeGroup rootGroup;

  SystemLayout copyWith({
    StaffNodeGroup? rootGroup,
  }) =>
      SystemLayout(
        rootGroup: rootGroup ?? this.rootGroup,
      );

  Map<String, dynamic> toJson() => {
        'rootGroup': rootGroup.toJson(),
      };

  factory SystemLayout.fromJson(Map<String, dynamic> json) => SystemLayout(
        rootGroup: json['rootGroup'] != null
            ? StaffNodeGroup.fromJson(json['rootGroup'] as Map<String, dynamic>)
            : const StaffNodeGroup(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemLayout &&
          runtimeType == other.runtimeType &&
          rootGroup == other.rootGroup;

  @override
  int get hashCode => rootGroup.hashCode;

  SystemLayout assignUids({int Function()? counter}) =>
      copyWith(rootGroup: rootGroup.assignUids(counter: counter));

  SystemLayout ensureUniqueUids({int Function()? counter}) =>
      copyWith(rootGroup: rootGroup.ensureUniqueUids(counter: counter));

  bool matchesStructure(SystemLayout other) =>
      rootGroup.matchesStructure(other.rootGroup);

  bool hasSameContent(SystemLayout other) =>
      rootGroup.hasSameContent(other.rootGroup);
}

/// Extension providing domain tree manipulation methods on [StaffNodeGroup].
extension StaffNodeGroupTreeX on StaffNodeGroup {
  /// Returns a new [StaffNodeGroup] with the [targetGroup] updated.
  StaffNodeGroup updateGroup(
    StaffNodeGroup targetGroup, {
    SystemConnector? connector,
    bool? continuousBarlines,
    String? label,
    String? abbreviation,
    bool? labelVisible,
    GroupLabelPlacement? labelPlacement,
    GroupNumberingStyle? numberingStyle,
    DescriptorPlacement? descriptorPlacement,
    GroupHeaderVisibility? headerVisibility,
  }) {
    if (identical(this, targetGroup) || hashCode == targetGroup.hashCode) {
      return copyWith(
        connector: connector ?? this.connector,
        continuousBarlines: continuousBarlines ?? this.continuousBarlines,
        label: label ?? this.label,
        abbreviation: abbreviation ?? this.abbreviation,
        labelVisible: labelVisible ?? this.labelVisible,
        labelPlacement: labelPlacement ?? this.labelPlacement,
        numberingStyle: numberingStyle ?? this.numberingStyle,
        descriptorPlacement: descriptorPlacement ?? this.descriptorPlacement,
        headerVisibility: headerVisibility ?? this.headerVisibility,
      );
    }
    return copyWith(
      children: children.map((child) {
        if (child is StaffNodeGroup) {
          return child.updateGroup(
            targetGroup,
            connector: connector,
            continuousBarlines: continuousBarlines,
            label: label,
            abbreviation: abbreviation,
            labelVisible: labelVisible,
            labelPlacement: labelPlacement,
            numberingStyle: numberingStyle,
            descriptorPlacement: descriptorPlacement,
            headerVisibility: headerVisibility,
          );
        }
        return child;
      }).toList(),
    );
  }

  /// Removes [targetGroup] by promoting its children to the parent group.
  StaffNodeGroup ungroup(StaffNodeGroup targetGroup) {
    final newChildren = <StaffNode>[];
    for (final child in children) {
      if (child is StaffNodeGroup) {
        if (identical(child, targetGroup) || child.hashCode == targetGroup.hashCode) {
          newChildren.addAll(child.children);
        } else {
          newChildren.add(child.ungroup(targetGroup));
        }
      } else {
        newChildren.add(child);
      }
    }
    return copyWith(children: newChildren);
  }

  /// Groups consecutive staves/nodes matching [selectedUids] under a new sub-group with [newConnector].
  StaffNodeGroup groupSelected(
    Set<String> selectedUids,
    SystemConnector newConnector,
  ) {
    bool nodeContainsSelected(StaffNode node) {
      return switch (node) {
        StaffDefinition def => selectedUids.contains(def.uid),
        StaffNodeGroup group => group.children.any(nodeContainsSelected),
      };
    }

    final matchingIndices = <int>[];
    for (var i = 0; i < children.length; i++) {
      if (nodeContainsSelected(children[i])) {
        matchingIndices.add(i);
      }
    }

    if (matchingIndices.length >= 2 &&
        matchingIndices.last - matchingIndices.first ==
            matchingIndices.length - 1) {
      final minIdx = matchingIndices.first;
      final maxIdx = matchingIndices.last;

      final subChildren = children.sublist(minIdx, maxIdx + 1);
      final newGroup = StaffNodeGroup(
        connector: newConnector,
        continuousBarlines: true,
        children: subChildren,
      );

      final newChildren = <StaffNode>[
        ...children.sublist(0, minIdx),
        newGroup,
        ...children.sublist(maxIdx + 1),
      ];
      return copyWith(children: newChildren);
    }

    return copyWith(
      children: children.map((child) {
        if (child is StaffNodeGroup) {
          return child.groupSelected(selectedUids, newConnector);
        }
        return child;
      }).toList(),
    );
  }

  /// Returns the maximum depth of nested sub-groups in this subtree (0 if no child groups).
  int get maxSubGroupDepth {
    int maxChild = 0;
    bool hasGroup = false;
    for (final child in children) {
      if (child is StaffNodeGroup) {
        hasGroup = true;
        final d = child.maxSubGroupDepth;
        if (d > maxChild) maxChild = d;
      }
    }
    return hasGroup ? 1 + maxChild : 0;
  }

  /// Finds the nesting depth of the group with [targetHash], where this root is at [currentDepth].
  int? findGroupDepth(int targetHash, [int currentDepth = 0]) {
    if (hashCode == targetHash) return currentDepth;
    for (final child in children) {
      if (child is StaffNodeGroup) {
        final res = child.findGroupDepth(targetHash, currentDepth + 1);
        if (res != null) return res;
      }
    }
    return null;
  }

  /// Finds the nesting depth of the direct parent group containing [staffUid], where this root is at [currentDepth].
  int? findStaffParentDepth(String staffUid, [int currentDepth = 0]) {
    for (final child in children) {
      if (child is StaffDefinition && child.uid == staffUid) {
        return currentDepth;
      } else if (child is StaffNodeGroup) {
        final res = child.findStaffParentDepth(staffUid, currentDepth + 1);
        if (res != null) return res;
      }
    }
    return null;
  }

  /// All descendant child staves flattened across this group and any sub-groups.
  List<StaffDefinition> get allStaves {
    final result = <StaffDefinition>[];
    for (final child in children) {
      if (child is StaffDefinition) {
        result.add(child);
      } else if (child is StaffNodeGroup) {
        result.addAll(child.allStaves);
      }
    }
    return result;
  }

  /// All descendant groups (including self) flattened across this group and sub-groups.
  List<StaffNodeGroup> get allGroups {
    final result = <StaffNodeGroup>[this];
    for (final child in children) {
      if (child is StaffNodeGroup) result.addAll(child.allGroups);
    }
    return result;
  }
}

/// Centralized engraving constants for system connectors and barlines.
abstract final class GroupPlacementMetrics {
  /// Gould and MOLA standard maximum nesting depth for system connectors.
  static const int standardMaxNestingDepth = 2;

  /// Gould and MOLA absolute emergency ceiling for nesting depth (multi-choirs/stage bands).
  /// Nesting beyond this depth (4+) is strictly prohibited by engraving standards.
  static const int emergencyMaxNestingDepth = 3;

  /// Horizontal offset in mm per nesting level for outer system connectors.
  /// (Gould p. 518 standard nested bracket clearance: 3.0 mm)
  static const double connectorLevelSpacingMm = 3.0;

  /// Length of horizontal end ticks for system brackets in mm.
  /// (SMuFL Bravura authentic square bracket tick: 1.8 mm)
  static const double bracketTickLengthMm = 1.8;

  /// System barline stroke thickness multiplier relative to staff line thickness.
  static const double systemBarlineWidthMultiplier = 2.5;

  /// Bracket stroke thickness multiplier relative to staff line thickness.
  static const double bracketWidthMultiplier = 3.0;

  /// Secondary sub-bracket stroke thickness multiplier relative to staff line thickness.
  static const double subBracketWidthMultiplier = 1.8;

  /// Default viewBox height for the SVG brace path asset.
  static const double braceNativeHeightMm = 997.0;

  /// Default horizontal offset for the SVG brace path asset scale anchor.
  static const double braceNativeWidthOffsetMm = 82.0;

  /// Horizontal clearance between staff label and starting barline in mm.
  /// (Gould p. 513 standard whitespace buffer: 2.0 mm)
  static const double staffLabelClearanceMm = 2.0;

  /// Horizontal clearance between the tip of a bracket tick (or connector) and inner staff labels in mm.
  /// (Gould p. 514: 1.5 mm)
  static const double staffLabelConnectorClearanceMm = 1.5;

  /// Horizontal clearance between group label and connector in mm.
  /// (Gould p. 513: 2.0 mm)
  static const double groupLabelClearanceMm = 2.0;

  /// Vertical offset in mm between the topmost staff line and the baseline of an above-staff section header.
  static const double aboveStaffHeaderOffsetMm = 2.5;

  /// Gould and MOLA standard headroom clearance reserved between systems
  /// when section headers (e.g. choir or brass group labels) are placed above staff.
  static const double aboveStaffHeaderClearanceMm = 5.5;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Margins &&
          runtimeType == other.runtimeType &&
          top == other.top &&
          bottom == other.bottom &&
          left == other.left &&
          right == other.right;

  @override
  int get hashCode => Object.hash(top, bottom, left, right);
}

/// Complete page configuration combining size, layout, staff, and margins.
class PageConfig {
  const PageConfig({
    this.pageSize = PageSize.a4,
    this.orientation = PageOrientation.portrait,
    this.staffConfig = const StaffConfig(),
    this.margins = const Margins(),
    this.engraving = EngravingConfig.standard,
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
  final EngravingConfig engraving;

  /// The hierarchical definition of the staves on this page.
  final SystemLayout systemLayout;

  PageConfig copyWith({
    PageSize? pageSize,
    PageOrientation? orientation,
    StaffConfig? staffConfig,
    Margins? margins,
    EngravingConfig? engraving,
    SystemLayout? systemLayout,
  }) =>
      PageConfig(
        pageSize: pageSize ?? this.pageSize,
        orientation: orientation ?? this.orientation,
        staffConfig: staffConfig ?? this.staffConfig,
        margins: margins ?? this.margins,
        engraving: engraving ?? this.engraving,
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
          engraving == other.engraving &&
          systemLayout == other.systemLayout;

  @override
  int get hashCode =>
      pageSize.hashCode ^
      orientation.hashCode ^
      staffConfig.hashCode ^
      margins.hashCode ^
      engraving.hashCode ^
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

  /// All descendant staves across the system layout.
  List<StaffDefinition> get allStaves => systemLayout.rootGroup.allStaves;

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
        'engraving': engraving.toJson(),
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
        engraving: json['engraving'] != null
            ? EngravingConfig.fromJson(json['engraving'] as Map<String, dynamic>)
            : EngravingConfig.standard,
        systemLayout: json['systemLayout'] != null
            ? SystemLayout.fromJson(
                json['systemLayout'] as Map<String, dynamic>)
            : const SystemLayout(),
      );

  PageConfig ensureUniqueUids({int Function()? counter}) =>
      copyWith(systemLayout: systemLayout.ensureUniqueUids(counter: counter));

  /// Checks whether two configs have identical musical and layout content,
  /// ignoring volatile runtime staff UIDs.
  bool hasSameContent(PageConfig other) =>
      identical(this, other) ||
      (pageSize == other.pageSize &&
          orientation == other.orientation &&
          staffConfig == other.staffConfig &&
          margins == other.margins &&
          engraving == other.engraving &&
          systemLayout.hasSameContent(other.systemLayout));
}
