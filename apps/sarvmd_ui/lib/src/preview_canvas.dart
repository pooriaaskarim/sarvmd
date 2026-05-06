import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
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

    // Manuscript paper is ALWAYS white for print-fidelity.
    const Color paperColor = Colors.white;
    const Color inkColor = Colors.black;

    return Container(
      width: sizePx.width,
      height: sizePx.height,
      decoration: BoxDecoration(
        color: paperColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
              layout: layout,
              scale: lpmm,
              viewNotifier: viewNotifier,
              colorScheme: Theme.of(context).colorScheme,
              inkColor: inkColor,
            ),
          );
        },
      ),
    );
  }
}

class _ManuscriptPainter extends CustomPainter {
  _ManuscriptPainter({
    required this.layout,
    required this.scale,
    required this.viewNotifier,
    required this.colorScheme,
    required this.inkColor,
  });

  final core.PageLayout layout;
  final double scale;
  final ViewNotifier viewNotifier;
  final ColorScheme colorScheme;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final staffPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke;

    final thicknessPx = layout.config.staffConfig.lineThicknessPt *
        (96 / 72) *
        (scale / (96 / 25.4));
    staffPaint.strokeWidth = thicknessPx;

    final lineGapPx = layout.config.staffConfig.lineGapMm * scale;
    final leftMm = layout.config.margins.left;
    final rightMm = layout.config.pageSize.width - layout.config.margins.right;

    final guidePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Hint lines for paper edges
    if (viewNotifier.isGuideActive(GuideType.paperEdges)) {
      canvas.drawLine(
          const Offset(-100000, 0), Offset(size.width + 100000, 0), guidePaint);
      canvas.drawLine(Offset(-100000, size.height),
          Offset(size.width + 100000, size.height), guidePaint);
      canvas.drawLine(
          const Offset(0, -100000), Offset(0, size.height + 100000), guidePaint);
      canvas.drawLine(Offset(size.width, -100000),
          Offset(size.width, size.height + 100000), guidePaint);
    }

    if (viewNotifier.isGuideActive(GuideType.paperCenters)) {
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      canvas.drawLine(Offset(centerX, -100000),
          Offset(centerX, size.height + 100000), guidePaint);
      canvas.drawLine(Offset(-100000, centerY),
          Offset(size.width + 100000, centerY), guidePaint);
    }

    // Margin guides
    if (viewNotifier.isGuideActive(GuideType.margins)) {
      final marginPaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final marginLeft = layout.config.margins.left * scale;
      final marginRight = size.width - layout.config.margins.right * scale;
      final marginTop = layout.config.margins.top * scale;
      final marginBottom = size.height - layout.config.margins.bottom * scale;

      canvas.drawLine(
          Offset(marginLeft, 0), Offset(marginLeft, size.height), marginPaint);
      canvas.drawLine(Offset(marginRight, 0), Offset(marginRight, size.height),
          marginPaint);
      canvas.drawLine(
          Offset(0, marginTop), Offset(size.width, marginTop), marginPaint);
      canvas.drawLine(Offset(0, marginBottom), Offset(size.width, marginBottom),
          marginPaint);
    }

    for (final system in layout.systems) {
      for (var sIdx = 0; sIdx < system.staves.length; sIdx++) {
        final staff = system.staves[sIdx];
        final topYPx = staff.topY * scale;

        // Staff bounding box guides
        if (viewNotifier.isGuideActive(GuideType.staffBounds)) {
          final boundsPaint = Paint()
            ..color = colorScheme.primary.withValues(alpha: 0.1)
            ..style = PaintingStyle.fill;

          final rect = Rect.fromLTRB(leftMm * scale, topYPx - (lineGapPx / 2),
              rightMm * scale, topYPx + (4 * lineGapPx) + (lineGapPx / 2));
          canvas.drawRect(rect, boundsPaint);
        }

        // Draw 5 lines (Top line snapped, others relative for equal gaps)
        final topSnappedY = topYPx.roundToDouble();
        for (var i = 0; i < 5; i++) {
          final y = topSnappedY + i * lineGapPx;
          canvas.drawLine(
            Offset(leftMm * scale, y),
            Offset(rightMm * scale, y),
            staffPaint,
          );
        }

        // ── Draw Clef ─────────────────────────────────────────
        final clef = (layout.config.layoutType == core.LayoutType.doubleLine &&
                sIdx == 1)
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
                color: inkColor,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          // Use the actual alphabetic baseline instead of general ascent,
          // and apply a micro-compensation to fix the symbols appearing "a little upper".
          final baselineDelta =
              tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);

          final anchorYPx = topYPx + (5 - clef.anchorLine) * lineGapPx;
          final baselineY = anchorYPx + anchorSp * lineGapPx;

          // NotoMusic's glyph ink often stops slightly above the baseline by around 0.01 em,
          // creating a visual effect where it seems "a little upper".
          // In spaces, 0.01 em = 0.04 sp. We push it down slightly to compensate.
          final microOffset = lineGapPx * 0.04;

          final glyphX = leftMm * scale + lineGapPx * 0.15;
          final glyphY = baselineY - baselineDelta + microOffset;

          tp.paint(
              canvas, Offset(glyphX.roundToDouble(), glyphY.roundToDouble()));
        }
      }

      // If piano, draw a bold vertical line connecting the two staves
      if (layout.config.layoutType == core.LayoutType.doubleLine &&
          system.staves.length >= 2) {
        final topY = (system.staves[0].topY * scale).roundToDouble();
        final bottomY =
            ((system.staves[1].topY + layout.config.staffConfig.staffHeightMm) *
                    scale)
                .roundToDouble();
        final startX = (leftMm * scale).roundToDouble();

        final connectorPaint = Paint()
          ..color = inkColor
          ..strokeWidth = thicknessPx * 2.5 // Bolder as requested
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(startX, topY),
          Offset(startX, bottomY),
          connectorPaint,
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
