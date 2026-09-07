// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../config.dart';
import '../domain/document.dart';
import '../domain/score.dart';
import 'document_command.dart';

/// Pure Dart transactional undo/redo command history engine.
class CommandHistory {
  SarvDocument _document;
  final List<DocumentCommand> _undoStack = [];
  final List<DocumentCommand> _redoStack = [];
  final int maxDepth;
  final Duration coalesceThreshold;
  final void Function(SarvDocument doc)? onDocumentChanged;
  DateTime? _lastExecutionTime;

  CommandHistory({
    SarvDocument? initialDocument,
    Score? initialScore,
    this.maxDepth = 100,
    this.coalesceThreshold = const Duration(milliseconds: 600),
    this.onDocumentChanged,
  }) : _document = initialDocument ??
            SarvDocument(
              score: initialScore ?? const Score(title: '', parts: []),
            );

  /// Current logical document state.
  SarvDocument get document => _document;

  /// Convenience getter for musical score AST.
  Score get score => _document.score;

  /// Convenience getter for physical layout configuration.
  PageConfig get config => _document.config;

  /// Read-only unmodifiable list of commands on the undo stack.
  List<DocumentCommand> get undoStack => List.unmodifiable(_undoStack);

  /// Read-only unmodifiable list of commands on the redo stack.
  List<DocumentCommand> get redoStack => List.unmodifiable(_redoStack);

  /// Whether undo operation is currently available.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo operation is currently available.
  bool get canRedo => _redoStack.isNotEmpty;

  /// User-visible label of the next command to undo, or null if empty.
  String? get lastUndoLabel => _undoStack.isNotEmpty ? _undoStack.last.label : null;

  /// User-visible label of the next command to redo, or null if empty.
  String? get lastRedoLabel => _redoStack.isNotEmpty ? _redoStack.last.label : null;

  /// Executes a [command], mutating current document state and appending to undo stack.
  SarvDocument execute(DocumentCommand command) {
    final now = DateTime.now();
    if (_undoStack.isNotEmpty) {
      final top = _undoStack.last;
      final isRecent = _lastExecutionTime != null &&
          now.difference(_lastExecutionTime!) < coalesceThreshold;

      if (isRecent && top.canCoalesceWith(command)) {
        final mergedCommand = top.coalesceWith(command);
        _undoStack.removeLast();
        _undoStack.add(mergedCommand);
        _document = command.execute(_document);
        _redoStack.clear();
        _lastExecutionTime = now;
        onDocumentChanged?.call(_document);
        return _document;
      }
    }

    _document = command.execute(_document);
    _undoStack.add(command);
    if (_undoStack.length > maxDepth) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _lastExecutionTime = now;
    onDocumentChanged?.call(_document);
    return _document;
  }

  /// Reverts the most recent command on the undo stack.
  SarvDocument? undo() {
    if (!canUndo) return null;
    final command = _undoStack.removeLast();
    _document = command.undo(_document);
    _redoStack.add(command);
    onDocumentChanged?.call(_document);
    return _document;
  }

  /// Re-applies the most recently reverted command on the redo stack.
  SarvDocument? redo() {
    if (!canRedo) return null;
    final command = _redoStack.removeLast();
    _document = command.execute(_document);
    _undoStack.add(command);
    onDocumentChanged?.call(_document);
    return _document;
  }

  /// Clears both undo and redo stacks.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
