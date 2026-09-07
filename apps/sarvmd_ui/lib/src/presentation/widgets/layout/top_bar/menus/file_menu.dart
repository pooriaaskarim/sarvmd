// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/score/score_cubit.dart';
import '../top_bar_menu_handler.dart';
import '../top_bar_menu_header.dart';

/// `File` desktop menu for the top bar.
class TopBarFileMenu extends StatelessWidget {
  final ScoreState scoreState;

  const TopBarFileMenu({super.key, required this.scoreState});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return TopBarMenuHeader(
      label: l10n.menuFile,
      onSelected: (value) => handleTopBarMenuSelection(context, value, scoreState),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_upload_outlined, size: 17, color: cs.onSurface),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.export, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }
}
