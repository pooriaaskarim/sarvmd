// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Represents the immutable state of the manuscript document editor session.
class DocumentState {
  /// The complete manuscript document state (Score AST + PageConfig layout).
  final core.SarvDocument document;

  /// The history stack of executed commands.
  final List<core.DocumentCommand> undoStack;

  /// The history stack of reverted commands.
  final List<core.DocumentCommand> redoStack;

  const DocumentState({
    required this.document,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  /// The musical score AST.
  core.Score get score => document.score;

  /// The physical page configuration.
  core.PageConfig get config => document.config;

  /// Returns a modified copy of this state with updated properties.
  DocumentState copyWith({
    core.SarvDocument? document,
    List<core.DocumentCommand>? undoStack,
    List<core.DocumentCommand>? redoStack,
  }) {
    return DocumentState(
      document: document ?? this.document,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  /// Whether a command is currently available in the undo stack.
  bool get canUndo => undoStack.isNotEmpty;

  /// Whether a command is currently available in the redo stack.
  bool get canRedo => redoStack.isNotEmpty;

  /// Label of the next command to undo, or null if empty.
  String? get lastUndoLabel => undoStack.isNotEmpty ? undoStack.last.label : null;

  /// Label of the next command to redo, or null if empty.
  String? get lastRedoLabel => redoStack.isNotEmpty ? redoStack.last.label : null;
}
