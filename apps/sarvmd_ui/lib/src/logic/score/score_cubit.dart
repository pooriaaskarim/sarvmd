// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/utils/app_logger.dart';

final _log = AppLogger.score;

/// Represents the immutable state of the score editor session.
class ScoreState {
  /// The compiled logical score containing all parts, measures, and voices.
  final core.Score score;

  /// The history stack of executed commands.
  final List<core.ScoreCommand> undoStack;

  /// The history stack of reverted commands.
  final List<core.ScoreCommand> redoStack;

  const ScoreState({
    required this.score,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  /// Returns a modified copy of this state with updated properties.
  ScoreState copyWith({
    core.Score? score,
    List<core.ScoreCommand>? undoStack,
    List<core.ScoreCommand>? redoStack,
  }) {
    return ScoreState(
      score: score ?? this.score,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  /// Whether a command is currently available in the undo stack.
  bool get canUndo => undoStack.isNotEmpty;

  /// Whether a command is currently available in the redo stack.
  bool get canRedo => redoStack.isNotEmpty;
}

/// Cubit managing the document's musical score AST and command execution pipeline.
class ScoreCubit extends Cubit<ScoreState> {
  final core.CommandHistory _history;

  ScoreCubit([core.CommandHistory? history])
      : _history = history ?? core.CommandHistory(),
        super(ScoreState(
          score: (history ?? core.CommandHistory()).score,
          undoStack: (history ?? core.CommandHistory()).undoStack,
          redoStack: (history ?? core.CommandHistory()).redoStack,
        ));

  void _syncState() {
    emit(state.copyWith(
      score: _history.score,
      undoStack: _history.undoStack,
      redoStack: _history.redoStack,
    ));
  }

  /// Executes a new command, updating the score and appending to the undo stack.
  void execute(core.ScoreCommand command) {
    _log.debug('Executing command: ${command.runtimeType}');
    _history.execute(command);
    _syncState();
  }

  /// Reverts the most recently executed command on the undo stack.
  void undo() {
    if (!state.canUndo) {
      _log.warning('undo() called with empty undo stack');
      return;
    }
    _log.debug('Undoing command');
    _history.undo();
    _syncState();
  }

  /// Re-applies the most recently reverted command on the redo stack.
  void redo() {
    if (!state.canRedo) {
      _log.warning('redo() called with empty redo stack');
      return;
    }
    _log.debug('Redoing command');
    _history.redo();
    _syncState();
  }
}
