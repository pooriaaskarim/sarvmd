import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../theme/app_theme.dart';

/// A standard, highly reusable, and fully theme-reactive live preview for a musical staff.
///
/// It automatically adapts to Light and Dark modes, accent themes (Lavender/Lemon/Sage/Sky),
/// renders high-visibility engraving staff lines, and supports interactive line tapping.
class LiveStaffPreview extends StatelessWidget {
  final String name;
  final String abbrev;
  final int lines;
  final core.ClefSymbol? clefSymbol;
  final int anchorLine;
  final bool visible;
  final double hOffset;
  final double vOffset;
  final String fontFamily;
  final double fontSize;
  final bool italic;

  /// Callback triggered when a staff line is tapped to change the anchor line.
  /// If null, interactive line tapping is disabled.
  final ValueChanged<int>? onAnchorLineChanged;

  const LiveStaffPreview({
    super.key,
    required this.name,
    required this.abbrev,
    required this.lines,
    required this.clefSymbol,
    required this.anchorLine,
    required this.visible,
    required this.hOffset,
    required this.vOffset,
    required this.fontFamily,
    required this.fontSize,
    required this.italic,
    this.onAnchorLineChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<SarvThemeExtension>();

    // Automatically match theme paper color (cream in light mode, dark tinted in dark mode)
    final paperColor = ext?.paperColor ?? theme.colorScheme.surfaceContainer;

    return Center(
      child: Container(
        width: 380,
        height: 140,
        decoration: BoxDecoration(
          color: paperColor,
          borderRadius:
              BorderRadius.circular(16), // Premium rounded paper edges
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5, // High contrast solid border
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.light ? 0.06 : 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              return GestureDetector(
                onTapUp: (details) {
                  if (onAnchorLineChanged == null || lines <= 0) return;

                  final double tappedX = details.localPosition.dx;
                  final double tappedY = details.localPosition.dy;

                  final double centerX = width / 2;
                  final double startX = centerX - 50.0;
                  final double endX = centerX + 110.0;

                  // Only register taps horizontally near the staff lines
                  if (tappedX < startX - 15.0 || tappedX > endX + 15.0) return;

                  const double gap =
                      15.0; // Scaled up gap for higher tactile precision
                  final double midY = 140 / 2; // Container height is 140
                  final double staffHeight = (lines - 1) * gap;
                  final double startY = midY - staffHeight / 2;

                  final int i = ((tappedY - startY) / gap).round();
                  if (i >= 0 && i < lines) {
                    onAnchorLineChanged!(lines - i);
                  }
                },
                child: CustomPaint(
                  painter: _LiveStaffPreviewPainter(
                    name: name,
                    abbrev: abbrev,
                    lines: lines,
                    clefSymbol: clefSymbol,
                    anchorLine: anchorLine,
                    visible: visible,
                    hOffset: hOffset,
                    vOffset: vOffset,
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                    italic: italic,
                    primaryColor: theme.colorScheme.primary,
                    onSurfaceColor: theme.colorScheme.onSurface,
                    theme: theme,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiveStaffPreviewPainter extends CustomPainter {
  final String name;
  final String abbrev;
  final int lines;
  final core.ClefSymbol? clefSymbol;
  final int anchorLine;
  final bool visible;
  final double hOffset;
  final double vOffset;
  final String fontFamily;
  final double fontSize;
  final bool italic;

  final Color primaryColor;
  final Color onSurfaceColor;
  final ThemeData theme;

  const _LiveStaffPreviewPainter({
    required this.name,
    required this.abbrev,
    required this.lines,
    required this.clefSymbol,
    required this.anchorLine,
    required this.visible,
    required this.hOffset,
    required this.vOffset,
    required this.fontFamily,
    required this.fontSize,
    required this.italic,
    required this.primaryColor,
    required this.onSurfaceColor,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    const double gap =
        15.0; // Scaled up line spacing for maximum visibility (up from 12.0)
    final double staffHeight = (lines - 1) * gap;
    final double startY = midY - staffHeight / 2;

    final Color inkColor = onSurfaceColor;

    // Perfectly balanced horizontal coordinates for a 380px wide container
    final double centerX = size.width / 2;
    final double startX = centerX - 50.0;
    final double endX =
        centerX + 110.0; // Staff lines remain a clean 160px wide
    final double clefX = startX + 15.0;

    // Draw staff lines with custom highlighted anchor line (ultra-clear high contrast)
    for (var i = 0; i < lines; i++) {
      final lineNum = lines - i;
      final y = startY + i * gap;
      final isAnchor = lineNum == anchorLine;
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        Paint()
          ..color = isAnchor ? primaryColor : inkColor.withValues(alpha: 0.35)
          ..strokeWidth =
              isAnchor ? 2.5 : 1.5 // Scaled up line weights for visual clarity
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw starting vertical barline (Standard musical engraving convention)
    if (lines > 1) {
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX, startY + staffHeight),
        Paint()
          ..color = inkColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.square,
      );
    } else if (lines == 1) {
      canvas.drawLine(
        Offset(startX, startY - gap * 0.8),
        Offset(startX, startY + gap * 0.8),
        Paint()
          ..color = inkColor
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.square,
      );
    }

    // Draw ending vertical double barline (Standard musical terminal engraving cutoff)
    final Paint thinPaint = Paint()
      ..color = inkColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;
    final Paint thickPaint = Paint()
      ..color = inkColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square;

    if (lines > 1) {
      canvas.drawLine(Offset(endX - 5.5, startY),
          Offset(endX - 5.5, startY + staffHeight), thinPaint);
      canvas.drawLine(
          Offset(endX, startY), Offset(endX, startY + staffHeight), thickPaint);
    } else if (lines == 1) {
      canvas.drawLine(Offset(endX - 5.5, startY - gap * 0.8),
          Offset(endX - 5.5, startY + gap * 0.8), thinPaint);
      canvas.drawLine(Offset(endX, startY - gap * 0.8),
          Offset(endX, startY + gap * 0.8), thickPaint);
    }

    // Draw Clef in preview
    if (clefSymbol != null && lines > 0) {
      if (clefSymbol == core.ClefSymbol.tab) {
        final double tabCenterY = startY + staffHeight / 2;
        final tabSize = gap * 1.5;

        // Standard visual padding matching standard clefs
        final startX = clefX + gap * 0.4;

        final lettersStyle = TextStyle(
          fontFamily: 'Noto Serif',
          fontSize: tabSize,
          fontWeight: FontWeight.bold,
          color: inkColor,
          height: 0.8,
        );
        final letters = ['T', 'A', 'B'];
        double currY = tabCenterY - (tabSize * 1.5 * 0.8);
        for (final char in letters) {
          final tp = TextPainter(
            text: TextSpan(text: char, style: lettersStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(startX, currY));
          currY += tabSize * 0.8;
        }
      } else if (clefSymbol == core.ClefSymbol.percussion) {
        final pPaint = Paint()
          ..color = inkColor
          ..style = PaintingStyle.fill;
        final barHeight = gap * 2.0;
        final barWidth = gap * 0.35;
        final centerY = startY + staffHeight / 2;

        // Standard visual padding matching standard clefs
        final leftX = clefX + gap * 0.4;

        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(leftX + barWidth / 2, centerY),
                width: barWidth,
                height: barHeight),
            pPaint);
        canvas.drawRect(
            Rect.fromCenter(
                center: Offset(leftX + barWidth * 2.5, centerY),
                width: barWidth,
                height: barHeight),
            pPaint);
      } else {
        const fontScale =
            3.8; // Scaled up clef glyph multiplier for maximum prominence
        final (String glyph, double anchorSp) = switch (clefSymbol!) {
          core.ClefSymbol.g => ('\u{1D11E}', 0.876),
          core.ClefSymbol.c => ('\u{1D121}', 2.0),
          core.ClefSymbol.f => ('\u{1D122}', 2.578),
          _ => ('', 0.0),
        };
        final tp = TextPainter(
          text: TextSpan(
            text: glyph,
            style: TextStyle(
              fontFamily: 'NotoMusic',
              fontSize: gap * fontScale,
              color: inkColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final baselineDelta =
            tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        final anchorYPx = startY + (lines - anchorLine) * gap;
        final baselineY = anchorYPx + anchorSp * gap;
        final glyphY = baselineY - baselineDelta;

        tp.paint(canvas, Offset(clefX, glyphY));
      }
    }

    // Draw Label if visible
    if (visible && lines > 0) {
      final labelStyle = TextStyle(
        fontFamily: fontFamily == 'serif' ? 'Noto Serif' : 'Roboto',
        fontSize: fontSize,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontWeight: FontWeight.w600,
        color: inkColor,
      );

      final String labelText = abbrev.isNotEmpty ? abbrev : name;
      final labelPainter = TextPainter(
        text: TextSpan(text: labelText, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final double staffMidY = startY + staffHeight / 2;

      // Calculate placement relative to start of staff (25px spacing)
      final double defaultX = (startX - 25.0) - labelPainter.width;
      final double x = defaultX + hOffset;
      final double y = staffMidY - labelPainter.height / 2 + vOffset;

      // Draw Alignment Guides & Displacement Vectors if there's active offset tuning
      if (hOffset.abs() > 0.5 || vOffset.abs() > 0.5) {
        final double defaultCenterX = (startX - 25.0) - labelPainter.width / 2;
        final double defaultCenterY = staffMidY;
        final double actualCenterX = defaultCenterX + hOffset;
        final double actualCenterY = defaultCenterY + vOffset;

        final guidePaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.5)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        // Draw dotted/dashed line connecting origin and current offset
        _drawDashedLine(canvas, Offset(defaultCenterX, defaultCenterY),
            Offset(actualCenterX, actualCenterY), guidePaint);

        // Draw soft default anchor dot/circle (outer ring + inner fill)
        canvas.drawCircle(
          Offset(defaultCenterX, defaultCenterY),
          3.0,
          Paint()
            ..color = primaryColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
        canvas.drawCircle(
          Offset(defaultCenterX, defaultCenterY),
          1.0,
          Paint()
            ..color = primaryColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        );

        // Draw displaced active target circle (concentric CAD cursor)
        canvas.drawCircle(
          Offset(actualCenterX, actualCenterY),
          4.0,
          Paint()
            ..color = primaryColor
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          Offset(actualCenterX, actualCenterY),
          7.0,
          Paint()
            ..color = primaryColor.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );

        // Render a premium, high-visibility CAD-style HUD badge in the top-right corner (zero collision!)
        final String offsetText =
            'Δx: ${hOffset.round() >= 0 ? '+' : ''}${hOffset.round()}   Δy: ${vOffset.round() >= 0 ? '+' : ''}${vOffset.round()}';
        final offsetPainter = TextPainter(
          text: TextSpan(
            text: offsetText,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w200,
              color: theme.colorScheme.onPrimaryContainer,
              letterSpacing: 0.5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final double padH = 8.0;
        final double padV = 4.0;
        final double rectW = offsetPainter.width + padH * 2;
        final double rectH = offsetPainter.height + padV * 2;

        final double rectX = size.width - rectW - 16.0;
        final double rectY = 16.0;

        final double textX = rectX + padH;
        final double textY = rectY + padV;

        final RRect capsule = RRect.fromRectAndRadius(
          Rect.fromLTWH(rectX, rectY, rectW, rectH),
          const Radius.circular(8),
        );

        // 1. Draw subtle ambient drop shadow for the capsule badge
        canvas.drawRRect(
          capsule.shift(const Offset(0, 2)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );

        // 2. Draw solid premium background fill (AA contrast-compliant primaryContainer)
        canvas.drawRRect(
          capsule,
          Paint()
            ..color = theme.colorScheme.primaryContainer
            ..style = PaintingStyle.fill,
        );

        // 3. Draw a crisp outline border around the badge
        canvas.drawRRect(
          capsule,
          Paint()
            ..color = theme.colorScheme.primary.withValues(alpha: 0.4)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke,
        );

        // 4. Paint the text inside the badge
        offsetPainter.paint(canvas, Offset(textX, textY));
      }

      labelPainter.paint(canvas, Offset(x, y));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 3.0;
    const double dashSpace = 3.0;
    final double distance = (p2 - p1).distance;
    if (distance == 0.0) return;

    final int count = (distance / (dashWidth + dashSpace)).floor();
    final double dx = (p2.dx - p1.dx) / distance;
    final double dy = (p2.dy - p1.dy) / distance;

    for (int i = 0; i < count; i++) {
      final double startDist = i * (dashWidth + dashSpace);
      final double endDist = startDist + dashWidth;
      canvas.drawLine(
        Offset(p1.dx + dx * startDist, p1.dy + dy * startDist),
        Offset(p1.dx + dx * endDist, p1.dy + dy * endDist),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveStaffPreviewPainter oldDelegate) {
    return oldDelegate.name != name ||
        oldDelegate.abbrev != abbrev ||
        oldDelegate.lines != lines ||
        oldDelegate.clefSymbol != clefSymbol ||
        oldDelegate.anchorLine != anchorLine ||
        oldDelegate.visible != visible ||
        oldDelegate.hOffset != hOffset ||
        oldDelegate.vOffset != vOffset ||
        oldDelegate.fontFamily != fontFamily ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.italic != italic ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.onSurfaceColor != onSurfaceColor;
  }
}
