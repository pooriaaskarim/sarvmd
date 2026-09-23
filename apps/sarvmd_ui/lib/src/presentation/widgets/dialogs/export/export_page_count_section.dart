// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';

/// Page count selection section for PDF and TeX exports.
class ExportPageCountSection extends StatelessWidget {
  final int pageCount;
  final TextEditingController pageController;
  final ValueChanged<int> onPageCountChanged;

  const ExportPageCountSection({
    super.key,
    required this.pageCount,
    required this.pageController,
    required this.onPageCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 300;
              final labelWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_none_outlined,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.numberOfPagesLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              );

              final stepperWidget = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepButton(
                    icon: Icons.remove,
                    onPressed: pageCount > 1
                        ? () => onPageCountChanged(pageCount - 1)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 48,
                    height: 32,
                    child: TextField(
                      controller: pageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: cs.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: cs.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          onPageCountChanged(parsed.clamp(1, 100));
                        }
                      },
                      onSubmitted: (val) {
                        final parsed = int.tryParse(val) ?? 1;
                        onPageCountChanged(parsed.clamp(1, 100));
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  _StepButton(
                    icon: Icons.add,
                    onPressed: pageCount < 100
                        ? () => onPageCountChanged(pageCount + 1)
                        : null,
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelWidget,
                    const SizedBox(height: 8),
                    stepperWidget,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  labelWidget,
                  stepperWidget,
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Quick Page Count Preset Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [1, 2, 3, 5, 10].map((preset) {
              final isSelected = pageCount == preset;
              return ChoiceChip(
                label: Text(
                  l10n.pageCountSuffix(preset),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
                selected: isSelected,
                selectedColor: cs.primary,
                backgroundColor:
                    cs.surfaceContainerHighest.withValues(alpha: 0.4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onPageCountChanged(preset),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 14),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          disabledBackgroundColor:
              cs.surfaceContainerHighest.withValues(alpha: 0.2),
          foregroundColor: cs.onSurface,
          disabledForegroundColor: cs.onSurface.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
