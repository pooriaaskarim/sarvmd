// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('SystemLayout & Staff Tree Traversal Tests', () {
    test('PageConfig staffCount recursively counts leaf staves', () {
      const config = PageConfig(
        systemLayout: SystemLayout(
          rootGroup: StaffGroup(
            children: [
              StaffDefinition(lines: 5),
              StaffGroup(
                children: [
                  StaffDefinition(lines: 5),
                  StaffDefinition(lines: 6),
                ],
              ),
              StaffDefinition(lines: 1),
            ],
          ),
        ),
      );

      expect(config.staffCount, equals(4));
    });

    test('PageConfig systemHeight calculates total height including line gaps and staff spacing', () {
      const config = PageConfig(
        staffConfig: StaffConfig(
          lineGapMm: 2.0, // 5-line staff height = 4 * 2.0 = 8.0 mm
          interStaffGapMm: 10.0,
        ),
        systemLayout: SystemLayout(
          rootGroup: StaffGroup(
            children: [
              StaffDefinition(lines: 5, scale: 1.0), // 8.0 mm
              StaffDefinition(lines: 5, scale: 1.0), // 8.0 mm
            ],
          ),
        ),
      );

      // 2 staves = 8.0 + 8.0 + 1 inter-staff gap (10.0) = 26.0 mm
      expect(config.systemHeight, equals(26.0));
    });

    test('Effective page dimensions adjust based on landscape orientation', () {
      const portraitConfig = PageConfig(
        pageSize: PageSize.a4, // 210 x 297
        orientation: PageOrientation.portrait,
      );

      expect(portraitConfig.effectiveWidth, equals(210.0));
      expect(portraitConfig.effectiveHeight, equals(297.0));

      const landscapeConfig = PageConfig(
        pageSize: PageSize.a4,
        orientation: PageOrientation.landscape,
      );

      expect(landscapeConfig.effectiveWidth, equals(297.0));
      expect(landscapeConfig.effectiveHeight, equals(210.0));
    });

    test('Usable dimensions correctly subtract margins', () {
      const config = PageConfig(
        pageSize: PageSize.a4,
        orientation: PageOrientation.portrait,
        margins: Margins(top: 20.0, bottom: 20.0, left: 15.0, right: 15.0),
      );

      // Usable width = 210 - 15 - 15 = 180
      expect(config.usableWidth, equals(180.0));
      // Usable height = 297 - 20 - 20 = 257
      expect(config.usableHeight, equals(257.0));
    });

    test('StaffGroup copyWith supports mutating connector and children', () {
      const original = StaffGroup(
        connector: SystemConnector.none,
        children: [StaffDefinition(lines: 5)],
      );

      final updated = original.copyWith(
        connector: SystemConnector.brace,
        children: [
          const StaffDefinition(lines: 5),
          const StaffDefinition(lines: 5),
        ],
      );

      expect(updated.connector, equals(SystemConnector.brace));
      expect(updated.children.length, equals(2));
    });
  });
}
