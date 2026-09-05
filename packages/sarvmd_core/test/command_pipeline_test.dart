// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('Core ScoreCommand & CommandHistory Engine Tests', () {
    late CommandHistory history;

    setUp(() {
      history = CommandHistory(
        initialScore: const Score(title: 'Initial Title', composer: 'Initial Composer', parts: []),
      );
    });

    test('Initial CommandHistory state', () {
      expect(history.score.title, equals('Initial Title'));
      expect(history.score.composer, equals('Initial Composer'));
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

    test('SetComposerCommand updates composer and undoes accurately', () {
      history.execute(SetComposerCommand('Beethoven', 'Initial Composer'));
      expect(history.score.composer, equals('Beethoven'));

      history.undo();
      expect(history.score.composer, equals('Initial Composer'));
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
      );

      boundedHistory.execute(SetTitleCommand('T1', 'Base'));
      boundedHistory.execute(SetTitleCommand('T2', 'T1'));
      boundedHistory.execute(SetTitleCommand('T3', 'T2'));

      expect(boundedHistory.undoStack.length, equals(2));
      expect((boundedHistory.undoStack.first as SetTitleCommand).newTitle, equals('T2'));
    });
  });
}
