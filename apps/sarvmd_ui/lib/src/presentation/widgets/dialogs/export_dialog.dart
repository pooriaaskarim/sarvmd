// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../logic/config/config_cubit.dart';
import '../../../logic/services/export_directory_service.dart';
import '../../../logic/services/export_service.dart';

enum ExportFormat {
  pdf(
    label: 'PDF Document',
    shortLabel: 'PDF',
    icon: Icons.picture_as_pdf,
    ext: '.pdf',
    description: 'Printable sheet music PDF.',
  ),
  svg(
    label: 'Vector Graphic (SVG)',
    shortLabel: 'SVG',
    icon: Icons.image_outlined,
    ext: '.svg',
    description: 'Editable vector paths.',
  ),
  tex(
    label: 'LaTeX Source (TeX)',
    shortLabel: 'TeX',
    icon: Icons.code,
    ext: '.tex',
    description: 'pdfliteral LaTeX code.',
  );

  const ExportFormat({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.ext,
    required this.description,
  });

  final String label;
  final String shortLabel;
  final IconData icon;
  final String ext;
  final String description;
}

/// Opens the master manuscript Export Dialog.
Future<ExportResult?> showExportDialog(
  BuildContext context, {
  ExportFormat initialFormat = ExportFormat.pdf,
}) {
  final configCubit = context.read<ConfigCubit>();
  return showDialog<ExportResult>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => BlocProvider.value(
      value: configCubit,
      child: ExportDialog(initialFormat: initialFormat),
    ),
  );
}

/// A spacious desktop modal dialog providing a professional, full-featured export studio.
///
/// Refactored with strict constraints and scrollable sections to prevent vertical
/// and horizontal pixel overflows.
class ExportDialog extends StatefulWidget {
  const ExportDialog({
    super.key,
    this.initialFormat = ExportFormat.pdf,
  });

  final ExportFormat initialFormat;

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late ExportFormat _selectedFormat;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  int _pageCount = 1;
  core.SvgLayeringMode _svgMode = core.SvgLayeringMode.flatByCategory;
  bool _isCustomName = false;
  String _outputDir = ExportDirectoryService.getDefaultDirectory();

