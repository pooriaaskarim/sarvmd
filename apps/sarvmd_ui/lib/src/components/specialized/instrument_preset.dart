import 'package:sarvmd_core/sarvmd_core.dart' as core;

class InstrumentPreset {
  final String name;
  final String abbreviation;
  final core.ClefConfig? defaultClef;
  final int defaultLines;

  const InstrumentPreset({
    required this.name,
    required this.abbreviation,
    this.defaultClef,
    this.defaultLines = 5,
  });
}

class InstrumentPresetFamily {
  final String name;
  final List<InstrumentPreset> instruments;

  const InstrumentPresetFamily({
    required this.name,
    required this.instruments,
  });
}

abstract final class InstrumentPresets {
  static const woodwinds = InstrumentPresetFamily(
    name: 'Woodwinds',
    instruments: [
      InstrumentPreset(
        name: 'Piccolo',
        abbreviation: 'Picc.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Flute',
        abbreviation: 'Fl.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Alto Flute',
        abbreviation: 'A. Fl.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Oboe',
        abbreviation: 'Ob.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'English Horn',
        abbreviation: 'E. Hn.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Clarinet in B♭',
        abbreviation: 'Cl. (B♭)',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Clarinet in A',
        abbreviation: 'Cl. (A)',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Bass Clarinet',
        abbreviation: 'B. Cl.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Bassoon',
        abbreviation: 'Bsn.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
      InstrumentPreset(
        name: 'Contrabassoon',
        abbreviation: 'C. Bsn.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
    ],
  );

  static const brass = InstrumentPresetFamily(
    name: 'Brass',
    instruments: [
      InstrumentPreset(
        name: 'Horn in F',
        abbreviation: 'Hn.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Trumpet in B♭',
        abbreviation: 'Tpt. (B♭)',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Trumpet in C',
        abbreviation: 'Tpt. (C)',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Trombone',
        abbreviation: 'Tbn.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
      InstrumentPreset(
        name: 'Bass Trombone',
        abbreviation: 'B. Tbn.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
      InstrumentPreset(
        name: 'Tuba',
        abbreviation: 'Tba.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
    ],
  );

  static const percussion = InstrumentPresetFamily(
    name: 'Percussion',
    instruments: [
      InstrumentPreset(
        name: 'Timpani',
        abbreviation: 'Timp.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
      InstrumentPreset(
        name: 'Snare Drum',
        abbreviation: 'S.D.',
        defaultClef:
            core.ClefConfig(symbol: core.ClefSymbol.percussion, anchorLine: 3),
      ),
      InstrumentPreset(
        name: 'Bass Drum',
        abbreviation: 'B.D.',
        defaultClef:
            core.ClefConfig(symbol: core.ClefSymbol.percussion, anchorLine: 3),
        defaultLines: 1,
      ),
      InstrumentPreset(
        name: 'Cymbals',
        abbreviation: 'Cym.',
        defaultClef:
            core.ClefConfig(symbol: core.ClefSymbol.percussion, anchorLine: 3),
        defaultLines: 1,
      ),
      InstrumentPreset(
        name: 'Triangle',
        abbreviation: 'Trgl.',
        defaultClef:
            core.ClefConfig(symbol: core.ClefSymbol.percussion, anchorLine: 3),
        defaultLines: 1,
      ),
      InstrumentPreset(
        name: 'Drum Set',
        abbreviation: 'Drs.',
        defaultClef:
            core.ClefConfig(symbol: core.ClefSymbol.percussion, anchorLine: 3),
      ),
      InstrumentPreset(
        name: 'Glockenspiel',
        abbreviation: 'Glock.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Xylophone',
        abbreviation: 'Xyl.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Marimba',
        abbreviation: 'Mar.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
    ],
  );

  static const strings = InstrumentPresetFamily(
    name: 'Strings',
    instruments: [
      InstrumentPreset(
        name: 'Violin I',
        abbreviation: 'Vln. I',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Violin II',
        abbreviation: 'Vln. II',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Viola',
        abbreviation: 'Vla.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.c, anchorLine: 3),
      ),
      InstrumentPreset(
        name: 'Violoncello',
        abbreviation: 'Vc.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
      InstrumentPreset(
        name: 'Double Bass',
        abbreviation: 'D.B.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
      InstrumentPreset(
        name: 'Harp',
        abbreviation: 'Hp.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
    ],
  );

  static const keyboardPlucked = InstrumentPresetFamily(
    name: 'Keyboard & Plucked',
    instruments: [
      InstrumentPreset(
        name: 'Piano',
        abbreviation: 'Pno.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Organ',
        abbreviation: 'Org.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Harpsichord',
        abbreviation: 'Hpschd.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Classical Guitar',
        abbreviation: 'Gtr.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Acoustic Guitar',
        abbreviation: 'Ac. Gtr.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Electric Guitar',
        abbreviation: 'El. Gtr.',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2),
      ),
      InstrumentPreset(
        name: 'Electric Bass',
        abbreviation: 'El. Bass',
        defaultClef: core.ClefConfig(symbol: core.ClefSymbol.f, anchorLine: 4),
      ),
      InstrumentPreset(
        name: 'Guitar TAB',
        abbreviation: 'Gtr. TAB',
        defaultClef:
            core.ClefConfig(symbol: core.ClefSymbol.tab, anchorLine: 3),
        defaultLines: 6,
      ),
      InstrumentPreset(
        name: 'Bass TAB',
        abbreviation: 'Bass TAB',
        defaultClef:
            core.ClefConfig(symbol: core.ClefSymbol.tab, anchorLine: 3),
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
}
