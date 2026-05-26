import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../logic/view/view_state.dart';

class RulerBox extends StatefulWidget {
  const RulerBox({
    super.key,
    required this.child,
    required this.transformationController,
    required this.paperSizeMm,
    required this.viewState,
    required this.cursorNotifier,
    this.rulerSize = 25.0,
  });

  final Widget child;
  final TransformationController transformationController;
  final Size paperSizeMm;
  final ViewState viewState;

  /// Dedicated high-frequency notifier for cursor position. Kept separate
  /// from ViewCubit intentionally so that every mouse-move only repaints
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Top Ruler
        SizedBox(
          height: widget.rulerSize,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Origin Switcher Button
              Tooltip(
                message: _centerOrigin
                    ? 'Switch to Top-Left Origin'
                    : 'Switch to Center Origin',
                child: Container(
                  width: widget.rulerSize,
                  height: widget.rulerSize,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    border: Border(
                      right: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleOrigin,
                      mouseCursor: SystemMouseCursors.click,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'mm',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _centerOrigin ? Icons.filter_center_focus : Icons.open_in_full,
                              key: ValueKey(_centerOrigin),
                              size: 9.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
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
                            showWings: widget.viewState
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
                            showWings: widget.viewState
                                .isGuideActive(GuideType.rulerWings),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.child),
                    // Dynamic WX Real-time Coordinate HUD Overlay
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _CoordinateHUD(
                        transformationController: widget.transformationController,
                        cursorNotifier: widget.cursorNotifier,
                        paperSizeMm: widget.paperSizeMm,
                        centerOrigin: _centerOrigin,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Floating glassmorphic HUD for real-time cursor coordinate tracking in millimeters.
class _CoordinateHUD extends StatelessWidget {
  const _CoordinateHUD({
    required this.transformationController,
    required this.cursorNotifier,
    required this.paperSizeMm,
    required this.centerOrigin,
  });

  final TransformationController transformationController;
  final ValueNotifier<Offset?> cursorNotifier;
  final Size paperSizeMm;
  final bool centerOrigin;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([transformationController, cursorNotifier]),
      builder: (context, _) {
        final pos = cursorNotifier.value;
        final isHovered = pos != null;

        return AnimatedOpacity(
          opacity: isHovered ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: isHovered ? _buildContent(context, pos) : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, Offset pos) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract transformation matrix parameters
    final matrix = transformationController.value;
    final double scale = matrix.storage[0];
    final double tx = matrix.getTranslation().x;
    final double ty = matrix.getTranslation().y;

    const double lpmm = 96 / 25.4; // Pixels per millimeter
    final double effectiveScale = lpmm * scale;

    // Convert local screen coordinates back into physical paper coordinates
    double xMm = (pos.dx - tx) / effectiveScale;
    double yMm = (pos.dy - ty) / effectiveScale;

    // Check if cursor lies inside the boundaries of physical paper sheet
    final bool onPaper = xMm >= 0 && xMm <= paperSizeMm.width &&
                         yMm >= 0 && yMm <= paperSizeMm.height;

    // Recalculate coordinates relative to origin (Top-Left or Center)
    if (centerOrigin) {
      xMm -= paperSizeMm.width / 2;
      yMm -= paperSizeMm.height / 2;
    }

    final String xStr = xMm.toStringAsFixed(1);
    final String yStr = yMm.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainer.withValues(alpha: 0.85)
            : colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: onPaper
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // On-Paper Status indicator dot
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: onPaper
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          // Coordinate system origin mode label
          Text(
            centerOrigin ? 'CTR' : 'TOP',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: onPaper ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          // Millimeter measurements
          Text(
            'X: $xStr',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Y: $yStr',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'mm',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
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

    // Draw cursor "wing" indicator
    if (showWings && cursorPos != null) {
      final wingPaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.7)
        ..strokeWidth = 1.5;

      final pos = axis == Axis.horizontal ? cursorPos!.dx : cursorPos!.dy;

      if (axis == Axis.horizontal) {
        canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), wingPaint);
      } else {
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