  bool _isExporting = false;
  ExportResult? _lastResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
    final config = context.read<ConfigCubit>().state;
    _nameController.text = ExportService.getDefaultFileName(config);
    _pageController.text = '$_pageCount';
    _loadOutputDir();
  }

  Future<void> _loadOutputDir() async {
    final dir = await ExportDirectoryService.getExportDirectory();
    if (mounted) {
      setState(() => _outputDir = dir);
    }
  }

  Future<void> _changeOutputDir() async {
    final chosen = await ExportDirectoryService.pickDirectory();
    if (chosen != null && mounted) {
      setState(() => _outputDir = chosen);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updatePageCount(int count) {
    final clamped = count.clamp(1, 100);
    setState(() {
      _pageCount = clamped;
      _pageController.text = '$clamped';
    });
  }

  void _resetToDefaultName() {
    final config = context.read<ConfigCubit>().state;
    setState(() {
      _isCustomName = false;
      _nameController.text = ExportService.getDefaultFileName(config);
    });
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _lastResult = null;
      _errorMessage = null;
    });

    final configCubit = context.read<ConfigCubit>();
    final config = configCubit.state;
    final layout = configCubit.layout;
    final customName = _nameController.text.trim();

    try {
      final ExportResult result;
      switch (_selectedFormat) {
        case ExportFormat.pdf:
          result = await ExportService.exportPdf(
            config,
            layout,
            fileName: customName,
            pageCount: _pageCount,
            outputDir: _outputDir,
          );
        case ExportFormat.svg:
          result = await ExportService.exportSvg(
            config,
            layout,
            fileName: customName,
            outputDir: _outputDir,
            layeringMode: _svgMode,
          );
        case ExportFormat.tex:
          result = await ExportService.exportTex(
            config,
            layout,
            fileName: customName,
            pageCount: _pageCount,
            outputDir: _outputDir,
          );
      }

      if (mounted) {
        setState(() {
          _isExporting = false;
          _lastResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _errorMessage = 'Export failed: $e';
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File path copied to clipboard!'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.4), width: 1),
      ),
      child: Container(
        width: 580,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Fixed Header Bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.ios_share,
                      color: cs.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Manuscript',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure file format, page count, and layer options.',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(_lastResult),
                    icon: Icon(Icons.close,
                        size: 20, color: cs.onSurface.withValues(alpha: 0.7)),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

            // --- Scrollable Body ---
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Section 1: Output Filename ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Output Filename',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (_isCustomName)
                          InkWell(
                            onTap: _resetToDefaultName,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Text(
                                'Reset to default',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: cs.outline.withValues(alpha: 0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note,
                              size: 18,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Manuscript filename...',
                              ),
                              onChanged: (val) {
                                if (!_isCustomName && val.trim().isNotEmpty) {
                                  setState(() => _isCustomName = true);
                                }
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedFormat.ext,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // --- Section 2: Format Selection Cards ---
                    Text(
                      'Format Selection',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ExportFormat.values.map((fmt) {
                        final isSelected = _selectedFormat == fmt;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: fmt != ExportFormat.tex ? 8.0 : 0.0),
                            child: InkWell(
                              onTap: () => setState(() => _selectedFormat = fmt),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primary.withValues(alpha: 0.12)
                                      : cs.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? cs.primary
                                        : cs.outline.withValues(alpha: 0.25),
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          fmt.icon,
                                          size: 15,
                                          color: isSelected
                                              ? cs.primary
                                              : cs.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            fmt.shortLabel,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? cs.primary
                                                  : cs.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      fmt.description,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onSurfaceVariant
                                            .withValues(alpha: 0.85),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // --- Section 3: Format Configuration ---
                    if (_selectedFormat == ExportFormat.pdf ||
                        _selectedFormat == ExportFormat.tex) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              cs.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: cs.outline.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.filter_none_outlined,
                                        size: 16, color: cs.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Number of Pages',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ],
                                ),

                                // Direct-Input Page Number Field + Steppers
                                Row(
                                  children: [
                                    _StepButton(
                                      icon: Icons.remove,
                                      onPressed: _pageCount > 1
                                          ? () =>
                                              _updatePageCount(_pageCount - 1)
                                          : null,
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 48,
                                      height: 32,
                                      child: TextField(
                                        controller: _pageController,
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
                                              const EdgeInsets.symmetric(
                                                  vertical: 6),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: BorderSide(
                                              color: cs.outline
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: BorderSide(
                                              color: cs.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          final parsed = int.tryParse(val);
                                          if (parsed != null) {
                                            _pageCount = parsed.clamp(1, 100);
                                          }
                                        },
                                        onSubmitted: (val) {
                                          final parsed = int.tryParse(val) ?? 1;
                                          _updatePageCount(parsed);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    _StepButton(
                                      icon: Icons.add,
                                      onPressed: _pageCount < 100
                                          ? () =>
                                              _updatePageCount(_pageCount + 1)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Quick Page Count Preset Chips (Wrap prevents horizontal overflow)
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Presets: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                ...[1, 5, 10, 20, 50, 100].map((count) {
                                  final isSelected = _pageCount == count;
                                  return InkWell(
                                    onTap: () => _updatePageCount(count),
                                    borderRadius: BorderRadius.circular(5),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cs.primary
                                            : cs.surface,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: isSelected
                                              ? cs.primary
                                              : cs.outline
                                                  .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        '$count pgs',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? cs.onPrimary
                                              : cs.onSurface,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_selectedFormat == ExportFormat.svg) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              cs.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: cs.outline.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.layers_outlined,
                                    size: 16, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'SVG Layer Organization',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // User-Friendly SVG Layering Cards
                            _SvgLayerCard(
                              title: 'Category Layers (Page-Wide)',
                              subtitle:
                                  'Groups elements by type (Staff Lines, Clefs, Barlines, Notes).\nBest for changing colors or line weights globally in Illustrator / Figma.',
                              icon: Icons.layers,
                              isSelected: _svgMode ==
                                  core.SvgLayeringMode.flatByCategory,
                              onTap: () => setState(() => _svgMode =
                                  core.SvgLayeringMode.flatByCategory),
                            ),
                            const SizedBox(height: 6),

                            _SvgLayerCard(
                              title: 'System & Staff Layers (Hierarchical)',
                              subtitle:
                                  'Groups elements by System (System 1, System 2...).\nBest for selecting, moving, or re-ordering whole staff systems with one click.',
                              icon: Icons.account_tree_outlined,
                              isSelected: _svgMode ==
                                  core.SvgLayeringMode.hierarchicalBySystem,
                              onTap: () => setState(() => _svgMode =
                                  core.SvgLayeringMode.hierarchicalBySystem),
                            ),
                            const SizedBox(height: 6),

                            _SvgLayerCard(
                              title: 'Minimal (Raw Vector Paths)',
                              subtitle:
                                  'Clean, un-grouped vector paths without layer tags.\nBest for embedding directly into websites or mobile applications.',
                              icon: Icons.code,
                              isSelected: _svgMode == core.SvgLayeringMode.none,
                              onTap: () => setState(
                                  () => _svgMode = core.SvgLayeringMode.none),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // --- Destination Path Indicator ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: cs.outline.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ExportDirectoryService.isWeb
                                ? Icons.download
                                : Icons.folder_open,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ExportDirectoryService.isWeb
                                      ? 'Browser Downloads'
                                      : _outputDir,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: ExportDirectoryService.isWeb
                                        ? null
                                        : 'monospace',
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'File: ${_nameController.text.trim()}${_selectedFormat.ext}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (!ExportDirectoryService.isWeb) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _changeOutputDir,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: cs.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.drive_file_move_outlined,
                                        size: 13, color: cs.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Change...',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // --- Result Banner ---
                    if (_lastResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saved ${_lastResult!.fileName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Size: ${_lastResult!.formattedSize} • Time: ${_lastResult!.elapsedMs}ms',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  _copyToClipboard(_lastResult!.filePath),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.copy,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Copy Path',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

            // --- Fixed Footer Action Bar ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isExporting
                        ? null
                        : () => Navigator.of(context).pop(_lastResult),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      side: BorderSide(
                          color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    child: Text(_lastResult != null ? 'Close' : 'Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      backgroundColor: cs.primary,
                    ),
                    icon: _isExporting
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Icon(_selectedFormat.icon, size: 16),
                    label: Text(
                      _isExporting
                          ? 'Exporting...'
                          : 'Export ${_selectedFormat.shortLabel}${_selectedFormat != ExportFormat.svg && _pageCount > 1 ? " ($_pageCount Pages)" : ""}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SvgLayerCard extends StatelessWidget {
  const _SvgLayerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon,
                          size: 13,
                          color: isSelected ? cs.primary : cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      style: IconButton.styleFrom(
        backgroundColor: cs.surface,
        disabledBackgroundColor:
            cs.surfaceContainerHighest.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}
