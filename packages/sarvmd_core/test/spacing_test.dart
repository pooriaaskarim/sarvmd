// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('SMuFL Vector Registry Tests', () {
    test('Glyph Codepoints and Names', () {
      expect(SmuflGlyph.gClef.smuflName, equals('gClef'));
      expect(SmuflGlyph.gClef.codepoint, equals('\uE050'));
      expect(SmuflGlyph.gClef.widthSp, equals(3.2));

      expect(SmuflGlyph.fClef.smuflName, equals('fClef'));
      expect(SmuflGlyph.fClef.codepoint, equals('\uE062'));

      expect(SmuflGlyph.noteheadBlack.smuflName, equals('noteheadBlack'));
      expect(SmuflGlyph.noteheadBlack.codepoint, equals('\uE0A4'));
    });

    test('Stem Connection Anchors', () {
      final blackNote = SmuflGlyph.noteheadBlack;
      expect(blackNote.stemConnectionUp, isNotNull);
      expect(blackNote.stemConnectionUp!.x, equals(1.18));
      expect(blackNote.stemConnectionUp!.y, equals(0.35));

      expect(blackNote.stemConnectionDown, isNotNull);
      expect(blackNote.stemConnectionDown!.x, equals(0.0));
      expect(blackNote.stemConnectionDown!.y, equals(-0.35));

      expect(SmuflGlyph.noteheadWhole.stemConnectionUp, isNull);
      expect(SmuflGlyph.restQuarter.stemConnectionUp, isNull);
    });
  });

  group('Gouldian Spacing Spindle Tests', () {
    test('Monophonic logarithmic spacing (Quarter, Quarter, Half)', () {
      // 1/4 + 1/4 + 1/2 = 1.0 (Whole)
      final voice = const Voice(
        id: '0',
        events: [
          NoteEvent(Pitch(NoteName.c, octave: 4), RhythmicDuration.quarter),
          NoteEvent(Pitch(NoteName.e, octave: 4), RhythmicDuration.quarter),
          NoteEvent(Pitch(NoteName.g, octave: 4), RhythmicDuration.half),
        ],
      );

      final spindle = SpacingSpindle.compute(
        voices: [voice],
        timeSignature: TimeSignature.commonTime, // 4/4
        referenceSpacingMm: 8.0,
        scalingExponent: 0.57,
        minimumWidthMm: 3.0,
      );

      // Unique onset timestamps: 0, 1/4, 1/2, 1.0
      expect(spindle.coordinates.containsKey(const RhythmicDuration(0, 1)), isTrue);
      expect(spindle.coordinates.containsKey(const RhythmicDuration(1, 4)), isTrue);
      expect(spindle.coordinates.containsKey(const RhythmicDuration(1, 2)), isTrue);
      expect(spindle.coordinates.containsKey(const RhythmicDuration(1, 1)), isTrue);

      // Verify coordinate progression
      // X(0) = 0.0
      expect(spindle.coordinates[const RhythmicDuration(0, 1)], closeTo(0.0, 0.001));

      // Slice 0: duration = 1/4. Spacing = S_ref * (0.25 / 0.25)^0.57 = 8.0 mm
      // X(1/4) = 8.0
      expect(spindle.coordinates[const RhythmicDuration(1, 4)], closeTo(8.0, 0.001));

      // Slice 1: duration = 1/4. Spacing = 8.0 mm
      // X(1/2) = 16.0
      expect(spindle.coordinates[const RhythmicDuration(1, 2)], closeTo(16.0, 0.001));

      // Slice 2: duration = 1/2. Spacing = 8.0 * (0.5 / 0.25)^0.57 = 8.0 * 2^0.57 ≈ 11.8762 mm
      // X(1.0) = 16.0 + 11.8762 = 27.8762
      expect(spindle.coordinates[const RhythmicDuration(1, 1)], closeTo(27.8762, 0.001));
      expect(spindle.totalWidth, closeTo(27.8762, 0.001));
    });

    test('Polyphonic onset column synchronization', () {
      // Voice 1: Quarter (1/4), Quarter (1/4), Half (1/2) -> onsets: 0, 1/4, 1/2
      final voice1 = const Voice(
        id: '0',
        events: [
          NoteEvent(Pitch(NoteName.c, octave: 4), RhythmicDuration.quarter),
          NoteEvent(Pitch(NoteName.e, octave: 4), RhythmicDuration.quarter),
          NoteEvent(Pitch(NoteName.g, octave: 4), RhythmicDuration.half),
        ],
      );

      // Voice 2: Eighth (1/8), Eighth (1/8), Half (1/2), Quarter (1/4)
      // Onsets: 0, 1/8, 1/4, 3/4
      final voice2 = const Voice(
        id: '1',
        events: [
          NoteEvent(Pitch(NoteName.d, octave: 4), RhythmicDuration.eighth),
          NoteEvent(Pitch(NoteName.f, octave: 4), RhythmicDuration.eighth),
          NoteEvent(Pitch(NoteName.a, octave: 4), RhythmicDuration.half),
          NoteEvent(Pitch(NoteName.f, octave: 4), RhythmicDuration.quarter),
        ],
      );

      final spindle = SpacingSpindle.compute(
        voices: [voice1, voice2],
        timeSignature: TimeSignature.commonTime,
      );

      // Consolidated unique onsets must be exactly:
      // 0, 1/8, 1/4, 1/2, 3/4, 1/1
      final expectedOnsets = [
        const RhythmicDuration(0, 1),
        const RhythmicDuration(1, 8),
        const RhythmicDuration(1, 4),
        const RhythmicDuration(1, 2),
        const RhythmicDuration(3, 4),
        const RhythmicDuration(1, 1),
      ];

      expect(spindle.coordinates.length, equals(6));
      for (final onset in expectedOnsets) {
        expect(spindle.coordinates.containsKey(onset), isTrue);
      }
    });

    test('Clamping to minimum width', () {
      // Very tiny duration: 1/64
      final voice = const Voice(
        id: '0',
        events: [
          RestEvent(RhythmicDuration(1, 64)),
        ],
      );

      final spindle = SpacingSpindle.compute(
        voices: [voice],
        referenceSpacingMm: 8.0,
        scalingExponent: 0.57,
        minimumWidthMm: 4.0, // Force large minimum width
      );

      // The spacing for 1/64 at reference 8.0 and exponent 0.57 is extremely small.
      // It should be clamped to our minimum width of 4.0 mm.
      expect(spindle.totalWidth, equals(4.0));
    });
  });
}
