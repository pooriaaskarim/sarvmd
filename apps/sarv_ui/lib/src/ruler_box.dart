import 'package:flutter/material.dart';
import 'dart:math' as math;


class RulerBox extends StatefulWidget {
  const RulerBox({
    super.key,
    required this.child,
    required this.transformationController,
    required this.paperSizeMm,
    this.rulerSize = 25.0,
  });

  final Widget child;
  final TransformationController transformationController;
  final Size paperSizeMm;
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 8),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _toggleOrigin,
                  child: ListenableBuilder(
                    listenable: widget.transformationController,
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
                    listenable: widget.transformationController,
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
  });

  final Axis axis;
  final Matrix4 matrix;
  final bool centerOrigin;
  final Size paperSizeMm;
  final ColorScheme colorScheme;

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

    // Extract scale and translation from matrix
    final double scale = matrix.getMaxScaleOnAxis();
    final double tx = matrix.getTranslation().x;
    final double ty = matrix.getTranslation().y;

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = colorScheme.surfaceContainer,
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
    double offset = axis == Axis.horizontal ? tx : ty;

    if (centerOrigin) {
      final double paperSpanMm =
          axis == Axis.horizontal ? paperSizeMm.width : paperSizeMm.height;
      offset += (paperSpanMm / 2) * effectiveScale;
    }

    // We want to calculate the range of mm visible in the viewport.
    // viewport_pos = matrix_pos * paper_pos
    // mm_val = (viewport_pos - offset) / effectiveScale

    final double startMm = -offset / effectiveScale;
    final double endMm =
        (axis == Axis.horizontal ? size.width - offset : size.height - offset) /
            effectiveScale;

    // Limit ticks to avoid performance issues if zoomed out too much
    // Adaptive step logic
    final double minPixelsPerLabel = 40.0;
    final double targetGapMm = minPixelsPerLabel / effectiveScale;

    int stepMm = 1;
    if (targetGapMm > 500) {
      stepMm = 1000;
    } else if (targetGapMm > 200) {
      stepMm = 500;
    } else if (targetGapMm > 100) {
      stepMm = 200;
    } else if (targetGapMm > 50) {
      stepMm = 100;
    } else if (targetGapMm > 20) {
      stepMm = 50;
    } else if (targetGapMm > 10) {
      stepMm = 20;
    } else if (targetGapMm > 5) {
      stepMm = 10;
    } else if (targetGapMm > 2) {
      stepMm = 5;
    } else if (targetGapMm > 1) {
      stepMm = 2;
    }

    // Adjust startTick to be a multiple of stepMm (or at least calculate cleanly)
    final int startTick = startMm.floor();
    final int endTick = endMm.ceil();

    for (int i = startTick; i <= endTick; i++) {
      final double pos = i * effectiveScale + offset;

      // Skip if off-screen (due to floating point or padding)
      if (pos < -0.1 ||
          (axis == Axis.horizontal
              ? pos > size.width + 0.1
              : pos > size.height + 0.1)) continue;

      double tickLength = 0.0;
      bool showLabel = false;

      if (i % stepMm == 0) {
        tickLength = 10.0;
        showLabel = true;
      } else if (stepMm >= 10 && i % (stepMm ~/ 2) == 0) {
        tickLength = 7.0;
      } else if (stepMm < 10) {
        if (i % 5 == 0) {
           tickLength = 7.0;
        } else if (stepMm <= 2) {
           tickLength = 4.0;
        }
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
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.matrix != matrix || 
           oldDelegate.axis != axis || 
           oldDelegate.colorScheme != colorScheme;
  }
}
