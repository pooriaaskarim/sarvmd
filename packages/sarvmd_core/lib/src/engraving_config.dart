// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Configuration for standard proportional spacing constants in engraving.
class EngravingConfig {
  /// The distance from the start of a system barline to the first clef, in staff spaces.
  final double initialClefClearanceSp;

  /// The distance between the clef and the key signature, in staff spaces.
  final double clefToKeySignatureSp;

  /// The distance between the key signature and the time signature, in staff spaces.
  final double keySignatureToTimeSignatureSp;

  /// Horizontal spacing multiplier between accidentals in a key signature.
  final double keySignatureAccidentalSpacingSp;

  /// The width of a heavy barline (e.g., final barline), in staff spaces.
  final double heavyBarlineWidthSp;

  /// The distance a single barline overhangs a 1-line percussion staff, in staff spaces.
  final double singleLineStaffBarlineOverhangSp;

  /// Scaling factor applied to standard SMuFL glyphs.
  final double smuflGlyphScale;

  const EngravingConfig({
    this.initialClefClearanceSp = 0.5,
    this.clefToKeySignatureSp = 1.0,
    this.keySignatureToTimeSignatureSp = 1.0,
    this.keySignatureAccidentalSpacingSp = 0.8,
    this.heavyBarlineWidthSp = 0.35,
    this.singleLineStaffBarlineOverhangSp = 0.8,
    this.smuflGlyphScale = 0.0035,
  });

  /// The standard engraving configuration (Gould standard).
  static const standard = EngravingConfig();

  EngravingConfig copyWith({
    double? initialClefClearanceSp,
    double? clefToKeySignatureSp,
    double? keySignatureToTimeSignatureSp,
    double? keySignatureAccidentalSpacingSp,
    double? heavyBarlineWidthSp,
    double? singleLineStaffBarlineOverhangSp,
    double? smuflGlyphScale,
  }) =>
      EngravingConfig(
        initialClefClearanceSp: initialClefClearanceSp ?? this.initialClefClearanceSp,
        clefToKeySignatureSp: clefToKeySignatureSp ?? this.clefToKeySignatureSp,
        keySignatureToTimeSignatureSp: keySignatureToTimeSignatureSp ?? this.keySignatureToTimeSignatureSp,
        keySignatureAccidentalSpacingSp: keySignatureAccidentalSpacingSp ?? this.keySignatureAccidentalSpacingSp,
        heavyBarlineWidthSp: heavyBarlineWidthSp ?? this.heavyBarlineWidthSp,
        singleLineStaffBarlineOverhangSp: singleLineStaffBarlineOverhangSp ?? this.singleLineStaffBarlineOverhangSp,
        smuflGlyphScale: smuflGlyphScale ?? this.smuflGlyphScale,
      );

  Map<String, dynamic> toJson() => {
        'initialClefClearanceSp': initialClefClearanceSp,
        'clefToKeySignatureSp': clefToKeySignatureSp,
        'keySignatureToTimeSignatureSp': keySignatureToTimeSignatureSp,
        'keySignatureAccidentalSpacingSp': keySignatureAccidentalSpacingSp,
        'heavyBarlineWidthSp': heavyBarlineWidthSp,
        'singleLineStaffBarlineOverhangSp': singleLineStaffBarlineOverhangSp,
        'smuflGlyphScale': smuflGlyphScale,
      };

  factory EngravingConfig.fromJson(Map<String, dynamic> json) => EngravingConfig(
        initialClefClearanceSp: (json['initialClefClearanceSp'] as num?)?.toDouble() ?? 0.5,
        clefToKeySignatureSp: (json['clefToKeySignatureSp'] as num?)?.toDouble() ?? 1.0,
        keySignatureToTimeSignatureSp: (json['keySignatureToTimeSignatureSp'] as num?)?.toDouble() ?? 1.0,
        keySignatureAccidentalSpacingSp: (json['keySignatureAccidentalSpacingSp'] as num?)?.toDouble() ?? 0.8,
        heavyBarlineWidthSp: (json['heavyBarlineWidthSp'] as num?)?.toDouble() ?? 0.35,
        singleLineStaffBarlineOverhangSp: (json['singleLineStaffBarlineOverhangSp'] as num?)?.toDouble() ?? 0.8,
        smuflGlyphScale: (json['smuflGlyphScale'] as num?)?.toDouble() ?? 0.0035,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngravingConfig &&
          runtimeType == other.runtimeType &&
          initialClefClearanceSp == other.initialClefClearanceSp &&
          clefToKeySignatureSp == other.clefToKeySignatureSp &&
          keySignatureToTimeSignatureSp == other.keySignatureToTimeSignatureSp &&
          keySignatureAccidentalSpacingSp == other.keySignatureAccidentalSpacingSp &&
          heavyBarlineWidthSp == other.heavyBarlineWidthSp &&
          singleLineStaffBarlineOverhangSp == other.singleLineStaffBarlineOverhangSp &&
          smuflGlyphScale == other.smuflGlyphScale;

  @override
  int get hashCode =>
      initialClefClearanceSp.hashCode ^
      clefToKeySignatureSp.hashCode ^
      keySignatureToTimeSignatureSp.hashCode ^
      keySignatureAccidentalSpacingSp.hashCode ^
      heavyBarlineWidthSp.hashCode ^
      singleLineStaffBarlineOverhangSp.hashCode ^
      smuflGlyphScale.hashCode;
}
