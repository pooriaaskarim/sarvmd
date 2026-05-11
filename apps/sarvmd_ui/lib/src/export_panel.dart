import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'export_service.dart';
import 'config_notifier.dart';

/// A compact export footer pinned at the bottom of the right view panel.
///
/// Shows three export actions: TeX / PDF / SVG.
/// Handles its own loading state and success/failure feedback via snackbar.
class ExportPanel extends StatefulWidget {
  const ExportPanel({
    super.key,
    required this.configNotifier,
    required this.layoutGetter,
  });

  final ConfigNotifier configNotifier;

  /// Returns the current layout. Called at time of export.
  final core.PageLayout Function() layoutGetter;

  @override
  State<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends State<ExportPanel> {
  _ExportKind? _loading;
  String? _successMessage;

  Future<void> _export(_ExportKind kind) async {
    if (_loading != null || _successMessage != null) return;
    setState(() => _loading = kind);

    final config = widget.configNotifier.config;
    final layout = widget.layoutGetter();

    try {
      final String path;
      switch (kind) {
        case _ExportKind.tex:
          path = await ExportService.exportTex(config, layout);
        case _ExportKind.pdf:
          path = await ExportService.exportPdf(config, layout);
        case _ExportKind.svg:
          path = await ExportService.exportSvg(config, layout);
      }
      if (mounted) {
        setState(() {
          _loading = null;
          _successMessage = 'Saved: ${path.split('/').last}';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = null);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red.withValues(alpha: 0.85),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border:
            Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.4))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _successMessage != null
            ? Container(
                key: const ValueKey('success'),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                key: const ValueKey('buttons'),
                children: [
                  Expanded(
                    child: _ExportChip(
                      label: 'TeX',
                      icon: Icons.code,
                      loading: _loading == _ExportKind.tex,
                      onPressed: () => _export(_ExportKind.tex),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ExportChip(
                      label: 'PDF',
                      icon: Icons.picture_as_pdf,
                      primary: true,
                      loading: _loading == _ExportKind.pdf,
                      onPressed: () => _export(_ExportKind.pdf),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ExportChip(
                      label: 'SVG',
                      icon: Icons.image_outlined,
                      loading: _loading == _ExportKind.svg,
                      onPressed: () => _export(_ExportKind.svg),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

enum _ExportKind { tex, pdf, svg }

class _ExportChip extends StatelessWidget {
  const _ExportChip({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = primary ? cs.primary : cs.onSurfaceVariant;
    final bg = primary
        ? cs.primary.withValues(alpha: 0.1)
        : cs.onSurface.withValues(alpha: 0.05);
    final border = primary
        ? cs.primary.withValues(alpha: 0.4)
        : cs.outline.withValues(alpha: 0.3);

    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 12,
                          color: fg,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
