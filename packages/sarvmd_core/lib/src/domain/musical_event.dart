// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'duration.dart';
import 'pitch.dart';

/// Sealed base class representing any musical event consuming rhythmic time.
///
/// In a score layout, musical events are the atomic components that occupy space
/// along a voice's horizontal timeline. By sealing [MusicalEvent], we guarantee that
/// downstream systems (like layout engine spacing or LaTeX coordinate emitters)
/// can exhaustively handle all possible event types (notes, rests, and chords)
/// without runtime type errors.
sealed class MusicalEvent {
  
  /// Base constructor for all musical events.
  ///
  /// Every event must have an exact [duration] to ensure robust timeline calculations
  /// and alignment.
  const MusicalEvent(this.duration);

  /// The exact rhythmic duration of this musical event.
  ///
  /// Represented as a [RhythmicDuration] to prevent cumulative rounding or floating-point drift.
  final RhythmicDuration duration;
}

/// Represents a single pitch played for a specific duration.
///
/// Models a standard monophonic note, such as a quarter note C4.
class NoteEvent extends MusicalEvent {
  
  /// Creates a [NoteEvent] representing a single pitch and its duration.
  const NoteEvent(this.pitch, RhythmicDuration duration) : super(duration);

  /// The pitch spelling (letter, accidental, and octave) of the note.
  final Pitch pitch;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEvent && pitch == other.pitch && duration == other.duration;

  @override
  int get hashCode => Object.hash(pitch, duration);

  @override
  String toString() => 'Note($pitch, $duration)';
}

/// Represents a musical silence of a specific duration.
///
/// Silent beats are crucial for padding voices, measuring metric sync points,
/// and rendering the correct rest shapes (e.g. whole rests, quarter rests)
/// on the staff.
class RestEvent extends MusicalEvent {
  
  /// Creates a [RestEvent] representing a timed silence.
  const RestEvent(RhythmicDuration duration) : super(duration);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RestEvent && duration == other.duration;

  @override
  int get hashCode => duration.hashCode;

  @override
  String toString() => 'Rest($duration)';
}

/// Represents multiple pitches sounded simultaneously for a specific duration.
///
/// A chord acts as a single rhythmic unit containing a set of distinct [pitches]
/// sharing the same onset time and [duration]. This is essential for engraving
/// because the pitches in a chord share a single stem and are stacked vertically.
class ChordEvent extends MusicalEvent {
  
  /// Creates a [ChordEvent] with a list of simultaneous pitches.
  ///
  /// * [pitches]: The list of pitches in the chord. Must contain at least one pitch.
  /// * [duration]: The duration of the entire chord.
  ChordEvent(this.pitches, RhythmicDuration duration)
      : assert(pitches.isNotEmpty, 'Chord must have at least one pitch.'),
        super(duration);

  /// The list of pitches sounding simultaneously in this chord.
  final List<Pitch> pitches;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChordEvent ||
        duration != other.duration ||
        pitches.length != other.pitches.length) {
      return false;
    }
    for (int i = 0; i < pitches.length; i++) {
      if (pitches[i] != other.pitches[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(pitches), duration);

  @override
  String toString() => 'Chord(${pitches.join(", ")}, $duration)';
}
