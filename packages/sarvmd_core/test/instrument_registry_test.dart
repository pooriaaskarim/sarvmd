// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('InstrumentPresets Registry', () {
    test('allFamilies contains 5 standard instrument families', () {
      expect(InstrumentPresets.allFamilies.length, equals(5));
      final names = InstrumentPresets.allFamilies.map((f) => f.name).toList();
      expect(
        names,
        containsAll([
          'Woodwinds',
          'Brass',
          'Percussion',
          'Strings',
          'Keyboard & Plucked',
        ]),
      );
    });

    test('allPresets aggregates instruments from all families', () {
      final totalInFamilies = InstrumentPresets.allFamilies.fold<int>(
        0,
        (sum, family) => sum + family.instruments.length,
      );
      expect(InstrumentPresets.allPresets.length, equals(totalInFamilies));
      expect(InstrumentPresets.allPresets.length, greaterThan(25));
    });

    test('findByName locates instruments by exact name, case-insensitively', () {
      final flute = InstrumentPresets.findByName('Flute');
      expect(flute, isNotNull);
      expect(flute?.name, equals('Flute'));
      expect(flute?.defaultClef, equals(Clef.treble));

      final fluteLower = InstrumentPresets.findByName('  flute ');
      expect(fluteLower, isNotNull);
      expect(fluteLower?.name, equals('Flute'));

      final cello = InstrumentPresets.findByName('Violoncello');
      expect(cello, isNotNull);
      expect(cello?.defaultClef, equals(Clef.bass));
    });

    test('findByName locates instruments by abbreviation', () {
      final piccolo = InstrumentPresets.findByName('Picc.');
      expect(piccolo, isNotNull);
      expect(piccolo?.name, equals('Piccolo'));

      final bassoon = InstrumentPresets.findByName('bsn.');
      expect(bassoon, isNotNull);
      expect(bassoon?.name, equals('Bassoon'));
      expect(bassoon?.defaultClef, equals(Clef.bass));

      final gtrTab = InstrumentPresets.findByName('Gtr. TAB');
      expect(gtrTab, isNotNull);
      expect(gtrTab?.defaultClef, equals(Clef.tab));
      expect(gtrTab?.defaultLines, equals(6));
    });

    test('findByName returns null for unknown queries', () {
      expect(InstrumentPresets.findByName('NonExistentInstrument'), isNull);
      expect(InstrumentPresets.findByName(''), isNull);
    });

    test('percussion and tab presets specify non-standard line counts', () {
      final bassDrum = InstrumentPresets.findByName('Bass Drum');
      expect(bassDrum, isNotNull);
      expect(bassDrum?.defaultLines, equals(1));
      expect(bassDrum?.defaultClef, equals(Clef.percussion));

      final bassTab = InstrumentPresets.findByName('Bass TAB');
      expect(bassTab, isNotNull);
      expect(bassTab?.defaultLines, equals(4));
      expect(bassTab?.defaultClef, equals(Clef.tab));
    });
  });

  group('LayoutPolicyMode', () {
    test('defines all required directionality modes', () {
      expect(LayoutPolicyMode.values.length, equals(3));
      expect(
        LayoutPolicyMode.values,
        containsAll([
          LayoutPolicyMode.bilingualFluid,
          LayoutPolicyMode.canvasStrict,
          LayoutPolicyMode.documentRtl,
        ]),
      );
    });
  });
}
