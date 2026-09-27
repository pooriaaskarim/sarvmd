// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:test/test.dart';

void main() {
  group('SarvDocument .sarv Format & Zero-Data-Loss Serialization Tests', () {
    test('Default SarvDocument round-trips with zero data loss', () {
      const original = SarvDocument();
      final jsonStr = original.toSarvJson();
      final restored = SarvDocument.parseSarvJson(jsonStr);

      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
      expect(restored.pageCount, equals(1));
      expect(restored.metadata.title, equals(''));
      expect(restored.config.pageSize, equals(PageSize.a4));
      expect(restored.config.orientation, equals(PageOrientation.portrait));
    });

    test('All 14 built-in StaffProfiles round-trip with zero data loss', () {
      for (final profile in StaffProfiles.all) {
        final doc = SarvDocument(
          score: Score(title: profile.label),
          config: profile.applyTo(const PageConfig()),
          metadata: DocumentMetadata(
            title: profile.label,
            profileId: profile.id,
            composer: 'Composer Name',
          ),
          pageCount: 3,
        );

        final jsonString = doc.toSarvJson();
        final restored = SarvDocument.parseSarvJson(jsonString);

        expect(
          restored,
          equals(doc),
          reason: 'Failed zero-data-loss round-trip for preset: ${profile.id}',
        );
        expect(
          restored.hashCode,
          equals(doc.hashCode),
          reason: 'HashCode mismatch for preset: ${profile.id}',
        );
        expect(restored.metadata.profileId, equals(profile.id));
        expect(restored.pageCount, equals(3));
      }
    });

    test('Complex custom manuscript with nested groups, notes, and metadata round-trips losslessly', () {
      final created = DateTime.utc(2026, 9, 28, 12, 0, 0);
      final modified = DateTime.utc(2026, 9, 28, 14, 30, 0);

      final complexDoc = SarvDocument(
        pageCount: 8,
        metadata: DocumentMetadata(
          title: 'Symphony No. 5 in C minor',
          subtitle: 'Op. 67',
          composer: 'Ludwig van Beethoven',
          arranger: 'Pooria Askari',
          lyricist: 'N/A',
          copyright: 'Public Domain',
          profileId: 'chamberOrchestra',
          createdAt: created,
          modifiedAt: modified,
          customProperties: {
            'rehearsalMarks': ['A', 'B', 'C'],
            'tempoBpm': 108,
          },
        ),
        config: const PageConfig(
          pageSize: PageSize.a3,
          orientation: PageOrientation.landscape,
          margins: Margins(top: 22.5, bottom: 25.0, left: 30.0, right: 18.0),
          staffConfig: StaffConfig(
            lineGapMm: 2.125,
            lineThicknessPt: 0.45,
            systemGapMm: 18.0,
            interStaffGapMm: 9.5,
          ),
          engraving: EngravingConfig(
            initialClefClearanceSp: 0.75,
            clefToKeySignatureSp: 1.1,
            keySignatureToTimeSignatureSp: 1.25,
            keySignatureAccidentalSpacingSp: 0.85,
            heavyBarlineWidthSp: 0.4,
            singleLineStaffBarlineOverhangSp: 0.9,
            smuflGlyphScale: 0.0038,
          ),
          systemLayout: SystemLayout(
            rootGroup: StaffNodeGroup(
              connector: SystemConnector.bracket,
              continuousBarlines: true,
              initialBarline: true,
              label: 'Full Orchestra',
              abbreviation: 'Orch.',
              labelVisible: true,
              children: [
                StaffDefinition(
                  uid: 'flute-1',
                  lines: 5,
                  clef: Clef.treble,
                  instrumentName: 'Flute',
                  instrumentAbbreviation: 'Fl.',
                  scale: 0.95,
                  labelHorizontalOffset: -2.5,
                  labelVerticalOffset: 1.0,
                  labelFontSize: 12.0,
                  labelItalic: false,
                  barlineStyle: BarlineStyle.standard,
                ),
                StaffNodeGroup(
                  connector: SystemConnector.subBracket,
                  continuousBarlines: true,
                  initialBarline: false,
                  label: 'Strings',
                  abbreviation: 'Str.',
                  children: [
                    StaffDefinition(
                      uid: 'vln-1',
                      lines: 5,
                      clef: Clef.treble,
                      instrumentName: 'Violin I',
                      instrumentAbbreviation: 'Vln. 1',
                    ),
                    StaffDefinition(
                      uid: 'vln-2',
                      lines: 5,
                      clef: Clef.treble,
                      instrumentName: 'Violin II',
                      instrumentAbbreviation: 'Vln. 2',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        score: const Score(
          title: 'Symphony No. 5 in C minor',
        ),
      );

      final jsonStr = complexDoc.toSarvJson(pretty: true);
      expect(jsonStr, contains(r'"$schema": "https://sarvmd.org/schemas/v1/sarv.json"'));
      expect(jsonStr, contains('"format": "sarv"'));
      expect(jsonStr, contains('"version": 1'));

      final restored = SarvDocument.parseSarvJson(jsonStr);

      expect(restored, equals(complexDoc));
      expect(restored.hashCode, equals(complexDoc.hashCode));
      expect(restored.metadata.title, equals('Symphony No. 5 in C minor'));
      expect(restored.metadata.subtitle, equals('Op. 67'));
      expect(restored.metadata.composer, equals('Ludwig van Beethoven'));
      expect(restored.metadata.createdAt, equals(created));
      expect(restored.metadata.modifiedAt, equals(modified));
      expect(restored.metadata.customProperties['tempoBpm'], equals(108));
      expect(restored.pageCount, equals(8));
      expect(restored.config.pageSize, equals(PageSize.a3));
      expect(restored.config.orientation, equals(PageOrientation.landscape));
      expect(restored.config.margins.top, equals(22.5));
      expect(restored.config.allStaves.length, equals(3));
    });

    test('Schema validation rejects mismatched format', () {
      final invalidJson = '''
      {
        "format": "musicxml",
        "version": 1
      }
      ''';

      expect(
        () => SarvDocument.parseSarvJson(invalidJson),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported document format: Expected "sarv", got "musicxml"'),
        )),
      );
    });

    test('Schema validation rejects future unsupported schema versions', () {
      final futureJson = '''
      {
        "format": "sarv",
        "version": 99
      }
      ''';

      expect(
        () => SarvDocument.parseSarvJson(futureJson),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported .sarv version 99'),
        )),
      );
    });

    test('Legacy or sparse JSON map deserializes with robust defaults', () {
      final sparseJson = '''
      {
        "config": {
          "pageSize": "letter"
        }
      }
      ''';

      final doc = SarvDocument.parseSarvJson(sparseJson);
      expect(doc.config.pageSize, equals(PageSize.letter));
      expect(doc.pageCount, equals(1));
      expect(doc.metadata.title, equals(''));
      expect(doc.score.title, equals(''));
    });
  });
}
