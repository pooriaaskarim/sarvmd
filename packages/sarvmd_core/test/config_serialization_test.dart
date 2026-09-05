// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('PageConfig & Component Serialization Tests', () {
    test('Default PageConfig round-trips via JSON accurately', () {
      const original = PageConfig();
      final jsonMap = original.toJson();
      final restored = PageConfig.fromJson(jsonMap);

      expect(restored.pageSize, equals(original.pageSize));
      expect(restored.orientation, equals(original.orientation));
      expect(restored.margins.top, equals(original.margins.top));
      expect(restored.margins.bottom, equals(original.margins.bottom));
      expect(restored.margins.left, equals(original.margins.left));
      expect(restored.margins.right, equals(original.margins.right));
      expect(restored.staffConfig.lineGapMm, equals(original.staffConfig.lineGapMm));
      expect(restored.staffConfig.systemGapMm, equals(original.staffConfig.systemGapMm));
      expect(restored.staffConfig.interStaffGapMm, equals(original.staffConfig.interStaffGapMm));
      expect(restored.staffCount, equals(original.staffCount));
    });

    test('Custom PageConfig with nested groups round-trips via JSON', () {
      const customConfig = PageConfig(
        pageSize: PageSize.a3,
        orientation: PageOrientation.landscape,
        margins: Margins(top: 20.0, bottom: 25.0, left: 30.0, right: 10.0),
        staffConfig: StaffConfig(
          lineGapMm: 2.5,
          lineThicknessPt: 0.5,
          interStaffGapMm: 12.0,
          systemGapMm: 24.0,
        ),
        engraving: EngravingConfig(
          initialClefClearanceSp: 0.8,
          clefToKeySignatureSp: 1.2,
          keySignatureToTimeSignatureSp: 1.5,
        ),
        systemLayout: SystemLayout(
          rootGroup: StaffGroup(
            connector: SystemConnector.bracket,
            children: [
              StaffDefinition(
                uid: 'staff-1',
                lines: 5,
                clef: Clef.treble,
                instrumentName: 'Violin 1',
                instrumentAbbreviation: 'Vln. 1',
              ),
              StaffGroup(
                connector: SystemConnector.brace,
                children: [
                  StaffDefinition(
                    uid: 'staff-2',
                    lines: 5,
                    clef: Clef.alto,
                    instrumentName: 'Viola',
                  ),
                  StaffDefinition(
                    uid: 'staff-3',
                    lines: 5,
                    clef: Clef.bass,
                    instrumentName: 'Cello',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      final jsonMap = customConfig.toJson();
      final restored = PageConfig.fromJson(jsonMap);

      expect(restored.pageSize, equals(PageSize.a3));
      expect(restored.orientation, equals(PageOrientation.landscape));
      expect(restored.margins.top, equals(20.0));
      expect(restored.margins.left, equals(30.0));
      expect(restored.staffConfig.lineGapMm, equals(2.5));
      expect(restored.engraving.initialClefClearanceSp, equals(0.8));
      expect(restored.staffCount, equals(3));
    });

    test('PageConfig.fromJson handles empty JSON maps with default values', () {
      final restored = PageConfig.fromJson({});
      expect(restored.pageSize, equals(PageSize.a4));
      expect(restored.orientation, equals(PageOrientation.portrait));
      expect(restored.margins.top, equals(15.0));
      expect(restored.staffConfig.lineGapMm, equals(1.80));
    });

    test('StaffDefinition JSON serialization preserves labels and offsets', () {
      const def = StaffDefinition(
        uid: 'stf-custom',
        lines: 6,
        scale: 1.2,
        instrumentName: 'Electric Guitar',
        instrumentAbbreviation: 'E.Gtr',
        labelVisible: true,
        labelHorizontalOffset: -5.0,
        labelVerticalOffset: 2.0,
        barlineStyle: BarlineStyle.dashed,
      );

      final json = def.toJson();
      final restored = StaffDefinition.fromJson(json);

      expect(restored.uid, equals('stf-custom'));
      expect(restored.lines, equals(6));
      expect(restored.scale, equals(1.2));
      expect(restored.instrumentName, equals('Electric Guitar'));
      expect(restored.instrumentAbbreviation, equals('E.Gtr'));
      expect(restored.labelHorizontalOffset, equals(-5.0));
      expect(restored.barlineStyle, equals(BarlineStyle.dashed));
    });
  });
}
