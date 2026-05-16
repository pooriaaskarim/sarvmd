import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// A lightweight visual preview of a musical staff layout and clef.
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
    final color = active ? colorScheme.onSurface : colorScheme.onSurfaceVariant;

    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: _MiniStaffPainter(
        systemLayout: systemLayout,
        color: color,
      ),
    );
  }
}

class _MiniStaffPainter extends CustomPainter {
  _MiniStaffPainter({
    required this.systemLayout,
    required this.color,
  });

  final core.SystemLayout systemLayout;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const lineGap = 2.0;

    void drawStaff(double topY, int lines) {
      for (int i = 0; i < lines; i++) {
        final y = topY + (i * lineGap);
        canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
      }
    }

    void drawClefProxy(core.ClefSymbol symbol, double topY, int lines) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: symbol.name.toUpperCase(),
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final centerY = topY + ((lines - 1) * lineGap) / 2;
      textPainter.paint(
        canvas,
        Offset(12, centerY - (textPainter.height / 2)),
      );
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
          ..color = color
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        if (root.connector == core.SystemConnector.brace) {
          final bracePath = Path()
            ..moveTo(8, currentTopY)
            ..quadraticBezierTo(
                4, currentTopY + totalHeight / 2, 8, currentTopY + totalHeight);
          canvas.drawPath(bracePath, connectorPaint);
        } else {
          canvas.drawLine(Offset(8, currentTopY), Offset(8, currentTopY + totalHeight), connectorPaint);
          canvas.drawLine(Offset(8, currentTopY), Offset(10, currentTopY), connectorPaint);
          canvas.drawLine(Offset(8, currentTopY + totalHeight), Offset(10, currentTopY + totalHeight), connectorPaint);
        }
      }

      for (final staff in staves) {
        drawStaff(currentTopY, staff.lines);
        if (staff.clef != null) {
          drawClefProxy(staff.clef!.symbol, currentTopY, staff.lines);
        }
        currentTopY += (staff.lines > 0 ? staff.lines - 1 : 0) * lineGap + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniStaffPainter oldDelegate) {
    return oldDelegate.systemLayout != systemLayout ||
        oldDelegate.color != color;
  }
}
