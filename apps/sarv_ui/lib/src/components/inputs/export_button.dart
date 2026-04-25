import 'package:flutter/material.dart';
import '../../theme/app_metrics.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: (color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: AppOpacities.hover),
        foregroundColor: color ?? Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.paddingMedium,
            horizontal: AppSpacing.paddingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
              color: color ?? Theme.of(context).colorScheme.primary, width: 1),
        ),
        elevation: 0,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
