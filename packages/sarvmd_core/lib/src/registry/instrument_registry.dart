// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../domain/clef.dart';

/// Predefined instrument configuration preset.
class InstrumentPreset {
  final String name;
  final String abbreviation;
  final Clef? defaultClef;
  final int defaultLines;

  const InstrumentPreset({
    required this.name,
    required this.abbreviation,
    this.defaultClef,
    this.defaultLines = 5,
  });
}

/// Grouping of instrument presets by orchestra/band section family.
class InstrumentPresetFamily {
  final String name;
  final List<InstrumentPreset> instruments;

  const InstrumentPresetFamily({
    required this.name,
    required this.instruments,
  });
}

/// Standard instrument registry containing presets for standard orchestral, band, tab, and percussion instruments.
abstract final class InstrumentPresets {
  static const woodwinds = InstrumentPresetFamily(
    name: 'Woodwinds',
    instruments: [
      InstrumentPreset(
        name: 'Piccolo',
        abbreviation: 'Picc.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Flute',
        abbreviation: 'Fl.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Alto Flute',
        abbreviation: 'A. Fl.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Oboe',
        abbreviation: 'Ob.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'English Horn',
        abbreviation: 'E. Hn.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Clarinet in B♭',
        abbreviation: 'Cl. (B♭)',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Clarinet in A',
        abbreviation: 'Cl. (A)',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Bass Clarinet',
        abbreviation: 'B. Cl.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Bassoon',
        abbreviation: 'Bsn.',
        defaultClef: Clef.bass,
      ),
      InstrumentPreset(
        name: 'Contrabassoon',
        abbreviation: 'C. Bsn.',
        defaultClef: Clef.bass,
      ),
    ],
  );

  static const brass = InstrumentPresetFamily(
    name: 'Brass',
    instruments: [
      InstrumentPreset(
        name: 'Horn in F',
        abbreviation: 'Hn.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Trumpet in B♭',
        abbreviation: 'Tpt. (B♭)',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Trumpet in C',
        abbreviation: 'Tpt. (C)',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Trombone',
        abbreviation: 'Tbn.',
        defaultClef: Clef.bass,
      ),
      InstrumentPreset(
        name: 'Bass Trombone',
        abbreviation: 'B. Tbn.',
        defaultClef: Clef.bass,
      ),
      InstrumentPreset(
        name: 'Tuba',
        abbreviation: 'Tba.',
        defaultClef: Clef.bass,
      ),
    ],
  );

  static const percussion = InstrumentPresetFamily(
    name: 'Percussion',
    instruments: [
      InstrumentPreset(
        name: 'Timpani',
        abbreviation: 'Timp.',
        defaultClef: Clef.bass,
      ),
      InstrumentPreset(
        name: 'Snare Drum',
        abbreviation: 'S.D.',
        defaultClef: Clef.percussion,
      ),
      InstrumentPreset(
        name: 'Bass Drum',
        abbreviation: 'B.D.',
        defaultClef: Clef.percussion,
        defaultLines: 1,
      ),
      InstrumentPreset(
        name: 'Cymbals',
        abbreviation: 'Cym.',
        defaultClef: Clef.percussion,
        defaultLines: 1,
      ),
      InstrumentPreset(
        name: 'Triangle',
        abbreviation: 'Trgl.',
        defaultClef: Clef.percussion,
        defaultLines: 1,
      ),
      InstrumentPreset(
        name: 'Drum Set',
        abbreviation: 'Drs.',
        defaultClef: Clef.percussion,
      ),
      InstrumentPreset(
        name: 'Glockenspiel',
        abbreviation: 'Glock.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Xylophone',
        abbreviation: 'Xyl.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Marimba',
        abbreviation: 'Mar.',
        defaultClef: Clef.treble,
      ),
    ],
  );

  static const strings = InstrumentPresetFamily(
    name: 'Strings',
    instruments: [
      InstrumentPreset(
        name: 'Violin I',
        abbreviation: 'Vln. I',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Violin II',
        abbreviation: 'Vln. II',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Viola',
        abbreviation: 'Vla.',
        defaultClef: Clef.alto,
      ),
      InstrumentPreset(
        name: 'Violoncello',
        abbreviation: 'Vc.',
        defaultClef: Clef.bass,
      ),
      InstrumentPreset(
        name: 'Double Bass',
        abbreviation: 'D.B.',
        defaultClef: Clef.bass,
      ),
      InstrumentPreset(
        name: 'Harp',
        abbreviation: 'Hp.',
        defaultClef: Clef.treble,
      ),
    ],
  );

  static const keyboardPlucked = InstrumentPresetFamily(
    name: 'Keyboard & Plucked',
    instruments: [
      InstrumentPreset(
        name: 'Piano',
        abbreviation: 'Pno.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Organ',
        abbreviation: 'Org.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Harpsichord',
        abbreviation: 'Hpschd.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Classical Guitar',
        abbreviation: 'Gtr.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Acoustic Guitar',
        abbreviation: 'Ac. Gtr.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Electric Guitar',
        abbreviation: 'El. Gtr.',
        defaultClef: Clef.treble,
      ),
      InstrumentPreset(
        name: 'Electric Bass',
        abbreviation: 'El. Bass',
        defaultClef: Clef.bass,
      ),
      InstrumentPreset(
        name: 'Guitar TAB',
        abbreviation: 'Gtr. TAB',
        defaultClef: Clef.tab,
        defaultLines: 6,
      ),
      InstrumentPreset(
        name: 'Bass TAB',
        abbreviation: 'Bass TAB',
        defaultClef: Clef.tab,
        defaultLines: 4,
      ),
    ],
  );

  static const allFamilies = [
    woodwinds,
    brass,
    percussion,
    strings,
    keyboardPlucked,
  ];

  static List<InstrumentPreset> get allPresets =>
      allFamilies.expand((f) => f.instruments).toList();

  /// Looks up an instrument preset by full name or abbreviation (case-insensitive).
  static InstrumentPreset? findByName(String name) {
    final query = name.trim().toLowerCase();
    for (final p in allPresets) {
      if (p.name.toLowerCase() == query || p.abbreviation.toLowerCase() == query) {
        return p;
      }
    }
    return null;
  }
}
