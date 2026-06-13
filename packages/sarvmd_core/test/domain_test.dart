// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('RhythmicDuration Tests', () {
    test('Exact arithmetic and simplification', () {
      const q = RhythmicDuration.quarter;
      const h = RhythmicDuration.half;
      expect(q + q, equals(h));
      expect(h - q, equals(q));
      expect(q * 2, equals(h));
    });

    test('Dotted duration calculation', () {
      const q = RhythmicDuration.quarter;
      // Dotted quarter = 1/4 + 1/8 = 3/8
      final dq = q.withDots(1);
      expect(dq, equals(const RhythmicDuration(3, 8)));
      expect(dq.decimal, equals(0.375));

      // Double dotted quarter = 1/4 + 1/8 + 1/16 = 7/16
      final ddq = q.withDots(2);
      expect(ddq, equals(const RhythmicDuration(7, 16)));
      expect(ddq.decimal, equals(0.4375));
    });

    test('Comparisons', () {
      const q = RhythmicDuration.quarter;
      const h = RhythmicDuration.half;
      expect(q < h, isTrue);
      expect(h > q, isTrue);
      expect(q <= q, isTrue);
    });
  });

  group('Pitch Tests', () {
    test('MIDI numbers for standard pitches', () {
      expect(const Pitch(NoteName.c, octave: 4).midiNumber, equals(60));
      expect(const Pitch(NoteName.a, octave: 4).midiNumber, equals(69));
      expect(const Pitch(NoteName.c, accidental: Accidental.sharp, octave: 4).midiNumber, equals(61));
      expect(const Pitch(NoteName.b, accidental: Accidental.flat, octave: 4).midiNumber, equals(70));
    });

    test('Diatonic step offsets from Middle C', () {
      final c4 = const Pitch(NoteName.c, octave: 4);
      final d4 = const Pitch(NoteName.d, octave: 4);
      final c5 = const Pitch(NoteName.c, octave: 5);
      final b3 = const Pitch(NoteName.b, octave: 3);

      expect(d4.diatonicStepOffset(reference: c4), equals(1));
      expect(c5.diatonicStepOffset(reference: c4), equals(7));
      expect(b3.diatonicStepOffset(reference: c4), equals(-1));
    });
  });

  group('Clef Tests', () {
    test('Standard reference pitches', () {
      expect(Clef.treble.referencePitch, equals(const Pitch(NoteName.g, octave: 4)));
      expect(Clef.bass.referencePitch, equals(const Pitch(NoteName.f, octave: 3)));
      expect(Clef.alto.referencePitch, equals(const Pitch(NoteName.c, octave: 4)));
    });
  });

  group('Signature Tests', () {
    test('TimeSignature validation', () {
      expect(() => TimeSignature(4, 3), throwsA(isA<AssertionError>()));
      expect(const TimeSignature(3, 4).toString(), equals('3/4'));
    });

    test('KeySignature alterations', () {
      // G Major (1 sharp: F#)
      const gMajor = KeySignature(1);
      expect(gMajor.accidentalFor(NoteName.f), equals(Accidental.sharp));
      expect(gMajor.accidentalFor(NoteName.c), equals(Accidental.natural));

      // F Major (1 flat: Bb)
      const fMajor = KeySignature(-1);
      expect(fMajor.accidentalFor(NoteName.b), equals(Accidental.flat));
      expect(fMajor.accidentalFor(NoteName.f), equals(Accidental.natural));
    });
  });

  group('Measure and Voice Validation Tests', () {
    test('Voice total duration and validation', () {
      const sig = TimeSignature(4, 4);
      final voice = Voice(
        id: 'melody',
        events: [
          NoteEvent(const Pitch(NoteName.c), RhythmicDuration.quarter),
          NoteEvent(const Pitch(NoteName.d), RhythmicDuration.quarter),
          RestEvent(RhythmicDuration.half),
        ],
      );

      expect(voice.totalDuration, equals(RhythmicDuration.whole));
      expect(voice.isValidFor(sig), isTrue);

      final invalidVoice = Voice(
        id: 'melody',
        events: [
          NoteEvent(const Pitch(NoteName.c), RhythmicDuration.quarter),
        ],
      );
      expect(invalidVoice.isValidFor(sig), isFalse);
    });
  });
}
