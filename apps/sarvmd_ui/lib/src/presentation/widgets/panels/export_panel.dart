// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

import '../dialogs/export_dialog.dart';

/// A simplified, ultra-polished export bar pinned at the bottom of the View panel.
///
/// Features a high-contrast primary "Export" action and quick format triggers
/// that launch the dedicated, spacious [ExportDialog].
class ExportPanel extends StatelessWidget {
  const ExportPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Export Button opening the Master Export Studio Dialog
          SizedBox(
            width: double.infinity,
            height: 42,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => showExportDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary,
                        cs.primary.withValues(alpha: 0.88),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.ios_share_rounded,
                        size: 17,
                        color: cs.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Export',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: cs.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Format Triggers
          Row(
            children: [
              Expanded(
                child: _QuickFormatChip(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onTap: () => showExportDialog(
                    context,
                    initialFormat: ExportFormat.pdf,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickFormatChip(
                  label: 'SVG',
                  icon: Icons.image_outlined,
                  onTap: () => showExportDialog(
                    context,
                    initialFormat: ExportFormat.svg,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickFormatChip(
                  label: 'TeX',
                  icon: Icons.code_rounded,
                  onTap: () => showExportDialog(
                    context,
                    initialFormat: ExportFormat.tex,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickFormatChip extends StatefulWidget {
  const _QuickFormatChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_QuickFormatChip> createState() => _QuickFormatChipState();
}

class _QuickFormatChipState extends State<_QuickFormatChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered
              ? cs.primary.withValues(alpha: 0.08)
              : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isHovered
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.25),
            width: _isHovered ? 1.2 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 13,
                  color: _isHovered ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _isHovered ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
