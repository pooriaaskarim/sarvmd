import 'package:flutter/material.dart';
import '../../theme/app_metrics.dart';

class DropdownSetting<T extends Enum> extends StatelessWidget {
  const DropdownSetting({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.labelMapper,
  });

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelMapper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: AppOpacities.border),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
          icon: Icon(Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          isExpanded: true,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: options.map((opt) {
            final label = labelMapper?.call(opt) ?? opt.name.toUpperCase();
            return DropdownMenuItem<T>(
              value: opt,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(label),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
