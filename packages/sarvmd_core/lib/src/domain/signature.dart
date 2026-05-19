// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'pitch.dart';

/// Represents a musical time signature (e.g., 4/4, 3/4, 6/8).
///
/// In standard music notation, a time signature defines the meter of a measure,
/// specifying the number of beats per measure ([beats]) and the duration that constitutes
/// one beat ([beatValue]).
class TimeSignature {
  
  /// Creates a new [TimeSignature] instance.
  ///
  /// * [beats]: The number of beats per measure (must be greater than zero).
  /// * [beatValue]: The note value receiving a single beat (must be a positive power of two,
  ///   such as 1, 2, 4, 8, 16, 32, or 64).
  const TimeSignature(this.beats, this.beatValue)
      : assert(beats > 0, 'Beats must be greater than zero.'),
        assert(beatValue > 0 && (beatValue & (beatValue - 1)) == 0,
            'Beat value must be a power of two.');

  /// The numerator of the time signature.
  ///
  /// Represents the number of beats or rhythmic pulses contained in a single measure.
  final int beats;

  /// The denominator of the time signature.
  ///
  /// Represents the fundamental note value that receives one beat (e.g. 4 for quarter, 8 for eighth).
  /// Enforced to be a power of two.
  final int beatValue;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSignature && beats == other.beats && beatValue == other.beatValue;

  @override
  int get hashCode => Object.hash(beats, beatValue);

  @override
  String toString() => '$beats/$beatValue';

  /// Standard Common Time (4/4).
  static const TimeSignature commonTime = TimeSignature(4, 4);

  /// Standard Cut Time (2/2).
  static const TimeSignature cutTime = TimeSignature(2, 2);
}

/// Represents a standard musical key signature in the Circle of Fifths.
///
/// Models key signatures using a single [fifths] index ranging from `-7` to `+7`.
/// * `0` represents C Major / A Minor (no sharps or flats).
/// * Positive numbers represent the number of sharps (e.g., `1` is G Major with 1 sharp, `7` is C# Major with 7 sharps).
/// * Negative numbers represent the number of flats (e.g., `-1` is F Major with 1 flat, `-7` is Cb Major with 7 flats).
class KeySignature {
  
  /// Creates a [KeySignature] using its [fifths] Circle of Fifths index.
  ///
  /// The index [fifths] must be between `-7` (7 flats) and `+7` (7 sharps) inclusive.
  const KeySignature(this.fifths)
      : assert(fifths >= -7 && fifths <= 7, 'Key signature fifths must be between -7 and +7.');

  /// Number of sharps (positive) or flats (negative) in the Circle of Fifths.
  final int fifths;

  /// True if the key signature contains sharps (fifths > 0).
  bool get isSharp => fifths > 0;

  /// True if the key signature contains flats (fifths < 0).
  bool get isFlat => fifths < 0;

  /// Returns the default accidental for a given [noteName] under this key signature.
  ///
  /// Follows standard music theory spelling rules for key signatures:
  /// * Sharp keys introduce sharps in the order: F, C, G, D, A, E, B (Father Charles Goes Down And Ends Battle).
  /// * Flat keys introduce flats in the order: B, E, A, D, G, C, F (Battle Ends And Down Goes Charles Father).
  ///
  /// E.g., in a key signature of 3 sharps (A Major, `fifths = 3`), [accidentalFor] returns
  /// [Accidental.sharp] for `F`, `C`, and `G`, and [Accidental.natural] for all other notes.
  Accidental accidentalFor(NoteName noteName) {
    if (fifths == 0) return Accidental.natural;

    if (fifths > 0) {
      // Sharps order: F, C, G, D, A, E, B
      const sharpOrder = [
        NoteName.f,
        NoteName.c,
        NoteName.g,
        NoteName.d,
        NoteName.a,
        NoteName.e,
        NoteName.b
      ];
      final index = sharpOrder.indexOf(noteName);
      if (index >= 0 && index < fifths) {
        return Accidental.sharp;
      }
    } else {
      // Flats order: B, E, A, D, G, C, F
      const flatOrder = [
        NoteName.b,
        NoteName.e,
        NoteName.a,
        NoteName.d,
        NoteName.g,
        NoteName.c,
        NoteName.f
      ];
      final index = flatOrder.indexOf(noteName);
      if (index >= 0 && index < fifths.abs()) {
        return Accidental.flat;
      }
    }

    return Accidental.natural;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KeySignature && fifths == other.fifths;

  @override
  int get hashCode => fifths.hashCode;

  @override
  String toString() {
    if (fifths == 0) return 'C Major / A Minor (Natural)';
    if (fifths > 0) return '$fifths Sharps';
    return '${fifths.abs()} Flats';
  }

  /// Reference key signature of C Major (no sharps or flats).
  static const KeySignature cMajor = KeySignature(0);
}
