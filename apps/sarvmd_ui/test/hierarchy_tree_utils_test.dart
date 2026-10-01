// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/presentation/widgets/panels/hierarchy/hierarchy_tree_utils.dart';

void main() {
  group('hierarchy_tree_utils tests', () {
    test('countStaves correctly counts all staves in nested groups', () {
      const s1 = core.StaffDefinition(uid: 's1');
      const s2 = core.StaffDefinition(uid: 's2');
      const s3 = core.StaffDefinition(uid: 's3');

      const innerGroup = core.StaffNodeGroup(
        label: 'Inner',
        children: [s2, s3],
      );

      const rootGroup = core.StaffNodeGroup(
        label: 'Root',
        children: [s1, innerGroup],
      );

      expect(countStaves(rootGroup), equals(3));
      expect(countStaves(innerGroup), equals(2));
      expect(countStaves(const core.StaffNodeGroup(label: 'Empty')), equals(0));
    });

    test('groupContains detects nested group hashes correctly', () {
      const s1 = core.StaffDefinition(uid: 's1');
      const innerInner = core.StaffNodeGroup(
        label: 'Level3',
        children: [s1],
      );
      const inner = core.StaffNodeGroup(
        label: 'Level2',
        children: [innerInner],
      );
      const root = core.StaffNodeGroup(
        label: 'Level1',
        children: [inner],
      );

      expect(groupContains(root, root.hashCode), isTrue);
      expect(groupContains(root, inner.hashCode), isTrue);
      expect(groupContains(root, innerInner.hashCode), isTrue);
      expect(groupContains(root, 9999999), isFalse);
    });

    test('computeTargetIndex calculates accurate destination indices', () {
      // Within the same group, inserting before
      expect(
        computeTargetIndex(
          sourceGroupHash: 1,
          targetGroupHash: 1,
          sourceIndex: 1,
          targetIndex: 3,
          insertAfter: false,
        ),
        equals(2),
      );

      // Within the same group, inserting after
      expect(
        computeTargetIndex(
          sourceGroupHash: 1,
          targetGroupHash: 1,
          sourceIndex: 1,
          targetIndex: 3,
          insertAfter: true,
        ),
        equals(3),
      );

      // Moving downwards (sourceIndex > targetIndex)
      expect(
        computeTargetIndex(
          sourceGroupHash: 1,
          targetGroupHash: 1,
          sourceIndex: 4,
          targetIndex: 1,
          insertAfter: false,
        ),
        equals(1),
      );
      expect(
        computeTargetIndex(
          sourceGroupHash: 1,
          targetGroupHash: 1,
          sourceIndex: 4,
          targetIndex: 1,
          insertAfter: true,
        ),
        equals(2),
      );

      // Across different groups
      expect(
        computeTargetIndex(
          sourceGroupHash: 1,
          targetGroupHash: 2,
          sourceIndex: 1,
          targetIndex: 3,
          insertAfter: false,
        ),
        equals(3),
      );
      expect(
        computeTargetIndex(
          sourceGroupHash: 1,
          targetGroupHash: 2,
          sourceIndex: 1,
          targetIndex: 3,
          insertAfter: true,
        ),
        equals(4),
      );
    });
  });
}
