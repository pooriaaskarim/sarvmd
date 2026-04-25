import 'package:flutter/material.dart';
import '../../theme/app_metrics.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.headerBottom),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
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
