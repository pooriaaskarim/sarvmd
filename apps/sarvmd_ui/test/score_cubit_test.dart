// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/score/score_cubit.dart';
import 'package:sarvmd_ui/src/logic/score/score_command.dart';

class _TestTitleUpdateCommand extends ScoreCommand {
  final String newTitle;
  final String oldTitle;

  const _TestTitleUpdateCommand(this.newTitle, this.oldTitle);

  @override
  core.Score execute(core.Score current) {
    return core.Score(
      title: newTitle,
      composer: current.composer,
      parts: current.parts,
    );
  }

  @override
  core.Score undo(core.Score current) {
    return core.Score(
      title: oldTitle,
      composer: current.composer,
      parts: current.parts,
    );
  }
}

void main() {
  group('ScoreCubit & ScoreCommand Pipeline Tests', () {
    late ScoreCubit cubit;

    setUp(() {
      cubit = ScoreCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial ScoreState has default score and empty undo/redo stacks', () {
      expect(cubit.state.score.title, equals('New Score'));
      expect(cubit.state.undoStack, isEmpty);
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.state.canUndo, isFalse);
      expect(cubit.state.canRedo, isFalse);
    });

    test('Executing command updates score and pushes to undo stack', () {
      const command = _TestTitleUpdateCommand('Symphony No. 1', 'New Score');
      cubit.execute(command);

      expect(cubit.state.score.title, equals('Symphony No. 1'));
      expect(cubit.state.undoStack.length, equals(1));
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.state.canUndo, isTrue);
      expect(cubit.state.canRedo, isFalse);
    });

    test('Undo reverts score mutation and moves command to redo stack', () {
      const command = _TestTitleUpdateCommand('Symphony No. 1', 'New Score');
      cubit.execute(command);
      cubit.undo();

      expect(cubit.state.score.title, equals('New Score'));
      expect(cubit.state.undoStack, isEmpty);
      expect(cubit.state.redoStack.length, equals(1));
      expect(cubit.state.canUndo, isFalse);
      expect(cubit.state.canRedo, isTrue);
    });

    test('Redo re-applies command and moves command back to undo stack', () {
      const command = _TestTitleUpdateCommand('Symphony No. 1', 'New Score');
      cubit.execute(command);
      cubit.undo();
      cubit.redo();

      expect(cubit.state.score.title, equals('Symphony No. 1'));
      expect(cubit.state.undoStack.length, equals(1));
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.state.canUndo, isTrue);
      expect(cubit.state.canRedo, isFalse);
    });

    test('Executing new command clears existing redo stack', () {
      const cmd1 = _TestTitleUpdateCommand('Score Version A', 'New Score');
      const cmd2 = _TestTitleUpdateCommand('Score Version B', 'Score Version A');

      cubit.execute(cmd1);
      cubit.undo();
      expect(cubit.state.canRedo, isTrue);

      cubit.execute(cmd2);
      expect(cubit.state.score.title, equals('Score Version B'));
      expect(cubit.state.undoStack.length, equals(1));
      expect(cubit.state.redoStack, isEmpty);
      expect(cubit.state.canRedo, isFalse);
    });

    test('NoOpCommand leaves score untouched', () {
      const noop = NoOpCommand();
      cubit.execute(noop);

      expect(cubit.state.score.title, equals('New Score'));
      expect(cubit.state.undoStack.length, equals(1));
    });
  });
}
