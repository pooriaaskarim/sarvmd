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

    test('NoOpCommand leaves document untouched', () {
      const noop = core.NoOpCommand();
      cubit.execute(noop);

      expect(cubit.state.score.title, equals(''));
      expect(cubit.state.undoStack.length, equals(1));
    });
  });
}
