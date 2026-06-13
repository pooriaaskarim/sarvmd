// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'clef.dart';
import 'duration.dart';
import 'musical_event.dart';
import 'signature.dart';

/// Represents a single linear, monophonic timeline of musical events within a measure.
///
/// In a multi-voice score (polyphony), each voice is plotted as an independent horizontal
/// timeline. E.g., a piano grand staff has two voices in the right hand (Soprano, Alto)
/// and two in the left hand (Tenor, Bass).
///
/// Each [Voice] contains a sequence of [MusicalEvent]s (notes, rests, or chords) and
/// is identified by a unique [id] to allow cross-system coordination.
class Voice {
  
  /// Creates a [Voice] with a unique identifier and a list of sequential events.
  const Voice({
    required this.id,
    this.events = const [],
  });

  /// The unique identifier of this voice (e.g., 'soprano', 'alto', 'bass', 'voice1').
  final String id;

  /// The linear list of sequential events (notes, rests, chords) in this voice.
  final List<MusicalEvent> events;

  /// Returns the accumulated total duration of all events in this voice.
  ///
  /// Adds all event durations together using exact rational arithmetic to prevent
  /// cumulative floating-point coordinate drift.
  RhythmicDuration get totalDuration {
    var total = const RhythmicDuration(0, 1);
    for (final event in events) {
      total = total + event.duration;
    }
    return total;
  }

  /// Validates whether the voice's events exactly fill the time signature.
  ///
  /// Engraving engines must ensure that voices are mathematically complete before rendering.
  /// If a voice's [totalDuration] is shorter than or exceeds the duration specified by the
  /// [signature], this returns `false`.
  bool isValidFor(TimeSignature signature) {
    final expected = RhythmicDuration(signature.beats, signature.beatValue);
    return totalDuration == expected;
  }

  /// Creates a copy of this voice with optional field overrides.
  Voice copyWith({
    String? id,
    List<MusicalEvent>? events,
  }) =>
      Voice(
        id: id ?? this.id,
        events: events ?? this.events,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Voice || id != other.id || events.length != other.events.length) {
      return false;
    }
    for (int i = 0; i < events.length; i++) {
      if (events[i] != other.events[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, Object.hashAll(events));

  @override
  String toString() => 'Voice($id, eventsCount: ${events.length}, totalTime: $totalDuration)';
}

/// Represents a single musical measure across all active voices.
///
/// A [Measure] represents a synchronized vertical slice of time in the score. It acts
/// as the structural boundary for key signatures, time signatures, and clefs.
///
/// Under standard engraving logic:
/// * Horizontal coordinate spacing is calculated per measure.
/// * Clef changes, time signatures, and key signatures can only be declared at a measure boundary.
class Measure {
  
  /// Creates a [Measure] representing a synchronized vertical time slice.
  ///
  /// * [number]: The 1-based index representing the measure number in the score.
  /// * [voices]: A map pairing voice IDs to their respective [Voice] timelines in this measure.
  /// * [timeSignature]: Optional time signature change starting at this measure.
  /// * [keySignature]: Optional key signature change starting at this measure.
  /// * [clef]: Optional clef change starting at this measure.
  const Measure({
    required this.number,
    this.voices = const {},
    this.timeSignature,
    this.keySignature,
    this.clef,
  });

  /// The 1-based index of this measure in the score sequence.
  final int number;

  /// Map of voice IDs to [Voice] timelines active in this measure.
  final Map<String, Voice> voices;

  /// Optional time signature change starting at this measure.
  /// If null, the previous time signature carries over.
  final TimeSignature? timeSignature;

  /// Optional key signature change starting at this measure.
  /// If null, the previous key signature carries over.
  final KeySignature? keySignature;

  /// Optional clef change starting at this measure.
  /// If null, the previous clef carries over.
  final Clef? clef;

  /// Creates a copy of this measure with optional field overrides.
  ///
  /// Use `timeSignature`, `keySignature`, or `clef` closures returning null to explicitly
  /// clear those boundary parameters.
  Measure copyWith({
    int? number,
    Map<String, Voice>? voices,
    TimeSignature? Function()? timeSignature,
    KeySignature? Function()? keySignature,
    Clef? Function()? clef,
  }) =>
      Measure(
        number: number ?? this.number,
        voices: voices ?? this.voices,
        timeSignature: timeSignature != null ? timeSignature() : this.timeSignature,
        keySignature: keySignature != null ? keySignature() : this.keySignature,
        clef: clef != null ? clef() : this.clef,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Measure ||
        number != other.number ||
        timeSignature != other.timeSignature ||
        keySignature != other.keySignature ||
        clef != other.clef ||
        voices.length != other.voices.length) {
      return false;
    }
    for (final key in voices.keys) {
      if (voices[key] != other.voices[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        number,
        timeSignature,
        keySignature,
        clef,
        Object.hashAll(voices.values),
      );

  @override
  String toString() => 'Measure($number, voicesCount: ${voices.length})';
}
