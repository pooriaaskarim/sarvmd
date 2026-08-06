import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// A lightweight, premium visual preview of a musical staff layout and clef.
class MiniStaffPreview extends StatelessWidget {
  const MiniStaffPreview({
    super.key,
    required this.systemLayout,
    required this.active,
  });

  final core.SystemLayout systemLayout;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium recessed background: clean card representing a paper snippet
    final bgColor = isDark
        ? colorScheme.surfaceContainer.withValues(alpha: 0.7)
        : colorScheme.surface.withValues(alpha: 0.9);

    final borderColor = isDark
        ? colorScheme.outlineVariant.withValues(alpha: 0.15)
        : colorScheme.outline.withValues(alpha: 0.08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? colorScheme.primary.withValues(alpha: 0.3)
              : borderColor,
          width: active ? 1.2 : 1.0,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          size: const Size(double.infinity, 36),
          painter: _MiniStaffPainter(
            systemLayout: systemLayout,
            color: active ? colorScheme.primary : colorScheme.onSurfaceVariant,
            active: active,
          ),
        ),
      ),
    );
  }
}

class _MiniStaffPainter extends CustomPainter {
  _MiniStaffPainter({
    required this.systemLayout,
    required this.color,
    required this.active,
  });

  final core.SystemLayout systemLayout;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: active ? 0.6 : 0.35)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const lineGap = 2.5;

    void drawStaff(double topY, int lines) {
      for (int i = 0; i < lines; i++) {
        final y = topY + (i * lineGap);
        canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), paint);
      }
    }

    void drawClefProxy(core.ClefSymbol symbol, double topY, int lines) {
      final x = 16.0; // horizontal alignment for clef
      final centerY = topY + ((lines - 1) * lineGap) / 2;

      final strokePaint = Paint()
        ..color = color.withValues(alpha: active ? 0.95 : 0.7)
        ..strokeWidth = 0.95
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final fillPaint = Paint()
        ..color = color.withValues(alpha: active ? 0.95 : 0.7)
        ..style = PaintingStyle.fill;

      switch (symbol) {
        case core.ClefSymbol.g: // Treble Clef
          final path = Path();
          final startY = topY + (lines - 1) * lineGap + 2.5; // below bottom line
          // Standard cursive G shape
          path.moveTo(x + 1.5, startY);
          path.cubicTo(x, startY + 1.5, x - 1, startY, x - 1, startY - 1); 
          path.lineTo(x + 1.5, topY - 3.5); 
          path.cubicTo(x + 1.5, topY - 6.5, x - 0.5, topY - 6.5, x - 0.5, topY - 3.5);
          path.cubicTo(x - 0.5, topY + 3.0, x + 5.0, topY + 3.0, x + 3.5, topY + (lines - 2.5) * lineGap);
          path.cubicTo(x + 1.5, topY + (lines - 1.5) * lineGap, x + 0.5, topY + (lines - 3) * lineGap, x + 1.8, topY + (lines - 3.2) * lineGap);
          canvas.drawPath(path, strokePaint);
          break;

        case core.ClefSymbol.f: // Bass Clef
          final bassPath = Path()
            ..moveTo(x - 1.5, centerY - 2.5)
            ..cubicTo(x + 2.0, centerY - 4.5, x + 4.0, centerY + 0.5, x + 0.5, centerY + 3.5);
          canvas.drawPath(bassPath, strokePaint);
          canvas.drawCircle(Offset(x - 1.5, centerY - 2.5), 1.2, fillPaint); 
          canvas.drawCircle(Offset(x + 4.5, centerY - 1.2), 0.75, fillPaint); 
          canvas.drawCircle(Offset(x + 4.5, centerY + 1.2), 0.75, fillPaint); 
          break;

        case core.ClefSymbol.c: // Alto/Tenor Clef
          // Double vertical bars
          canvas.drawRect(Rect.fromLTWH(x - 2.5, topY - 1, 1.2, (lines - 1) * lineGap + 2), fillPaint);
          canvas.drawRect(Rect.fromLTWH(x - 0.5, topY - 1, 0.5, (lines - 1) * lineGap + 2), fillPaint);
          // Standard bracket (like 3)
          final cPath = Path()
            ..moveTo(x + 0.5, topY - 0.5)
            ..cubicTo(x + 2.5, topY - 0.5, x + 3.5, centerY - 2.0, x + 1.5, centerY)
            ..cubicTo(x + 3.5, centerY + 2.0, x + 2.5, topY + (lines - 1) * lineGap + 0.5, x + 0.5, topY + (lines - 1) * lineGap + 0.5);
          canvas.drawPath(cPath, strokePaint);
          break;

        case core.ClefSymbol.tab:
          // Stack T, A, B vertically
          final double totalHeight = (lines - 1) * lineGap;
          final double step = totalHeight / 2;

          final fontStyle = TextStyle(
            fontSize: lines >= 5 ? 6.5 : 5.0,
            fontWeight: FontWeight.w900,
            color: color.withValues(alpha: active ? 1.0 : 0.8),
            height: 1.0,
            letterSpacing: 0,
          );

          final tpT = TextPainter(
            text: TextSpan(text: 'T', style: fontStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          final tpA = TextPainter(
            text: TextSpan(text: 'A', style: fontStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          final tpB = TextPainter(
            text: TextSpan(text: 'B', style: fontStyle),
            textDirection: TextDirection.ltr,
          )..layout();

          tpT.paint(canvas, Offset(x - (tpT.width / 2), topY - 1));
          tpA.paint(canvas, Offset(x - (tpA.width / 2), topY + step - (tpA.height / 2)));
          tpB.paint(canvas, Offset(x - (tpB.width / 2), topY + totalHeight - tpB.height + 1));
          break;

        case core.ClefSymbol.percussion:
          final height = (lines - 1) * lineGap;
          final rectWidth = 2.5;
          canvas.drawRect(Rect.fromLTWH(x - 1.25, topY, rectWidth, height), strokePaint);
          final fillRect = Rect.fromLTWH(x - 0.75, topY + 0.5, rectWidth - 1.0, height - 1.0);
          canvas.drawRect(fillRect, fillPaint);
          break;
      }
    }

    // Faint placeholders notes/melody
    void drawNotes(double topY, int lines) {
      if (lines <= 1) {
        // Draw standard single line percussion diamond or note
        final notePaint = Paint()
          ..color = color.withValues(alpha: active ? 0.25 : 0.12)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(size.width * 0.5, topY), 2.0, notePaint);
        canvas.drawCircle(Offset(size.width * 0.7, topY), 2.0, notePaint);
        return;
      }

      final notePaint = Paint()
        ..color = color.withValues(alpha: active ? 0.22 : 0.1)
        ..style = PaintingStyle.fill;
      final stemPaint = Paint()
        ..color = color.withValues(alpha: active ? 0.22 : 0.1)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke;

      // Draw two elegant, tiny music notes
      // Note 1: On 2nd line from bottom
      final y1 = topY + (lines - 2) * lineGap;
      final x1 = size.width * 0.45;
      canvas.save();
      canvas.translate(x1, y1);
      canvas.rotate(-0.25); // music tilt
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 4.5, height: 2.8), notePaint);
      canvas.restore();
      canvas.drawLine(Offset(x1 + 2.15, y1), Offset(x1 + 2.15, y1 - 8), stemPaint);

      // Note 2: On 4th line from bottom
      final y2 = topY + (lines - 4) * lineGap;
      final x2 = size.width * 0.72;
      canvas.save();
      canvas.translate(x2, y2);
      canvas.rotate(-0.25);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 4.5, height: 2.8), notePaint);
      canvas.restore();
      canvas.drawLine(Offset(x2 - 2.15, y2), Offset(x2 - 2.15, y2 + 8), stemPaint);
    }

    final root = systemLayout.rootGroup;
    final staves = root.children.whereType<core.StaffDefinition>().toList();
    if (staves.isEmpty) return;

    if (staves.length == 1) {
      final staff = staves.first;
      final staffTop = (size.height - ((staff.lines - 1) * lineGap)) / 2;
      drawStaff(staffTop, staff.lines);
      if (staff.clef != null) {
        drawClefProxy(staff.clef!.symbol, staffTop, staff.lines);
      }
      drawNotes(staffTop, staff.lines);
    } else {
      // Multiple staves
      const gap = 8.0;
      double totalHeight = 0;
      for (final staff in staves) {
        totalHeight += (staff.lines > 0 ? staff.lines - 1 : 0) * lineGap;
      }
      totalHeight += (staves.length - 1) * gap;

      double currentTopY = (size.height - totalHeight) / 2;

      // Draw brace/bracket proxy if needed
      if (root.connector != core.SystemConnector.none) {
        final connectorPaint = Paint()
          ..color = color.withValues(alpha: active ? 0.9 : 0.6)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        if (root.connector == core.SystemConnector.brace) {
          final double fontSize = totalHeight * (1000.0 / 997.0);
          final tp = TextPainter(
            text: TextSpan(
              text: '\u{E000}',
              style: TextStyle(
                fontFamily: 'Bravura',
                fontSize: fontSize,
                color: color.withValues(alpha: active ? 0.9 : 0.6),
                height: 1.0,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final double baselineOffset =
              tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          final double paintX = 5.0 - tp.width * (82.0 / 84.0);
          final double paintY = currentTopY + totalHeight - baselineOffset;
          tp.paint(canvas, Offset(paintX, paintY));
        } else {
          canvas.drawLine(Offset(4, currentTopY),
              Offset(4, currentTopY + totalHeight), connectorPaint);
          canvas.drawLine(
              Offset(4, currentTopY), Offset(6, currentTopY), connectorPaint);
          canvas.drawLine(Offset(4, currentTopY + totalHeight),
              Offset(6, currentTopY + totalHeight), connectorPaint);
        }
      }

      for (final staff in staves) {
        drawStaff(currentTopY, staff.lines);
        if (staff.clef != null) {
          drawClefProxy(staff.clef!.symbol, currentTopY, staff.lines);
        }
        drawNotes(currentTopY, staff.lines);
        currentTopY += (staff.lines > 0 ? staff.lines - 1 : 0) * lineGap + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniStaffPainter oldDelegate) {
    return oldDelegate.systemLayout != systemLayout ||
        oldDelegate.color != color ||
        oldDelegate.active != active;
  }
}
