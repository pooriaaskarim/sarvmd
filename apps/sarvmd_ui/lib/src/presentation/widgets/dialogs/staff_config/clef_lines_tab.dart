// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../../core/utils/smufl_glyphs.dart';
import '../../../../l10n/app_localizations.dart';

/// Tab 2 of Staff Config Dialog: Clef Symbol & Line Count configuration.
class ClefLinesTab extends StatelessWidget {
  final core.ClefSymbol? selectedClefSymbol;
  final int selectedAnchorLine;
  final int selectedLines;
  final void Function(core.ClefSymbol symbol, int anchorLine, int defaultLines)
      onClefSelect;
  final ValueChanged<int> onAnchorLineChanged;
  final ValueChanged<int> onLinesChanged;

  const ClefLinesTab({
    super.key,
    required this.selectedClefSymbol,
    required this.selectedAnchorLine,
    required this.selectedLines,
    required this.onClefSelect,
    required this.onAnchorLineChanged,
    required this.onLinesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 500;
    final isFixedLines = selectedClefSymbol?.requiresFixedLines ?? false;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.clefSettingsHeader,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 12),

        // Clef Symbol Column
        Column(
          children: core.ClefSymbol.values.map((symbol) {
            final isSelected = selectedClefSymbol == symbol;
            final String glyph = symbol.smuflGlyph;

            String title = switch (symbol) {
              core.ClefSymbol.g => l10n.clefTrebleTitle,
              core.ClefSymbol.c => l10n.clefMovableCTitle,
              core.ClefSymbol.f => l10n.clefBassTitle,
              core.ClefSymbol.tab => l10n.clefTabTitle,
              core.ClefSymbol.percussion => l10n.clefPercussionTitle,
            };

            String description = switch (symbol) {
              core.ClefSymbol.g => l10n.clefTrebleDesc,
              core.ClefSymbol.c => l10n.clefMovableCDesc,
              core.ClefSymbol.f => l10n.clefBassDesc,
              core.ClefSymbol.tab => l10n.clefTabDesc,
              core.ClefSymbol.percussion => l10n.clefPercussionDesc,
            };

            return _buildClefRowCard(
              theme: theme,
              symbol: symbol,
              glyph: glyph,
              title: title,
              description: description,
              isSelected: isSelected,
              onTap: () {
                final defaultAnchor = switch (symbol) {
                  core.ClefSymbol.g => 2,
                  core.ClefSymbol.c => 3,
                  core.ClefSymbol.f => 4,
                  core.ClefSymbol.percussion => 3,
                  core.ClefSymbol.tab => 3,
                };
                onClefSelect(
                  symbol,
                  defaultAnchor,
                  symbol.requiresFixedLines ? symbol.defaultLines : selectedLines,
                );
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Clef Presets / Register Chips (Only for pitched clefs supporting anchor offset)
        if (selectedClefSymbol != null &&
            selectedClefSymbol!.supportsAnchorOffset) ...[
          Text(
            l10n.clefPresetRegisterHeader,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedClefSymbol!.registerPresets.map((preset) {
              return _buildClefPresetChip(
                theme,
                preset.label,
                preset.anchorLine,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        const Divider(),
        const SizedBox(height: 20),

        // Staff Line Count Section
        Text(
          l10n.numberOfStaffLinesHeader,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          isFixedLines ? l10n.lineCountLockedNote : l10n.numberOfStaffLinesDesc,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isFixedLines ? cs.error : cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        if (isFixedLines)
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(
                label: Text(l10n.numberOfLinesReadout(5)),
                selected: true,
                onSelected: null,
                selectedColor: cs.primaryContainer,
                labelStyle: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                avatar: Icon(Icons.star, size: 14, color: cs.primary),
              ),
            ],
          )
        else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [1, 2, 3, 4, 5, 6].map((lines) {
              final isSelected = selectedLines == lines;

              return ChoiceChip(
                label: Text(l10n.numberOfLinesReadout(lines)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onLinesChanged(lines);
                  }
                },
                selectedColor: cs.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                avatar: lines == (selectedClefSymbol == core.ClefSymbol.tab ? 6 : 5)
                    ? Icon(Icons.star, size: 14, color: cs.primary)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Custom Line Count:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    icon: const Icon(Icons.remove, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: selectedLines > 1
                        ? () => onLinesChanged(selectedLines - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      '$selectedLines',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    icon: const Icon(Icons.add, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: selectedLines < 10
                        ? () => onLinesChanged(selectedLines + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildClefRowCard({
    required ThemeData theme,
    required core.ClefSymbol symbol,
    required String glyph,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.6),
                      width: isSelected ? 5.5 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (glyph.isNotEmpty) ...[
                  Text(
                    glyph,
                    style: TextStyle(
                      fontFamily: 'Bravura',
                      fontSize: 32,
                      height: 1.0,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClefPresetChip(
    ThemeData theme,
    String label,
    int targetAnchorLine,
  ) {
    final cs = theme.colorScheme;
    final isSelected = selectedAnchorLine == targetAnchorLine;

    return ActionChip(
      label: Text(label),
      onPressed: () => onAnchorLineChanged(targetAnchorLine),
      backgroundColor: isSelected
          ? cs.secondaryContainer
          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
      labelStyle: TextStyle(
        color: isSelected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? cs.secondary : Colors.transparent,
        width: 1.2,
      ),
    );
  }
}
