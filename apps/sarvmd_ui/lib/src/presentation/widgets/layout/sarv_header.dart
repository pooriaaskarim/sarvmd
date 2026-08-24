// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../dialogs/about_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// The primary branding header for SarvMD, featuring the handwriting logo
/// and the 'MANUSCRIPT DESIGNER' subtitle with Hero shared-element transition support.
class SarvHeader extends StatelessWidget {
  const SarvHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: AppLocalizations.of(context)!.aboutSarvMD,
      child: InkWell(
        onTap: () => showSarvAboutDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'sarv_brand_logo',
                  child: SvgPicture.asset(
                    'assets/handwriting/Sarv Handwriting.svg',
                    height: 54,
                    colorFilter: ColorFilter.mode(
                      cs.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'sarv_brand_subtitle',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          AppLocalizations.of(context)!.appSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .extension<SarvThemeExtension>()
                              ?.brandSubtitleStyle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: cs.primary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
