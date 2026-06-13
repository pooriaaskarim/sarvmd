// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'pitch.dart';

/// Represents a musical clef with anchoring rules and octave shifts.
///
/// A clef acts as a mapping coordinator. In sheet music, it anchors a specific
/// reference pitch to a particular staff line. All other pitches are then plotted
/// relative to this reference point.
///
/// By using a `sealed` class hierarchy, we eliminate procedural enums (like `ClefType`)
/// and leverage type-safe OOP polymorphism. You can determine the type of clef
/// using standard Dart pattern matching:
///
/// ```dart
/// switch (clef) {
///   case TrebleClef(): // treble clef logic
///   case BassClef():   // bass clef logic
///   // ...
/// }
/// ```
sealed class Clef {
  
  /// Creates a [Clef] instance with specific layout rules.
  ///
  /// * [anchorLine]: The staff line on which the clef's center/primary loop is drawn.
  ///   Must be in range 1-5 (1 is the bottommost line).
  /// * [octaveShift]: Shifts the pitch mapping up or down.
  ///   E.g., `-1` shifts the reference pitch down an octave (8vb - common for classical tenor voices).
  ///   `+1` shifts it up an octave (8va - piccolo/sopranino).
  const Clef({
    required this.anchorLine,
    this.octaveShift = 0,
  })  : assert(anchorLine >= 1 && anchorLine <= 5, 'Anchor line must be between 1 and 5.');

  /// The 1-indexed staff line from the bottom (1 to 5) on which the clef symbol is anchored.
  final int anchorLine;

  /// The octave displacement multiplier (+1 for 8va, -1 for 8vb, 0 for standard).
  final int octaveShift;

  /// The standard reference pitch centered on this clef's [anchorLine].
  Pitch get referencePitch;

  /// User-friendly display name of the clef (e.g. 'Treble', 'Bass', 'TAB').
  String get displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Clef &&
          runtimeType == other.runtimeType &&
          anchorLine == other.anchorLine &&
          octaveShift == other.octaveShift;

  @override
  int get hashCode => Object.hash(runtimeType, anchorLine, octaveShift);

  @override
  String toString() => '$displayName (line $anchorLine, shift $octaveShift)';

  /// Predefined Treble G-Clef anchored on staff line 2.
  static const Clef treble = TrebleClef();

  /// Predefined Bass F-Clef anchored on staff line 4.
  static const Clef bass = BassClef();

  /// Predefined Alto C-Clef anchored on staff line 3.
  static const Clef alto = AltoClef();

  /// Predefined Tenor C-Clef anchored on staff line 4.
  static const Clef tenor = TenorClef();

  /// Predefined Neutral Percussion Clef anchored on staff line 3.
  static const Clef percussion = PercussionClef();

  /// Predefined Tablature Clef ("TAB") anchored on staff line 3.
  static const Clef tab = TabClef();
}

/// G-clef (Treble), traditionally representing high pitch registers (violin, flute, soprano, etc.).
class TrebleClef extends Clef {
  
  /// Creates a [TrebleClef] instance.
  ///
  /// * [anchorLine]: Staff line on which the G loop centers (defaults to 2).
  /// * [octaveShift]: Octave shift (+1 for 8va, -1 for 8vb, 0 for standard).
  const TrebleClef({int anchorLine = 2, int octaveShift = 0})
      : super(anchorLine: anchorLine, octaveShift: octaveShift);

  @override
  Pitch get referencePitch => Pitch(NoteName.g, octave: 4 + octaveShift);

  @override
  String get displayName => 'Treble';
}

/// F-clef (Bass), traditionally representing low pitch registers (cello, double bass, bass guitar, etc.).
class BassClef extends Clef {
  
  /// Creates a [BassClef] instance.
  ///
  /// * [anchorLine]: Staff line on which the F dots bracket (defaults to 4).
  /// * [octaveShift]: Octave shift (+1 for 8va, -1 for 8vb, 0 for standard).
  const BassClef({int anchorLine = 4, int octaveShift = 0})
      : super(anchorLine: anchorLine, octaveShift: octaveShift);

  @override
  Pitch get referencePitch => Pitch(NoteName.f, octave: 3 + octaveShift);

  @override
  String get displayName => 'Bass';
}

/// C-clef centered on Alto line (viola, alto trombone).
class AltoClef extends Clef {
  
  /// Creates an [AltoClef] instance.
  ///
  /// * [anchorLine]: Staff line on which the C center arrow sits (defaults to 3).
  /// * [octaveShift]: Octave shift (+1 for 8va, -1 for 8vb, 0 for standard).
  const AltoClef({int anchorLine = 3, int octaveShift = 0})
      : super(anchorLine: anchorLine, octaveShift: octaveShift);

  @override
  Pitch get referencePitch => Pitch(NoteName.c, octave: 4 + octaveShift);

  @override
  String get displayName => 'Alto';
}

/// C-clef centered on Tenor line (tenor trombone, cello high registers, bassoon high registers).
class TenorClef extends Clef {
  
  /// Creates a [TenorClef] instance.
  ///
  /// * [anchorLine]: Staff line on which the C center arrow sits (defaults to 4).
  /// * [octaveShift]: Octave shift (+1 for 8va, -1 for 8vb, 0 for standard).
  const TenorClef({int anchorLine = 4, int octaveShift = 0})
      : super(anchorLine: anchorLine, octaveShift: octaveShift);

  @override
  Pitch get referencePitch => Pitch(NoteName.c, octave: 4 + octaveShift);

  @override
  String get displayName => 'Tenor';
}

/// Neutral percussion clef for unpitched instruments (drum set, percussion).
class PercussionClef extends Clef {
  
  /// Creates a [PercussionClef] instance.
  ///
  /// * [anchorLine]: Staff line on which the symbol centers (defaults to 3).
  const PercussionClef({int anchorLine = 3})
      : super(anchorLine: anchorLine, octaveShift: 0);

  @override
  Pitch get referencePitch => const Pitch(NoteName.c, octave: 4); // Middle C as standard default

  @override
  String get displayName => 'Percussion';
}

/// Tablature clef ("TAB") for fretted stringed instruments (guitar, bass guitar, banjo).
class TabClef extends Clef {
  
  /// Creates a [TabClef] instance.
  ///
  /// * [anchorLine]: Staff line on which the "TAB" text centers (defaults to 3).
  const TabClef({int anchorLine = 3})
      : super(anchorLine: anchorLine, octaveShift: 0);

  @override
  Pitch get referencePitch => const Pitch(NoteName.c, octave: 4); // Middle C as standard default

  @override
  String get displayName => 'TAB';
}
