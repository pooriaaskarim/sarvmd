// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('ScoreCompiler', () {
    final config = PageConfig();
    final layout = computeLayout(config);

    test('getDefaultFileName generates clean descriptive default filenames', () {
      final name = ScoreCompiler.getDefaultFileName(config);
      expect(name, isNotEmpty);
      expect(name, contains('A4'));
      expect(name, contains('Portrait'));
    });

    test('sanitizeFileName removes extensions and invalid characters', () {
      expect(
        ScoreCompiler.sanitizeFileName('my_score.pdf', config),
        equals('my_score'),
      );
      expect(
        ScoreCompiler.sanitizeFileName('  test:score/name.tex  ', config),
        equals('test_score_name'),
      );
      expect(
        ScoreCompiler.sanitizeFileName('', config),
        equals(ScoreCompiler.getDefaultFileName(config)),
      );
    });

    test('compileToTex produces valid LaTeX document string', () {
      final tex = ScoreCompiler.compileToTex(config, layout);
      expect(tex, contains(r'\documentclass'));
      expect(tex, contains(r'\begin{document}'));
      expect(tex, contains(r'\end{document}'));
    });

    test('compileToSvg produces valid SVG XML document string', () {
      final svg = ScoreCompiler.compileToSvg(config, layout);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
    });

    test('compileToPdf produces non-empty byte buffer', () async {
      final pdfBytes = await ScoreCompiler.compileToPdf(config, layout);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });
  });
}
