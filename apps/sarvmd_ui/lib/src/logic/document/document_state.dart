// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Represents the immutable state of the manuscript document editor session.
class DocumentState {
  /// The complete manuscript document state (Score AST + PageConfig layout).
  final core.SarvDocument document;

  /// The history stack of executed commands.
  final List<core.DocumentCommand> undoStack;

  /// The history stack of reverted commands.
  final List<core.DocumentCommand> redoStack;

  /// The file path on disk where this document is currently saved (null if new/untitled or web).
  final String? filePath;

  /// The snapshot of [document] when it was last successfully saved or opened.
  /// If null, the document has not yet been saved to an external file.
  final core.SarvDocument? lastSavedDocument;

  const DocumentState({
    required this.document,
    this.undoStack = const [],
    this.redoStack = const [],
    this.filePath,
    this.lastSavedDocument,
  });

  /// The musical score AST.
  core.Score get score => document.score;

  /// The document metadata (title, composer, timestamps).
  core.DocumentMetadata get metadata => document.metadata;

  /// The physical page configuration.
  core.PageConfig get config => document.config;

  /// Total number of staves in the page layout.
  int get staffCount => config.allStaves.length;

  /// Whether the document has unsaved modifications.
  ///
  /// If [lastSavedDocument] is set, compares [document] against it.
  /// If [lastSavedDocument] is null, considers modified if the user has executed any commands.
  bool get isDirty {
    if (lastSavedDocument != null) {
      return !document.hasSameContent(lastSavedDocument!);
    }
    return undoStack.isNotEmpty;
  }

  /// Display name of current document (file name if saved, score title, or layout description).
  String get displayName {
    if (filePath != null && filePath!.isNotEmpty) {
      if (!filePath!.startsWith('blob:') &&
          !filePath!.startsWith('http:') &&
          !filePath!.startsWith('https:') &&
          !filePath!.startsWith('data:')) {
        return p.basename(filePath!);
      }
    }
    if (document.score.title.trim().isNotEmpty) {
      return document.score.title.trim();
    }
    if (document.metadata.title.trim().isNotEmpty) {
      return document.metadata.title.trim();
    }
    return core.ScoreCompiler.getEffectiveTitle(document.score, document.config);
  }

  /// Returns a modified copy of this state with updated properties.
  DocumentState copyWith({
    core.SarvDocument? document,
    List<core.DocumentCommand>? undoStack,
    List<core.DocumentCommand>? redoStack,
    String? filePath,
    bool clearFilePath = false,
    core.SarvDocument? lastSavedDocument,
    bool clearLastSavedDocument = false,
  }) {
    return DocumentState(
      document: document ?? this.document,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      lastSavedDocument: clearLastSavedDocument ? null : (lastSavedDocument ?? this.lastSavedDocument),
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
