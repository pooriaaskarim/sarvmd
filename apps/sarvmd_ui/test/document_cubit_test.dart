// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';

import 'package:shared_preferences/shared_preferences.dart';

class _TestTitleUpdateCommand extends core.DocumentCommand {
  final String newTitle;
  final String oldTitle;

  const _TestTitleUpdateCommand(this.newTitle, this.oldTitle);

  @override
  String get label => 'Update Title';

  @override
  core.SarvDocument execute(core.SarvDocument current) {
    return current.copyWith(
      score: current.score.copyWith(title: newTitle),
    );
  }

  @override
  core.SarvDocument undo(core.SarvDocument current) {
    return current.copyWith(
      score: current.score.copyWith(title: oldTitle),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentCubit & DocumentCommand Pipeline Tests', () {
    late DocumentCubit cubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cubit = DocumentCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial DocumentState has default document and empty undo/redo stacks', () {
      expect(cubit.state.score.title, equals(''));
      expect(cubit.state.undoStack, isEmpty);
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.state.canUndo, isFalse);
      expect(cubit.state.canRedo, isFalse);
    });

    test('Executing command updates score and pushes to undo stack', () {
      const command = _TestTitleUpdateCommand('Symphony No. 1', '');
      cubit.execute(command);

      expect(cubit.state.score.title, equals('Symphony No. 1'));
      expect(cubit.state.undoStack.length, equals(1));
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.state.canUndo, isTrue);
      expect(cubit.state.canRedo, isFalse);
      expect(cubit.state.lastUndoLabel, equals('Update Title'));
    });

    test('Undo reverts score mutation and moves command to redo stack', () {
      const command = _TestTitleUpdateCommand('Symphony No. 1', '');
      cubit.execute(command);
      cubit.undo();

      expect(cubit.state.score.title, equals(''));
      expect(cubit.state.undoStack, isEmpty);
      expect(cubit.state.redoStack.length, equals(1));
      expect(cubit.state.canUndo, isFalse);
      expect(cubit.state.canRedo, isTrue);
      expect(cubit.state.lastRedoLabel, equals('Update Title'));
    });

    test('Redo re-applies command and moves command back to undo stack', () {
      const command = _TestTitleUpdateCommand('Symphony No. 1', '');
      cubit.execute(command);
      cubit.undo();
      cubit.redo();

      expect(cubit.state.score.title, equals('Symphony No. 1'));
      expect(cubit.state.undoStack.length, equals(1));
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.state.canUndo, isTrue);
      expect(cubit.state.canRedo, isFalse);
    });

    test('PageConfig mutations are transactional with undo/redo', () {
      expect(cubit.state.config.pageSize, equals(core.PageSize.a4));

      cubit.updatePageSize(core.PageSize.letter);
      expect(cubit.state.config.pageSize, equals(core.PageSize.letter));
      expect(cubit.state.lastUndoLabel, equals('Set Page Size'));

      cubit.undo();
      expect(cubit.state.config.pageSize, equals(core.PageSize.a4));

      cubit.redo();
      expect(cubit.state.config.pageSize, equals(core.PageSize.letter));
    });

    test('removeStaffByUid removes targeted staff from nested group hierarchy', () {
      cubit.applyProfile(core.StaffProfiles.stringQuartet);
      final staves = cubit.allStaves;
      expect(staves.length, equals(4));

      final targetUid = staves[1].uid;
      cubit.removeStaffByUid(targetUid);

      final remaining = cubit.allStaves;
      expect(remaining.length, equals(3));
      expect(remaining.any((s) => s.uid == targetUid), isFalse);
    });

    test('ungroupSubGroup dissolves sub-group and promotes staves to parent', () {
      cubit.applyProfile(core.StaffProfiles.chamberOrchestra);
      final root = cubit.state.config.systemLayout.rootGroup;
      expect(root.children.first, isA<core.StaffNodeGroup>());
      final subGroup = root.children.first as core.StaffNodeGroup;

      cubit.ungroupSubGroup(subGroup.hashCode);

      final newRoot = cubit.state.config.systemLayout.rootGroup;
      expect(newRoot.children.every((c) => c is core.StaffDefinition), isTrue);
    });

    test('moveStaffNode moves staff out of sub-group into root group without removing it', () {
      cubit.applyProfile(core.StaffProfiles.chamberOrchestra);
      final initialStaves = cubit.allStaves;
      final initialCount = initialStaves.length;

      final root = cubit.state.config.systemLayout.rootGroup;
      final subGroup = root.children.first as core.StaffNodeGroup;

      cubit.moveStaffNode(
        sourceGroupHash: subGroup.hashCode,
        targetGroupHash: root.hashCode,
        sourceIndex: 0,
        targetIndex: root.children.length,
      );

      final newStaves = cubit.allStaves;
      expect(newStaves.length, equals(initialCount));

      final newRoot = cubit.state.config.systemLayout.rootGroup;
      expect(newRoot.children.last, isA<core.StaffDefinition>());
    });

    test('NoOpCommand leaves document untouched', () {
      const noop = core.NoOpCommand();
      cubit.execute(noop);

      expect(cubit.state.score.title, equals(''));
      expect(cubit.state.undoStack.length, equals(1));
    });
  });
}
