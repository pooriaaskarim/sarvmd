// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:sarvmd_composer/sarvmd_composer.dart';

void main() {
  group('MusicXmlTranscriber', () {
    test('scoreToMusicXml generates valid MusicXML header and tags', () {
      final score = const Score(
        title: 'Symphony No. 5',
        parts: [
          Part(id: 'vln1', name: 'Violin I', measures: []),
        ],
      );

      final xml = MusicXmlTranscriber.scoreToMusicXml(score);
      expect(xml, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(xml, contains('<work-title>Symphony No. 5</work-title>'));
      expect(xml, contains('<part-name>Violin I</part-name>'));
    });

    test('musicXmlToScore extracts title from XML source', () {
      const xml = '''
<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="4.0">
  <work>
    <work-title>Nocturne Op. 9 No. 2</work-title>
  </work>
</score-partwise>
''';

      final score = MusicXmlTranscriber.musicXmlToScore(xml);
      expect(score.title, equals('Nocturne Op. 9 No. 2'));
    });
  });
}
