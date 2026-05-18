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
      layout.config.effectiveWidth * lpmm,
      layout.config.effectiveHeight * lpmm,
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
    final rightMm = layout.config.effectiveWidth - layout.config.margins.right;

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
      canvas.drawLine(const Offset(0, -100000), Offset(0, size.height + 100000),
          guidePaint);
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

    for (var sysIdx = 0; sysIdx < layout.systems.length; sysIdx++) {
      final system = layout.systems[sysIdx];
      for (var sIdx = 0; sIdx < system.staves.length; sIdx++) {
        final staff = system.staves[sIdx];
        final topYPx = staff.topY * scale;

        // Staff bounding box guides
        if (viewNotifier.isGuideActive(GuideType.staffBounds)) {
          final boundsPaint = Paint()
            ..color = colorScheme.primary.withValues(alpha: 0.1)
            ..style = PaintingStyle.fill;

          final rect = Rect.fromLTRB(leftMm * scale, topYPx - (lineGapPx / 2),
              rightMm * scale, topYPx + staff.height * scale + (lineGapPx / 2));
          canvas.drawRect(rect, boundsPaint);
        }

        // Draw staff lines (Top line snapped, others relative for equal gaps)
        final topSnappedY = topYPx.roundToDouble();
        for (var i = 0; i < staff.lines; i++) {
          final y = topSnappedY + i * lineGapPx;
          canvas.drawLine(
            Offset(leftMm * scale, y),
            Offset(rightMm * scale, y),
            staffPaint,
          );
        }

        // ── Draw Clef ─────────────────────────────────────────
        final clef = staff.definition?.clef;

        if (clef != null) {
          final localScale = staff.scale;
          if (clef.symbol == core.ClefSymbol.tab) {
            _paintTabClef(canvas, leftMm * scale, topSnappedY, staff.lines,
                lineGapPx * localScale, inkColor,
                scale: localScale);
          } else if (clef.symbol == core.ClefSymbol.percussion) {
            _paintPercussionClef(canvas, leftMm * scale, topSnappedY,
                staff.lines, lineGapPx * localScale, inkColor,
                scale: localScale);
          } else {
            _paintStandardClef(canvas, clef, leftMm * scale, topSnappedY,
                staff.lines, lineGapPx * localScale, inkColor,
                scale: localScale);
          }
        }

        // ── Draw Instrument Name ──────────────────────────────
        final isLabelVisible = staff.definition?.labelVisible ?? true;
        if (isLabelVisible) {
          final isFirstSystem = sysIdx == 0;
          final String? name = isFirstSystem
              ? staff.definition?.instrumentName
              : (staff.definition?.instrumentAbbreviation ??
                  staff.definition?.instrumentName);

          if (name != null && name.isNotEmpty) {
            final double ptScale =
                scale / (96 / 25.4); // Points conversion scale
            final double fontSize =
                (staff.definition?.labelFontSize ?? 11.0) * ptScale;
            final bool italic = staff.definition?.labelItalic ?? true;
            final String fontFamily =
                staff.definition?.labelFontFamily == 'serif'
                    ? 'Noto Serif'
                    : 'Roboto';

            final namePainter = TextPainter(
              text: TextSpan(
                text: name,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: inkColor.withValues(alpha: 0.8),
                  fontFamily: fontFamily,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();

            final staffMidY = topSnappedY + (staff.height * scale) / 2;

            // Place label in the left margin area, 4mm from the staff.
            // Clamp to ensure it doesn't go off-page (min 2mm from edge).
            final double marginSpace = 4 * scale;
            final double minEdgePadding = 2 * scale;

            double nameX = (leftMm * scale) - namePainter.width - marginSpace;
            if (nameX < minEdgePadding) {
              nameX = minEdgePadding;
            }

            // Apply custom offsets
            final double hOffset =
                (staff.definition?.labelHorizontalOffset ?? 0.0) * ptScale;
            final double vOffset =
                (staff.definition?.labelVerticalOffset ?? 0.0) * ptScale;

            final nameY = staffMidY - namePainter.height / 2;
            namePainter.paint(canvas, Offset(nameX + hOffset, nameY + vOffset));
          }
        }
      }

      // ── Draw Connectors & Group Barlines ─────────────────
      // We iterate through all group placements to support nested brackets
      // and MOLA-compliant broken barlines.
      for (final group in system.groupPlacements) {
        final staves =
            system.staves.sublist(group.startStaffIdx, group.endStaffIdx + 1);
        if (staves.length < 1) continue;

        final topY = (staves.first.topY * scale).roundToDouble();
        final bottomY = (staves.last.topY * scale + staves.last.height * scale)
            .roundToDouble();

        // Offset connectors horizontally based on level to avoid overlap
        // Root group (level 0) is the outermost.
        final double xOffset = group.level * (4.0 * scale);
        final startX = (leftMm * scale).roundToDouble() - xOffset;

        final connectorPaint = Paint()
          ..color = inkColor
          ..strokeWidth = thicknessPx * 1.5
          ..style = PaintingStyle.stroke;

        // 1. Draw Group Barline (Continuous within group if enabled)
        // MOLA: Barlines break between instrument families.
        if (group.continuousBarlines && staves.length > 1) {
          canvas.drawLine(
            Offset(startX, topY),
            Offset(startX, bottomY),
            connectorPaint
              ..strokeWidth = thicknessPx * 2.5, // Bolder for system start
          );
        } else if (!group.continuousBarlines) {
          // For groups with broken barlines, we still need a small segment for each staff
          for (final staff in staves) {
            final sTop = (staff.topY * scale).roundToDouble();
            final sBottom =
                (staff.topY * scale + staff.height * scale).roundToDouble();
            canvas.drawLine(
              Offset(startX, sTop),
              Offset(startX, sBottom),
              connectorPaint..strokeWidth = thicknessPx * 2.5,
            );
          }
        }

        // 2. Draw Connector (Bracket/Brace)
        if (group.connector == core.SystemConnector.brace &&
            staves.length >= 2) {
          _paintBrace(canvas, startX, topY, bottomY, scale, inkColor);
        } else if (group.connector == core.SystemConnector.bracket &&
            staves.length >= 2) {
          final bracketPaint = Paint()
            ..color = inkColor
            ..strokeWidth = thicknessPx * 3.0
            ..style = PaintingStyle.stroke;

          canvas.drawLine(
              Offset(startX, topY), Offset(startX, bottomY), bracketPaint);

          final tickLen = 2.0 * scale;
          canvas.drawLine(Offset(startX, topY), Offset(startX + tickLen, topY),
              bracketPaint);
          canvas.drawLine(Offset(startX, bottomY),
              Offset(startX + tickLen, bottomY), bracketPaint);
        }
      }
    }
  }

  void _paintStandardClef(Canvas canvas, core.ClefConfig clef, double x,
      double topY, int lines, double gap, Color color,
      {double scale = 1.0}) {
    const fontScale = 4.0;
    final (String glyph, double anchorSp) = switch (clef.symbol) {
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
          fontSize: gap * fontScale, // Gap is already pre-scaled
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baselineDelta =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);

    // Anchor is relative to the bottom line usually, but clef.anchorLine is 1-indexed from bottom
    final anchorYPx = topY + (lines - clef.anchorLine) * gap;
    final baselineY = anchorYPx + anchorSp * gap;
    final microOffset = gap * 0.04;

    final glyphX = x + gap * 0.15;
    final glyphY = baselineY - baselineDelta + microOffset;

    tp.paint(canvas, Offset(glyphX.roundToDouble(), glyphY.roundToDouble()));
  }

  void _paintTabClef(
      Canvas canvas, double x, double topY, int lines, double gap, Color color,
      {double scale = 1.0}) {
    final staffHeight = (lines - 1) * gap;
    final centerY = topY + staffHeight / 2;

    // Standard visual padding matching standard clefs
    final startX = x + gap * 0.5;

    // Use a high-fidelity Serif font for authentic engraving
    final fontSize = gap * 1.5;
    final textStyle = TextStyle(
      fontFamily: 'Noto Serif',
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      color: color,
      height: 0.8,
    );

    final List<String> letters = ['T', 'A', 'B'];
    double currentY = centerY - (fontSize * 1.5 * 0.8);

    for (final char in letters) {
      final tp = TextPainter(
        text: TextSpan(text: char, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(startX, currentY));
      currentY += fontSize * 0.8;
    }
  }

  void _paintPercussionClef(
      Canvas canvas, double x, double topY, int lines, double gap, Color color,
      {double scale = 1.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = gap * 0.35;
    final barHeight = gap * 2.0;

    final staffHeight = (lines - 1) * gap;
    final centerY = topY + staffHeight / 2;

    // Standard visual padding matching standard clefs
    final leftX = x + gap * 0.5;

    // Space between the two bars is exactly one bar width
    final rect1 = Rect.fromCenter(
        center: Offset(leftX + barWidth / 2, centerY),
        width: barWidth,
        height: barHeight);
    final rect2 = Rect.fromCenter(
        center: Offset(leftX + barWidth * 2.5, centerY),
        width: barWidth,
        height: barHeight);

    canvas.drawRect(rect1, paint);
    canvas.drawRect(rect2, paint);
  }

  void _paintBrace(Canvas canvas, double x, double topY, double bottomY,
      double scale, Color color) {
    final double h = bottomY - topY;
    final double w = (h * 0.12).clamp(6.0 * scale, 30.0 * scale);
    final double mid = (topY + bottomY) / 2;

    final path = Path();
    // Start at top tip
    path.moveTo(x, topY);

    // Outer edge (the left-most curve with the sharp beak)
    path.cubicTo(x - w * 0.1, topY + h * 0.05, x - w * 0.9, mid - h * 0.15,
        x - w, mid // THE BEAK POINT
        );
    path.cubicTo(x - w * 0.9, mid + h * 0.15, x - w * 0.1, bottomY - h * 0.05,
        x, bottomY);

    // Inner edge (the right-side curve that creates the calligraphic width)
    // Tapers back up to the tips
    path.cubicTo(x - w * 0.15, bottomY - h * 0.08, x - w * 0.65, mid + h * 0.1,
        x - w * 0.65, mid);
    path.cubicTo(
        x - w * 0.65, mid - h * 0.1, x - w * 0.15, topY + h * 0.08, x, topY);

    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ManuscriptPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.scale != scale ||
        oldDelegate.viewNotifier != viewNotifier;
  }
}
