// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Responsive cluster of controls for configuring staff label typography:
/// font family (Serif/Sans), style toggles (Italic, Bold), and font size stepper.
class LabelTypographyCluster extends StatelessWidget {
  const LabelTypographyCluster({
    super.key,
    required this.style,
    required this.onChanged,
  });

  final core.StaffLabelStyle style;
  final ValueChanged<core.StaffLabelStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields_rounded, size: 13, color: cs.primary),
              const SizedBox(width: 4),
              Text(
                'Style',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Style toggles cluster (Italic, Bold, Serif/Sans)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.format_italic,
                      size: 15,
                      color: style.isItalic
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    isSelected: style.isItalic,
                    onPressed: () =>
                        onChanged(style.copyWith(isItalic: !style.isItalic)),
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                    tooltip: 'Italic',
                    style: IconButton.styleFrom(
                      backgroundColor: style.isItalic
                          ? cs.primaryContainer.withValues(alpha: 0.5)
                          : null,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: Icon(
                      Icons.format_bold,
                      size: 15,
                      color: style.isBold
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    isSelected: style.isBold,
                    onPressed: () =>
                        onChanged(style.copyWith(isBold: !style.isBold)),
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: EdgeInsets.zero,
                    tooltip: 'Bold',
                    style: IconButton.styleFrom(
                      backgroundColor: style.isBold
                          ? cs.primaryContainer.withValues(alpha: 0.5)
                          : null,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      final next =
                          style.fontFamily == 'serif' ? 'sans' : 'serif';
                      onChanged(style.copyWith(fontFamily: next));
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        style.fontFamily == 'serif' ? 'Serif' : 'Sans',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Font size stepper cluster
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 12),
                    onPressed: style.fontSizePt > 7
                        ? () => onChanged(
                            style.copyWith(fontSizePt: style.fontSizePt - 0.5))
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 22),
                    padding: EdgeInsets.zero,
                    tooltip: 'Smaller Font',
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    alignment: Alignment.center,
                    child: Text(
                      '${style.fontSizePt.toStringAsFixed(1)} pt',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 12),
                    onPressed: style.fontSizePt < 22
                        ? () => onChanged(
                            style.copyWith(fontSizePt: style.fontSizePt + 0.5))
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 22),
                    padding: EdgeInsets.zero,
                    tooltip: 'Larger Font',
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
