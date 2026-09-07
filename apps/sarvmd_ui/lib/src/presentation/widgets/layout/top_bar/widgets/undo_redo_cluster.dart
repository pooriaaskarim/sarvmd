// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/score/score_cubit.dart';

/// Undo and Redo icon button pair used in the top bar's left zone.
///
/// Reads [scoreState] to decide whether each button is enabled.
/// Callbacks ([onUndo], [onRedo]) are wired by the parent so this widget
/// stays stateless and trivially testable.
class UndoRedoCluster extends StatelessWidget {
  final ScoreState scoreState;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const UndoRedoCluster({
    super.key,
    required this.scoreState,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: scoreState.canUndo ? 'Undo (Ctrl+Z)' : 'Undo (${l10n.hidden})',
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: const EdgeInsets.all(5),
            icon: const Icon(Icons.undo_rounded, size: 18.0),
            color: cs.onSurface,
            disabledColor: cs.onSurface.withValues(alpha: 0.38),
            onPressed: scoreState.canUndo ? onUndo : null,
          ),
        ),
        Tooltip(
          message: scoreState.canRedo ? 'Redo (Ctrl+Y)' : 'Redo (${l10n.hidden})',
          child: IconButton(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: const EdgeInsets.all(5),
            icon: const Icon(Icons.redo_rounded, size: 18.0),
            color: cs.onSurface,
            disabledColor: cs.onSurface.withValues(alpha: 0.38),
            onPressed: scoreState.canRedo ? onRedo : null,
          ),
        ),
      ],
    );
  }
}
