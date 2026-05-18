import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../config_notifier.dart';
import 'instrument_preset.dart';
import 'live_staff_preview.dart';

class StaffConfigDialog extends StatefulWidget {
  final core.StaffDefinition staff;
  final ConfigNotifier notifier;

  const StaffConfigDialog({
    super.key,
    required this.staff,
    required this.notifier,
  });

  @override
  State<StaffConfigDialog> createState() => _StaffConfigDialogState();
}

class _StaffConfigDialogState extends State<StaffConfigDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late String _currentName;
  TextEditingController? _autoCompleteController;
  late TextEditingController _abbrController;

  late bool _labelVisible;
  late int _selectedLines;
  late core.ClefSymbol? _selectedClefSymbol;
  late int _selectedAnchorLine;

  late double _horizontalOffset;
  late double _verticalOffset;
  late String _fontFamily;
  late double _fontSize;
  late bool _italic;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _currentName = widget.staff.instrumentName ?? '';
    _abbrController =
        TextEditingController(text: widget.staff.instrumentAbbreviation ?? '');

    _labelVisible = widget.staff.labelVisible;
    _selectedLines = widget.staff.lines;
    _selectedClefSymbol = widget.staff.clef?.symbol;
    _selectedAnchorLine = widget.staff.clef?.anchorLine ?? 2;

    _horizontalOffset = widget.staff.labelHorizontalOffset;
    _verticalOffset = widget.staff.labelVerticalOffset;
    _fontFamily = widget.staff.labelFontFamily;
    _fontSize = widget.staff.labelFontSize;
    _italic = widget.staff.labelItalic;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _abbrController.dispose();
    super.dispose();
  }

  void _applyPreset(InstrumentPreset preset) {
    setState(() {
      _currentName = preset.name;
      _autoCompleteController?.text = preset.name;
      _abbrController.text = preset.abbreviation;
      _selectedLines = preset.defaultLines;
      if (preset.defaultClef != null) {
        _selectedClefSymbol = preset.defaultClef!.symbol;
        _selectedAnchorLine = preset.defaultClef!.anchorLine;
      }
    });
  }

  void _onSave() {
    core.ClefConfig? newClef;
    if (_selectedClefSymbol != null) {
      newClef = core.ClefConfig(
        symbol: _selectedClefSymbol!,
        anchorLine: _selectedAnchorLine,
      );
    }

    widget.notifier.updateStaffConfigDetails(
      widget.staff.uid,
      name: () => _currentName.trim().isEmpty ? null : _currentName.trim(),
      abbreviation: () => _abbrController.text.trim().isEmpty
          ? null
          : _abbrController.text.trim(),
      visible: _labelVisible,
      lines: _selectedLines,
      clef: () => newClef,
      horizontalOffset: _horizontalOffset,
      verticalOffset: _verticalOffset,
      fontFamily: _fontFamily,
      fontSize: _fontSize,
      italic: _italic,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      elevation: 24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 550,
          maxHeight:
              (MediaQuery.sizeOf(context).height * 0.85).clamp(450.0, 720.0),
        ),
        child: Column(
          children: [
            // ── Dialog Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.settings_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configure Staff Settings',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ───────────────────────────────────────────
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: Icon(Icons.label_outlined), text: 'Labeling'),
                Tab(
                    icon: Icon(Icons.music_note_outlined),
                    text: 'Clef & Lines'),
                Tab(icon: Icon(Icons.tune_outlined), text: 'Fine-Tuning'),
              ],
            ),

            const Divider(height: 1),

            // ── Interactive Live Preview Panel ─────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: LiveStaffPreview(
                name: _currentName.isEmpty ? 'Instrument' : _currentName,
                abbrev: _abbrController.text,
                lines: _selectedLines,
                clefSymbol: _selectedClefSymbol,
                anchorLine: _selectedAnchorLine,
                visible: _labelVisible,
                hOffset: _horizontalOffset,
                vOffset: _verticalOffset,
                fontFamily: _fontFamily,
                fontSize: _fontSize,
                italic: _italic,
                onAnchorLineChanged: (newLine) {
                  setState(() {
                    _selectedAnchorLine = newLine;
                  });
                },
              ),
            ),

            // ── Tab Bar Views (Scrollable with fading edges) ────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Labeling & Presets
                  _buildLabelingTab(theme),

                  // Tab 2: Clef & Lines
                  _buildClefTab(theme),

                  // Tab 3: Fine-Tuning & Styling
                  _buildFineTuningTab(theme),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Dialog Actions ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Apply Changes'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Labeling & Presets ────────────────────────────────────
  Widget _buildLabelingTab(ThemeData theme) {
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),

        // Presets Header Section
        Text(
          'Quick Instrument Presets',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a family to pick an orchestral instrument preset',
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
                      family.name,
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
              onSelected: _applyPreset,
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
                          'Show Label on Canvas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Toggle visibility of instrument name on score margins',
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
                      value: _labelVisible,
                      onChanged: (val) => setState(() => _labelVisible = val),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Animated Opacity and IgnorePointer when disabled
              AnimatedOpacity(
                opacity: _labelVisible ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_labelVisible,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name Autocomplete Input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instrument Name',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Autocomplete<InstrumentPreset>(
                              initialValue:
                                  TextEditingValue(text: _currentName),
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
                              onSelected: _applyPreset,
                              fieldViewBuilder: (context, textController,
                                  focusNode, onFieldSubmitted) {
                                if (_autoCompleteController != textController) {
                                  _autoCompleteController = textController;
                                  textController.addListener(() {
                                    if (_currentName != textController.text) {
                                      setState(() {
                                        _currentName = textController.text;
                                      });
                                    }
                                  });
                                }

                                return TextField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Violin I, Cello...',
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
                              'Abbreviation',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _abbrController,
                              decoration: InputDecoration(
                                hintText: 'e.g. Vln. I, Vc.',
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
                              onChanged: (val) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // ── Tab 2: Clef & Lines ──────────────────────────────────────────
  // ── Tab 2: Clef & Lines ──────────────────────────────────────────
  Widget _buildClefTab(ThemeData theme) {
    final cs = theme.colorScheme;
    final isFixedLines = _selectedClefSymbol?.requiresFixedLines ?? false;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),
        Text(
          'Clef Settings',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 12),

        // Clef Symbol Column - Spacious & Informative Rows
        Column(
          children: core.ClefSymbol.values.map((symbol) {
            final isSelected = _selectedClefSymbol == symbol;

            String glyph = switch (symbol) {
              core.ClefSymbol.g => '\u{1D11E}',
              core.ClefSymbol.c => '\u{1D121}',
              core.ClefSymbol.f => '\u{1D122}',
              _ => '',
            };

            String title = switch (symbol) {
              core.ClefSymbol.g => 'Treble Clef (G-Clef)',
              core.ClefSymbol.c => 'Movable C-Clef',
              core.ClefSymbol.f => 'Bass Clef (F-Clef)',
              core.ClefSymbol.tab => 'Tablature (TAB)',
              core.ClefSymbol.percussion => 'Percussion Clef (Neutral)',
            };

            String description = switch (symbol) {
              core.ClefSymbol.g =>
                'For high-register instruments (Violin, Flute, Oboe, Soprano, Piano RH). Anchors G4 on Line 2.',
              core.ClefSymbol.c =>
                'For mid-register instruments. Placed on Line 3 for Viola (Alto) or Line 4 for Tenor Cello/Trombone. Anchors C4.',
              core.ClefSymbol.f =>
                'For low-register instruments (Cello, Bassoon, Trombone, Tuba, Double Bass, Piano LH). Anchors F3 on Line 4.',
              core.ClefSymbol.tab =>
                'For fretted string instruments (Guitar, Bass). Staff lines represent strings, and numbers represent fret positions.',
              core.ClefSymbol.percussion =>
                'For non-pitched rhythm instruments (Snare Drum, Bass Drum, Cymbals, Triangle). Focuses purely on rhythm.',
            };

            return _buildClefRowCard(
              theme: theme,
              symbol: symbol,
              glyph: glyph,
              title: title,
              description: description,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedClefSymbol = symbol;
                  _selectedAnchorLine = switch (symbol) {
                    core.ClefSymbol.g => 2,
                    core.ClefSymbol.c => 3,
                    core.ClefSymbol.f => 4,
                    _ => 3,
                  };
                  if (symbol.requiresFixedLines) {
                    _selectedLines = symbol.defaultLines;
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Clef Presets / Register Chips (Dynamic based on selected Clef Symbol)
        if (_selectedClefSymbol != null) ...[
          Text(
            'Clef Preset / Register',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedClefSymbol == core.ClefSymbol.g) ...[
                _buildClefPresetChip(
                    theme, 'Treble (G2)', core.ClefSymbol.g, 2),
              ],
              if (_selectedClefSymbol == core.ClefSymbol.c) ...[
                _buildClefPresetChip(theme, 'Alto (C3)', core.ClefSymbol.c, 3),
                _buildClefPresetChip(theme, 'Tenor (C4)', core.ClefSymbol.c, 4),
                _buildClefPresetChip(
                    theme, 'Soprano (C1)', core.ClefSymbol.c, 1),
                _buildClefPresetChip(
                    theme, 'Mezzo-Soprano (C2)', core.ClefSymbol.c, 2),
              ],
              if (_selectedClefSymbol == core.ClefSymbol.f) ...[
                _buildClefPresetChip(theme, 'Bass (F4)', core.ClefSymbol.f, 4),
                _buildClefPresetChip(
                    theme, 'Baritone (F3)', core.ClefSymbol.f, 3),
              ],
              if (_selectedClefSymbol == core.ClefSymbol.tab) ...[
                _buildClefPresetChip(
                    theme, 'Guitar TAB', core.ClefSymbol.tab, 3),
              ],
              if (_selectedClefSymbol == core.ClefSymbol.percussion) ...[
                _buildClefPresetChip(
                    theme, 'Percussion', core.ClefSymbol.percussion, 2),
              ],
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Anchor Line Slider Container
        if (_selectedClefSymbol?.supportsAnchorOffset ?? false) ...[
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clef Anchor Line',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sets which staff line the clef anchors to',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        'Line $_selectedAnchorLine',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Slider(
                  min: 1,
                  max: 5,
                  divisions: 4,
                  value: _selectedAnchorLine.toDouble(),
                  onChanged: (val) =>
                      setState(() => _selectedAnchorLine = val.round()),
                  activeColor: cs.primary,
                  inactiveColor: cs.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Tip: You can also tap directly on any line in the visual preview above to snap the clef to that line!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Staff Lines Slider Container
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Number of Staff Lines',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Standard is 5 lines (TAB is 6, percussion varies)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFixedLines
                          ? cs.outlineVariant.withValues(alpha: 0.2)
                          : cs.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isFixedLines
                              ? cs.outlineVariant
                              : cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '$_selectedLines Lines',
                      style: TextStyle(
                        color: isFixedLines ? cs.onSurfaceVariant : cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                min: 1,
                max: 8,
                divisions: 7,
                value: _selectedLines.toDouble(),
                onChanged: isFixedLines
                    ? null
                    : (val) => setState(() => _selectedLines = val.round()),
                activeColor: cs.primary,
                inactiveColor: cs.outlineVariant.withValues(alpha: 0.6),
              ),
              if (isFixedLines) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Note: Line count is locked for the selected specialized clef.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

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

    // Custom graphical indicator for Percussion and TAB
    Widget graphicsIndicator;
    if (symbol == core.ClefSymbol.percussion) {
      graphicsIndicator = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 3),
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    } else if (symbol == core.ClefSymbol.tab) {
      graphicsIndicator = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'T',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 0.9,
              fontFamily: 'NotoSerif',
              color: isSelected ? cs.primary : cs.onSurface,
            ),
          ),
          Text(
            'A',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 0.9,
              fontFamily: 'NotoSerif',
              color: isSelected ? cs.primary : cs.onSurface,
            ),
          ),
          Text(
            'B',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 0.9,
              fontFamily: 'NotoSerif',
              color: isSelected ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      );
    } else {
      graphicsIndicator = Text(
        glyph,
        style: TextStyle(
          fontFamily: 'NotoMusic',
          fontSize: 32,
          height: 1.0,
          color: isSelected ? cs.primary : cs.onSurface,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.15)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? cs.primary : cs.outlineVariant,
          width: isSelected ? 1.8 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left: Icon Box
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.1)
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: graphicsIndicator,
              ),
              const SizedBox(width: 16),
              // Right: Title & Description Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClefPresetChip(
      ThemeData theme, String title, core.ClefSymbol sym, int line) {
    final isSelected =
        _selectedClefSymbol == sym && _selectedAnchorLine == line;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedClefSymbol = sym;
          _selectedAnchorLine = line;
          if (sym.requiresFixedLines) {
            _selectedLines = sym.defaultLines;
          }
        });
      },
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      selectedColor: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  // ── Tab 3: Fine-Tuning & Styling ─────────────────────────────────
  Widget _buildFineTuningTab(ThemeData theme) {
    final cs = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),
        Text(
          'Typography & Styling',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 12),

        // Font Family Visual Previews Row
        Row(
          children: [
            _buildFontFamilyCard(
              theme: theme,
              title: 'Classic Serif',
              fontFamily: 'serif',
              preview: 'Aa',
              isSelected: _fontFamily == 'serif',
              onTap: () => setState(() => _fontFamily = 'serif'),
            ),
            const SizedBox(width: 12),
            _buildFontFamilyCard(
              theme: theme,
              title: 'Modern Sans',
              fontFamily: 'sans',
              preview: 'Aa',
              isSelected: _fontFamily == 'sans',
              onTap: () => setState(() => _fontFamily = 'sans'),
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
              _PrecisionNumericSlider(
                label: 'Label Font Size',
                value: _fontSize,
                min: 8.0,
                max: 20.0,
                step: 0.5,
                fractionDigits: 1,
                onChanged: (val) => setState(() => _fontSize = val),
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
                          'Italicize Label',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold, color: cs.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Use standard italics for score titles',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _italic,
                    onChanged: (val) => setState(() => _italic = val),
                    activeThumbColor: cs.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Fine Alignment & Offsets',
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        const SizedBox(height: 12),

        // Alignment Settings Container
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
              // Horizontal Offset Dual Slider
              _PrecisionNumericSlider(
                label: 'Horizontal Offset',
                value: _horizontalOffset,
                min: -60.0,
                max: 60.0,
                step: 1.0,
                fractionDigits: 0,
                onChanged: (val) => setState(() => _horizontalOffset = val),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              // Vertical Offset Dual Slider
              _PrecisionNumericSlider(
                label: 'Vertical Offset',
                value: _verticalOffset,
                min: -40.0,
                max: 40.0,
                step: 1.0,
                fractionDigits: 0,
                onChanged: (val) => setState(() => _verticalOffset = val),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tip: Changes are instantly previewed in the live staff above.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
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

  Widget _buildFontFamilyCard({
    required ThemeData theme,
    required String title,
    required String fontFamily,
    required String preview,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = theme.colorScheme;
    final previewStyle = TextStyle(
      fontFamily: fontFamily == 'serif' ? 'Noto Serif' : 'Roboto',
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color:
          isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(preview, style: previewStyle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Premium Dual-Control Slider with Precision Spinners ────
class _PrecisionNumericSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final int fractionDigits;
  final ValueChanged<double> onChanged;

  const _PrecisionNumericSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1.0,
    this.fractionDigits = 0,
    required this.onChanged,
  });

  @override
  State<_PrecisionNumericSlider> createState() =>
      _PrecisionNumericSliderState();
}

class _PrecisionNumericSliderState extends State<_PrecisionNumericSlider> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _PrecisionNumericSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _textController.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    return val.toStringAsFixed(widget.fractionDigits);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Re-sync on focus loss
      _textController.text = _formatValue(widget.value);
    }
  }

  void _updateValue(double newValue) {
    final clamped = newValue.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
    if (_focusNode.hasFocus) {
      final formatted = _formatValue(clamped);
      if (_textController.text != formatted) {
        _textController.text = formatted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            // High contrast status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_formatValue(widget.value)} pt',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            // Smooth Slider
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  valueIndicatorColor: theme.colorScheme.primary,
                ),
                child: Slider(
                  min: widget.min,
                  max: widget.max,
                  value: widget.value,
                  onChanged: (val) {
                    _updateValue(val);
                    if (!_focusNode.hasFocus) {
                      _textController.text = _formatValue(val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Custom Numeric Step Box
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 14),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final target = widget.value - widget.step;
                      _updateValue(target);
                      _textController.text =
                          _formatValue(target.clamp(widget.min, widget.max));
                    },
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(
                    width: 38,
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        if (text.isEmpty) return;
                        final parsed = double.tryParse(text);
                        if (parsed != null) {
                          widget
                              .onChanged(parsed.clamp(widget.min, widget.max));
                        }
                      },
                      onSubmitted: (text) {
                        if (text.isEmpty) {
                          _textController.text = _formatValue(widget.value);
                          return;
                        }
                        final parsed = double.tryParse(text);
                        _updateValue(parsed ?? widget.value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 14),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final target = widget.value + widget.step;
                      _updateValue(target);
                      _textController.text =
                          _formatValue(target.clamp(widget.min, widget.max));
                    },
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
