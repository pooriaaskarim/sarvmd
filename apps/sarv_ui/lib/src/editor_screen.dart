import 'package:flutter/material.dart';
import 'package:sarv_core/sarv_core.dart' as core;
import 'config_notifier.dart';
import 'preview_canvas.dart';
import 'export_service.dart';
import 'ruler_box.dart';
import 'view_notifier.dart';
import 'view_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.viewNotifier});
  
  final ViewNotifier viewNotifier;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ConfigNotifier _notifier = ConfigNotifier();
  final TransformationController _transformationController = TransformationController();
  double _zoom = 0.5;
  bool _hasCentered = false;

  @override
  void initState() {
    super.initState();
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Row(
            children: [
              // Sidebar
              Container(
                width: 320,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          const SizedBox(height: 48),
                          const _Header(),
                          const SizedBox(height: 32),
                          const _SectionHeader(title: 'Document'),
                          const SizedBox(height: 8),
                          _DropdownSetting<core.PageSize>(
                            value: _notifier.config.pageSize,
                            options: core.PageSize.values,
                            onChanged: (v) => _notifier.updatePageSize(v),
                          ),
                          const SizedBox(height: 16),
                          _SegmentedSetting<core.LayoutType>(
                            value: _notifier.config.layoutType,
                            options: core.LayoutType.values,
                            onChanged: (v) => _notifier.updateLayoutType(v),
                          ),
                          Divider(color: Theme.of(context).colorScheme.outline, height: 32),
                          const _SectionHeader(title: 'Margins (mm)'),
                          _SliderSetting(
                            label: 'Vertical',
                            value: _notifier.config.margins.top,
                            min: 5.0,
                            max: 40.0,
                            onChanged: (v) => _notifier.updateVerticalMargins(v),
                          ),
                          _SliderSetting(
                            label: 'Horizontal',
                            value: _notifier.config.margins.left,
                            min: 5.0,
                            max: 40.0,
                            onChanged: (v) => _notifier.updateHorizontalMargins(v),
                          ),
                          Divider(color: Theme.of(context).colorScheme.outline, height: 32),
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
                          Divider(color: Theme.of(context).colorScheme.outline, height: 32),
                          const _SectionHeader(title: 'Clefs & Symbols'),
                          _ClefConfigWidget(
                            label: layout.config.layoutType == core.LayoutType.piano ? 'Upper Staff' : 'Staff Clef',
                            value: _notifier.config.primaryClef,
                            onChanged: (v) => _notifier.updatePrimaryClef(v),
                          ),
                          if (layout.config.layoutType == core.LayoutType.piano) ...[
                            const SizedBox(height: 16),
                            _ClefConfigWidget(
                              label: 'Lower Staff',
                              value: _notifier.config.secondaryClef,
                              onChanged: (v) => _notifier.updateSecondaryClef(v),
                            ),
                          ],
                          Divider(color: Theme.of(context).colorScheme.outline, height: 32),
                          const _SectionHeader(title: 'Actions & Export'),
                          const SizedBox(height: 8),
                          _ExportButton(
                            label: 'Reset to Defaults',
                            icon: Icons.restore,
                            onPressed: () => _notifier.resetToDefaults(),
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
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
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              // Preview Area
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (!_hasCentered) {
                        _hasCentered = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final double lpmm = 96 / 25.4;
                          final paperWidth = _notifier.layout.config.pageSize.width * lpmm;
                          final paperHeight = _notifier.layout.config.pageSize.height * lpmm;

                          final dx = (constraints.maxWidth - paperWidth * _zoom) / 2;
                          final dy = (constraints.maxHeight - paperHeight * _zoom) / 2;

                          _transformationController.value = Matrix4.translationValues(dx, dy, 0.0)
                            ..multiply(Matrix4.diagonal3Values(_zoom, _zoom, 1.0));
                        });
                      }
                      
                      return RulerBox(
                        transformationController: _transformationController,
                        paperSizeMm: Size(
                          layout.config.pageSize.width,
                          layout.config.pageSize.height,
                        ),
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          boundaryMargin: const EdgeInsets.all(100000),
                          minScale: 0.1,
                          maxScale: 4.0,
                          constrained: false,
                          child: PreviewCanvas(
                            layout: layout,
                            viewNotifier: widget.viewNotifier,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // View Panel (Right)
              ViewPanel(
                viewNotifier: widget.viewNotifier,
                transformationController: _transformationController,
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
        Text(
          'SARV',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        Text(
          'MANUSCRIPT DESIGNER',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
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
        style: TextStyle(color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SliderSetting extends StatefulWidget {
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
  State<_SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<_SliderSetting> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(_SliderSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String? text) {
    if (text == null) return;
    final parsed = double.tryParse(text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toStringAsFixed(1);
    } else {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onSubmitted: _submit,
                onTapOutside: (_) {
                  _submit(_controller.text);
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),
          ],
        ),
        Slider(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          onChanged: widget.onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                  border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1) : null,
                ),
                child: Center(
                  child: Text(
                    opt.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
        foregroundColor: color ?? Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color ?? Theme.of(context).colorScheme.primary, width: 1),
        ),
        elevation: 0,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

class _DropdownSetting<T extends Enum> extends StatelessWidget {
  const _DropdownSetting({
    super.key,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
          isExpanded: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: options.map((opt) {
            return DropdownMenuItem<T>(
              value: opt,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(opt.name.toUpperCase()),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}



class _ClefConfigWidget extends StatelessWidget {
  const _ClefConfigWidget({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final core.ClefConfig? value;
  final ValueChanged<core.ClefConfig?> onChanged;

  bool _isPreset(core.ClefSymbol sym, int line) {
    return value?.symbol == sym && value?.anchorLine == line;
  }

  Widget _buildPresetChip(BuildContext context, String title, core.ClefSymbol sym, int line) {
    final selected = _isPreset(sym, line);
    return FilterChip(
      label: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onChanged(core.ClefConfig(symbol: sym, anchorLine: line)),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
          Switch(value: false, onChanged: (on) => onChanged(const core.ClefConfig(symbol: core.ClefSymbol.g, anchorLine: 2))),
        ],
      );
    }
    
    final selectedSym = value!.symbol;
    
    Widget buildVerticalTab(core.ClefSymbol sym, String glyph, String tabLabel) {
      final isSelected = sym == selectedSym;
      final colorScheme = Theme.of(context).colorScheme;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isSelected) return;
            int defaultLine = 3;
            if (sym == core.ClefSymbol.g) defaultLine = 2; // Treble
            if (sym == core.ClefSymbol.f) defaultLine = 4; // Bass
            onChanged(core.ClefConfig(symbol: sym, anchorLine: defaultLine));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  glyph, 
                  style: TextStyle(
                    fontFamily: 'NotoMusic', 
                    fontSize: 34, 
                    height: 1.0, 
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)),
            Switch(value: true, onChanged: (on) => onChanged(null)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Tabs Column - Soft Pills
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildVerticalTab(core.ClefSymbol.g, '\u{1D11E}', 'G'),
                  const SizedBox(height: 8),
                  buildVerticalTab(core.ClefSymbol.c, '\u{1D121}', 'C'),
                  const SizedBox(height: 8),
                  buildVerticalTab(core.ClefSymbol.f, '\u{1D122}', 'F'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Content Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Presets specific to this symbol
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (selectedSym == core.ClefSymbol.g) ...[
                        _buildPresetChip(context, 'Treble', core.ClefSymbol.g, 2),
                      ],
                      if (selectedSym == core.ClefSymbol.c) ...[
                        _buildPresetChip(context, 'Alto', core.ClefSymbol.c, 3),
                        _buildPresetChip(context, 'Tenor', core.ClefSymbol.c, 4),
                        _buildPresetChip(context, 'Soprano', core.ClefSymbol.c, 1),
                        _buildPresetChip(context, 'Mezzo', core.ClefSymbol.c, 2),
                      ],
                      if (selectedSym == core.ClefSymbol.f) ...[
                        _buildPresetChip(context, 'Bass', core.ClefSymbol.f, 4),
                        _buildPresetChip(context, 'Baritone', core.ClefSymbol.f, 3),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Interactive Mini Staff Canvas
                  LayoutBuilder(builder: (context, constraints) {
                    final gap = constraints.maxWidth / 10;
                    return Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTapUp: (details) {
                              final tappedY = details.localPosition.dy;
                              final staffTop = gap * 2.5; 
                              final i = ((tappedY - staffTop) / gap).round();
                              if (i >= 0 && i <= 4) {
                                onChanged(core.ClefConfig(symbol: value!.symbol, anchorLine: 5 - i));
                              }
                            },
                            child: CustomPaint(
                              size: Size(constraints.maxWidth, gap * 8.5),
                              painter: _MiniStaffClefPainter(value!, gap, Theme.of(context).colorScheme),
                            ),
                          ),
                          // Elegant overlay label
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Line ${value!.anchorLine}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStaffClefPainter extends CustomPainter {
  const _MiniStaffClefPainter(this.clef, this.gap, this.scheme);
  final core.ClefConfig clef;
  final double gap;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final staffColor = scheme.onSurface;
    final highlightColor = scheme.primary;
    final staffTop = gap * 2.5;

    for (var i = 0; i < 5; i++) {
      final lineNum = 5 - i;
      final y = staffTop + i * gap;
      final isAnchor = lineNum == clef.anchorLine;
      canvas.drawLine(
        Offset(gap * 1.6, y),
        Offset(size.width - gap * 0.2, y),
        Paint()
          ..color = isAnchor ? highlightColor : staffColor.withValues(alpha: 0.4)
          ..strokeWidth = isAnchor ? gap * 0.12 : gap * 0.05
          ..strokeCap = StrokeCap.round,
      );
    }

    final double anchorSp = switch (clef.symbol) {
      core.ClefSymbol.g => 0.876,
      core.ClefSymbol.c => 2.0,
      core.ClefSymbol.f => 2.578,
    };
    final String glyph = switch (clef.symbol) {
      core.ClefSymbol.g => '\u{1D11E}',
      core.ClefSymbol.c => '\u{1D121}',
      core.ClefSymbol.f => '\u{1D122}',
    };

    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(fontFamily: 'NotoMusic', fontSize: gap * 4.0, color: staffColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final ascent = tp.computeLineMetrics().first.ascent;
    final anchorYPx = staffTop + (5 - clef.anchorLine) * gap;
    tp.paint(canvas, Offset(gap * 0.05, anchorYPx + anchorSp * gap - ascent));
  }

  @override
  bool shouldRepaint(_MiniStaffClefPainter old) =>
      old.clef != clef || old.gap != gap;
}
