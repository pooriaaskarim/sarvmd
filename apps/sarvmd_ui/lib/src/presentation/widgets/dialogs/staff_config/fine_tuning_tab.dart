// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'precision_numeric_slider.dart';

/// Tab 3 of Staff Config Dialog: Fine-Tuning & Typography styling configuration.
class FineTuningTab extends StatelessWidget {
  final String fontFamily;
  final double fontSize;
  final bool italic;
  final double horizontalOffset;
  final double verticalOffset;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onItalicChanged;
  final ValueChanged<double> onHorizontalOffsetChanged;
  final ValueChanged<double> onVerticalOffsetChanged;

  const FineTuningTab({
    super.key,
    required this.fontFamily,
    required this.fontSize,
    required this.italic,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.onFontFamilyChanged,
    required this.onFontSizeChanged,
    required this.onItalicChanged,
    required this.onHorizontalOffsetChanged,
    required this.onVerticalOffsetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.typographyStylingHeader,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 12),

        // Font Family Visual Previews Row
        Row(
          children: [
            _buildFontFamilyCard(
              theme: theme,
              title: l10n.fontSerifTitle,
              familyKey: 'serif',
              preview: 'Aa',
              isSelected: fontFamily == 'serif',
              onTap: () => onFontFamilyChanged('serif'),
            ),
            const SizedBox(width: 12),
            _buildFontFamilyCard(
              theme: theme,
              title: l10n.fontSansTitle,
              familyKey: 'sans',
              preview: 'Aa',
              isSelected: fontFamily == 'sans',
              onTap: () => onFontFamilyChanged('sans'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Typography Settings Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Font Size Dual Slider
              PrecisionNumericSlider(
                label: l10n.labelFontSizeLabel,
                value: fontSize,
                min: 8.0,
                max: 20.0,
                step: 0.5,
                fractionDigits: 1,
                onChanged: onFontSizeChanged,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              // Italics Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.italicizeLabelHeader,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold, color: cs.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.italicizeLabelDesc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: italic,
                      onChanged: onItalicChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        // Precision Placement & Alignment Offset Section
        Text(
          l10n.alignmentOffsetsHeader,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrecisionNumericSlider(
                label: l10n.horizontalOffsetLabel,
                value: horizontalOffset,
                min: -50.0,
                max: 50.0,
                step: 0.5,
                fractionDigits: 1,
                onChanged: onHorizontalOffsetChanged,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              PrecisionNumericSlider(
                label: l10n.verticalOffsetLabel,
                value: verticalOffset,
                min: -30.0,
                max: 30.0,
                step: 0.5,
                fractionDigits: 1,
                onChanged: onVerticalOffsetChanged,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFontFamilyCard({
    required ThemeData theme,
    required String title,
    required String familyKey,
    required String preview,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = theme.colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primaryContainer.withValues(alpha: 0.35)
                  : cs.surfaceContainerHigh.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(
                  preview,
                  style: TextStyle(
                    fontFamily: familyKey == 'serif' ? 'serif' : 'sans-serif',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
