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
/// Lets the user choose their preferred SVG Layering Architecture
/// (Flat by Category, Hierarchical by System, or Minimal) before exporting.
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
      final path = await ExportService.exportSvg(
        widget.config,
        widget.layout,
        layeringMode: _selectedMode,
      );
      if (mounted) {
        Navigator.of(context).pop(path);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title & Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.image_outlined,
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
                        'Export Vector Graphic (SVG)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Configure layer organization for vector editors',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Cancel',
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Select Layering Architecture',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // Layering Options Selection Cards
            _LayerOptionCard(
              mode: core.SvgLayeringMode.flatByCategory,
              selectedMode: _selectedMode,
              title: 'Flat (by Category)',
              subtitle:
                  'Page-wide layers for Staff Lines, Clefs, Barlines, and Notation. Ideal for page-wide color & line style editing.',
              icon: Icons.layers_outlined,
              onSelect: (m) => setState(() => _selectedMode = m),
            ),
            const SizedBox(height: 8),

            _LayerOptionCard(
              mode: core.SvgLayeringMode.hierarchicalBySystem,
              selectedMode: _selectedMode,
              title: 'Hierarchical (by System)',
              subtitle:
                  'Grouped by System & Staff (System 1, System 2...). Ideal for moving, hiding, or extracting individual score systems in Inkscape/Illustrator.',
              icon: Icons.account_tree_outlined,
              onSelect: (m) => setState(() => _selectedMode = m),
            ),
            const SizedBox(height: 8),

            _LayerOptionCard(
              mode: core.SvgLayeringMode.none,
              selectedMode: _selectedMode,
              title: 'Minimal (No Layers)',
              subtitle:
                  'Clean vector paths without Inkscape layer metadata wrappers. Ideal for web embedding or lightweight vector graphics.',
              icon: Icons.border_all_outlined,
              onSelect: (m) => setState(() => _selectedMode = m),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isExporting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isExporting ? null : _handleExport,
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
                  label: Text(_isExporting ? 'Exporting...' : 'Export SVG'),
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
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.4)
              : cs.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outline,
                  width: isSelected ? 5.5 : 2.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 20,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? cs.primary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }
}
