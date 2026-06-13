// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('Engraver Compiler & Pagination Tests', () {
    late PageConfig config;

    setUp(() {
      config = const PageConfig();
    });

    test('Compile empty score returns empty layout', () {
      final score = Score(title: 'Empty Score', parts: []);
      final layout = Engraver.compile(score, config);
      expect(layout.pages, isEmpty);
    });

    test('Compile a single measure, single voice score', () {
      final part = Part(
        id: 'violin1',
        name: 'Violin I',
        measures: [
          Measure(
            number: 1,
            clef: Clef.treble,
            timeSignature: const TimeSignature(4, 4),
            voices: {
              'v1': Voice(
                id: 'v1',
                events: [
                  const NoteEvent(
                    Pitch(NoteName.c, octave: 4),
                    RhythmicDuration.quarter,
                  ),
                  const RestEvent(RhythmicDuration.quarter),
                  const NoteEvent(
                    Pitch(NoteName.e, octave: 4),
                    RhythmicDuration.half,
                  ),
                ],
              ),
            },
          ),
        ],
      );

      final score = Score(title: 'Simple Score', parts: [part]);
      final layout = Engraver.compile(score, config);

      expect(layout.pages, hasLength(1));
      final page = layout.pages.first;
      expect(page.elements, isNotEmpty);

      // Verify presence of specific visual elements
      final barlines = page.elements.whereType<PositionedBarline>().toList();
      final notes = page.elements.whereType<PositionedNote>().toList();
      final rests = page.elements.whereType<PositionedRest>().toList();
      final clefs = page.elements.whereType<PositionedClef>().toList();
      final timeSigs = page.elements.whereType<PositionedTimeSignature>().toList();

      expect(barlines, hasLength(2)); // Left start barline + right end barline
      expect(notes, hasLength(2)); // C4 + E4
      expect(rests, hasLength(1)); // Quarter rest
      expect(clefs, hasLength(1)); // Treble clef
      expect(timeSigs, hasLength(1)); // 4/4

      // E4 is line 1, C4 is 1 ledger line below bottom line (E4).
      // Check that C4 note has 1 ledger line Y value calculated.
      final c4Note = notes.firstWhere((n) => n.pitch == const Pitch(NoteName.c, octave: 4));
      expect(c4Note.ledgerLineYs, hasLength(1));

      final e4Note = notes.firstWhere((n) => n.pitch == const Pitch(NoteName.e, octave: 4));
      expect(e4Note.ledgerLineYs, isEmpty); // E4 is on the bottom line, no ledger needed
    });

    test('Greedy measure pagination wrapping onto multiple pages/systems', () {
      // Create a score with 200 measures. Since each measure has a minimum width,
      // this must wrap onto multiple systems and pages.
      final measures = <Measure>[];
      for (var i = 1; i <= 200; i++) {
        measures.add(
          Measure(
            number: i,
            clef: i == 1 ? Clef.treble : null,
            timeSignature: i == 1 ? const TimeSignature(4, 4) : null,
            voices: {
              'v1': Voice(
                id: 'v1',
                events: [
                  const NoteEvent(
                    Pitch(NoteName.a, octave: 4),
                    RhythmicDuration.whole,
                  ),
                ],
              ),
            },
          ),
        );
      }

      final part = Part(id: 'flute', name: 'Flute', measures: measures);
      final score = Score(title: 'Paginated Piece', parts: [part]);
      final layout = Engraver.compile(score, config);

      // Verify multi-page pagination works cleanly
      expect(layout.pages.length, greaterThan(1));
      
      for (final page in layout.pages) {
        expect(page.pageLayout.systems, isNotEmpty);
        expect(page.elements, isNotEmpty);
      }
    });

    test('Logarithmic spacing justification spans exact system width', () {
      final part = Part(
        id: 'guitar',
        name: 'Classical Guitar',
        measures: [
          Measure(
            number: 1,
            clef: Clef.treble,
            voices: {
              'v1': Voice(
                id: 'v1',
                events: [
                  const NoteEvent(
                    Pitch(NoteName.g, octave: 4),
                    RhythmicDuration.quarter,
                  ),
                  const NoteEvent(
                    Pitch(NoteName.b, octave: 4),
                    RhythmicDuration.quarter,
                  ),
                ],
              ),
            },
          ),
        ],
      );

      final score = Score(title: 'Justification Spec', parts: [part]);
      final layout = Engraver.compile(score, config);

      final page = layout.pages.first;
      final barlines = page.elements.whereType<PositionedBarline>().toList();

      expect(barlines, hasLength(2));
      final leftBarline = barlines[0];
      final rightBarline = barlines[1];

      // Absolute visual span between left and right measure boundary should equal
      // the exact usable page width (from margins.left to rightX).
      final usableWidth = config.effectiveWidth - config.margins.right - config.margins.left;
      final measureWidth = rightBarline.x - leftBarline.x;

      expect(measureWidth, closeTo(usableWidth, 0.001));
    });
  });

  group('SVG & LaTeX Emitter Compiled Integration Tests', () {
    late PageConfig config;
    late Score score;

    setUp(() {
      config = const PageConfig();
      final part = Part(
        id: 'oboe',
        name: 'Oboe',
        measures: [
          Measure(
            number: 1,
            clef: Clef.treble,
            keySignature: const KeySignature(-1), // F major / D minor (1 flat)
            timeSignature: const TimeSignature(3, 4),
            voices: {
              'v1': Voice(
                id: 'v1',
                events: [
                  const NoteEvent(
                    Pitch(NoteName.f, octave: 4),
                    RhythmicDuration.quarter,
                  ),
                  const RestEvent(RhythmicDuration.half),
                ],
              ),
            },
          ),
        ],
      );
      score = Score(title: 'Emitter Check', parts: [part]);
    });

    test('emitCompiledSvg runs successfully and returns valid SVG XML', () {
      final layout = Engraver.compile(score, config);
      expect(layout.pages, hasLength(1));

      final svg = emitCompiledSvg(config, layout.pages.first);
      expect(svg, startsWith('<?xml'));
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
      expect(svg, contains('<ellipse')); // Notehead
      expect(svg, contains('<rect')); // Rest
      expect(svg, contains('<text')); // Time Signature beats
    });

    test('emitCompiled runs successfully and returns valid LaTeX document', () {
      final layout = Engraver.compile(score, config);
      expect(layout.pages, hasLength(1));

      final tex = emitCompiled(config, layout.pages.first);
      expect(tex, contains(r'\documentclass{article}'));
      expect(tex, contains(r'\begin{document}'));
      expect(tex, contains(r'\pdfliteral direct'));
      expect(tex, contains(r'\end{document}'));
    });
  });
}
