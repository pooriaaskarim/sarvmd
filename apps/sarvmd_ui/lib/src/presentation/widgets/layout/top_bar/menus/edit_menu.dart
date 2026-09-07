// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/config/config_cubit.dart';
import '../../../../../logic/score/score_cubit.dart';
import '../../../dialogs/staff_config_dialog.dart';
import '../top_bar_menu_handler.dart';

/// `Edit` desktop menu for the top bar.
///
/// Uses [MenuAnchor] + [SubmenuButton] to support cascading sub-menus for
/// "Add Staff" and "Edit Staff" — something [PopupMenuButton] cannot do.
class TopBarEditMenu extends StatelessWidget {
  final ScoreState scoreState;

  const TopBarEditMenu({super.key, required this.scoreState});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(4.0),
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Text(
              l10n.menuEdit,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.87),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        // ── Undo / Redo ───────────────────────────────────────────────────
        MenuItemButton(
          leadingIcon: Icon(
            Icons.undo_rounded,
            size: 17,
            color: scoreState.canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
          ),
          onPressed:
              scoreState.canUndo ? () => handleTopBarMenuSelection(context, 'undo', scoreState) : null,
          trailingIcon: Text('Ctrl+Z', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          child: Text(l10n.undo),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.redo_rounded,
            size: 17,
            color: scoreState.canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.38),
          ),
          onPressed:
              scoreState.canRedo ? () => handleTopBarMenuSelection(context, 'redo', scoreState) : null,
          trailingIcon: Text('Ctrl+Y', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          child: Text(l10n.redo),
        ),
        const Divider(),

        // ── Add Staff ▸ ───────────────────────────────────────────────────
        SubmenuButton(
          leadingIcon: Icon(Icons.add_circle_outline, size: 17, color: cs.onSurface),
          menuChildren: [
            MenuItemButton(
              leadingIcon: Icon(Icons.music_note_outlined, size: 17, color: cs.onSurface),
              onPressed: () => handleTopBarMenuSelection(context, 'add_staff_5line', scoreState),
              child: Text(l10n.staffPreset5LineTreble),
            ),
            MenuItemButton(
              leadingIcon: Icon(Icons.music_note_outlined, size: 17, color: cs.onSurface),
              onPressed: () => handleTopBarMenuSelection(context, 'add_staff_5line_bass', scoreState),
              child: Text(l10n.staffPreset5LineBass),
            ),
            MenuItemButton(
              leadingIcon: Icon(Icons.piano_outlined, size: 17, color: cs.onSurface),
              onPressed: () => handleTopBarMenuSelection(context, 'add_staff_grand', scoreState),
              child: Text(l10n.staffPresetGrandPair),
            ),
            MenuItemButton(
              leadingIcon: Icon(Icons.grid_on_outlined, size: 17, color: cs.onSurface),
              onPressed: () => handleTopBarMenuSelection(context, 'add_staff_tab', scoreState),
              child: Text(l10n.staffPreset6LineTab),
            ),
            MenuItemButton(
              leadingIcon: Icon(Icons.horizontal_rule_outlined, size: 17, color: cs.onSurface),
              onPressed: () => handleTopBarMenuSelection(context, 'add_staff_rhythm', scoreState),
              child: Text(l10n.staffPreset1LineRhythm),
            ),
            const Divider(),
            MenuItemButton(
              leadingIcon: Icon(Icons.tune_outlined, size: 17, color: cs.primary),
              onPressed: () => handleTopBarMenuSelection(context, 'add_staff_custom', scoreState),
              child: Text(
                l10n.staffPresetCustomConfigure,
                style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
              ),
            ),
          ],
          child: Text(l10n.addStaffToSystem),
        ),

        // ── Edit Staff ▸ ─────────────────────────────────────────────────
        SubmenuButton(
          leadingIcon: Icon(Icons.edit_note_outlined, size: 17, color: cs.onSurface),
          menuChildren: _buildEditStaffChildren(context, cs, l10n),
          child: Text(l10n.editStaff),
        ),

        // ── Remove Staff ▸ ───────────────────────────────────────────────
        SubmenuButton(
          leadingIcon: Icon(Icons.delete_outline, size: 17, color: cs.error),
          menuChildren: _buildRemoveStaffChildren(context, cs, l10n),
          child: Text(l10n.removeStaff),
        ),

        const Divider(),

        // ── History (informational) ───────────────────────────────────────
        MenuItemButton(
          leadingIcon: Icon(Icons.history, size: 17, color: cs.onSurface),
          onPressed: () => handleTopBarMenuSelection(context, 'history', scoreState),
          child: Text(l10n.editHistoryCount(scoreState.undoStack.length)),
        ),
      ],
    );
  }

  /// Builds the list of [MenuItemButton]s for each active staff in the layout.
  List<Widget> _buildEditStaffChildren(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final configCubit = context.read<ConfigCubit>();
    final allStaves = configCubit.allStaves;

    if (allStaves.isEmpty) {
      return [
        MenuItemButton(
          onPressed: null,
          child: Text(l10n.noActiveStaves),
        ),
      ];
    }

    return [
      for (var i = 0; i < allStaves.length; i++)
        () {
          final staff = allStaves[i];
          final label = staff.instrumentName?.isNotEmpty == true
              ? staff.instrumentName!
              : l10n.staffNumberWithHash(i + 1);
          return MenuItemButton(
            leadingIcon: Icon(Icons.tune_outlined, size: 16, color: cs.onSurface),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (dialogCtx) => StaffConfigDialog(
                  staff: staff,
                  notifier: configCubit,
                ),
              );
            },
            child: Text(l10n.staffMenuSummary(i + 1, label, staff.lines)),
          );
        }(),
    ];
  }

  /// Builds the list of [MenuItemButton]s to remove active staves in the layout.
  List<Widget> _buildRemoveStaffChildren(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final configCubit = context.read<ConfigCubit>();
    final allStaves = configCubit.allStaves;

    if (allStaves.length <= 1) {
      return [
        MenuItemButton(
          onPressed: null,
          child: Text(l10n.minOneStaffRequired),
        ),
      ];
    }

    return [
      for (var i = 0; i < allStaves.length; i++)
        () {
          final staff = allStaves[i];
          final label = staff.instrumentName?.isNotEmpty == true
              ? staff.instrumentName!
              : l10n.staffNumberWithHash(i + 1);
          return MenuItemButton(
            leadingIcon: Icon(Icons.remove_circle_outline, size: 16, color: cs.error),
            onPressed: () {
              configCubit.removeStaff(i);
            },
            child: Text(l10n.staffMenuSummary(i + 1, label, staff.lines)),
          );
        }(),
    ];
  }
}
