// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../core/utils/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../logic/document/document_cubit.dart';
import '../../../../logic/document/document_state.dart';
import '../../../../logic/locale/locale_cubit.dart';
import '../../../../logic/services/sarv_file_service.dart';
import '../../../../logic/view/view_cubit.dart';
import '../../../../logic/workspace/workspace_cubit.dart';
import '../../dialogs/about_dialog.dart';
import '../../dialogs/document_properties_dialog.dart';
import '../../dialogs/export_dialog.dart';
import '../../dialogs/staff_config_dialog.dart';
import '../../dialogs/unsaved_changes_dialog.dart';

final _log = AppLogger.get('sarvmd.ui.menu');

/// Central dispatcher for all string-keyed menu actions across the top bar.
///
/// Keeps action logic in one place so menu widgets stay declarative and thin.
void handleTopBarMenuSelection(
  BuildContext context,
  String value,
  DocumentState documentState,
) {
  final documentCubit = context.read<DocumentCubit>();

  switch (value) {
    case 'undo':
      if (documentState.canUndo) documentCubit.undo();
      break;
    case 'redo':
      if (documentState.canRedo) documentCubit.redo();
      break;

    // ── Add Staff presets ───────────────────────────────────────────────────
    case 'add_staff':
    case 'add_staff_5line':
      documentCubit.addStaff(def: const core.StaffDefinition(lines: 5, clef: core.Clef.treble));
      break;
    case 'add_staff_5line_bass':
      documentCubit.addStaff(def: const core.StaffDefinition(lines: 5, clef: core.Clef.bass));
      break;
    case 'add_staff_grand':
      documentCubit.addStaff(def: const core.StaffDefinition(lines: 5, clef: core.Clef.treble));
      documentCubit.addStaff(def: const core.StaffDefinition(lines: 5, clef: core.Clef.bass));
      break;
    case 'add_staff_tab':
      documentCubit.addStaff(
          def: const core.StaffDefinition(lines: 6, clef: core.Clef.tab, instrumentName: 'TAB'));
      break;
    case 'add_staff_rhythm':
      documentCubit.addStaff(
          def: const core.StaffDefinition(
              lines: 1, clef: core.Clef.percussion, instrumentName: 'Rhythm'));
      break;
    case 'add_staff_custom':
      final newStaff = documentCubit.addStaff(
          def: const core.StaffDefinition(
        lines: 5,
        clef: core.TrebleClef(),
      ));
      showStaffConfigDialog(
        context,
        staff: newStaff,
        notifier: documentCubit,
      );
      break;

    // ── File / Export ───────────────────────────────────────────────────────
    case 'new_document':
      final workspace = context.read<WorkspaceCubit?>();
      if (workspace != null) {
        workspace.openNewTab();
      } else {
        _handleNewDocument(context, documentCubit, documentState);
      }
      break;
    case 'open_document':
      final workspace = context.read<WorkspaceCubit?>();
      if (workspace != null) {
        _handleWorkspaceOpenDocument(context, workspace);
      } else {
        _handleOpenDocument(context, documentCubit, documentState);
      }
      break;
    case 'save_document':
      _handleSaveDocument(context, documentCubit, documentState);
      break;
    case 'save_as_document':
      _handleSaveAsDocument(context, documentCubit, documentState);
      break;
    case 'export':
      showExportDialog(context);
      break;
    case 'document_properties':
      showDocumentPropertiesDialog(context);
      break;

    // ── View / Appearance ───────────────────────────────────────────────────
    case 'language':
      try {
        context.read<LocaleCubit>().toggleLocale();
      } catch (_) {}
      break;
    case 'theme':
      // Compact menu fires 'theme' directly; wide-mode View menu intercepts it
      // before reaching this handler via its own onSelected callback.
      try {
        context.read<ViewCubit>().toggleThemeMode();
      } catch (_) {}
      break;
    case 'preset_a3':
      documentCubit.updatePageSize(core.PageSize.a3);
      break;
    case 'preset_a4':
      documentCubit.updatePageSize(core.PageSize.a4);
      break;
    case 'preset_a5':
      documentCubit.updatePageSize(core.PageSize.a5);
      break;
    case 'preset_b4':
      documentCubit.updatePageSize(core.PageSize.b4);
      break;
    case 'preset_b5':
      documentCubit.updatePageSize(core.PageSize.b5);
      break;
    case 'preset_letter':
      documentCubit.updatePageSize(core.PageSize.letter);
      break;
    case 'toggle_orientation':
      final next = documentCubit.state.config.orientation == core.PageOrientation.portrait
          ? core.PageOrientation.landscape
          : core.PageOrientation.portrait;
      documentCubit.updateOrientation(next);
      break;

    // ── Misc ────────────────────────────────────────────────────────────────
    case 'about':
      showSarvAboutDialog(context);
      break;
    case 'reset_config':
      documentCubit.resetToDefaults();
      break;

    default:
      // ── Per-staff actions (compact menu: edit_staff_N / remove_staff_N) ──
      if (value.startsWith('edit_staff_')) {
        final index = int.tryParse(value.substring('edit_staff_'.length));
        if (index != null) {
          final staves = documentCubit.allStaves;
          if (index >= 0 && index < staves.length) {
            showStaffConfigDialog(
              context,
              staff: staves[index],
              notifier: documentCubit,
            );
          }
        }
      } else if (value.startsWith('remove_staff_')) {
        final param = value.substring('remove_staff_'.length);
        final index = int.tryParse(param);
        if (index != null && index >= 0 && index < documentCubit.allStaves.length) {
          documentCubit.removeStaffByUid(documentCubit.allStaves[index].uid);
        } else {
          documentCubit.removeStaffByUid(param);
        }
      }
      break;
  }
}

