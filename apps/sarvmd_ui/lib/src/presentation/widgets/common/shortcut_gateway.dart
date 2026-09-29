// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/document/document_cubit.dart';

import '../../../logic/workspace/workspace_cubit.dart';
import '../dialogs/keyboard_shortcuts_dialog.dart';
import '../dialogs/unsaved_changes_dialog.dart';
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

class DocumentPropertiesIntent extends Intent {
  const DocumentPropertiesIntent();
}

class NewTabIntent extends Intent {
  const NewTabIntent();
}

class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

class NextTabIntent extends Intent {
  const NextTabIntent();
}

class PreviousTabIntent extends Intent {
  const PreviousTabIntent();
}

class KeyboardShortcutsHelpIntent extends Intent {
  const KeyboardShortcutsHelpIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ZoomResetIntent extends Intent {
  const ZoomResetIntent();
}

class ToggleSidebarIntent extends Intent {
  const ToggleSidebarIntent();
}

class ToggleViewPanelIntent extends Intent {
  const ToggleViewPanelIntent();
}

class ToggleZenModeIntent extends Intent {
  const ToggleZenModeIntent();
}

/// Global keyboard shortcut interceptor gateway for SarvMD.
///
/// Binds standard desktop & web keyboard shortcuts for:
/// - Help & Shortcuts (`F1`, `Ctrl+/`, `Cmd+/`)
/// - Undo / Redo (`Ctrl+Z`, `Cmd+Z`, `Ctrl+Y`, `Cmd+Shift+Z`)
/// - New Document (`Ctrl+N`, `Cmd+N`)
/// - Open Document (`Ctrl+O`, `Cmd+O`)
/// - Save Document (`Ctrl+S`, `Cmd+S`)
/// - Save Document As (`Ctrl+Shift+S`, `Cmd+Shift+S`)
/// - Export (`Ctrl+E`, `Cmd+E`)
/// - Document Properties (`Ctrl+I`, `Cmd+I`)
/// - Tab Navigation (`Ctrl+T`, `Ctrl+W`, `Ctrl+Tab`, `Ctrl+Shift+Tab`)
/// - Canvas Navigation & Zoom (`Ctrl +`, `Ctrl -`, `Ctrl 0`)
/// - Panel Visibility (`Ctrl+B`, `Ctrl+\`, `F11`)
class SarvShortcutGateway extends StatelessWidget {
  final Widget child;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomReset;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onToggleViewPanel;
  final VoidCallback? onToggleZenMode;
  final VoidCallback? onShowShortcuts;

  const SarvShortcutGateway({
    super.key,
    required this.child,
    this.onZoomIn,
    this.onZoomOut,
    this.onZoomReset,
    this.onToggleSidebar,
    this.onToggleViewPanel,
    this.onToggleZenMode,
    this.onShowShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // General / Help
        SingleActivator(LogicalKeyboardKey.f1): KeyboardShortcutsHelpIntent(),
        SingleActivator(LogicalKeyboardKey.slash, control: true): KeyboardShortcutsHelpIntent(),
        SingleActivator(LogicalKeyboardKey.slash, meta: true): KeyboardShortcutsHelpIntent(),

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
        SingleActivator(LogicalKeyboardKey.keyI, control: true): DocumentPropertiesIntent(),
        SingleActivator(LogicalKeyboardKey.keyI, meta: true): DocumentPropertiesIntent(),

        // Tab operations
        SingleActivator(LogicalKeyboardKey.keyT, control: true): NewTabIntent(),
        SingleActivator(LogicalKeyboardKey.keyT, meta: true): NewTabIntent(),
        SingleActivator(LogicalKeyboardKey.keyW, control: true): CloseTabIntent(),
        SingleActivator(LogicalKeyboardKey.keyW, meta: true): CloseTabIntent(),
        SingleActivator(LogicalKeyboardKey.tab, control: true): NextTabIntent(),
        SingleActivator(LogicalKeyboardKey.pageDown, control: true): NextTabIntent(),
        SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true): PreviousTabIntent(),
        SingleActivator(LogicalKeyboardKey.pageUp, control: true): PreviousTabIntent(),

        // Canvas Zoom & Navigation
        SingleActivator(LogicalKeyboardKey.equal, control: true): ZoomInIntent(),
        SingleActivator(LogicalKeyboardKey.equal, meta: true): ZoomInIntent(),
        SingleActivator(LogicalKeyboardKey.add, control: true): ZoomInIntent(),
        SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): ZoomInIntent(),
        SingleActivator(LogicalKeyboardKey.minus, control: true): ZoomOutIntent(),
        SingleActivator(LogicalKeyboardKey.minus, meta: true): ZoomOutIntent(),
        SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): ZoomOutIntent(),
        SingleActivator(LogicalKeyboardKey.digit0, control: true): ZoomResetIntent(),
        SingleActivator(LogicalKeyboardKey.digit0, meta: true): ZoomResetIntent(),
        SingleActivator(LogicalKeyboardKey.numpad0, control: true): ZoomResetIntent(),

