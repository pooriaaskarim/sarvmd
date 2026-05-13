import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../specialized/mini_staff_preview.dart';

class LayoutTypeSwitcher extends StatelessWidget {
  const LayoutTypeSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final core.LayoutType value;
  final ValueChanged<core.LayoutType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: core.LayoutType.values.map((type) {
          final active = type == value;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  color: active
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: active ? 1.5 : 1.0,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiniStaffPreview(
                      layoutType: type,
                      active: active,
                      // We use generic G/F clefs for the preview switcher
                      // primaryClef: core.ClefSymbol.g,
                      // secondaryClef: type == core.LayoutType.doubleLine
                      //     ? core.ClefSymbol.f
                      //     : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
