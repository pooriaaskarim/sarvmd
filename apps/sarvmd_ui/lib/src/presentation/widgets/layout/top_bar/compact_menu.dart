// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../logic/score/score_cubit.dart';

/// Builds the flat [PopupMenuEntry] list used by the compact (< 960 px) app-menu.
///
/// In compact mode there is no room for separate "File / Edit / View / Help"
/// headers, so everything collapses into a single [PopupMenuButton] triggered
/// by tapping the brand logo.
List<PopupMenuEntry<String>> buildCompactMenuItems(
  BuildContext context,
  AppLocalizations l10n,
  ColorScheme cs,
  SarvThemeExtension? themeExt,
  ScoreState scoreState,
  core.PageConfig configState,
) {
  return [
    // Brand header card (non-interactive)
    PopupMenuItem<String>(
      enabled: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/handwriting/Sarv Handwriting.svg',
              height: 28.0,
              colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
            ),
            const SizedBox(height: 4.0),
            Text(
              l10n.appSubtitle,
              style: themeExt?.brandSubtitleStyle ??
                  TextStyle(
                    fontSize: 13.5,
                    fontFamily: 'IranNastaliq',
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
            ),
          ],
        ),
      ),
    ),
    const PopupMenuDivider(),
    PopupMenuItem<String>(
      value: 'export',
      child: Row(
        children: [
          Icon(Icons.file_upload_outlined, size: 18, color: cs.primary),
          const SizedBox(width: 12),
          Text(l10n.export, style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'language',
      child: Row(
        children: [
          Icon(Icons.language, size: 18, color: cs.onSurface),
          const SizedBox(width: 12),
          Text(l10n.toggleLanguage),
        ],
      ),
    ),
    PopupMenuItem<String>(
      value: 'about',
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.onSurface),
          const SizedBox(width: 12),
          Text(l10n.aboutSarvMD),
        ],
      ),
    ),
  ];
}
