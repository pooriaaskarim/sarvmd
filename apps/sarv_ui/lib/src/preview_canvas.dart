import 'package:flutter/material.dart';
import 'package:sarv_core/sarv_core.dart' as core;

class PreviewCanvas extends StatelessWidget {
  const PreviewCanvas({
    super.key,
    required this.layout,
  });

  final core.PageLayout layout;

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
      child: CustomPaint(
        size: sizePx,
        painter: _ManuscriptPainter(layout, lpmm),
      ),
    );
  }
}

class _ManuscriptPainter extends CustomPainter {
  _ManuscriptPainter(this.layout, this.scale);

  final core.PageLayout layout;
  final double scale;

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

    // Hint lines for paper edges (faint dashed-like lines)
    final hintPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Top paper edge hint
    canvas.drawLine(const Offset(-100000, 0), Offset(size.width + 100000, 0), hintPaint);
    // Bottom paper edge hint
    canvas.drawLine(Offset(-100000, size.height), Offset(size.width + 100000, size.height), hintPaint);
    // Left paper edge hint
    canvas.drawLine(const Offset(0, -100000), Offset(0, size.height + 100000), hintPaint);
    // Right paper edge hint
    canvas.drawLine(Offset(size.width, -100000), Offset(size.width, size.height + 100000), hintPaint);

    for (final system in layout.systems) {
      for (final staff in system.staves) {
        final topYPx = staff.topY * scale;
        
        // Draw 5 lines
        for (var i = 0; i < 5; i++) {
          final y = topYPx + i * lineGapPx;
          canvas.drawLine(
            Offset(leftMm * scale, y),
            Offset(rightMm * scale, y),
            staffPaint,
          );
        }
      }

      // If piano, draw vertical line connecting staves on the left
      if (layout.config.layoutType == core.LayoutType.piano && system.staves.length >= 2) {
        final topY = system.staves[0].topY * scale;
        final bottomY = (system.staves[1].topY + layout.config.staffConfig.staffHeightMm) * scale;
        canvas.drawLine(
          Offset(leftMm * scale, topY),
          Offset(leftMm * scale, bottomY),
          staffPaint..strokeWidth = thicknessPx * 2, // Slightly thicker connecting line
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ManuscriptPainter oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.scale != scale;
  }
}
