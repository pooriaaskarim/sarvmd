import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'view_notifier.dart';

class RulerBox extends StatefulWidget {
  const RulerBox({
    super.key,
    required this.child,
    required this.transformationController,
    required this.paperSizeMm,
    required this.viewNotifier,
    required this.cursorNotifier,
    this.rulerSize = 25.0,
  });

  final Widget child;
  final TransformationController transformationController;
  final Size paperSizeMm;
  final ViewNotifier viewNotifier;

  /// Dedicated high-frequency notifier for cursor position. Kept separate
  /// from ViewNotifier intentionally so that every mouse-move only repaints
  /// the rulers, NOT the whole widget tree.
  final ValueNotifier<Offset?> cursorNotifier;
  final double rulerSize;

  @override
  State<RulerBox> createState() => _RulerBoxState();
}

class _RulerBoxState extends State<RulerBox> {
  bool _centerOrigin = false;

  void _toggleOrigin() {
    setState(() {
      _centerOrigin = !_centerOrigin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Ruler
        SizedBox(
          height: widget.rulerSize,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _toggleOrigin,
                child: Container(
                  width: widget.rulerSize,
                  height: widget.rulerSize,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Center(
                    child: Text(
                      _centerOrigin ? 'mm\nCTR' : 'mm\nTOP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleOrigin,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.transformationController,
                      widget.cursorNotifier,
                      widget.viewNotifier,
                    ]),
                    builder: (context, _) {
                      final colorScheme = Theme.of(context).colorScheme;
                      return ClipRect(
                        child: CustomPaint(
                          painter: RulerPainter(
                            axis: Axis.horizontal,
                            matrix: widget.transformationController.value,
                            centerOrigin: _centerOrigin,
                            paperSizeMm: widget.paperSizeMm,
                            colorScheme: colorScheme,
                            cursorPos: widget.cursorNotifier.value,
                            showWings: widget.viewNotifier
                                .isGuideActive(GuideType.rulerWings),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Ruler
              SizedBox(
                width: widget.rulerSize,
                child: GestureDetector(
                  onTap: _toggleOrigin,
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.transformationController,
                      widget.cursorNotifier,
                      widget.viewNotifier,
                    ]),
                    builder: (context, _) {
                      final colorScheme = Theme.of(context).colorScheme;
                      return ClipRect(
                        child: CustomPaint(
                          painter: RulerPainter(
                            axis: Axis.vertical,
                            matrix: widget.transformationController.value,
                            centerOrigin: _centerOrigin,
                            paperSizeMm: widget.paperSizeMm,
                            colorScheme: colorScheme,
                            cursorPos: widget.cursorNotifier.value,
                            showWings: widget.viewNotifier
                                .isGuideActive(GuideType.rulerWings),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ],
    );
  }
}

class RulerPainter extends CustomPainter {
  RulerPainter({
    required this.axis,
    required this.matrix,
    required this.centerOrigin,
    required this.paperSizeMm,
    required this.colorScheme,
    required this.cursorPos,
    required this.showWings,
  });

  final Axis axis;
  final Matrix4 matrix;
  final bool centerOrigin;
  final Size paperSizeMm;
  final ColorScheme colorScheme;
  final Offset? cursorPos;
  final bool showWings;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 9,
    );

    // Standard pixels per mm
    const double lpmm = 96 / 25.4;

    // Extract scale and translation from matrix.
    // NOTE: getMaxScaleOnAxis() returns max(scaleX, scaleY, scaleZ). Since Z is
    // always 1.0 in our 2-D matrix, it would return 1.0 whenever zoom < 100%.
    // Read storage[0] directly — it's the X-axis (= visual zoom) scale.
    final double scale = matrix.storage[0];
    final double tx = matrix.getTranslation().x;
    final double ty = matrix.getTranslation().y;

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = Color.alphaBlend(
          colorScheme.primary.withValues(alpha: 0.05),
          colorScheme.surfaceContainer,
        ),
    );

    // Draw border
    if (axis == Axis.horizontal) {
      canvas.drawLine(
          Offset(0, size.height), Offset(size.width, size.height), paint);
    } else {
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, size.height), paint);
    }

    final double effectiveScale = lpmm * scale;

    // The InteractiveViewer and each ruler painter share the same coordinate
    // origin (both begin after the ruler strip). tx/ty from the matrix already
    // represent the paper position in painter-local space — no offset needed.
    double offset = axis == Axis.horizontal ? tx : ty;

    if (centerOrigin) {
      final double paperSpanMm =
          axis == Axis.horizontal ? paperSizeMm.width : paperSizeMm.height;
      offset += (paperSpanMm / 2) * effectiveScale;
    }

    final double startMm = -offset / effectiveScale;
    final double endMm =
        (axis == Axis.horizontal ? size.width - offset : size.height - offset) /
            effectiveScale;

    // Adaptive step logic for Labels (Major Ticks)
    // We want labels to be at least 40 logical pixels apart.
    final double minPixelsPerLabel = 40.0;
    final double targetGapMm = minPixelsPerLabel / effectiveScale;

    int labelStep = 1;
    if (targetGapMm > 100) {
      labelStep = 200;
    } else if (targetGapMm > 50) {
      labelStep = 100;
    } else if (targetGapMm > 20) {
      labelStep = 50;
    } else if (targetGapMm > 10) {
      labelStep = 20;
    } else if (targetGapMm > 5) {
      labelStep = 10;
    } else if (targetGapMm > 2) {
      labelStep = 5;
    } else if (targetGapMm > 1) {
      labelStep = 2;
    }

    final int startTick = startMm.floor();
    final int endTick = endMm.ceil();

    // Visual thresholds for minor ticks (in logical pixels)
    final double pixelsPer10mm = effectiveScale * 10;
    final double pixelsPer5mm = effectiveScale * 5;
    final double pixelsPer1mm = effectiveScale * 1;

    for (int i = startTick; i <= endTick; i++) {
      final double pos = i * effectiveScale + offset;

      if (pos < -0.1 ||
          (axis == Axis.horizontal
              ? pos > size.width + 0.1
              : pos > size.height + 0.1)) continue;

      double tickLength = 0.0;
      bool showLabel = false;

      // 1. Major Ticks (Labels)
      if (i % labelStep == 0) {
        tickLength = 10.0;
        showLabel = true;
      }
      // 2. 10mm Ticks
      else if (i % 10 == 0 && pixelsPer10mm >= 12) {
        tickLength = 7.0;
      }
      // 3. 5mm Ticks
      else if (i % 5 == 0 && pixelsPer5mm >= 10) {
        tickLength = 5.0;
      }
      // 4. 1mm Ticks
      else if (pixelsPer1mm >= 4) {
        tickLength = 3.0;
      }

      if (tickLength == 0.0) continue;

      if (axis == Axis.horizontal) {
        canvas.drawLine(
          Offset(pos, size.height - tickLength),
          Offset(pos, size.height),
          paint,
        );
        if (showLabel) {
          final tp = TextPainter(
            text: TextSpan(text: '$i', style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(pos - tp.width / 2, 2));
        }
      } else {
        canvas.drawLine(
          Offset(size.width - tickLength, pos),
          Offset(size.width, pos),
          paint,
        );
        if (showLabel) {
          final tp = TextPainter(
            text: TextSpan(text: '$i', style: textStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          canvas.save();
          canvas.translate(size.width / 2 - 2, pos);
          canvas.rotate(-math.pi / 2);
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
          canvas.restore();
        }
      }
    }

    // Draw cursor "wing" indicator — painted last so it's always on top of tick marks
    if (showWings && cursorPos != null) {
      final wingPaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.7)
        ..strokeWidth = 1.5;

      final pos = axis == Axis.horizontal ? cursorPos!.dx : cursorPos!.dy;

      if (axis == Axis.horizontal) {
        // Solid line along full height of the horizontal ruler
        canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), wingPaint);
      } else {
        // Solid line along full width of the vertical ruler
        canvas.drawLine(Offset(0, pos), Offset(size.width, pos), wingPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.axis != axis ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.cursorPos != cursorPos ||
        oldDelegate.showWings != showWings ||
        oldDelegate.paperSizeMm != paperSizeMm ||
        oldDelegate.centerOrigin != centerOrigin;
  }
}
