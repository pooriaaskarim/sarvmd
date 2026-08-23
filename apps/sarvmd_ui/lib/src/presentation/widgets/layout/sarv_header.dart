import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../dialogs/about_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

/// The primary branding header for SarvMD, featuring the handwriting logo
/// and the 'Manuscript Designer' subtitle in IranNastaliq.
class SarvHeader extends StatelessWidget {
  const SarvHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Tooltip(
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
                  SvgPicture.asset(
                    'assets/handwriting/Sarv Handwriting.svg',
                    height: 64,
                    colorFilter: ColorFilter.mode(
                      cs.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.appSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .extension<SarvThemeExtension>()
                            ?.brandSubtitleStyle,
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
      ),
    );
  }
}
