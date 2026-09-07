// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../config.dart';
import '../domain/document.dart';
import '../profiles.dart';
import 'document_command.dart';

/// Base class for commands that mutate the physical [PageConfig] layout.
abstract class PageConfigCommand extends DocumentCommand {
  PageConfig? _previousConfig;

  PageConfigCommand();

  /// Computes the new [PageConfig] state given the [current] config.
  PageConfig mutateConfig(PageConfig current);

  @override
  SarvDocument execute(SarvDocument current) {
    _previousConfig = current.config;
    final updatedConfig = mutateConfig(current.config);
    return current.copyWith(config: updatedConfig);
  }

  @override
  SarvDocument undo(SarvDocument current) {
    if (_previousConfig == null) return current;
    return current.copyWith(config: _previousConfig);
  }
}

/// Command to change page size (e.g. A4, Letter).
class SetPageSizeCommand extends PageConfigCommand {
  final PageSize size;
  SetPageSizeCommand(this.size);

  @override
  String get label => 'Set Page Size';

  @override
  PageConfig mutateConfig(PageConfig current) => current.copyWith(pageSize: size);

  @override
  bool canCoalesceWith(DocumentCommand other) => other is SetPageSizeCommand;

  @override
  DocumentCommand coalesceWith(DocumentCommand other) {
    final next = other as SetPageSizeCommand;
    final merged = SetPageSizeCommand(next.size);
    merged._previousConfig = _previousConfig;
    return merged;
  }
}

/// Command to change page orientation (portrait, landscape).
class SetOrientationCommand extends PageConfigCommand {
  final PageOrientation orientation;
  SetOrientationCommand(this.orientation);

  @override
  String get label => 'Set Orientation';

  @override
  PageConfig mutateConfig(PageConfig current) =>
      current.copyWith(orientation: orientation);

  @override
  bool canCoalesceWith(DocumentCommand other) => other is SetOrientationCommand;

  @override
  DocumentCommand coalesceWith(DocumentCommand other) {
    final next = other as SetOrientationCommand;
    final merged = SetOrientationCommand(next.orientation);
    merged._previousConfig = _previousConfig;
    return merged;
  }
}

/// Command to update page margins.
class SetMarginsCommand extends PageConfigCommand {
  final Margins margins;
  SetMarginsCommand(this.margins);

  @override
  String get label => 'Set Margins';

  @override
  PageConfig mutateConfig(PageConfig current) => current.copyWith(margins: margins);

  @override
  bool canCoalesceWith(DocumentCommand other) => other is SetMarginsCommand;

  @override
  DocumentCommand coalesceWith(DocumentCommand other) {
    final next = other as SetMarginsCommand;
    final merged = SetMarginsCommand(next.margins);
    merged._previousConfig = _previousConfig;
    return merged;
  }
}

/// Command to update staff spacing / line thickness configuration.
class SetStaffConfigCommand extends PageConfigCommand {
  final StaffConfig staffConfig;
  SetStaffConfigCommand(this.staffConfig);

  @override
  String get label => 'Set Staff Spacing';

  @override
  PageConfig mutateConfig(PageConfig current) =>
      current.copyWith(staffConfig: staffConfig);

  @override
  bool canCoalesceWith(DocumentCommand other) => other is SetStaffConfigCommand;

  @override
  DocumentCommand coalesceWith(DocumentCommand other) {
    final next = other as SetStaffConfigCommand;
    final merged = SetStaffConfigCommand(next.staffConfig);
    merged._previousConfig = _previousConfig;
    return merged;
  }
}

/// Command to set the system layout tree explicitly.
class SetSystemLayoutCommand extends PageConfigCommand {
  final SystemLayout systemLayout;
  final String _label;

  SetSystemLayoutCommand(this.systemLayout, [this._label = 'Update System Layout']);

  @override
  String get label => _label;

  @override
  PageConfig mutateConfig(PageConfig current) =>
      current.copyWith(systemLayout: systemLayout);
}

/// Command to add a staff node to the system layout root.
class AddStaffCommand extends PageConfigCommand {
  final StaffDefinition? def;

  AddStaffCommand({this.def});

  @override
  String get label => 'Add Staff';

  @override
  PageConfig mutateConfig(PageConfig current) {
    final root = current.systemLayout.rootGroup;
    final newDef = (def ?? const StaffDefinition()).copyWith(
      uid: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    final newChildren = List<StaffNode>.from(root.children)..add(newDef);
    return current.copyWith(
      systemLayout: current.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ),
    );
  }
}

/// Command to remove a staff node from the root group by index.
class RemoveStaffCommand extends PageConfigCommand {
  final int index;
  RemoveStaffCommand(this.index);

  @override
  String get label => 'Remove Staff';

