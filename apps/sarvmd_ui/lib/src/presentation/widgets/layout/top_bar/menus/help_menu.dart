// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/score/score_cubit.dart';
import '../top_bar_menu_handler.dart';
import '../top_bar_menu_header.dart';

/// `Help` desktop menu for the top bar.
class TopBarHelpMenu extends StatelessWidget {
  final ScoreState scoreState;

  const TopBarHelpMenu({super.key, required this.scoreState});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return TopBarMenuHeader(
      label: l10n.menuHelp,
      onSelected: (value) => handleTopBarMenuSelection(context, value, scoreState),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 17, color: cs.onSurface),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.aboutSarvMD, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }
}