Future<void> _handleNewDocument(BuildContext context, DocumentCubit cubit, DocumentState state) async {
  final liveState = cubit.state;
  if (liveState.isDirty) {
    final action = await showUnsavedChangesDialog(context, documentName: liveState.displayName);
    if (action == UnsavedChangesAction.cancel) return;
    if (action == UnsavedChangesAction.save) {
      final saved = await cubit.save();
      if (!saved) return;
    }
  }
  cubit.newDocument();
}

Future<void> _handleOpenDocument(BuildContext context, DocumentCubit cubit, DocumentState state) async {
  final liveState = cubit.state;
  if (liveState.isDirty) {
    final action = await showUnsavedChangesDialog(context, documentName: liveState.displayName);
    if (action == UnsavedChangesAction.cancel) return;
    if (action == UnsavedChangesAction.save) {
      final saved = await cubit.save();
      if (!saved) return;
    }
  }
  try {
    await cubit.openFile();
  } catch (e, st) {
    _log.error('Failed to open document', error: e, stackTrace: st);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileOpenFailed)),
      );
    }
  }
}

Future<void> _handleSaveDocument(BuildContext context, DocumentCubit cubit, DocumentState state) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final success = await cubit.save();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileSavedSuccess)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileSaveFailed)),
      );
    }
  }
}

Future<void> _handleSaveAsDocument(BuildContext context, DocumentCubit cubit, DocumentState state) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final success = await cubit.saveAs();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileSavedSuccess)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileSaveFailed)),
      );
    }
  }
}

Future<void> _handleWorkspaceOpenDocument(BuildContext context, WorkspaceCubit workspace) async {
  try {
    final result = await SarvFileService().openSarvFile();
    if (result != null) {
      await workspace.openDocumentTab(
        result.document,
        filePath: result.filePath,
        title: result.fileName,
      );
    }
  } catch (e, st) {
    _log.error('Failed to open document in workspace', error: e, stackTrace: st);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileOpenFailed)),
      );
    }
  }
}

/// Handles opening a recent document file from its [filePath].
Future<void> handleOpenRecentDocument(
  BuildContext context,
  String filePath,
) async {
  final fileService = SarvFileService();
  final workspace = context.read<WorkspaceCubit?>();
  final documentCubit = workspace == null ? context.read<DocumentCubit>() : null;

  try {
    if (workspace != null) {
      // If already open in an existing session, switch to that tab
      final existingIndex = workspace.state.sessions.indexWhere(
        (s) => s.filePath == filePath,
      );
      if (existingIndex != -1) {
        workspace.switchTab(existingIndex);
        return;
      }

      final loadResult = await fileService.loadFileFromPath(filePath);
      await workspace.openDocumentTab(
        loadResult.document,
        filePath: loadResult.filePath,
        title: loadResult.fileName,
      );
    } else if (documentCubit != null) {
      final documentState = documentCubit.state;
      if (documentState.isDirty && context.mounted) {
        final action = await showUnsavedChangesDialog(
          context,
          documentName: documentState.displayName,
        );
        if (action == UnsavedChangesAction.cancel) return;
        if (action == UnsavedChangesAction.save) {
          final saved = await documentCubit.save();
          if (!saved) return;
        }
      }
      final loadResult = await fileService.loadFileFromPath(filePath);
      documentCubit.loadDocument(
        loadResult.document,
        filePath: loadResult.filePath,
      );
    }
  } catch (e, st) {
    _log.error('Failed to open recent document', error: e, stackTrace: st);
    if (context.mounted) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileOpenFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
