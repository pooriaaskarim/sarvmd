// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('Clef Tests', () {
    test('Clef symbols and default anchor lines', () {
      expect(Clef.treble.symbol, equals(ClefSymbol.g));
      expect(Clef.treble.anchorLine, equals(2));
      expect(Clef.bass.symbol, equals(ClefSymbol.f));
      expect(Clef.bass.anchorLine, equals(4));
      expect(Clef.alto.symbol, equals(ClefSymbol.c));
      expect(Clef.alto.anchorLine, equals(3));
      expect(Clef.tenor.symbol, equals(ClefSymbol.c));
      expect(Clef.tenor.anchorLine, equals(4));
      expect(Clef.percussion.symbol, equals(ClefSymbol.percussion));
      expect(Clef.tab.symbol, equals(ClefSymbol.tab));
    });

    test('Clef anchoring offsets', () {
      expect(Clef.treble.anchorOffsetInSpaces(5), equals(3.0));
      expect(Clef.bass.anchorOffsetInSpaces(5), equals(1.0));
      expect(Clef.percussion.anchorOffsetInSpaces(5), equals(2.0));
      expect(Clef.tab.anchorOffsetInSpaces(6), equals(2.5));
    });
  });

  group('StaffNodeGroupTreeX Tests', () {
    test('updateGroup modifies connector and continuous barlines for target', () {
      const staff1 = StaffDefinition(uid: 's1');
      const staff2 = StaffDefinition(uid: 's2');
      const targetGroup = StaffNodeGroup(
        connector: SystemConnector.none,
        children: [staff1, staff2],
      );
      final root = StaffNodeGroup(
        children: [targetGroup],
      );

      final updated = root.updateGroup(
        targetGroup,
        connector: SystemConnector.brace,
        continuousBarlines: false,
      );

      final sub = updated.children.first as StaffNodeGroup;
      expect(sub.connector, equals(SystemConnector.brace));
      expect(sub.continuousBarlines, isFalse);
    });

    test('ungroup promotes child nodes to parent group', () {
      const staff1 = StaffDefinition(uid: 's1');
      const staff2 = StaffDefinition(uid: 's2');
      const targetGroup = StaffNodeGroup(
        connector: SystemConnector.bracket,
        children: [staff1, staff2],
      );
      final root = StaffNodeGroup(
        children: [targetGroup],
      );

      final ungrouped = root.ungroup(targetGroup);
      expect(ungrouped.children.length, equals(2));
      expect(ungrouped.children[0], equals(staff1));
      expect(ungrouped.children[1], equals(staff2));
    });

    test('groupSelected bundles selected staves into a new sub-group', () {
      const staff1 = StaffDefinition(uid: 's1');
      const staff2 = StaffDefinition(uid: 's2');
      const staff3 = StaffDefinition(uid: 's3');
      final root = StaffNodeGroup(
        children: [staff1, staff2, staff3],
      );

      final grouped = root.groupSelected({'s1', 's2'}, SystemConnector.bracket);
      expect(grouped.children.length, equals(2));
      final sub = grouped.children.first as StaffNodeGroup;
      expect(sub.connector, equals(SystemConnector.bracket));
      expect(sub.children.length, equals(2));
      expect(grouped.children.last, equals(staff3));
    });
  });
}
