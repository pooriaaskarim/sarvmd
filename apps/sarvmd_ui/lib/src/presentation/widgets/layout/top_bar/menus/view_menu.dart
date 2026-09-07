// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/document/document_state.dart';
import '../top_bar_menu_handler.dart';
import '../top_bar_menu_header.dart';

/// `View` desktop menu for the top bar.
///
/// Covers page size presets, orientation toggle, theme toggle, and language switch.
/// The [onThemeToggle] callback is provided by the parent so the menu stays decoupled
/// from the concrete theme management implementation (ThemeCubit, etc.).
class TopBarViewMenu extends StatelessWidget {
  final DocumentState documentState;
  final core.PageConfig configState;
  final VoidCallback onThemeToggle;

  const TopBarViewMenu({
    super.key,
    required this.documentState,
    required this.configState,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TopBarMenuHeader(
      label: l10n.menuView,
      onSelected: (value) {
        if (value == 'theme') {
          onThemeToggle();
        } else {
          handleTopBarMenuSelection(context, value, documentState);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            l10n.headerScorePageSizes,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'preset_a3',
          child: Text(
            'A3 (297×420 mm) ${configState.pageSize == core.PageSize.a3 ? '✓' : ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuItem<String>(
          value: 'preset_a4',
          child: Text(
            'A4 (210×297 mm) ${configState.pageSize == core.PageSize.a4 ? '✓' : ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuItem<String>(
          value: 'preset_a5',
          child: Text(
            'A5 (148×210 mm) ${configState.pageSize == core.PageSize.a5 ? '✓' : ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuItem<String>(
          value: 'preset_b4',
          child: Text(
            'B4 (250×353 mm) ${configState.pageSize == core.PageSize.b4 ? '✓' : ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuItem<String>(
          value: 'preset_b5',
          child: Text(
            'B5 (176×250 mm) ${configState.pageSize == core.PageSize.b5 ? '✓' : ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PopupMenuItem<String>(
          value: 'preset_letter',
          child: Text(
            'Letter (216×279 mm) ${configState.pageSize == core.PageSize.letter ? '✓' : ''}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'toggle_orientation',
          child: Text(
            l10n.orientationToggleSummary(
              configState.orientation == core.PageOrientation.portrait
                  ? l10n.portrait
                  : l10n.landscape,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 17,
                color: cs.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isDark ? l10n.lightTheme : l10n.darkTheme,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'language',
          child: Row(
            children: [
              Icon(Icons.language, size: 17, color: cs.onSurface),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.toggleLanguage, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ],
    );
  }
}
