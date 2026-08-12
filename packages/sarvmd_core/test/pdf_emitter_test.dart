// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('PDF Emitter Tests', () {
    test('emitPdf generates non-empty vector PDF bytes for single page layout', () async {
      final config = const PageConfig();
      final layout = computeLayout(config);

      final pdfBytes = await emitPdf(config, layout);

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, equals('%PDF'));
    });

    test('emitPdf generates non-empty PDF bytes for multi-page document', () async {
      final config = const PageConfig();
      final layout = computeLayout(config);

      final pdfBytes = await emitPdf(config, layout, pageCount: 3);

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, equals('%PDF'));
    });

    test('emitCompiledPdf generates non-empty PDF bytes for engraved page', () async {
      final config = const PageConfig();
      final score = Part(
        id: 'v1',
        name: 'Violin',
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
                ],
              ),
            },
          ),
        ],
      );
      final scoreObj = Score(title: 'Test Score', parts: [score]);
      final engravedLayout = Engraver.compile(scoreObj, config);
      expect(engravedLayout.pages, isNotEmpty);

      final pdfBytes = await emitCompiledPdf(config, engravedLayout.pages.first);

      expect(pdfBytes, isNotEmpty);
      final header = String.fromCharCodes(pdfBytes.take(4));
      expect(header, equals('%PDF'));
    });
  });
}
