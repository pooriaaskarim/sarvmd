// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/document/document_state.dart';
import '../top_bar_menu_handler.dart';
import '../top_bar_menu_header.dart';

/// `Help` desktop menu for the top bar.
class TopBarHelpMenu extends StatelessWidget {
  final DocumentState documentState;

  const TopBarHelpMenu({super.key, required this.documentState});

  /// Builds the [Widget] entries for the Help menu.
  ///
  /// Shared between desktop wide-mode [TopBarHelpMenu] and compact [TopBarCompactAppMenu].
  static List<Widget> buildChildren(BuildContext context, DocumentState documentState) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return [
      MenuItemButton(
        leadingIcon: Icon(Icons.info_outline, size: 17, color: cs.onSurface),
        onPressed: () => handleTopBarMenuSelection(context, 'about', documentState),
        child: Text(l10n.aboutSarvMD),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TopBarMenuHeader(
      label: l10n.menuHelp,
      menuChildren: buildChildren(context, documentState),
    );
  }
}