  @override
  PageConfig mutateConfig(PageConfig current) {
    final root = current.systemLayout.rootGroup;
    if (index < 0 || index >= root.children.length) return current;
    if (root.children.length <= 1) return current;

    final newChildren = List<StaffNode>.from(root.children)..removeAt(index);
    return current.copyWith(
      systemLayout: current.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ),
    );
  }
}

/// Command to remove a staff node by its unique identifier (UID).
class RemoveStaffByUidCommand extends PageConfigCommand {
  final String uid;
  RemoveStaffByUidCommand(this.uid);

  @override
  String get label => 'Remove Staff';

  @override
  PageConfig mutateConfig(PageConfig current) {
    final root = current.systemLayout.rootGroup;
    if (root.children.length <= 1) return current;

    final newChildren = root.children.where((child) {
      if (child is StaffDefinition) {
        return child.uid != uid;
      }
      return true;
    }).toList();

    if (newChildren.length == root.children.length) return current;

    return current.copyWith(
      systemLayout: current.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ),
    );
  }
}

/// Command to mutate specific properties of a staff node matching a target UID.
class UpdateStaffByUidCommand extends PageConfigCommand {
  final String uid;
  final StaffDefinition Function(StaffDefinition) updater;
  final String _label;

  UpdateStaffByUidCommand(
    this.uid,
    this.updater, [
    this._label = 'Edit Staff',
  ]);

  @override
  String get label => _label;

  @override
  PageConfig mutateConfig(PageConfig current) {
    final root = current.systemLayout.rootGroup;

    StaffNode findAndUpdate(StaffNode node) {
      return switch (node) {
        StaffDefinition def => def.uid == uid ? updater(def) : def,
        StaffNodeGroup group => group.copyWith(
            children: group.children.map(findAndUpdate).toList(),
          ),
      };
    }

    final newRoot = findAndUpdate(root) as StaffNodeGroup;
    return current.copyWith(
      systemLayout: current.systemLayout.copyWith(rootGroup: newRoot),
    );
  }
}

/// Command to change system group connector (brace, bracket, none).
class UpdateGroupConnectorCommand extends PageConfigCommand {
  final SystemConnector connector;
  UpdateGroupConnectorCommand(this.connector);

  @override
  String get label => 'Set System Connector';

  @override
  PageConfig mutateConfig(PageConfig current) {
    final root = current.systemLayout.rootGroup;
    return current.copyWith(
      systemLayout: current.systemLayout.copyWith(
        rootGroup: root.copyWith(connector: connector),
      ),
    );
  }
}

/// Command to toggle continuous barlines across staves in a system group.
class UpdateGroupContinuousBarlinesCommand extends PageConfigCommand {
  final bool value;
  UpdateGroupContinuousBarlinesCommand(this.value);

  @override
  String get label => 'Toggle Continuous Barlines';

  @override
  PageConfig mutateConfig(PageConfig current) {
    final root = current.systemLayout.rootGroup;
    return current.copyWith(
      systemLayout: current.systemLayout.copyWith(
        rootGroup: root.copyWith(continuousBarlines: value),
      ),
    );
  }
}

/// Command to reorder children inside a staff group matching a target hash code.
class ReorderGroupChildrenCommand extends PageConfigCommand {
  final int groupHash;
  final int oldIndex;
  final int newIndex;

  ReorderGroupChildrenCommand(this.groupHash, this.oldIndex, this.newIndex);

  @override
  String get label => 'Reorder Staves';

  @override
  PageConfig mutateConfig(PageConfig current) {
    final root = current.systemLayout.rootGroup;

    StaffNode findAndReorder(StaffNode node) {
      if (node is StaffNodeGroup) {
        if (node.hashCode == groupHash) {
          final children = List<StaffNode>.from(node.children);
          final item = children.removeAt(oldIndex);
          children.insert(newIndex, item);
          return node.copyWith(children: children);
        } else {
          final newChildren = node.children.map(findAndReorder).toList();
          return node.copyWith(children: newChildren);
        }
      }
      return node;
    }

    final newRoot = findAndReorder(root) as StaffNodeGroup;
    return current.copyWith(
      systemLayout: current.systemLayout.copyWith(rootGroup: newRoot),
    );
  }
}

/// Command to apply an ensemble staff profile preset to the page layout.
class ApplyProfileCommand extends PageConfigCommand {
  final StaffProfile profile;
  ApplyProfileCommand(this.profile);

  @override
  String get label => 'Apply ${profile.label} Profile';

  @override
  PageConfig mutateConfig(PageConfig current) {
    final newConfig = profile.applyTo(current);
    final root = newConfig.systemLayout.rootGroup;
    final newChildren = root.children.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value;
      if (c is StaffDefinition) {
        return c.copyWith(
          uid: '${DateTime.now().microsecondsSinceEpoch}_$index',
        );
      }
      return c;
    }).toList();

    return newConfig.copyWith(
      systemLayout: newConfig.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ),
    );
  }
}
