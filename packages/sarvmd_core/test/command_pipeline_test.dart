// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('Core ScoreCommand & CommandHistory Engine Tests', () {
    late CommandHistory history;

    setUp(() {
      history = CommandHistory(
        initialScore: const Score(title: 'Initial Title', parts: []),
      );
    });

    test('Initial CommandHistory state', () {
      expect(history.score.title, equals('Initial Title'));
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
      expect(history.undoStack, isEmpty);
      expect(history.redoStack, isEmpty);
    });

    test('SetTitleCommand updates score title and undoes accurately', () {
      history.execute(SetTitleCommand('Symphony No. 5', 'Initial Title'));
      expect(history.score.title, equals('Symphony No. 5'));
      expect(history.canUndo, isTrue);

      history.undo();
      expect(history.score.title, equals('Initial Title'));
      expect(history.canRedo, isTrue);

      history.redo();
      expect(history.score.title, equals('Symphony No. 5'));
    });

    test('AddPartCommand and RemovePartCommand mutate parts list transactionally', () {
      const part1 = Part(id: 'vln1', name: 'Violin I');
      const part2 = Part(id: 'vln2', name: 'Violin II');

      history.execute(const AddPartCommand(part1));
      history.execute(const AddPartCommand(part2));
      expect(history.score.parts.length, equals(2));
      expect(history.score.parts[0].id, equals('vln1'));

      history.execute(RemovePartCommand('vln1'));
      expect(history.score.parts.length, equals(1));
      expect(history.score.parts.first.id, equals('vln2'));

      history.undo();
      expect(history.score.parts.length, equals(2));
      expect(history.score.parts[0].id, equals('vln1'));
    });

    test('AddMeasureCommand and RemoveMeasureCommand mutate measures transactionally', () {
      const part = Part(id: 'flute', name: 'Flute');
      history.execute(const AddPartCommand(part));

      const m1 = Measure(number: 1);
      const m2 = Measure(number: 2);

      history.execute(const AddMeasureCommand('flute', m1));
      history.execute(const AddMeasureCommand('flute', m2));

      expect(history.score.parts.first.measures.length, equals(2));

      history.execute(RemoveMeasureCommand('flute', 1));
      expect(history.score.parts.first.measures.length, equals(1));
      expect(history.score.parts.first.measures.first.number, equals(2));

      history.undo();
      expect(history.score.parts.first.measures.length, equals(2));
      expect(history.score.parts.first.measures.first.number, equals(1));
    });

    test('Executing new command clears redo history', () {
      history.execute(SetTitleCommand('Version 1', 'Initial Title'));
      history.undo();
      expect(history.canRedo, isTrue);

      history.execute(SetTitleCommand('Version 2', 'Initial Title'));
      expect(history.canRedo, isFalse);
      expect(history.score.title, equals('Version 2'));
    });

    test('Max depth truncates oldest undo command', () {
      final boundedHistory = CommandHistory(
        initialScore: const Score(title: 'Base', parts: []),
        maxDepth: 2,
        coalesceThreshold: Duration.zero,
      );

      boundedHistory.execute(SetTitleCommand('T1', 'Base'));
      boundedHistory.execute(SetTitleCommand('T2', 'T1'));
      boundedHistory.execute(SetTitleCommand('T3', 'T2'));

      expect(boundedHistory.undoStack.length, equals(2));
      expect((boundedHistory.undoStack.first as SetTitleCommand).newTitle, equals('T2'));
    });

    test('PageConfig commands mutate document layout and undo accurately', () {
      expect(history.config.pageSize, equals(PageSize.a4));
      expect(history.config.orientation, equals(PageOrientation.portrait));

      history.execute(SetPageSizeCommand(PageSize.letter));
      expect(history.config.pageSize, equals(PageSize.letter));
      expect(history.lastUndoLabel, equals('Set Page Size'));

      history.execute(SetOrientationCommand(PageOrientation.landscape));
      expect(history.config.orientation, equals(PageOrientation.landscape));
      expect(history.lastUndoLabel, equals('Set Orientation'));

      history.undo();
      expect(history.config.orientation, equals(PageOrientation.portrait));
      expect(history.lastRedoLabel, equals('Set Orientation'));

      history.undo();
      expect(history.config.pageSize, equals(PageSize.a4));
    });

    test('AddStaffCommand and RemoveStaffByUidCommand undo layout changes transactionally', () {
      final initialCount = history.config.systemLayout.rootGroup.children.length;

      history.execute(AddStaffCommand(def: const StaffDefinition(instrumentName: 'Violin')));
      expect(history.config.systemLayout.rootGroup.children.length, equals(initialCount + 1));
      expect(history.lastUndoLabel, equals('Add Staff'));

      final addedStaff = history.config.systemLayout.rootGroup.children.last as StaffDefinition;
      expect(addedStaff.instrumentName, equals('Violin'));

      history.execute(RemoveStaffByUidCommand(addedStaff.uid));
      expect(history.config.systemLayout.rootGroup.children.length, equals(initialCount));

      history.undo();
      expect(history.config.systemLayout.rootGroup.children.length, equals(initialCount + 1));

      history.undo();
      expect(history.config.systemLayout.rootGroup.children.length, equals(initialCount));
    });

    test('Command coalescing merges consecutive commands within threshold', () {
      final coalesceHistory = CommandHistory(
        initialScore: const Score(title: 'Base', parts: []),
        coalesceThreshold: const Duration(milliseconds: 500),
      );

      coalesceHistory.execute(SetMarginsCommand(const Margins(top: 10, bottom: 10, left: 10, right: 10)));
      coalesceHistory.execute(SetMarginsCommand(const Margins(top: 15, bottom: 15, left: 15, right: 15)));
      coalesceHistory.execute(SetMarginsCommand(const Margins(top: 20, bottom: 20, left: 20, right: 20)));

      expect(coalesceHistory.undoStack.length, equals(1));
      expect(coalesceHistory.config.margins.top, equals(20));

      coalesceHistory.undo();
      expect(coalesceHistory.config.margins.top, equals(const PageConfig().margins.top));
    });

    test('AddStaffToGroupCommand and MoveStaffNodeCommand transactionally mutate tree', () {
      const staff1 = StaffDefinition(uid: 's1', instrumentName: 'Staff 1');
      const staff2 = StaffDefinition(uid: 's2', instrumentName: 'Staff 2');
      const subGroup = StaffNodeGroup(
        connector: SystemConnector.brace,
        children: [staff1],
      );

      final layout = SystemLayout(
        rootGroup: StaffNodeGroup(children: [subGroup, staff2]),
      );
      history.execute(SetSystemLayoutCommand(layout));

      final targetGroupHash = subGroup.hashCode;
      history.execute(AddStaffToGroupCommand(
        groupHash: targetGroupHash,
        def: const StaffDefinition(instrumentName: 'Nested Staff'),
      ));

      expect(history.lastUndoLabel, equals('Add Staff to Group'));
      final currentRoot = history.config.systemLayout.rootGroup;
      final currentSub = currentRoot.children.first as StaffNodeGroup;
      expect(currentSub.children.length, equals(2));

      // Move staff2 into subGroup
      history.execute(MoveStaffNodeCommand(
        sourceGroupHash: currentRoot.hashCode,
        targetGroupHash: currentSub.hashCode,
        sourceIndex: 1,
        targetIndex: 0,
      ));

      expect(history.lastUndoLabel, equals('Move Staff Node'));
      final movedRoot = history.config.systemLayout.rootGroup;
      expect(movedRoot.children.length, equals(1)); // Only subGroup remains at root
      final movedSub = movedRoot.children.first as StaffNodeGroup;
      expect(movedSub.children.length, equals(3));

      history.undo();
      expect(history.config.systemLayout.rootGroup.children.length, equals(2));

      history.undo();
      expect((history.config.systemLayout.rootGroup.children.first as StaffNodeGroup).children.length, equals(1));
    });

    test('UpdateGroupInitialBarlineCommand modifies initialBarline and undoes cleanly', () {
      final configHistory = CommandHistory(
        initialScore: const Score(title: 'Base', parts: []),
      );
      expect(configHistory.config.systemLayout.rootGroup.initialBarline, isTrue);

      configHistory.execute(UpdateGroupInitialBarlineCommand(false));
      expect(configHistory.config.systemLayout.rootGroup.initialBarline, isFalse);
      expect(configHistory.lastUndoLabel, equals('Toggle Initial Barline'));

      configHistory.undo();
      expect(configHistory.config.systemLayout.rootGroup.initialBarline, isTrue);

      configHistory.redo();
      expect(configHistory.config.systemLayout.rootGroup.initialBarline, isFalse);
    });

    test('RemoveStaffCommand removes targeted staff from nested group without deleting the whole group', () {
      final configHistory = CommandHistory(
        initialScore: const Score(title: 'Chamber Score', parts: []),
      );
      configHistory.execute(ApplyProfileCommand(StaffProfiles.chamberOrchestra));

      // chamberOrchestra has 4 staves total:
      // index 0: Violin I (in subGroup)
      // index 1: Violin II (in subGroup)
      // index 2: Viola (in rootGroup)
      // index 3: Cello (in rootGroup)
      expect(configHistory.config.staffCount, equals(4));
      final initialRoot = configHistory.config.systemLayout.rootGroup;
      expect(initialRoot.children.first, isA<StaffNodeGroup>());
      final initialSub = initialRoot.children.first as StaffNodeGroup;
      expect(initialSub.children.length, equals(2));

      // Remove staff at index 0 (Violin I)
      configHistory.execute(RemoveStaffCommand(0));

      expect(configHistory.config.staffCount, equals(3));
      final updatedRoot = configHistory.config.systemLayout.rootGroup;
      // Sub-group must NOT have been deleted! It still contains Violin II.
      expect(updatedRoot.children.first, isA<StaffNodeGroup>());
      final updatedSub = updatedRoot.children.first as StaffNodeGroup;
      expect(updatedSub.children.length, equals(1));
      expect((updatedSub.children.first as StaffDefinition).clef, equals(Clef.treble));

      // Other root children (Viola, Cello) must remain intact
      expect(updatedRoot.children.length, equals(3)); // subGroup + Viola + Cello

      // Undo restores Violin I back into the sub-group
      configHistory.undo();
      expect(configHistory.config.staffCount, equals(4));
      final revertedSub = configHistory.config.systemLayout.rootGroup.children.first as StaffNodeGroup;
      expect(revertedSub.children.length, equals(2));
    });

    test('RemoveStaffByUidCommand prunes empty sub-group when its last staff is removed', () {
      const v1 = StaffDefinition(uid: 'v1', instrumentName: 'V1');
      const v2 = StaffDefinition(uid: 'v2', instrumentName: 'V2');
      const cello = StaffDefinition(uid: 'cello', instrumentName: 'Cello');
      final violinGroup = StaffNodeGroup(
        connector: SystemConnector.bracket,
        children: [v1, v2],
      );
      final layout = SystemLayout(
        rootGroup: StaffNodeGroup(children: [violinGroup, cello]),
      );

      final configHistory = CommandHistory(
        initialScore: const Score(title: 'Score', parts: []),
      );
      configHistory.execute(SetSystemLayoutCommand(layout));
      expect(configHistory.config.staffCount, equals(3));
      expect(configHistory.config.systemLayout.rootGroup.children.length, equals(2));

      // Remove first violin
      configHistory.execute(RemoveStaffByUidCommand(v1.uid));
      expect(configHistory.config.staffCount, equals(2));
      var root = configHistory.config.systemLayout.rootGroup;
      expect(root.children.length, equals(2)); // violinGroup (with 1 staff) + cello

      // Remove second violin - violinGroup now has 0 staves and should be pruned
      configHistory.execute(RemoveStaffByUidCommand(v2.uid));
      expect(configHistory.config.staffCount, equals(1));
      root = configHistory.config.systemLayout.rootGroup;
      expect(root.children.length, equals(1));
      expect(root.children.first, isA<StaffDefinition>());
      expect((root.children.first as StaffDefinition).uid, equals(cello.uid));
    });
  });
}

