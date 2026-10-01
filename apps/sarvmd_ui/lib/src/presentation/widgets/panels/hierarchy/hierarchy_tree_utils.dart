// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Recursively counts all staves within a group hierarchy.
int countStaves(core.StaffNodeGroup group) {
  int count = 0;
  for (final child in group.children) {
    if (child is core.StaffDefinition) {
      count++;
    } else if (child is core.StaffNodeGroup) {
      count += countStaves(child);
    }
  }
  return count;
}

/// Recursively checks whether a group hierarchy contains a child group with [targetHash].
bool groupContains(core.StaffNodeGroup parent, int targetHash) {
  if (parent.hashCode == targetHash) return true;
  for (final child in parent.children) {
    if (child is core.StaffNodeGroup) {
      if (child.hashCode == targetHash || groupContains(child, targetHash)) {
        return true;
      }
    }
  }
  return false;
}

/// Computes the destination index when moving an item within or across groups.
int computeTargetIndex({
  required int sourceGroupHash,
  required int targetGroupHash,
  required int sourceIndex,
  required int targetIndex,
  required bool insertAfter,
}) {
  if (sourceGroupHash == targetGroupHash) {
    if (insertAfter) {
      return sourceIndex < targetIndex ? targetIndex : targetIndex + 1;
    } else {
      return sourceIndex < targetIndex ? targetIndex - 1 : targetIndex;
    }
  } else {
    return insertAfter ? targetIndex + 1 : targetIndex;
  }
}
