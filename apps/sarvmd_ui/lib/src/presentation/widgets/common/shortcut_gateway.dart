// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/document/document_cubit.dart';
import '../layout/top_bar/top_bar_menu_handler.dart';

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class NewDocumentIntent extends Intent {
  const NewDocumentIntent();
}

class OpenDocumentIntent extends Intent {
  const OpenDocumentIntent();
}

class SaveDocumentIntent extends Intent {
  const SaveDocumentIntent();
}

class SaveAsDocumentIntent extends Intent {
  const SaveAsDocumentIntent();
}

class ExportIntent extends Intent {
  const ExportIntent();
}

/// Global keyboard shortcut interceptor gateway for SarvMD.
///
/// Binds standard desktop & web keyboard shortcuts for:
/// - Undo / Redo (`Ctrl+Z`, `Cmd+Z`, `Ctrl+Y`, `Cmd+Shift+Z`)
/// - New Document (`Ctrl+N`, `Cmd+N`)
/// - Open Document (`Ctrl+O`, `Cmd+O`)
/// - Save Document (`Ctrl+S`, `Cmd+S`)
/// - Save Document As (`Ctrl+Shift+S`, `Cmd+Shift+S`)
/// - Export (`Ctrl+E`, `Cmd+E`)
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
        // Undo / Redo
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): RedoIntent(),

        // File operations
        SingleActivator(LogicalKeyboardKey.keyN, control: true): NewDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, meta: true): NewDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyO, control: true): OpenDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyO, meta: true): OpenDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true): SaveDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true): SaveDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): SaveAsDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true): SaveAsDocumentIntent(),
        SingleActivator(LogicalKeyboardKey.keyE, control: true): ExportIntent(),
        SingleActivator(LogicalKeyboardKey.keyE, meta: true): ExportIntent(),
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
          NewDocumentIntent: CallbackAction<NewDocumentIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit>();
              handleTopBarMenuSelection(context, 'new_document', cubit.state);
              return null;
            },
          ),
          OpenDocumentIntent: CallbackAction<OpenDocumentIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit>();
              handleTopBarMenuSelection(context, 'open_document', cubit.state);
              return null;
            },
          ),
          SaveDocumentIntent: CallbackAction<SaveDocumentIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit>();
              handleTopBarMenuSelection(context, 'save_document', cubit.state);
              return null;
            },
          ),
          SaveAsDocumentIntent: CallbackAction<SaveAsDocumentIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit>();
              handleTopBarMenuSelection(context, 'save_as_document', cubit.state);
              return null;
            },
          ),
          ExportIntent: CallbackAction<ExportIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit>();
              handleTopBarMenuSelection(context, 'export', cubit.state);
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
