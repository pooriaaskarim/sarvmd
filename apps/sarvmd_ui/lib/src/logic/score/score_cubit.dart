// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'score_command.dart';

/// Represents the immutable state of the score editor session.
class ScoreState {
  /// The compiled logical score containing all parts, measures, and voices.
  final core.Score score;

  /// The history stack of executed commands.
  final List<ScoreCommand> undoStack;

  /// The history stack of reverted commands.
  final List<ScoreCommand> redoStack;

  const ScoreState({
    required this.score,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  /// Returns a modified copy of this state with updated properties.
  ScoreState copyWith({
    core.Score? score,
    List<ScoreCommand>? undoStack,
    List<ScoreCommand>? redoStack,
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
  ScoreCubit()
      : super(const ScoreState(
          score: core.Score(title: 'New Score', parts: []),
        ));

  /// Executes a new command, updating the score and appending to the undo stack.
  void execute(ScoreCommand command) {
    final nextScore = command.execute(state.score);
    final nextUndo = List<ScoreCommand>.from(state.undoStack)..add(command);
    emit(state.copyWith(
      score: nextScore,
      undoStack: nextUndo,
      redoStack: const [], // Standard: executing a new command clears the redo history.
    ));
  }

  /// Reverts the most recently executed command on the undo stack.
  void undo() {
    if (!state.canUndo) return;
    final nextUndo = List<ScoreCommand>.from(state.undoStack);
    final command = nextUndo.removeLast();
    final prevScore = command.undo(state.score);
    final nextRedo = List<ScoreCommand>.from(state.redoStack)..add(command);

    emit(state.copyWith(
      score: prevScore,
      undoStack: nextUndo,
      redoStack: nextRedo,
    ));
  }

  /// Re-applies the most recently reverted command on the redo stack.
  void redo() {
    if (!state.canRedo) return;
    final nextRedo = List<ScoreCommand>.from(state.redoStack);
    final command = nextRedo.removeLast();
    final nextScore = command.execute(state.score);
    final nextUndo = List<ScoreCommand>.from(state.undoStack)..add(command);

    emit(state.copyWith(
      score: nextScore,
      undoStack: nextUndo,
      redoStack: nextRedo,
    ));
  }
}
