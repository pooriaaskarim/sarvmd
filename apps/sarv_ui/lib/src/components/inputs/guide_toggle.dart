import 'package:flutter/material.dart';
import '../../theme/app_metrics.dart';

class GuideToggle extends StatelessWidget {
  const GuideToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: AppOpacities.surfaceHint),
      ),
      child: CheckboxListTile(
        title: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
        checkColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
      ),
    );
  }
}
