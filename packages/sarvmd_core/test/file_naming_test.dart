// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:test/test.dart';

void main() {
  group('FileNaming', () {
    test('appendIndex places numeric index immediately before file extension', () {
      expect(FileNaming.appendIndex('Piano_A4_Portrait.pdf', 1), equals('Piano_A4_Portrait_1.pdf'));
      expect(FileNaming.appendIndex('Piano_A4_Portrait.sarv', 2), equals('Piano_A4_Portrait_2.sarv'));
      expect(FileNaming.appendIndex('Layout.svg', 3), equals('Layout_3.svg'));
      expect(FileNaming.appendIndex('Document.tex', 1), equals('Document_1.tex'));
      expect(FileNaming.appendIndex('Preview.png', 4), equals('Preview_4.png'));
      expect(FileNaming.appendIndex('Piece.mid', 1), equals('Piece_1.mid'));
    });

    test('appendIndex handles filenames with internal dots correctly', () {
      expect(FileNaming.appendIndex('Piano.Grand.A4.pdf', 1), equals('Piano.Grand.A4_1.pdf'));
      expect(FileNaming.appendIndex('v1.0.final.sarv', 2), equals('v1.0.final_2.sarv'));
    });

    test('appendIndex handles filenames without extension', () {
      expect(FileNaming.appendIndex('Piano_A4_Portrait', 1), equals('Piano_A4_Portrait_1'));
      expect(FileNaming.appendIndex('MyScore', 2), equals('MyScore_2'));
    });

    test('stripExtension removes only trailing extension', () {
      expect(FileNaming.stripExtension('Piano_A4_Portrait.pdf'), equals('Piano_A4_Portrait'));
      expect(FileNaming.stripExtension('Score.sarv'), equals('Score'));
      expect(FileNaming.stripExtension('My.Multi.Dot.File.svg'), equals('My.Multi.Dot.File'));
      expect(FileNaming.stripExtension('NoExtension'), equals('NoExtension'));
    });

    test('getExtension returns extension including leading dot', () {
      expect(FileNaming.getExtension('score.sarv'), equals('.sarv'));
      expect(FileNaming.getExtension('document.pdf'), equals('.pdf'));
      expect(FileNaming.getExtension('no_ext'), equals(''));
    });

    test('disambiguateFileName increments index before extension', () {
      final existing = ['Piano_A4_Portrait.pdf', 'Piano_A4_Portrait_1.pdf'];
      expect(
        FileNaming.disambiguateFileName('Piano_A4_Portrait.pdf', existing),
        equals('Piano_A4_Portrait_2.pdf'),
      );

      final existingSarv = ['MyTemplate.sarv'];
      expect(
        FileNaming.disambiguateFileName('MyTemplate.sarv', existingSarv),
        equals('MyTemplate_1.sarv'),
      );

      // Unique name is returned as-is
      expect(
        FileNaming.disambiguateFileName('Unique.sarv', existingSarv),
        equals('Unique.sarv'),
      );
    });

    test('handles cross-platform directory paths with dots in folders', () {
      expect(
        FileNaming.appendIndex('/home/user.dir/score.pdf', 1),
        equals('/home/user.dir/score_1.pdf'),
      );
      expect(
        FileNaming.appendIndex(r'C:\Users\John.Doe\Documents\Piano.sarv', 2),
        equals(r'C:\Users\John.Doe\Documents\Piano_2.sarv'),
      );
      expect(
        FileNaming.stripExtension('/home/user.dir/score.pdf'),
        equals('/home/user.dir/score'),
      );
      expect(
        FileNaming.getExtension(r'C:\Users\John.Doe\Documents\Piano.sarv'),
        equals('.sarv'),
      );
    });

    test('ensureUniquePath generates unique path placing number before extension', () {
      final existingPaths = {
        '/export/Piano_A4_Portrait.pdf',
        '/export/Piano_A4_Portrait_1.pdf',
      };
      final unique = FileNaming.ensureUniquePath(
        '/export/Piano_A4_Portrait.pdf',
        exists: existingPaths.contains,
      );
      expect(unique, equals('/export/Piano_A4_Portrait_2.pdf'));

      final nonExistent = FileNaming.ensureUniquePath(
        '/export/Unique.pdf',
        exists: existingPaths.contains,
      );
      expect(nonExistent, equals('/export/Unique.pdf'));
    });

    test('ScoreCompiler.sanitizeFileName strips known extensions before sanitizing', () {
      final config = PageConfig();
      expect(ScoreCompiler.sanitizeFileName('Piano_A4_Portrait.sarv', config), equals('Piano_A4_Portrait'));
      expect(ScoreCompiler.sanitizeFileName('MyScore.pdf', config), equals('MyScore'));
      expect(ScoreCompiler.sanitizeFileName('Score.svg', config), equals('Score'));
      expect(ScoreCompiler.sanitizeFileName('Template.tex', config), equals('Template'));
    });
  });
}
