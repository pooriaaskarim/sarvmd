// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Diatonic note names in standard Western music notation.
///
/// In standard music notation, notes are spelled using seven letters: C, D, E, F, G, A, B.
/// Each letter corresponds to a unique vertical step position on a musical staff.
enum NoteName {
  
  /// Note 'C'.
  c(stepValue: 0, semitone: 0),
  
  /// Note 'D'.
  d(stepValue: 1, semitone: 2),
  
  /// Note 'E'.
  e(stepValue: 2, semitone: 4),
  
  /// Note 'F'.
  f(stepValue: 3, semitone: 5),
  
  /// Note 'G'.
  g(stepValue: 4, semitone: 7),
  
  /// Note 'A'.
  a(stepValue: 5, semitone: 9),
  
  /// Note 'B'.
  b(stepValue: 6, semitone: 11);

  const NoteName({required this.stepValue, required this.semitone});

  /// Diatonic step value relative to C (0-indexed).
  ///
  /// Used for calculating vertical staff offsets. E.g. C is 0, D is 1, E is 2, etc.
  final int stepValue;

  /// Semitones relative to C within the same octave.
  ///
  /// Used for calculating MIDI values and physical frequencies.
  final int semitone;
}

/// Standard accidentals used to alter the pitch of a diatonic note.
enum Accidental {
  
  /// Double flat (𝄫) lowers the pitch by 2 semitones.
  doubleFlat(semitoneOffset: -2, symbol: '𝄫'),
  
  /// Flat (♭) lowers the pitch by 1 semitone.
  flat(semitoneOffset: -1, symbol: '♭'),
  
  /// Natural (♮) represents the unaltered diatonic pitch.
  natural(semitoneOffset: 0, symbol: '♮'),
  
  /// Sharp (♯) raises the pitch by 1 semitone.
  sharp(semitoneOffset: 1, symbol: '♯'),
  
  /// Double sharp (𝄪) raises the pitch by 2 semitones.
  doubleSharp(semitoneOffset: 2, symbol: '𝄪');

  const Accidental({required this.semitoneOffset, required this.symbol});

  /// The physical semitone displacement caused by the accidental.
  final int semitoneOffset;

  /// The standard SMuFL or Unicode glyph symbol representing the accidental.
  final String symbol;
}

/// Represents a musical pitch.
///
/// In standard music engraving, a pitch is defined by a [noteName] (diatonic spelling),
/// an optional [accidental] alteration, and a scientific [octave] registration.
///
/// Under scientific pitch notation, middle C is represented as `C4`.
///
/// Unlike raw frequency values or MIDI note numbers, `Pitch` preserves the correct
/// diatonic spelling of the notes. This is crucial for engraving because enharmonically
/// equivalent pitches (e.g. `G#4` and `Ab4` which share MIDI number 68) sit on completely
/// different staff lines and require different accidental symbols and ledger lines.
class Pitch implements Comparable<Pitch> {
  
  /// Creates a new [Pitch] instance.
  ///
  /// * [noteName]: The diatonic spelling of the note (e.g., [NoteName.c], [NoteName.a]).
  /// * [accidental]: The accidental alteration. Defaults to [Accidental.natural].
  /// * [octave]: The scientific octave registry. Defaults to `4` (middle octave).
  const Pitch(
    this.noteName, {
    this.accidental = Accidental.natural,
    this.octave = 4,
  });

  /// The diatonic note letter (C, D, E, F, G, A, or B).
  final NoteName noteName;

  /// The accidental altering the note (natural, flat, sharp, double flat, double sharp).
  final Accidental accidental;

  /// The scientific octave number (e.g., 4 for Middle C, 0 for MIDI lowest, etc.).
  final int octave;

  /// Returns the MIDI note number for this pitch (C4 = 60, A4 = 69).
  ///
  /// Calculated using standard Western tuning formulas:
  /// `MidiNumber = (Octave + 1) * 12 + Semitones + AccidentalOffset`
  int get midiNumber {
    return (octave + 1) * 12 + noteName.semitone + accidental.semitoneOffset;
  }

  /// Calculates the diatonic step offset of this pitch from a [reference] pitch.
  ///
  /// Positive values are higher, negative values are lower.
  /// Defaults to reference pitch `C4` (Middle C).
  ///
  /// This calculation ignores accidentals and only accounts for the diatonic letter spelling
  /// and octave, which directly correlates to the pitch's vertical line/space position
  /// on a standard 5-line staff.
  int diatonicStepOffset({Pitch reference = const Pitch(NoteName.c, octave: 4)}) {
    final selfDiatonic = octave * 7 + noteName.stepValue;
    final refDiatonic = reference.octave * 7 + reference.noteName.stepValue;
    return selfDiatonic - refDiatonic;
  }

  @override
  int compareTo(Pitch other) {
    // Compare diatonically first to order them on the staff lines,
    // then by semitones if the diatonic pitch spelling is identical.
    final diatonicDiff = diatonicStepOffset() - other.diatonicStepOffset();
    if (diatonicDiff != 0) return diatonicDiff;
    return midiNumber.compareTo(other.midiNumber);
  }

  /// Returns true if this pitch is diatonically/musically lower than [other].
  bool operator <(Pitch other) => compareTo(other) < 0;

  /// Returns true if this pitch is diatonically/musically lower than or equal to [other].
  bool operator <=(Pitch other) => compareTo(other) <= 0;

  /// Returns true if this pitch is diatonically/musically higher than [other].
  bool operator >(Pitch other) => compareTo(other) > 0;

  /// Returns true if this pitch is diatonically/musically higher than or equal to [other].
  bool operator >=(Pitch other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pitch &&
          noteName == other.noteName &&
          accidental == other.accidental &&
          octave == other.octave;

  @override
  int get hashCode => Object.hash(noteName, accidental, octave);

  @override
  String toString() {
    final accStr = accidental == Accidental.natural ? '' : accidental.symbol;
    return '${noteName.name.toUpperCase()}$accStr$octave';
  }
}