        // Panels & View
        SingleActivator(LogicalKeyboardKey.keyB, control: true): ToggleSidebarIntent(),
        SingleActivator(LogicalKeyboardKey.keyB, meta: true): ToggleSidebarIntent(),
        SingleActivator(LogicalKeyboardKey.backslash, control: true): ToggleViewPanelIntent(),
        SingleActivator(LogicalKeyboardKey.backslash, meta: true): ToggleViewPanelIntent(),
        SingleActivator(LogicalKeyboardKey.f11): ToggleZenModeIntent(),
      },

      child: Actions(
        actions: <Type, Action<Intent>>{
          KeyboardShortcutsHelpIntent: CallbackAction<KeyboardShortcutsHelpIntent>(
            onInvoke: (intent) {
              if (onShowShortcuts != null) {
                onShowShortcuts!();
              } else {
                showKeyboardShortcutsDialog(context);
              }
              return null;
            },
          ),
          ZoomInIntent: CallbackAction<ZoomInIntent>(
            onInvoke: (intent) {
              onZoomIn?.call();
              return null;
            },
          ),
          ZoomOutIntent: CallbackAction<ZoomOutIntent>(
            onInvoke: (intent) {
              onZoomOut?.call();
              return null;
            },
          ),
          ZoomResetIntent: CallbackAction<ZoomResetIntent>(
            onInvoke: (intent) {
              onZoomReset?.call();
              return null;
            },
          ),
          ToggleSidebarIntent: CallbackAction<ToggleSidebarIntent>(
            onInvoke: (intent) {
              onToggleSidebar?.call();
              return null;
            },
          ),
          ToggleViewPanelIntent: CallbackAction<ToggleViewPanelIntent>(
            onInvoke: (intent) {
              onToggleViewPanel?.call();
              return null;
            },
          ),
          ToggleZenModeIntent: CallbackAction<ToggleZenModeIntent>(
            onInvoke: (intent) {
              onToggleZenMode?.call();
              return null;
            },
          ),
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit?>();
              if (cubit != null && cubit.state.canUndo) {
                cubit.undo();
              }
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit?>();
              if (cubit != null && cubit.state.canRedo) {
                cubit.redo();
              }
              return null;
            },
          ),
          NewDocumentIntent: CallbackAction<NewDocumentIntent>(
            onInvoke: (intent) {
              final workspace = context.read<WorkspaceCubit?>();
              if (workspace != null) {
                workspace.openNewTab();
              } else {
                final cubit = context.read<DocumentCubit?>();
                if (cubit != null) {
                  handleTopBarMenuSelection(context, 'new_document', cubit.state);
                }
              }
              return null;
            },
          ),
          OpenDocumentIntent: CallbackAction<OpenDocumentIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit?>();
              if (cubit != null) {
                handleTopBarMenuSelection(context, 'open_document', cubit.state);
              }
              return null;
            },
          ),
          SaveDocumentIntent: CallbackAction<SaveDocumentIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit?>();
              if (cubit != null) {
                handleTopBarMenuSelection(context, 'save_document', cubit.state);
              }
              return null;
            },
          ),
          SaveAsDocumentIntent: CallbackAction<SaveAsDocumentIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit?>();
              if (cubit != null) {
                handleTopBarMenuSelection(context, 'save_as_document', cubit.state);
              }
              return null;
            },
          ),
          ExportIntent: CallbackAction<ExportIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit?>();
              if (cubit != null) {
                handleTopBarMenuSelection(context, 'export', cubit.state);
              }
              return null;
            },
          ),
          DocumentPropertiesIntent: CallbackAction<DocumentPropertiesIntent>(
            onInvoke: (intent) {
              final cubit = context.read<DocumentCubit?>();
              if (cubit != null) {
                handleTopBarMenuSelection(context, 'document_properties', cubit.state);
              }
              return null;
            },
          ),
          NewTabIntent: CallbackAction<NewTabIntent>(
            onInvoke: (intent) {
              final workspace = context.read<WorkspaceCubit?>();
              if (workspace != null) {
                workspace.openNewTab();
              } else {
                final cubit = context.read<DocumentCubit?>();
                if (cubit != null) {
                  handleTopBarMenuSelection(context, 'new_document', cubit.state);
                }
              }
              return null;
            },
          ),
          CloseTabIntent: CallbackAction<CloseTabIntent>(
            onInvoke: (intent) {
              final workspace = context.read<WorkspaceCubit?>();
              if (workspace != null) {
                workspace.closeTab(
                  workspace.state.activeIndex,
                  unsavedGuard: (session) async {
                    if (!session.isDirty) return true;
                    final action = await showUnsavedChangesDialog(
                      context,
                      documentName: session.title,
                    );
                    if (action == UnsavedChangesAction.save) {
                      return await session.cubit.save();
                    }
                    if (action == UnsavedChangesAction.discard) {
                      return true;
                    }
                    return false;
                  },
                );
              }
              return null;
            },
          ),
          NextTabIntent: CallbackAction<NextTabIntent>(
            onInvoke: (intent) {
              context.read<WorkspaceCubit?>()?.nextTab();
              return null;
            },
          ),
          PreviousTabIntent: CallbackAction<PreviousTabIntent>(
            onInvoke: (intent) {
              context.read<WorkspaceCubit?>()?.previousTab();
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
