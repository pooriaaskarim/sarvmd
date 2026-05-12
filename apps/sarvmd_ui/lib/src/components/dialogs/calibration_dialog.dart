import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../view_notifier.dart';

/// Opens the display calibration dialog.
Future<void> showCalibrationDialog(
  BuildContext context,
  ViewNotifier viewNotifier,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => CalibrationDialog(viewNotifier: viewNotifier),
  );
}

/// A dialog that lets the user calibrate their display so that "Actual Size"
/// renders manuscript paper at exactly its real-world physical dimensions.
///
/// The user holds a physical ruler to their screen and nudges the reference
/// bar until it spans exactly 25 mm, then clicks Apply to commit.
class CalibrationDialog extends StatefulWidget {
  const CalibrationDialog({super.key, required this.viewNotifier});

  final ViewNotifier viewNotifier;

  @override
  State<CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<CalibrationDialog> {
  late double _localFactor;

  // Canvas renders at 96/25.4 logical px per mm.
  static const double _referenceMm = 50.0;
  static const double _baseLpMm = 96.0 / 25.4;
  static const double _step = 0.005; // Finer steps for 50mm

  double get _barWidth => _referenceMm * _baseLpMm * _localFactor;

  String _getPhysicalPpiSrting(double dpr) =>
      (_localFactor * 96 * dpr).toStringAsFixed(2);

  bool get _isDefault => (_localFactor - 1.0).abs() < 0.001;

  @override
  void initState() {
    super.initState();
    _localFactor = widget.viewNotifier.calibrationFactor;
  }

  void _nudge(double delta) {
    setState(() {
      _localFactor = (_localFactor + delta).clamp(0.3, 5.0);
    });
  }

  void _apply() {
    widget.viewNotifier.updateCalibrationFactor(_localFactor);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.straighten_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Display Calibration',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Calibrate "Actual Size" to your physical display.',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numbered steps
                  _StepText(
                    number: '1',
                    text: 'Hold a physical ruler flat against your screen.',
                    colorScheme: cs,
                  ),
                  const SizedBox(height: 6),
                  _StepText(
                    number: '2',
                    text: 'Use the slider or buttons to nudge the bar until it '
                        'spans exactly 50 mm on your ruler.',
                    colorScheme: cs,
                  ),
                  const SizedBox(height: 6),
                  _StepText(
                    number: '3',
                    text: 'Click Apply. Done.',
                    colorScheme: cs,
                  ),

                  const SizedBox(height: 24),

                  // Ruler bar with Drag & Scroll interaction
                  _RulerArea(
                    barWidth: _barWidth,
                    colorScheme: cs,
                    onAdjust: (delta) =>
                        _nudge(delta / (_referenceMm * _baseLpMm)),
                    onScroll: (delta) => _nudge(-delta * 0.002), // Fine scroll
                  ),

                  const SizedBox(height: 16),

                  // Coarse Adjustment Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: _localFactor,
                      min: 0.5,
                      max: 3.5,
                      onChanged: (v) => setState(() => _localFactor = v),
                      activeColor: cs.primary,
                      inactiveColor: cs.primary.withValues(alpha: 0.1),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Nudge controls + PPI readout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NudgeButton(
                        icon: Icons.remove,
                        onTap: () => _nudge(-_step),
                        onLongPress: () => _nudge(-_step * 10),
                        colorScheme: cs,
                      ),
                      const SizedBox(width: 24),
                      Builder(builder: (context) {
                        final dpr = MediaQuery.of(context).devicePixelRatio;
                        final physicalPpi = _getPhysicalPpiSrting(dpr);

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Column(
                            key: ValueKey(physicalPpi),
                            children: [
                              Text(
                                '$physicalPpi PPI',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: _isDefault
                                      ? cs.onSurfaceVariant
                                      : cs.primary,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              Text(
                                _isDefault
                                    ? 'baseline (96 DPI)'
                                    : 'physical density',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(width: 24),
                      _NudgeButton(
                        icon: Icons.add,
                        onTap: () => _nudge(_step),
                        onLongPress: () => _nudge(_step * 10),
                        colorScheme: cs,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Reset
                  AnimatedOpacity(
                    opacity: _isDefault ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton.icon(
                      icon: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Reset'),
                      onPressed: _isDefault
                          ? null
                          : () => setState(() => _localFactor = 1.0),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurfaceVariant,
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Cancel
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.onSurfaceVariant,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  // Apply
                  FilledButton(
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Apply'),
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

/// The ruler bar area — uses TweenAnimationBuilder so the animation state
/// survives setState() calls without losing interpolation progress.
/// Now supports dragging to resize and mouse wheel to nudge.
class _RulerArea extends StatelessWidget {
  const _RulerArea({
    required this.barWidth,
    required this.colorScheme,
    required this.onAdjust,
    required this.onScroll,
  });

  final double barWidth;
  final ColorScheme colorScheme;
  final ValueChanged<double> onAdjust;
  final ValueChanged<double> onScroll;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onAdjust(details.delta.dx),
        child: Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              onScroll(pointerSignal.scrollDelta.dy);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: barWidth, end: barWidth),
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              builder: (context, width, _) {
                return ClipRect(
                  child: SizedBox(
                    height: 36,
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: SizedBox(
                        width: width,
                        height: 36,
                        child: CustomPaint(
                          painter: _RulerBarPainter(colorScheme: colorScheme),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerBarPainter extends CustomPainter {
  _RulerBarPainter({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final primary = colorScheme.primary;

    // Background fill - exactly matching the logical width
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(6),
      ),
      Paint()..color = primary.withValues(alpha: 0.10),
    );

    final tickPaint = Paint()
      ..color = primary.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 10 segments of 5 mm each = 50 mm total
    const segmentCount = 10;
    for (var i = 0; i <= segmentCount; i++) {
      final x = size.width * i / segmentCount;
      final isEnd = i == 0 || i == segmentCount;

      if (isEnd) continue; // Caps handled separately for pixel perfection

      final tickH = (i % 2 == 0) ? size.height * 0.6 : size.height * 0.35;
      final y0 = (size.height - tickH) / 2;
      canvas.drawLine(Offset(x, y0), Offset(x, y0 + tickH), tickPaint);
    }

    // Pixel-perfect end caps:
    // We draw them INSIDE the size.width boundaries so that the outer visual
    // edges are exactly 0 and size.width.
    final capWidth = 2.0;
    final capPaint = Paint()..color = primary;

    // Left cap
    canvas.drawRect(Rect.fromLTWH(0, 0, capWidth, size.height), capPaint);
    // Right cap
    canvas.drawRect(
        Rect.fromLTWH(size.width - capWidth, 0, capWidth, size.height),
        capPaint);

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: '50 mm',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: primary,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_RulerBarPainter old) => old.colorScheme != colorScheme;
}

class _StepText extends StatelessWidget {
  const _StepText({
    required this.number,
    required this.text,
    required this.colorScheme,
  });

  final String number;
  final String text;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({
    required this.icon,
    required this.onTap,
    required this.onLongPress,
    required this.colorScheme,
  });

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
