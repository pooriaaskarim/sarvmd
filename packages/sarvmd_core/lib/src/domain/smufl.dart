// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// A 2D point representation for coordinates in standard music engraving.
///
/// Coordinates are represented in staff-space units (`sp`), where 1.0 `sp` is the
/// distance between two adjacent lines of a standard five-line staff.
class EngravingPoint {
  
  /// Creates a new [EngravingPoint] coordinate representation.
  const EngravingPoint(this.x, this.y);

  /// The horizontal coordinate in staff-space units (`sp`).
  final double x;

  /// The vertical coordinate in staff-space units (`sp`).
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EngravingPoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x, $y) sp';
}

/// The Standard Music Font Layout (SMuFL) Vector Asset Registry.
///
/// SMuFL standardizes the mapping of musical symbols to the Private Use Area
/// (PUA) of Unicode (starting at U+E000). This registry acts as a type-safe metadata
/// catalog, mapping logical symbols to their SMuFL PUA codepoints, official names,
/// visual widths, and exact physical layout anchors (such as stem connection points
/// on noteheads).
///
/// All dimensions and coordinates are specified in staff-space units (`sp`).
enum SmuflGlyph {
  // --- CLEFS ---
  /// The standard G Clef (Treble Clef). SMuFL: `gClef` (U+E050).
  gClef(
    smuflName: 'gClef',
    codepoint: '\uE050',
    widthSp: 3.2,
  ),

  /// The standard F Clef (Bass Clef). SMuFL: `fClef` (U+E062).
  fClef(
    smuflName: 'fClef',
    codepoint: '\uE062',
    widthSp: 3.12,
  ),

  /// The standard C Clef (Alto/Tenor Clef). SMuFL: `cClef` (U+E05C).
  cClef(
    smuflName: 'cClef',
    codepoint: '\uE05C',
    widthSp: 2.8,
  ),

  /// The Percussion Clef. SMuFL: `semipitchedPercussionClef1` (U+E069).
  percussionClef(
    smuflName: 'semipitchedPercussionClef1',
    codepoint: '\uE069',
    widthSp: 1.5,
  ),

  /// The Guitar Tablature Clef. SMuFL: `6stringTabClef` (U+E05F).
  tabClef(
    smuflName: '6stringTabClef',
    codepoint: '\uE05F',
    widthSp: 2.5,
  ),

  // --- NOTEHEADS ---
  /// A standard black notehead (used for quarter, eighth, etc.). SMuFL: `noteheadBlack` (U+E0A4).
  noteheadBlack(
    smuflName: 'noteheadBlack',
    codepoint: '\uE0A4',
    widthSp: 1.18,
    stemConnectionUp: EngravingPoint(1.18, 0.35),
    stemConnectionDown: EngravingPoint(0.0, -0.35),
  ),

  /// A standard half notehead. SMuFL: `noteheadHalf` (U+E0A3).
  noteheadHalf(
    smuflName: 'noteheadHalf',
    codepoint: '\uE0A3',
    widthSp: 1.18,
    stemConnectionUp: EngravingPoint(1.18, 0.35),
    stemConnectionDown: EngravingPoint(0.0, -0.35),
  ),

  /// A standard whole notehead. SMuFL: `noteheadWhole` (U+E0A2).
  noteheadWhole(
    smuflName: 'noteheadWhole',
    codepoint: '\uE0A2',
    widthSp: 1.62,
  ),

  // --- RESTS ---
  /// A whole measure rest. SMuFL: `restWhole` (U+E4F4).
  restWhole(
    smuflName: 'restWhole',
    codepoint: '\uE4F4',
    widthSp: 1.0,
  ),

  /// A half measure rest. SMuFL: `restHalf` (U+E4F5).
  restHalf(
    smuflName: 'restHalf',
    codepoint: '\uE4F5',
    widthSp: 1.0,
  ),

