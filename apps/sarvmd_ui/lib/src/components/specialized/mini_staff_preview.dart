import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// A lightweight visual preview of a musical staff layout and clef.
class MiniStaffPreview extends StatelessWidget {
  const MiniStaffPreview({
    super.key,
    required this.layoutType,
    this.primaryClef,
    this.secondaryClef,
    required this.active,
  });

  final core.LayoutType layoutType;
  final core.ClefSymbol? primaryClef;
  final core.ClefSymbol? secondaryClef;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: _MiniStaffPainter(
        layoutType: layoutType,
        primaryClef: primaryClef,
        secondaryClef: secondaryClef,
        color: color,
      ),
    );
  }
}

class _MiniStaffPainter extends CustomPainter {
  _MiniStaffPainter({
    required this.layoutType,
    this.primaryClef,
    this.secondaryClef,
    required this.color,
  });

  final core.LayoutType layoutType;
  final core.ClefSymbol? primaryClef;
  final core.ClefSymbol? secondaryClef;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const lineGap = 2.0;

    void drawStaff(double topY) {
      for (int i = 0; i < 5; i++) {
        final y = topY + (i * lineGap);
        canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
      }
    }

    void drawClefProxy(core.ClefSymbol symbol, double topY) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: symbol.name.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(12, topY + (lineGap * 2) - (textPainter.height / 2)),
      );
    }

    if (layoutType == core.LayoutType.singleLine) {
      final staffTop = (size.height - (4 * lineGap)) / 2;
      drawStaff(staffTop);
      if (primaryClef != null) {
        drawClefProxy(primaryClef!, staffTop);
      }
    } else {
      // Double line (Piano)
      const totalHeight = (4 * lineGap) * 2 + 6.0; // two staffs + 6px gap
      final topStaffY = (size.height - totalHeight) / 2;
      final bottomStaffY = topStaffY + (4 * lineGap) + 6.0;

      // Draw brace proxy
      final bracePaint = Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      final bracePath = Path()
        ..moveTo(8, topStaffY)
        ..quadraticBezierTo(
            4, topStaffY + totalHeight / 2, 8, topStaffY + totalHeight);
      canvas.drawPath(bracePath, bracePaint);

      drawStaff(topStaffY);
      drawStaff(bottomStaffY);

      if (primaryClef != null) drawClefProxy(primaryClef!, topStaffY);
      if (secondaryClef != null) drawClefProxy(secondaryClef!, bottomStaffY);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniStaffPainter oldDelegate) {
    return oldDelegate.layoutType != layoutType ||
        oldDelegate.primaryClef != primaryClef ||
        oldDelegate.secondaryClef != secondaryClef ||
        oldDelegate.color != color;
  }
}
