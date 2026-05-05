import 'package:flutter/material.dart';
import '../../theme/app_metrics.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onReset});
  final String title;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );

    if (onReset == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.headerBottom),
        child: label,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.headerBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          label,
          Tooltip(
            message: 'Reset to defaults',
            child: GestureDetector(
              onTap: onReset,
              child: Icon(
                Icons.restart_alt,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant
                .withValues(alpha: AppOpacities.surfaceEmphasized),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