  /// A quarter rest. SMuFL: `restQuarter` (U+E4F6).
  restQuarter(
    smuflName: 'restQuarter',
    codepoint: '\uE4F6',
    widthSp: 1.0,
  ),

  /// An eighth rest. SMuFL: `rest8th` (U+E4F7).
  restEighth(
    smuflName: 'rest8th',
    codepoint: '\uE4F7',
    widthSp: 1.0,
  ),

  /// A sixteenth rest. SMuFL: `rest16th` (U+E4F8).
  restSixteenth(
    smuflName: 'rest16th',
    codepoint: '\uE4F8',
    widthSp: 1.25,
  ),

  /// A thirty-second rest. SMuFL: `rest32nd` (U+E4F9).
  restThirtySecond(
    smuflName: 'rest32nd',
    codepoint: '\uE4F9',
    widthSp: 1.5,
  ),

  // --- FLAGS ---
  /// An eighth note flag pointing up. SMuFL: `flag8thUp` (U+E240).
  flag8thUp(
    smuflName: 'flag8thUp',
    codepoint: '\uE240',
    widthSp: 0.96,
  ),

  /// An eighth note flag pointing down. SMuFL: `flag8thDown` (U+E241).
  flag8thDown(
    smuflName: 'flag8thDown',
    codepoint: '\uE241',
    widthSp: 0.96,
  ),

  /// A sixteenth note flag pointing up. SMuFL: `flag16thUp` (U+E242).
  flag16thUp(
    smuflName: 'flag16thUp',
    codepoint: '\uE242',
    widthSp: 0.96,
  ),

  /// A sixteenth note flag pointing down. SMuFL: `flag16thDown` (U+E243).
  flag16thDown(
    smuflName: 'flag16thDown',
    codepoint: '\uE243',
    widthSp: 0.96,
  ),

  // --- ACCIDENTALS ---
  /// A standard flat sign. SMuFL: `accidentalFlat` (U+E260).
  accidentalFlat(
    smuflName: 'accidentalFlat',
    codepoint: '\uE260',
    widthSp: 0.92,
  ),

  /// A standard natural sign. SMuFL: `accidentalNatural` (U+E261).
  accidentalNatural(
    smuflName: 'accidentalNatural',
    codepoint: '\uE261',
    widthSp: 0.68,
  ),

  /// A standard sharp sign. SMuFL: `accidentalSharp` (U+E262).
  accidentalSharp(
    smuflName: 'accidentalSharp',
    codepoint: '\uE262',
    widthSp: 0.86,
  ),

  /// A double-flat sign. SMuFL: `accidentalDoubleFlat` (U+E264).
  accidentalDoubleFlat(
    smuflName: 'accidentalDoubleFlat',
    codepoint: '\uE264',
    widthSp: 1.64,
  ),

  /// A double-sharp sign. SMuFL: `accidentalDoubleSharp` (U+E263).
  accidentalDoubleSharp(
    smuflName: 'accidentalDoubleSharp',
    codepoint: '\uE263',
    widthSp: 1.0,
  );

  /// Creates a new [SmuflGlyph] entry with the specified SMuFL metadata.
  const SmuflGlyph({
    required this.smuflName,
    required this.codepoint,
    required this.widthSp,
    this.stemConnectionUp,
    this.stemConnectionDown,
  });

  /// The official SMuFL metadata identifier name.
  final String smuflName;

  /// The Unicode PUA character representing this glyph.
  final String codepoint;

  /// The typical visual width of this glyph in staff-space units (`sp`).
  final double widthSp;

  /// The exact coordinate where an upward stem connects to this notehead.
  ///
  /// Measured in staff-space units (`sp`) relative to the notehead center.
  /// Null if this glyph is not a notehead.
  final EngravingPoint? stemConnectionUp;

  /// The exact coordinate where a downward stem connects to this notehead.
  ///
  /// Measured in staff-space units (`sp`) relative to the notehead center.
  /// Null if this glyph is not a notehead.
  final EngravingPoint? stemConnectionDown;
}
