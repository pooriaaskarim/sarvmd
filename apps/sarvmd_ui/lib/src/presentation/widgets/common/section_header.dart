import 'package:flutter/material.dart';
import '../../../core/theme/app_metrics.dart';
import 'property_row.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onReset});
  final String title;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final label = Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
    );

    final resetButton = onReset == null
        ? null
        : Tooltip(
            message: 'Reset to defaults',
            child: GestureDetector(
              onTap: onReset,
              child: Icon(
                Icons.restart_alt,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.headerBottom),
      child: PropertyRow(
        label: label,
        control: resetButton ?? const SizedBox.shrink(),
      ),
    );
  }
}

class SectionHeaderWithSubtitle extends StatelessWidget {
  const SectionHeaderWithSubtitle({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl ||
        Localizations.localeOf(context).languageCode == 'fa';
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment:
          isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant
                .withValues(alpha: AppOpacities.surfaceEmphasized),
          ),
        ),
      ],
    );
  }
}
