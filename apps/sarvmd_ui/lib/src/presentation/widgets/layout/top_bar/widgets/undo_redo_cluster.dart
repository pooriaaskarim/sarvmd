// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/document/document_state.dart';

/// Undo and Redo icon button pair used in the top bar's left zone.
///
/// Reads [documentState] to decide whether each button is enabled and show action labels.
class UndoRedoCluster extends StatelessWidget {
  final DocumentState documentState;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const UndoRedoCluster({
    super.key,
    required this.documentState,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final undoLabel = documentState.lastUndoLabel;
    final redoLabel = documentState.lastRedoLabel;

    final undoMsg = documentState.canUndo
        ? (undoLabel != null ? 'Undo $undoLabel (Ctrl+Z)' : 'Undo (Ctrl+Z)')
        : 'Undo (${l10n.hidden})';

    final redoMsg = documentState.canRedo
        ? (redoLabel != null ? 'Redo $redoLabel (Ctrl+Y)' : 'Redo (Ctrl+Y)')
        : 'Redo (${l10n.hidden})';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: undoMsg,
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: const EdgeInsets.all(5),
            icon: const Icon(Icons.undo_rounded, size: 18.0),
            color: cs.onSurface,
            disabledColor: cs.onSurface.withValues(alpha: 0.38),
            onPressed: documentState.canUndo ? onUndo : null,
          ),
        ),
        Tooltip(
          message: redoMsg,
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: const EdgeInsets.all(5),
            icon: const Icon(Icons.redo_rounded, size: 18.0),
            color: cs.onSurface,
            disabledColor: cs.onSurface.withValues(alpha: 0.38),
            onPressed: documentState.canRedo ? onRedo : null,
          ),
        ),
      ],
    );
  }
}
