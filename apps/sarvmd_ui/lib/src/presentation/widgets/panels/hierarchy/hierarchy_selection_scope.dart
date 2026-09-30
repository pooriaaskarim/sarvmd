import 'package:flutter/material.dart';

/// Scoped inherited widget providing multi-selection state, collapsed groups,
/// and hierarchy interaction callbacks down the tree.
class HierarchySelectionScope extends InheritedWidget {
  const HierarchySelectionScope({
    super.key,
    required this.selectedUids,
    required this.lastSelectedUid,
    required this.collapsedGroupHashes,
    required this.allUidsInOrder,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onToggleCollapseGroup,
    required super.child,
  });

  final Set<String> selectedUids;
  final String? lastSelectedUid;
  final Set<int> collapsedGroupHashes;
  final List<String> allUidsInOrder;
  final void Function(String uid, {bool isShift}) onToggleSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final void Function(int groupHash) onToggleCollapseGroup;

  static HierarchySelectionScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HierarchySelectionScope>();
  }

  @override
  bool updateShouldNotify(HierarchySelectionScope oldWidget) {
    return selectedUids != oldWidget.selectedUids ||
        collapsedGroupHashes != oldWidget.collapsedGroupHashes ||
        lastSelectedUid != oldWidget.lastSelectedUid ||
        allUidsInOrder != oldWidget.allUidsInOrder;
  }
}
