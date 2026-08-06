// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../logic/services/export_service.dart';

/// Shows the dedicated SVG export configuration dialog.
Future<String?> showSvgExportDialog(
  BuildContext context,
  core.PageConfig config,
  core.PageLayout layout,
) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => SvgExportDialog(config: config, layout: layout),
  );
}

/// A dedicated desktop modal dialog for configuring SVG vector export options.
///
/// Provides a high-contrast, polished UI for selecting SVG Layering Architecture
/// (Category Layers, System & Staff Layers, or Raw Vector Paths) before exporting.
class SvgExportDialog extends StatefulWidget {
  const SvgExportDialog({
    super.key,
    required this.config,
    required this.layout,
  });

  final core.PageConfig config;
  final core.PageLayout layout;

  @override
  State<SvgExportDialog> createState() => _SvgExportDialogState();
}

class _SvgExportDialogState extends State<SvgExportDialog> {
  core.SvgLayeringMode _selectedMode = core.SvgLayeringMode.flatByCategory;
  bool _isExporting = false;
  String? _errorMessage;

  Future<void> _handleExport() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final result = await ExportService.exportSvg(
        widget.config,
        widget.layout,
        layeringMode: _selectedMode,
      );
      if (mounted) {
        Navigator.of(context).pop(result.filePath);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.5), width: 1),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title & Icon Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: cs.onPrimaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Vector Graphic (SVG)',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select layer organization for Illustrator, Inkscape, Figma, and Affinity Designer.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close,
                      size: 20, color: cs.onSurface.withValues(alpha: 0.8)),
                  tooltip: 'Cancel',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section Label
            Text(
              'Layer Organization Strategy',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 12),

            // Layering Options Cards
            _LayerOptionCard(
              mode: core.SvgLayeringMode.flatByCategory,
              selectedMode: _selectedMode,
              title: 'Category Layers (Page-Wide)',
              subtitle:
                  'Organizes elements into top-level functional layers (Staff Lines, Clefs, Barlines, Notes). Ideal for changing colors, line weights, or hiding staff lines page-wide.',
              icon: Icons.layers_outlined,
              onSelect: (m) => setState(() => _selectedMode = m),
            ),
            const SizedBox(height: 10),

            _LayerOptionCard(
              mode: core.SvgLayeringMode.hierarchicalBySystem,
              selectedMode: _selectedMode,
              title: 'System & Staff Layers (Hierarchical)',
              subtitle:
                  'Groups elements by System & Staff first (System 1, System 2...). Essential if you want to select, move, re-order, or hide individual musical systems with one click.',
              icon: Icons.account_tree_outlined,
              onSelect: (m) => setState(() => _selectedMode = m),
            ),
            const SizedBox(height: 10),

            _LayerOptionCard(
              mode: core.SvgLayeringMode.none,
              selectedMode: _selectedMode,
              title: 'Raw Vector Paths (No Layers)',
              subtitle:
                  'Outputs clean, un-grouped vector paths without layer metadata. Best for embedding SVGs in websites, apps, or lightweight documents.',
              icon: Icons.border_all_outlined,
              onSelect: (m) => setState(() => _selectedMode = m),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
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
                          color: Colors.red,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Actions Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed:
                      _isExporting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    side: BorderSide(
                        color: cs.outline.withValues(alpha: 0.5)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download, size: 18),
                  label: Text(
                    _isExporting ? 'Exporting...' : 'Export SVG',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerOptionCard extends StatelessWidget {
  const _LayerOptionCard({
    required this.mode,
    required this.selectedMode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelect,
  });

  final core.SvgLayeringMode mode;
  final core.SvgLayeringMode selectedMode;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<core.SvgLayeringMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = mode == selectedMode;

    return InkWell(
      onTap: () => onSelect(mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Radio Indicator Badge
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.6),
                    width: isSelected ? 2.0 : 2.0,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Icon Badge Box
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.18)
                    : cs.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 14),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.85),
                      height: 1.35,
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
