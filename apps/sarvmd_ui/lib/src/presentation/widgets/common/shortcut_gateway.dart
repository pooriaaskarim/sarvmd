// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/document/document_cubit.dart';

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

/// Global keyboard shortcut interceptor gateway for SarvMD.
///
/// Binds standard desktop & web keyboard shortcuts for Undo/Redo (`Ctrl+Z`, `Cmd+Z`, `Ctrl+Y`, `Cmd+Shift+Z`)
/// to dispatch transactions on [DocumentCubit].
class SarvShortcutGateway extends StatelessWidget {
  final Widget child;

  const SarvShortcutGateway({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): RedoIntent(),
      },

      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit>();
              if (cubit.state.canUndo) {
                cubit.undo();
              }
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit>();
              if (cubit.state.canRedo) {
                cubit.redo();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
