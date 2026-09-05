// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('StaffProfile Presets & Application Tests', () {
    test('All built-in profiles are correctly registered in StaffProfiles.all', () {
      expect(StaffProfiles.all.length, equals(13));
      final uniqueIds = StaffProfiles.all.map((p) => p.id).toSet();
      expect(uniqueIds.length, equals(13), reason: 'Every profile must have a unique ID');
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

    test('String Quartet profile generates 4 staves with bracket connector', () {
      final config = StaffProfiles.stringQuartet.applyTo(const PageConfig());
      expect(config.staffCount, equals(4));
      expect(config.systemLayout.rootGroup.connector, equals(SystemConnector.bracket));
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
  });
}
