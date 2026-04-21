import 'package:flutter/material.dart';
import 'package:sarv_core/sarv_core.dart' as core;
import 'config_notifier.dart';
import 'preview_canvas.dart';
import 'export_service.dart';
import 'ruler_box.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ConfigNotifier _notifier = ConfigNotifier();
  final TransformationController _transformationController = TransformationController();
  double _zoom = 0.5;

  @override
  void initState() {
    super.initState();
    // Set initial zoom
    _transformationController.value = Matrix4.diagonal3Values(_zoom, _zoom, 1.0);
  }

  @override
  void dispose() {
    _notifier.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final layout = _notifier.layout;
        return Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          body: Row(
            children: [
              // Sidebar
              Container(
                width: 320,
                color: const Color(0xFF252525),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          const SizedBox(height: 48),
                          const _Header(),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Page Size'),
                          _SegmentedSetting<core.PageSize>(
                            value: _notifier.config.pageSize,
                            options: core.PageSize.values,
                            onChanged: (v) => _notifier.updatePageSize(v),
                          ),
                          const SizedBox(height: 24),
                          const _SectionHeader(title: 'Layout Type'),
                          _SegmentedSetting<core.LayoutType>(
                            value: _notifier.config.layoutType,
                            options: core.LayoutType.values,
                            onChanged: (v) => _notifier.updateLayoutType(v),
                          ),
                          const Divider(color: Colors.white24, height: 32),
                          const _SectionHeader(title: 'Spacing (mm)'),
                          _SliderSetting(
                            label: 'Line Gap',
                            value: _notifier.config.staffConfig.lineGapMm,
                            min: 1.0,
                            max: 3.0,
                            onChanged: (v) => _notifier.updateLineGap(v),
                          ),
                          _SliderSetting(
                            label: 'System Gap',
                            value: _notifier.config.staffConfig.systemGapMm,
                            min: 5.0,
                            max: 30.0,
                            onChanged: (v) => _notifier.updateSystemGap(v),
                          ),
                          if (layout.config.layoutType == core.LayoutType.piano)
                            _SliderSetting(
                              label: 'Inter-staff Gap',
                              value: _notifier.config.staffConfig.interStaffGapMm,
                              min: 5.0,
                              max: 20.0,
                              onChanged: (v) => _notifier.updateInterStaffGap(v),
                            ),
                          const Divider(color: Colors.white24, height: 32),
                          const _SectionHeader(title: 'View'),
                          ListenableBuilder(
                            listenable: _transformationController,
                            builder: (context, _) {
                              final currentZoom = _transformationController.value.getMaxScaleOnAxis();
                              return _SliderSetting(
                                label: 'Preview Zoom',
                                value: currentZoom.clamp(0.1, 4.0),
                                min: 0.1,
                                max: 4.0,
                                onChanged: (v) {
                                  final t = _transformationController.value.getTranslation();
                                  _transformationController.value = Matrix4.translationValues(t.x, t.y, 0.0)
                                    ..multiply(Matrix4.diagonal3Values(v, v, 1.0));
                                },
                              );
                            },
                          ),
                          const Divider(color: Colors.white24, height: 32),
                          const _SectionHeader(title: 'Export'),
                          const SizedBox(height: 8),
                          _ExportButton(
                            label: 'Generate LaTeX',
                            icon: Icons.code,
                            onPressed: () => _handleExport(context, isPdf: false),
                          ),
                          const SizedBox(height: 12),
                          _ExportButton(
                            label: 'Generate PDF',
                            icon: Icons.picture_as_pdf,
                            onPressed: () => _handleExport(context, isPdf: true),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        '${layout.systemCount} Systems',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
              // Preview Area
              Expanded(
                child: Container(
                  color: const Color(0xFF121212),
                  child: RulerBox(
                    transformationController: _transformationController,
                    paperSizeMm: Size(
                      layout.config.pageSize.width,
                      layout.config.pageSize.height,
                    ),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      boundaryMargin: const EdgeInsets.all(1000),
                      minScale: 0.1,
                      maxScale: 4.0,
                      constrained: false,
                      child: PreviewCanvas(
                        layout: layout,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleExport(BuildContext context, {required bool isPdf}) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Generating ${isPdf ? 'PDF' : 'LaTeX'}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final path = isPdf 
          ? await ExportService.exportPdf(_notifier.config, _notifier.layout)
          : await ExportService.exportTex(_notifier.config, _notifier.layout);
      
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Exported to: $path'),
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SARV',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        Text(
          'MANUSCRIPT DESIGNER',
          style: TextStyle(
            color: const Color(0xFF64B5F6).withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64B5F6),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: const Color(0xFF64B5F6),
          inactiveColor: Colors.white10,
        ),
      ],
    );
  }
}

class _SegmentedSetting<T extends Enum> extends StatelessWidget {
  const _SegmentedSetting({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt) ,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF64B5F6).withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: const Color(0xFF64B5F6), width: 1) : null,
                ),
                child: Center(
                  child: Text(
                    opt.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF64B5F6) : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF64B5F6).withValues(alpha: 0.1),
        foregroundColor: const Color(0xFF64B5F6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF64B5F6), width: 1),
        ),
        elevation: 0,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}
