// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/services/export_directory_service.dart';
import '../../../logic/services/export_service.dart';
import 'adaptive_dialog_helper.dart';
import 'export/export_format.dart';
import 'export/export_format_selector.dart';
import 'export/export_page_count_section.dart';
import 'export/export_svg_options_section.dart';

export 'export/export_format.dart';

/// Opens the master manuscript Export Dialog.
Future<ExportResult?> showExportDialog(
  BuildContext context, {
  ExportFormat initialFormat = ExportFormat.pdf,
}) {
  final documentCubit = context.read<DocumentCubit>();
  return showSarvAdaptiveModal<ExportResult>(
    context: context,
    maxWidth: 580.0,
    builder: (ctx, isMobile) => BlocProvider.value(
      value: documentCubit,
      child: ExportDialog(initialFormat: initialFormat),
    ),
  );
}

/// A spacious desktop modal dialog providing a professional, full-featured export studio.
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
    final docCubit = context.read<DocumentCubit>();
    final config = docCubit.state.config;
    final defaultName = ExportService.getDefaultFileName(config);
    _nameController.text = defaultName;
    _pageController.text = '1';
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
    final docCubit = context.read<DocumentCubit>();
    final config = docCubit.state.config;
    final score = docCubit.state.score;
    if (score.title.isNotEmpty) {
      docCubit.execute(core.SetTitleCommand('', score.title));
    }
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

    final documentCubit = context.read<DocumentCubit>();
    final config = documentCubit.state.config;
    final layout = documentCubit.layout;
    final rawName = _nameController.text.trim();
    final score = documentCubit.state.score;
    final effectiveExportName =
        core.ScoreCompiler.sanitizeFileName(rawName, config);

    if (rawName != score.title) {
      documentCubit.execute(core.SetTitleCommand(rawName, score.title));
    }

    try {
      final ExportResult result;
      switch (_selectedFormat) {
        case ExportFormat.pdf:
          result = await ExportService.exportPdf(
            config,
            layout,
            fileName: effectiveExportName,
            pageCount: _pageCount,
            outputDir: _outputDir,
          );
        case ExportFormat.svg:
          result = await ExportService.exportSvg(
            config,
            layout,
            fileName: effectiveExportName,
            outputDir: _outputDir,
            layeringMode: _svgMode,
          );
        case ExportFormat.tex:
          result = await ExportService.exportTex(
            config,
            layout,
            fileName: effectiveExportName,
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
      SnackBar(
        content: Text(AppLocalizations.of(context)!.pathCopiedToast),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 600;
    final l10n = AppLocalizations.of(context)!;
    final maxDialogHeight =
        isMobile ? media.size.height * 0.90 : media.size.height * 0.85;

    final content = Container(
      constraints: BoxConstraints(maxWidth: 580, maxHeight: maxDialogHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Fixed Header Bar ─────────────────────────────────
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
                        l10n.exportManuscriptTitle,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                  letterSpacing: -0.3,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.exportManuscriptSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  tooltip: l10n.close,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

          // ── Scrollable Body ─────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Output Filename
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.outputFilenameLabel,
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
                              l10n.resetToDefault,
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
                      border:
                          Border.all(color: cs.outline.withValues(alpha: 0.3)),
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
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: core.ScoreCompiler.getDefaultFileName(
                                context.read<DocumentCubit>().state.config,
                              ),
                            ),
                            onChanged: (val) {
                              final isCustom = val.trim().isNotEmpty;
                              if (_isCustomName != isCustom) {
                                setState(() => _isCustomName = isCustom);
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

                  // Section 2: Format Selection Cards
                  ExportFormatSelector(
                    selectedFormat: _selectedFormat,
                    onFormatSelected: (fmt) =>
                        setState(() => _selectedFormat = fmt),
                  ),
                  const SizedBox(height: 18),

                  // Section 3: Format Specific Configuration
                  if (_selectedFormat == ExportFormat.pdf ||
                      _selectedFormat == ExportFormat.tex)
                    ExportPageCountSection(
                      pageCount: _pageCount,
                      pageController: _pageController,
                      onPageCountChanged: _updatePageCount,
                    )
                  else if (_selectedFormat == ExportFormat.svg)
                    ExportSvgOptionsSection(
                      svgMode: _svgMode,
                      onModeChanged: (mode) =>
                          setState(() => _svgMode = mode),
                    ),
                  const SizedBox(height: 18),

                  // Section 4: Export Output Location
                  Text(
                    'Destination Folder',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: cs.outline.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder_outlined,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _outputDir,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontFamily: 'monospace',
                              color: cs.onSurface.withValues(alpha: 0.85),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _changeOutputDir,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text(
                              l10n.changeOutputDir,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section 5: Results Feedback / Errors
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: cs.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 18, color: cs.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_lastResult != null && _errorMessage == null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: cs.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.savedBannerTitle(
                                      _lastResult!.filePath.split('/').last),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 14),
                                visualDensity: VisualDensity.compact,
                                tooltip: l10n.copyPath,
                                onPressed: () =>
                                    _copyToClipboard(_lastResult!.filePath),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _lastResult!.filePath,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color:
                                  cs.onPrimaryContainer.withValues(alpha: 0.9),
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

          // ── Fixed Footer Actions ──────────────────────────────
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_lastResult),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Icon(Icons.download, size: 16),
                    label: Text(
                      _isExporting
                          ? l10n.exportingState
                          : l10n.exportButtonLabel(_selectedFormat.shortLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return content;
  }
}
