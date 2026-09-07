// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../domain/score.dart';
import 'score_command.dart';

/// Pure Dart transactional undo/redo command history engine.
class CommandHistory {
  Score _score;
  final List<ScoreCommand> _undoStack = [];
  final List<ScoreCommand> _redoStack = [];
  final int maxDepth;
  final void Function(Score score)? onScoreChanged;

  CommandHistory({
    Score initialScore = const Score(title: '', parts: []),
    this.maxDepth = 100,
    this.onScoreChanged,
  }) : _score = initialScore;

  /// Current logical score AST.
  Score get score => _score;

  /// Read-only unmodifiable list of commands on the undo stack.
  List<ScoreCommand> get undoStack => List.unmodifiable(_undoStack);

  /// Read-only unmodifiable list of commands on the redo stack.
  List<ScoreCommand> get redoStack => List.unmodifiable(_redoStack);

  /// Whether undo operation is currently available.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo operation is currently available.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Executes a [command], mutating the current score and appending to the undo stack.
  Score execute(ScoreCommand command) {
    _score = command.execute(_score);
    _undoStack.add(command);
    if (_undoStack.length > maxDepth) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    onScoreChanged?.call(_score);
    return _score;
  }

  /// Reverts the most recent command on the undo stack.
  Score? undo() {
    if (!canUndo) return null;
    final command = _undoStack.removeLast();
    _score = command.undo(_score);
    _redoStack.add(command);
    onScoreChanged?.call(_score);
    return _score;
  }

  /// Re-applies the most recently reverted command on the redo stack.
  Score? redo() {
    if (!canRedo) return null;
    final command = _redoStack.removeLast();
    _score = command.execute(_score);
    _undoStack.add(command);
    onScoreChanged?.call(_score);
    return _score;
  }

  /// Clears both undo and redo stacks.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
