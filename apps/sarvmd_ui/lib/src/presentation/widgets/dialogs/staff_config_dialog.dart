// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../staff/instrument_preset.dart';
import '../staff/live_staff_preview.dart';
import 'adaptive_dialog_helper.dart';
import 'staff_config/clef_lines_tab.dart';
import 'staff_config/fine_tuning_tab.dart';
import 'staff_config/labeling_tab.dart';

/// Opens the adaptive Staff Configuration dialog or bottom sheet.
Future<void> showStaffConfigDialog(
  BuildContext context, {
  required core.StaffDefinition staff,
  required DocumentCubit notifier,
}) {
  return showSarvAdaptiveModal<void>(
    context: context,
    builder: (ctx, isMobile) => StaffConfigDialog(
      staff: staff,
      notifier: notifier,
    ),
  );
}

/// Adaptive modal dialog for configuring individual staff parameters.
class StaffConfigDialog extends StatefulWidget {
  final core.StaffDefinition staff;
  final DocumentCubit notifier;

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
      _abbrController.text = preset.abbreviation;
      _selectedLines = preset.defaultLines;
      if (preset.defaultClef != null) {
        _selectedClefSymbol = preset.defaultClef!.symbol;
        _selectedAnchorLine = preset.defaultClef!.anchorLine;
      }
    });
  }

  void _onSave() {
    core.Clef? newClef = _selectedClefSymbol?.createClef(
      anchorLine: _selectedAnchorLine,
    );

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
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    final content = Container(
      constraints: BoxConstraints(
        maxWidth: 550,
        maxHeight: isMobile
            ? media.size.height * 0.90
            : (media.size.height * 0.85).clamp(320.0, 720.0),
      ),
      child: Column(
        children: [
          // ── Dialog Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.configureStaffSettings,
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
            tabs: [
              Tab(icon: const Icon(Icons.label_outlined), text: l10n.tabLabeling),
              Tab(
                  icon: const Icon(Icons.music_note_outlined),
                  text: l10n.tabClefLines),
              Tab(icon: const Icon(Icons.tune_outlined), text: l10n.tabFineTuning),
            ],
          ),

          const Divider(height: 1),

          // ── Interactive Live Preview Panel ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: LiveStaffPreview(
              name: _currentName.isEmpty
                  ? l10n.defaultInstrumentName
                  : _currentName,
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

          // ── Tab Bar Views ─────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LabelingTab(
                  currentName: _currentName,
                  abbrController: _abbrController,
                  labelVisible: _labelVisible,
                  onApplyPreset: _applyPreset,
                  onLabelVisibleChanged: (val) =>
                      setState(() => _labelVisible = val),
                  onNameChanged: (val) => setState(() => _currentName = val),
                ),
                ClefLinesTab(
                  selectedClefSymbol: _selectedClefSymbol,
                  selectedAnchorLine: _selectedAnchorLine,
                  selectedLines: _selectedLines,
                  onClefSelect: (symbol, anchorLine, defaultLines) {
                    setState(() {
                      _selectedClefSymbol = symbol;
                      _selectedAnchorLine = anchorLine;
                      _selectedLines = defaultLines;
                    });
                  },
                  onAnchorLineChanged: (line) =>
                      setState(() => _selectedAnchorLine = line),
                  onLinesChanged: (lines) =>
                      setState(() => _selectedLines = lines),
                ),
                FineTuningTab(
                  fontFamily: _fontFamily,
                  fontSize: _fontSize,
                  italic: _italic,
                  horizontalOffset: _horizontalOffset,
                  verticalOffset: _verticalOffset,
                  onFontFamilyChanged: (family) =>
                      setState(() => _fontFamily = family),
                  onFontSizeChanged: (val) => setState(() => _fontSize = val),
                  onItalicChanged: (val) => setState(() => _italic = val),
                  onHorizontalOffsetChanged: (val) =>
                      setState(() => _horizontalOffset = val),
                  onVerticalOffsetChanged: (val) =>
                      setState(() => _verticalOffset = val),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Dialog Actions ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.notifier.allStaves.length > 1
                      ? () {
                          widget.notifier.removeStaffByUid(widget.staff.uid);
                          Navigator.of(context).pop();
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: theme.colorScheme.error,
                  tooltip: l10n.removeStaff,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _onSave,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}
