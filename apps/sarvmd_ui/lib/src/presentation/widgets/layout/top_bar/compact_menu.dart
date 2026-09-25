// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../l10n/app_localizations.dart';
import '../../../../logic/document/document_state.dart';
import 'menus/edit_menu.dart';
import 'menus/file_menu.dart';
import 'menus/help_menu.dart';
import 'menus/view_menu.dart';
import 'top_bar_menu_handler.dart';

/// Dedicated cascading application menu button for compact top-bar layouts (< 760 px).
///
/// Replaces the wide-mode horizontal menu headers (File, Edit, View, Help) with
/// a single [ ☰ ] button. When pressed, it opens a clean cascading [MenuAnchor]
/// with 4 submenus:
/// - File ❯
/// - Edit ❯
/// - View ❯
/// - Help ❯
///
/// Reuses the exact same menu items from [TopBarFileMenu], [TopBarEditMenu],
/// [TopBarViewMenu], and [TopBarHelpMenu], eliminating duplication and legacy flat lists.
class TopBarCompactAppMenu extends StatelessWidget {
  final DocumentState documentState;
  final core.PageConfig configState;

  const TopBarCompactAppMenu({
    super.key,
    required this.documentState,
    required this.configState,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          tooltip: l10n.appMenuTooltip,
          icon: const Icon(Icons.menu_rounded, size: 20),
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
          ),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        SubmenuButton(
          leadingIcon: Icon(Icons.folder_open_outlined, size: 17, color: cs.onSurface),
          menuChildren: TopBarFileMenu.buildChildren(context, documentState),
          child: Text(l10n.menuFile),
        ),
        SubmenuButton(
          leadingIcon: Icon(Icons.edit_outlined, size: 17, color: cs.onSurface),
          menuChildren: TopBarEditMenu.buildChildren(context, documentState),
          child: Text(l10n.menuEdit),
        ),
        SubmenuButton(
          leadingIcon: Icon(Icons.visibility_outlined, size: 17, color: cs.onSurface),
          menuChildren: TopBarViewMenu.buildChildren(
            context,
            documentState,
            configState,
            () => handleTopBarMenuSelection(context, 'theme', documentState),
          ),
          child: Text(l10n.menuView),
        ),
        SubmenuButton(
          leadingIcon: Icon(Icons.help_outline_rounded, size: 17, color: cs.onSurface),
          menuChildren: TopBarHelpMenu.buildChildren(context, documentState),
          child: Text(l10n.menuHelp),
        ),
      ],
    );
  }
}
