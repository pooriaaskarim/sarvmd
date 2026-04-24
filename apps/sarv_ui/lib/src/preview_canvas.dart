import 'package:flutter/material.dart';
import 'package:sarv_core/sarv_core.dart' as core;
import 'view_notifier.dart';

class PreviewCanvas extends StatelessWidget {
  const PreviewCanvas({
    super.key,
    required this.layout,
    required this.viewNotifier,
  });

  final core.PageLayout layout;
  final ViewNotifier viewNotifier;

  @override
  Widget build(BuildContext context) {
    const double lpmm = 96 / 25.4;
    final sizePx = Size(
      layout.config.pageSize.width * lpmm,
      layout.config.pageSize.height * lpmm,
    );

    return Container(
      width: sizePx.width,
      height: sizePx.height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListenableBuilder(
        listenable: viewNotifier,
        builder: (context, _) {
          return CustomPaint(
            size: sizePx,
            painter: _ManuscriptPainter(
              layout,
              lpmm,
              viewNotifier,
            ),
          );
        },
      ),
    );
  }
}

class _ManuscriptPainter extends CustomPainter {
  _ManuscriptPainter(this.layout, this.scale, this.viewNotifier);

  final core.PageLayout layout;
  final double scale;
  final ViewNotifier viewNotifier;

