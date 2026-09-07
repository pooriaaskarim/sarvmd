// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../logic/document/document_cubit.dart';
import '../../../../logic/document/document_state.dart';
import '../../../../logic/locale/locale_cubit.dart';
import '../../../../logic/view/view_cubit.dart';
import '../../dialogs/about_dialog.dart';
import '../../dialogs/export_dialog.dart';
import '../../dialogs/staff_config_dialog.dart';

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
      documentCubit.execute(core.AddPartCommand(
        core.Part(
          id: 'part_${DateTime.now().microsecondsSinceEpoch}',
          name: 'Standard Treble Staff',
        ),
      ));
      break;
    case 'add_staff_5line_bass':
      documentCubit.addStaff(def: const core.StaffDefinition(lines: 5, clef: core.Clef.bass));
      documentCubit.execute(core.AddPartCommand(
        core.Part(
          id: 'part_${DateTime.now().microsecondsSinceEpoch}',
          name: 'Standard Bass Staff',
        ),
      ));
      break;
    case 'add_staff_grand':
      documentCubit.addStaff(def: const core.StaffDefinition(lines: 5, clef: core.Clef.treble));
      documentCubit.addStaff(def: const core.StaffDefinition(lines: 5, clef: core.Clef.bass));
      final now = DateTime.now().microsecondsSinceEpoch;
      documentCubit.execute(core.AddPartCommand(
        core.Part(id: 'part_${now}_1', name: 'Grand Staff Treble'),
      ));
      documentCubit.execute(core.AddPartCommand(
        core.Part(id: 'part_${now}_2', name: 'Grand Staff Bass'),
      ));
      break;
    case 'add_staff_tab':
      documentCubit.addStaff(
          def: const core.StaffDefinition(lines: 6, clef: core.Clef.tab, instrumentName: 'TAB'));
      documentCubit.execute(core.AddPartCommand(
        core.Part(
          id: 'part_${DateTime.now().microsecondsSinceEpoch}',
          name: 'Guitar TAB',
        ),
      ));
      break;
    case 'add_staff_rhythm':
      documentCubit.addStaff(
          def: const core.StaffDefinition(
              lines: 1, clef: core.Clef.percussion, instrumentName: 'Rhythm'));
      documentCubit.execute(core.AddPartCommand(
        core.Part(
          id: 'part_${DateTime.now().microsecondsSinceEpoch}',
          name: 'Rhythm Staff',
        ),
      ));
      break;
    case 'add_staff_custom':
      final newStaff = documentCubit.addStaff(
          def: const core.StaffDefinition(
        lines: 5,
        clef: core.TrebleClef(),
      ));
      documentCubit.execute(core.AddPartCommand(
        core.Part(
          id: 'part_${DateTime.now().microsecondsSinceEpoch}',
          name: '',
        ),
      ));
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => StaffConfigDialog(staff: newStaff, notifier: documentCubit),
      );
      break;

    // ── File / Export ───────────────────────────────────────────────────────
    case 'export':
      showExportDialog(context);
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
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (dialogCtx) => StaffConfigDialog(
                staff: staves[index],
                notifier: documentCubit,
              ),
            );
          }
        }
      } else if (value.startsWith('remove_staff_')) {
        final index = int.tryParse(value.substring('remove_staff_'.length));
        if (index != null) {
          documentCubit.removeStaff(index);
        }
      }
      break;
  }
}
