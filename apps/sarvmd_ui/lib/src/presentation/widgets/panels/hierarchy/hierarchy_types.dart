// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Drag payload for an individual staff node in the hierarchy tree.
typedef StaffDragPayload = ({
  core.StaffDefinition staff,
  int parentGroupHash,
  int index,
});

/// Drag payload for a group node in the hierarchy tree.
typedef GroupDragPayload = ({
  core.StaffNodeGroup group,
  int parentGroupHash,
  int index,
});

/// Shared coordinator for tree drag-and-drop operations and hover tracking.
abstract final class HierarchyDragState {
  static Object? activeDropToken;
  static Object? hoveredChildDropPayload;
}
