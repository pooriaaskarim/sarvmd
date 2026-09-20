// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../staff/instrument_preset.dart';

/// Tab 1 of Staff Config Dialog: Instrument Labeling & Presets configuration.
class LabelingTab extends StatefulWidget {
  final String currentName;
  final TextEditingController abbrController;
  final bool labelVisible;
  final ValueChanged<InstrumentPreset> onApplyPreset;
  final ValueChanged<bool> onLabelVisibleChanged;
  final ValueChanged<String> onNameChanged;

  const LabelingTab({
    super.key,
    required this.currentName,
    required this.abbrController,
    required this.labelVisible,
    required this.onApplyPreset,
    required this.onLabelVisibleChanged,
    required this.onNameChanged,
  });

  @override
  State<LabelingTab> createState() => _LabelingTabState();
}

class _LabelingTabState extends State<LabelingTab> {
  TextEditingController? _autoCompleteController;

  String _getFamilyName(BuildContext context, String rawName) {
    final l10n = AppLocalizations.of(context)!;
    switch (rawName) {
      case 'Woodwinds':
        return l10n.familyWoodwinds;
      case 'Brass':
        return l10n.familyBrass;
      case 'Percussion':
        return l10n.familyPercussion;
      case 'Strings':
        return l10n.familyStrings;
      case 'Keyboard & Plucked':
        return l10n.familyKeyboardPlucked;
      default:
        return rawName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),

        // Presets Header Section
        Text(
          l10n.quickInstrumentPresets,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.selectFamilyPresetDesc,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: InstrumentPresets.allFamilies.map((family) {
            final IconData familyIcon = switch (family.name) {
              'Woodwinds' => Icons.air,
              'Brass' => Icons.music_note,
              'Percussion' => Icons.circle_outlined,
              'Strings' => Icons.line_weight,
              'Keyboard & Plucked' => Icons.piano,
              _ => Icons.music_video_outlined,
            };

            return PopupMenuButton<InstrumentPreset>(
              offset: const Offset(0, 40),
              tooltip: 'Select ${family.name} Preset',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(familyIcon, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      _getFamilyName(context, family.name),
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: cs.primary,
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) {
                return family.instruments.map((preset) {
                  return PopupMenuItem<InstrumentPreset>(
                    value: preset,
                    child: Text('${preset.name} (${preset.abbreviation})'),
                  );
                }).toList();
              },
              onSelected: widget.onApplyPreset,
            );
          }).toList(),
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),

        // Cohesive Label Details Card
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Show Label Switch Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.showLabelOnCanvas,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.showLabelOnCanvasDesc,
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
                      value: widget.labelVisible,
                      onChanged: widget.onLabelVisibleChanged,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name Autocomplete Input
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.instrumentNameLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Autocomplete<InstrumentPreset>(
                          initialValue:
                              TextEditingValue(text: widget.currentName),
                          displayStringForOption: (option) => option.name,
                          optionsBuilder: (textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<
                                  InstrumentPreset>.empty();
                            }
                            return InstrumentPresets.allPresets.where(
                                (preset) => preset.name
                                    .toLowerCase()
                                    .contains(textEditingValue.text
                                        .toLowerCase()));
                          },
                          onSelected: widget.onApplyPreset,
                          fieldViewBuilder: (context, textController,
                              focusNode, onFieldSubmitted) {
                            if (_autoCompleteController != textController) {
                              _autoCompleteController = textController;
                              textController.addListener(() {
                                if (widget.currentName != textController.text) {
                                  widget.onNameChanged(textController.text);
                                }
                              });
                            }

                            return TextField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: l10n.instrumentNameHint,
                                prefixIcon:
                                    const Icon(Icons.search, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: cs.outlineVariant, width: 1.2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: cs.outlineVariant, width: 1.2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: cs.primary, width: 1.8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              onSubmitted: (_) => onFieldSubmitted(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Abbreviation Input
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.abbreviationLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: widget.abbrController,
                          decoration: InputDecoration(
                            hintText: l10n.abbreviationHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: cs.outlineVariant, width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: cs.outlineVariant, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: cs.primary, width: 1.8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