  @override
  void paint(Canvas canvas, Size size) {
    final staffPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = layout.config.staffConfig.lineThicknessPt * (96 / 72) * scale / scale // This is tricky.
      // Thickness in pt. 1pt = 1.333 logic pixels at scale 1.0.
      ..style = PaintingStyle.stroke;

    // Actually, stroke width should be scaled by our internal scale too.
    // thicknessPt * (96/72) gives logic pixels at default DPI. 
    // Then we multiply by zoom/scale.
    final thicknessPx = layout.config.staffConfig.lineThicknessPt * (96 / 72) * (scale / (96 / 25.4));
    staffPaint.strokeWidth = thicknessPx;

    final lineGapPx = layout.config.staffConfig.lineGapMm * scale;
    final leftMm = layout.config.margins.left;
    final rightMm = layout.config.pageSize.width - layout.config.margins.right;

    // Hint lines for paper edges
    if (viewNotifier.isGuideActive(GuideType.paperEdges)) {
      final hintPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(const Offset(-100000, 0), Offset(size.width + 100000, 0), hintPaint);
      canvas.drawLine(Offset(-100000, size.height), Offset(size.width + 100000, size.height), hintPaint);
      canvas.drawLine(const Offset(0, -100000), Offset(0, size.height + 100000), hintPaint);
      canvas.drawLine(Offset(size.width, -100000), Offset(size.width, size.height + 100000), hintPaint);
    }

    if (viewNotifier.isGuideActive(GuideType.paperCenters)) {
      final hintPaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      canvas.drawLine(Offset(centerX, -100000), Offset(centerX, size.height + 100000), hintPaint);
      canvas.drawLine(Offset(-100000, centerY), Offset(size.width + 100000, centerY), hintPaint);
    }
    
    // Margin guides
    if (viewNotifier.isGuideActive(GuideType.margins)) {
      final marginPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      final marginLeft = layout.config.margins.left * scale;
      final marginRight = size.width - layout.config.margins.right * scale;
      final marginTop = layout.config.margins.top * scale;
      final marginBottom = size.height - layout.config.margins.bottom * scale;
      
      canvas.drawLine(Offset(marginLeft, 0), Offset(marginLeft, size.height), marginPaint);
      canvas.drawLine(Offset(marginRight, 0), Offset(marginRight, size.height), marginPaint);
      canvas.drawLine(Offset(0, marginTop), Offset(size.width, marginTop), marginPaint);
      canvas.drawLine(Offset(0, marginBottom), Offset(size.width, marginBottom), marginPaint);
    }

    for (final system in layout.systems) {
      for (var sIdx = 0; sIdx < system.staves.length; sIdx++) {
        final staff = system.staves[sIdx];
        final topYPx = staff.topY * scale;
        
        // Staff bounding box guides
        if (viewNotifier.isGuideActive(GuideType.staffBounds)) {
          final boundsPaint = Paint()
            ..color = Colors.green.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill;
          
          final rect = Rect.fromLTRB(
            leftMm * scale,
            topYPx - (lineGapPx / 2),
            rightMm * scale,
            topYPx + (4 * lineGapPx) + (lineGapPx / 2)
          );
          canvas.drawRect(rect, boundsPaint);
        }
        
        // Draw 5 lines (pixel-snapped to prevent blurry sub-pixel strokes)
        for (var i = 0; i < 5; i++) {
          final y = topYPx + i * lineGapPx;
          // To get sharp 1px equivalent strokes, snapping to int + 0.5 is often required in logical space,
          // but since scale is arbitrary, simply rounding Y can reduce "fuzz" relative to clef anti-aliasing.
          final snappedY = (y * scale).round() / scale;
          canvas.drawLine(
            Offset(leftMm * scale, snappedY),
            Offset(rightMm * scale, snappedY),
            staffPaint,
          );
        }

        // ── Draw Clef ─────────────────────────────────────────
        final clef = (layout.config.layoutType == core.LayoutType.piano && sIdx == 1)
            ? layout.config.secondaryClef
            : layout.config.primaryClef;

        if (clef != null) {
          // Glyph-centroid anchors (from fontTools contour analysis):
          //   G U+1D11E : lower-oval centre   = 0.876 sp above baseline
          //   C U+1D121 : bracket midpoint     = 2.004 sp ≈ 2.0 sp  ✓ (confirmed)
          //   F U+1D122 : dot midpoint         = (3.018+2.138)/2 = 2.578 sp
          const fontScale = 4.0;
          final (String glyph, double anchorSp) = switch (clef.symbol) {
            core.ClefSymbol.g => ('\u{1D11E}', 0.876),
            core.ClefSymbol.c => ('\u{1D121}', 2.0),
            core.ClefSymbol.f => ('\u{1D122}', 2.578),
          };

          final tp = TextPainter(
            text: TextSpan(
              text: glyph,
              style: TextStyle(
                fontFamily: 'NotoMusic',
                fontSize: lineGapPx * fontScale,
                color: Colors.black,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          // Use the actual alphabetic baseline instead of general ascent, 
          // and apply a micro-compensation to fix the symbols appearing "a little upper".
          final baselineDelta = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          
          final anchorYPx = topYPx + (5 - clef.anchorLine) * lineGapPx;
          final baselineY = anchorYPx + anchorSp * lineGapPx;
          
          // NotoMusic's glyph ink often stops slightly above the baseline by around 0.01 em,
          // creating a visual effect where it seems "a little upper".
          // In spaces, 0.01 em = 0.04 sp. We push it down slightly to compensate.
          final microOffset = lineGapPx * 0.04;
          
          final glyphX = leftMm * scale + lineGapPx * 0.15;
          final glyphY = baselineY - baselineDelta + microOffset;
          
          // Snap exact top left for the TextPainter to match staff crispness
          tp.paint(canvas, Offset((glyphX * scale).round() / scale, (glyphY * scale).round() / scale));
        }
      }

      // If piano, draw vertical line connecting staves on the left
      if (layout.config.layoutType == core.LayoutType.piano && system.staves.length >= 2) {
        final topY = system.staves[0].topY * scale;
        final bottomY = (system.staves[1].topY + layout.config.staffConfig.staffHeightMm) * scale;
        final startX = (leftMm * scale).round() / scale;
        canvas.drawLine(
          Offset(startX, (topY * scale).round() / scale),
          Offset(startX, (bottomY * scale).round() / scale),
          staffPaint..strokeWidth = thicknessPx * 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ManuscriptPainter oldDelegate) {
    return oldDelegate.layout != layout || 
           oldDelegate.scale != scale || 
           oldDelegate.viewNotifier != viewNotifier;
  }
}
