// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('StaffProfile Presets & Application Tests', () {
    test('All built-in profiles are correctly registered in StaffProfiles.all', () {
      expect(StaffProfiles.all.length, equals(15));
      final uniqueIds = StaffProfiles.all.map((p) => p.id).toSet();
      expect(uniqueIds.length, equals(15), reason: 'Every profile must have a unique ID');
    });

    test('StaffProfile.applyTo applies profile layout while preserving margins & page config', () {
      const initialConfig = PageConfig(
        pageSize: PageSize.a3,
        orientation: PageOrientation.landscape,
        margins: Margins(top: 25.0, bottom: 25.0, left: 25.0, right: 25.0),
      );

      final pianoConfig = StaffProfiles.piano.applyTo(initialConfig);

      expect(pianoConfig.pageSize, equals(PageSize.a3));
      expect(pianoConfig.orientation, equals(PageOrientation.landscape));
      expect(pianoConfig.margins.top, equals(25.0));
      expect(pianoConfig.staffCount, equals(2));
      expect(pianoConfig.systemLayout.rootGroup.connector, equals(SystemConnector.brace));
    });

    test('String Quartet profile generates 4 staves with bracket connector and unique UIDs', () {
      final config = StaffProfiles.stringQuartet.applyTo(const PageConfig());
      expect(config.staffCount, equals(4));
      expect(config.systemLayout.rootGroup.connector, equals(SystemConnector.bracket));

      final uids = config.allStaves.map((s) => s.uid).toList();
      expect(uids.every((uid) => uid.isNotEmpty), isTrue);
      expect(uids.toSet().length, equals(4), reason: 'Every staff must have a distinct unique UID');
      expect(StaffProfiles.stringQuartet.matches(config), isTrue);
    });

    test('Guitar TAB profile generates 6-line staff', () {
      final config = StaffProfiles.guitarTab.applyTo(const PageConfig());
      expect(config.staffCount, equals(1));
      
      final firstStaff = config.systemLayout.rootGroup.children.first as StaffDefinition;
      expect(firstStaff.lines, equals(6));
      expect(firstStaff.clef, equals(Clef.tab));
    });

    test('Percussion 1-line profile generates single line staff', () {
      final config = StaffProfiles.percussion1.applyTo(const PageConfig());
      expect(config.staffCount, equals(1));

      final firstStaff = config.systemLayout.rootGroup.children.first as StaffDefinition;
      expect(firstStaff.lines, equals(1));
      expect(firstStaff.clef, equals(Clef.percussion));
    });

    test('StaffUIHints fallback to default labels', () {
      const hints = StaffUIHints();
      expect(hints.lineGapLabel, equals('Staff Size'));
      expect(hints.systemGapLabel, equals('System Gap'));
      expect(hints.interStaffGapLabel, equals('Inter-staff Gap'));
    });

    test('StaffProfiles have standard labels, with visibility restricted to ensembles', () {
      // Solo & Standard profiles have hidden labels
      expect(StaffProfiles.piano.systemLayout.rootGroup.labelVisible, isFalse);
      expect(StaffProfiles.piano.systemLayout.rootGroup.label, equals('Piano'));
      expect(StaffProfiles.piano.systemLayout.rootGroup.allStaves.every((s) => !s.labelVisible), isTrue);

      expect(StaffProfiles.treble.systemLayout.rootGroup.allStaves.first.labelVisible, isFalse);
      expect(StaffProfiles.treble.systemLayout.rootGroup.allStaves.first.instrumentName, equals('Treble'));

      expect(StaffProfiles.bass.systemLayout.rootGroup.allStaves.first.labelVisible, isFalse);
      expect(StaffProfiles.bass.systemLayout.rootGroup.allStaves.first.instrumentName, equals('Bass'));

      expect(StaffProfiles.alto.systemLayout.rootGroup.allStaves.first.labelVisible, isFalse);
      expect(StaffProfiles.alto.systemLayout.rootGroup.allStaves.first.instrumentName, equals('Viola'));

      expect(StaffProfiles.guitarTab.systemLayout.rootGroup.allStaves.first.labelVisible, isFalse);
      expect(StaffProfiles.guitarTab.systemLayout.rootGroup.allStaves.first.instrumentName, equals('Guitar TAB'));

      expect(StaffProfiles.guitarGrand.systemLayout.rootGroup.labelVisible, isFalse);
      expect(StaffProfiles.guitarGrand.systemLayout.rootGroup.allStaves.every((s) => !s.labelVisible), isTrue);

      expect(StaffProfiles.drumSet.systemLayout.rootGroup.allStaves.first.labelVisible, isFalse);
      expect(StaffProfiles.drumSet.systemLayout.rootGroup.allStaves.first.instrumentName, equals('Drum Set'));

      // String Quartet: bracket group with standard Gould Roman numerals and abbreviations
      expect(StaffProfiles.stringQuartet.systemLayout.rootGroup.label, equals('String Quartet'));
      expect(StaffProfiles.stringQuartet.systemLayout.rootGroup.abbreviation, equals('Str. Qt.'));
      expect(StaffProfiles.stringQuartet.systemLayout.rootGroup.labelVisible, isFalse);
      final sqStaves = StaffProfiles.stringQuartet.systemLayout.rootGroup.allStaves;
      expect(sqStaves.map((s) => s.instrumentName).toList(), equals(['Violin I', 'Violin II', 'Viola', 'Violoncello']));
      expect(sqStaves.map((s) => s.instrumentAbbreviation).toList(), equals(['Vln. I', 'Vln. II', 'Vla.', 'Vc.']));
      expect(sqStaves.every((s) => s.labelVisible), isTrue);

      // String Orchestra: 5-part strings with sub-bracketed violins
      expect(StaffProfiles.stringOrchestra.systemLayout.rootGroup.label, equals('Strings'));
      expect(StaffProfiles.stringOrchestra.systemLayout.rootGroup.abbreviation, equals('Str.'));
      final soViolins = StaffProfiles.stringOrchestra.systemLayout.rootGroup.children.first as StaffNodeGroup;
      expect(soViolins.label, equals('Violins'));
      expect(soViolins.abbreviation, equals('Vln.'));
      expect(soViolins.numberingStyle, equals(GroupNumberingStyle.none));
      expect(soViolins.labelVisible, isFalse);
      final soStaves = StaffProfiles.stringOrchestra.systemLayout.rootGroup.allStaves;
      expect(soStaves.length, equals(5));
      expect(soStaves.map((s) => s.instrumentName).toList(),
          equals(['Violin I', 'Violin II', 'Viola', 'Violoncello', 'Double Bass']));
      expect(soStaves.map((s) => s.instrumentAbbreviation).toList(),
          equals(['Vln. I', 'Vln. II', 'Vla.', 'Vc.', 'D.B.']));

      // Chamber Orchestra: Woodwinds, Brass, and Strings sections
      final coGroups = StaffProfiles.chamberOrchestra.systemLayout.rootGroup.children
          .whereType<StaffNodeGroup>()
          .toList();
      expect(coGroups.map((g) => g.label).toList(), equals(['Woodwinds', 'Brass', 'Strings']));
      final coStaves = StaffProfiles.chamberOrchestra.systemLayout.rootGroup.allStaves;
      expect(coStaves.length, equals(10));
      expect(coStaves.every((s) => s.labelVisible), isTrue);
      expect(coStaves.every((s) => s.scale == 0.70), isTrue);

      // Verify that Chamber Orchestra defaults to modernHeader (above-staff group headers)
      expect(StaffProfiles.chamberOrchestra.systemLayout.engravingHouseStyle,
          equals(EngravingHouseStyle.modernHeader));

      // Verify that Chamber Orchestra fits 2 systems vertically on standard A4
      final coLayout = computeLayout(StaffProfiles.chamberOrchestra.applyTo(const PageConfig()));
      expect(coLayout.systems.length, equals(2));
    });
  });
}
