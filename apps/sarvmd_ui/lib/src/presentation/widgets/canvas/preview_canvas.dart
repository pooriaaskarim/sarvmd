import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../logic/view/view_state.dart';
import '../../../logic/sample/sample_score.dart';
import 'dart:math' as math;

class PreviewCanvas extends StatelessWidget {
  const PreviewCanvas({
    super.key,
    required this.layout,
    required this.viewState,
  });

  final core.PageLayout layout;
  final ViewState viewState;

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
      child: CustomPaint(
        size: sizePx,
        painter: _ManuscriptPainter(
          layout: layout,
          scale: lpmm,
          viewState: viewState,
          colorScheme: Theme.of(context).colorScheme,
          inkColor: inkColor,
        ),
      ),
    );
  }
}

class _ManuscriptPainter extends CustomPainter {
  _ManuscriptPainter({
    required this.layout,
    required this.scale,
    required this.viewState,
    required this.colorScheme,
    required this.inkColor,
  });

  final core.PageLayout layout;
  final double scale;
  final ViewState viewState;
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
    if (viewState.isGuideActive(GuideType.paperEdges)) {
      canvas.drawLine(
          const Offset(-100000, 0), Offset(size.width + 100000, 0), guidePaint);
      canvas.drawLine(Offset(-100000, size.height),
          Offset(size.width + 100000, size.height), guidePaint);
      canvas.drawLine(const Offset(0, -100000), Offset(0, size.height + 100000),
          guidePaint);
      canvas.drawLine(Offset(size.width, -100000),
          Offset(size.width, size.height + 100000), guidePaint);
    }

    if (viewState.isGuideActive(GuideType.paperCenters)) {
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      canvas.drawLine(Offset(centerX, -100000),
          Offset(centerX, size.height + 100000), guidePaint);
      canvas.drawLine(Offset(-100000, centerY),
          Offset(size.width + 100000, centerY), guidePaint);
    }

    // Margin guides
    if (viewState.isGuideActive(GuideType.margins)) {
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

    // Active Scrubbing Margin Guide Overlay HUD
    final activeScrub = viewState.activeScrubbingMargin;
    if (activeScrub != null) {
      final double marginLeft = layout.config.margins.left * scale;
      final double marginRight =
          size.width - layout.config.margins.right * scale;
      final double marginTop = layout.config.margins.top * scale;
      final double marginBottom =
          size.height - layout.config.margins.bottom * scale;

      if (activeScrub == 'left' || activeScrub == 'horizontal') {
        _drawScrubHUD(
          canvas,
          size,
          'left',
          'Left: ${layout.config.margins.left.toStringAsFixed(1)} mm',
          marginLeft,
          true,
        );
      }
      if (activeScrub == 'right' || activeScrub == 'horizontal') {
        _drawScrubHUD(
          canvas,
          size,
          'right',
          'Right: ${layout.config.margins.right.toStringAsFixed(1)} mm',
          marginRight,
          true,
        );
      }
      if (activeScrub == 'top' || activeScrub == 'vertical') {
        _drawScrubHUD(
          canvas,
          size,
          'top',
          'Top: ${layout.config.margins.top.toStringAsFixed(1)} mm',
          marginTop,
          false,
        );
      }
      if (activeScrub == 'bottom' || activeScrub == 'vertical') {
        _drawScrubHUD(
          canvas,
          size,
          'bottom',
          'Bottom: ${layout.config.margins.bottom.toStringAsFixed(1)} mm',
          marginBottom,
          false,
        );
      }
    }

    for (var sysIdx = 0; sysIdx < layout.systems.length; sysIdx++) {
      final system = layout.systems[sysIdx];
      final systemLeftMm = leftMm + system.leftIndentMm;

      // Pre-calculate the system's optimal maximum split word length
      int systemMaxSplitLength = 0;
      for (final staff in system.staves) {
        final def = staff.definition;
        if (def != null && def.labelVisible) {
          final String label = sysIdx == 0
              ? (def.instrumentName ?? '')
              : (def.instrumentAbbreviation ?? def.instrumentName ?? '');
          if (label.isNotEmpty) {
            int maxWordLength = 0;
            for (final word in label.split(' ')) {
              if (word.length > maxWordLength) {
                maxWordLength = word.length;
              }
            }
            if (maxWordLength > systemMaxSplitLength) {
              systemMaxSplitLength = maxWordLength;
            }
          }
        }
      }

      for (var sIdx = 0; sIdx < system.staves.length; sIdx++) {
        final staff = system.staves[sIdx];
        final topYPx = staff.topY * scale;

        // Staff bounding box guides
        if (viewState.isGuideActive(GuideType.staffBounds)) {
          final boundsPaint = Paint()
            ..color = colorScheme.primary.withValues(alpha: 0.1)
            ..style = PaintingStyle.fill;

          final rect = Rect.fromLTRB(systemLeftMm * scale, topYPx - (lineGapPx / 2),
              rightMm * scale, topYPx + staff.height * scale + (lineGapPx / 2));
          canvas.drawRect(rect, boundsPaint);
        }

        // Draw staff lines (Top line snapped, others relative for equal gaps)
        final topSnappedY = topYPx.roundToDouble();
        for (var i = 0; i < staff.lines; i++) {
          final y = topSnappedY + i * lineGapPx;
          canvas.drawLine(
            Offset(systemLeftMm * scale, y),
            Offset(rightMm * scale, y),
            staffPaint,
          );
        }

        // ── Draw Clef ─────────────────────────────────────────
        final clef = staff.definition?.clef;

        if (clef != null) {
          final localScale = staff.scale;
          if (clef.symbol == core.ClefSymbol.tab) {
            _paintTabClef(canvas, systemLeftMm * scale, topSnappedY, staff.lines,
                lineGapPx * localScale, inkColor,
                scale: localScale);
          } else if (clef.symbol == core.ClefSymbol.percussion) {
            _paintPercussionClef(canvas, systemLeftMm * scale, topSnappedY,
                staff.lines, lineGapPx * localScale, inkColor,
                scale: localScale);
          } else {
            _paintStandardClef(canvas, clef, systemLeftMm * scale, topSnappedY,
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
            // Only wrap if name length is longer than the systemMaxSplitLength (which represents the optimal split indent)
            final formattedName = name.length > systemMaxSplitLength
                ? name.replaceAll(' ', '\n')
                : name;
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
                text: formattedName,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: inkColor.withValues(alpha: 0.8),
                  fontFamily: fontFamily,
                  fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              textAlign: TextAlign.right, // Always right-align multi-line text
              textDirection: TextDirection.ltr,
            )..layout();

            final staffMidY = topSnappedY + (staff.height * scale) / 2;

            // Place label in the left margin area, dynamically computing leftmost layout boundary
            final double marginSpace = 4 * scale;
            final double minEdgePadding = 2 * scale;

            double leftmostLayoutX = systemLeftMm * scale;
            for (final group in system.groupPlacements) {
              if (sIdx >= group.startStaffIdx && sIdx <= group.endStaffIdx) {
                final double xOffset = group.level * (4.0 * scale);
                final double startX =
                    (systemLeftMm * scale).roundToDouble() - xOffset;

                double boundary = startX;
                if (group.connector == core.SystemConnector.brace &&
                    (group.endStaffIdx - group.startStaffIdx + 1) >= 2) {
                  final groupStaves = system.staves
                      .sublist(group.startStaffIdx, group.endStaffIdx + 1);
                  final double gTopY =
                      (groupStaves.first.topY * scale).roundToDouble();
                  final double gBottomY = (groupStaves.last.topY * scale +
                          groupStaves.last.height * scale)
                      .roundToDouble();
                  final double h = gBottomY - gTopY;
                  final double w = (h * 0.12).clamp(6.0 * scale, 30.0 * scale);
                  boundary -= w;
                }
                leftmostLayoutX = math.min(leftmostLayoutX, boundary);
              }
            }

            final double availableWidth =
                leftmostLayoutX - marginSpace - minEdgePadding;

            if (namePainter.width > availableWidth) {
              final double finalMaxWidth = math.max(availableWidth, 10.0);
              namePainter.textAlign = TextAlign.right;
              namePainter.layout(maxWidth: finalMaxWidth);
            }

            double nameX = leftmostLayoutX - namePainter.width - marginSpace;
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
        final startX = (systemLeftMm * scale).roundToDouble() - xOffset;

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

    if (viewState.showNotation) {
      final score = createSampleScore(layout.config);
      final engravingLayout = core.Engraver.compile(score, layout.config);
      if (engravingLayout.pages.isNotEmpty) {
        final page = engravingLayout.pages.first;
        for (final element in page.elements) {
          _paintPositionedElement(canvas, element, lineGapPx, inkColor);
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
    // Bravura U+E000: yMin=0 (baseline = bottom tip), yMax=997 (top tip), em=1000.
    // fontSize chosen so that 997 font-units = h pixels.
    final double fontSize = h * (1000.0 / 997.0);

    final tp = TextPainter(
      text: TextSpan(
        text: '\u{E000}',
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // The baseline (y=0 in glyph space = bottom tip of brace) must land at bottomY.
    // computeDistanceToActualBaseline gives distance from the top-left of the
    // painted rect to the alphabetic baseline.
    final double baselineOffset =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final double paintY = bottomY - baselineOffset;

    // Right-align: the glyph's right visual edge (82/84 of advance) lands at x.
    // tp.width is the advance width; LSB=2 and RSB=2 out of 84 units.
    final double paintX = x - tp.width * (82.0 / 84.0);

    tp.paint(canvas, Offset(paintX, paintY));
  }

  void _paintPositionedElement(
      Canvas canvas, core.PositionedElement elem, double gap, Color color) {
    if (elem is core.PositionedNote) {
      final x = elem.x * scale;
      final y = elem.y * scale;
      final rx = 0.59 * gap * elem.scale;
      final ry = 0.40 * gap * elem.scale;

      // Draw ledger lines
      final ledgerPaint = Paint()
        ..color = color
        ..strokeWidth = 0.12 * gap
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final ledgerY in elem.ledgerLineYs) {
        final len = gap * 1.6 * elem.scale;
        final ly = ledgerY * scale;
        canvas.drawLine(
          Offset(x - len / 2, ly),
          Offset(x + len / 2, ly),
          ledgerPaint,
        );
      }

      // Draw notehead (rotated oval by -20 degrees)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-20 * math.pi / 180);

      final rect = Rect.fromLTRB(-rx, -ry, rx, ry);
      if (elem.glyph == core.SmuflGlyph.noteheadBlack) {
        canvas.drawOval(
            rect,
            Paint()
              ..color = color
              ..style = PaintingStyle.fill);
      } else if (elem.glyph == core.SmuflGlyph.noteheadHalf) {
        canvas.drawOval(
            rect,
            Paint()
              ..color = color
              ..strokeWidth = 0.18 * gap
              ..style = PaintingStyle.stroke);
      } else if (elem.glyph == core.SmuflGlyph.noteheadWhole) {
        final wholeRect =
            Rect.fromLTRB(-rx * 1.3, -ry * 1.1, rx * 1.3, ry * 1.1);
        canvas.drawOval(
            wholeRect,
            Paint()
              ..color = color
              ..strokeWidth = 0.18 * gap
              ..style = PaintingStyle.stroke);
      }
      canvas.restore();

      // Draw stem
      if (elem.hasStem) {
        final stemLen = elem.stemLengthSp * gap * elem.scale;
        final stemThickness = 0.11 * gap * elem.scale;
        final stemX = elem.stemUp ? x + rx * 0.95 : x - rx * 0.95;
        final stemEndY = elem.stemUp ? y - stemLen : y + stemLen;

        canvas.drawLine(
          Offset(stemX, y),
          Offset(stemX, stemEndY),
          Paint()
            ..color = color
            ..strokeWidth = stemThickness
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );

        // Draw flag if present
        if (elem.flagGlyph != null) {
          final tp = TextPainter(
            text: TextSpan(
              text: elem.flagGlyph!.codepoint,
              style: TextStyle(
                fontFamily: 'NotoMusic',
                fontSize: gap * 4.0 * elem.scale,
                color: color,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final baselineDelta =
              tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);

          final double flagX = stemX;
          final double flagY = elem.stemUp
              ? stemEndY - baselineDelta + gap * 0.1
              : stemEndY - baselineDelta - gap * 0.1;
          tp.paint(canvas, Offset(flagX, flagY));
        }
      }
    } else if (elem is core.PositionedRest) {
      final x = elem.x * scale;
      final y = elem.y * scale;

      if (elem.glyph == core.SmuflGlyph.restWhole) {
        // Hangs below staff line
        canvas.drawRect(
          Rect.fromLTWH(x - 0.5 * gap * elem.scale, y, 1.0 * gap * elem.scale,
              0.6 * gap * elem.scale),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      } else if (elem.glyph == core.SmuflGlyph.restHalf) {
        // Sits on top of staff line
        canvas.drawRect(
          Rect.fromLTWH(x - 0.5 * gap * elem.scale, y - 0.6 * gap * elem.scale,
              1.0 * gap * elem.scale, 0.6 * gap * elem.scale),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      } else {
        // Other rests (quarter, eighth, sixteenth)
        final tp = TextPainter(
          text: TextSpan(
            text: elem.glyph.codepoint,
            style: TextStyle(
              fontFamily: 'NotoMusic',
              fontSize: gap * 4.0 * elem.scale,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final baselineDelta =
            tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);

        final double glyphX = x - tp.width / 2;
        final double baselineY = y + 1.0 * gap * elem.scale;
        final double glyphY = baselineY - baselineDelta;

        tp.paint(canvas, Offset(glyphX, glyphY));
      }
    } else if (elem is core.PositionedBarline) {
      canvas.drawLine(
        Offset(elem.x * scale, elem.topY * scale),
        Offset(elem.x * scale, elem.bottomY * scale),
        Paint()
          ..color = color
          ..strokeWidth = elem.thicknessMm * scale
          ..style = PaintingStyle.stroke,
      );
    } else if (elem is core.PositionedClef) {
      final anchorSp = switch (elem.glyph) {
        core.SmuflGlyph.gClef => 0.876,
        core.SmuflGlyph.cClef => 2.0,
        core.SmuflGlyph.fClef => 2.578,
        core.SmuflGlyph.tabClef => 0.0,
        core.SmuflGlyph.percussionClef => 1.0,
        _ => 0.0,
      };

      final tp = TextPainter(
        text: TextSpan(
          text: elem.glyph.codepoint,
          style: TextStyle(
            fontFamily: 'NotoMusic',
            fontSize: gap * 4.0 * elem.scale,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final baselineDelta =
          tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);

      final anchorYPx = elem.y * scale;
      final baselineY = anchorYPx + anchorSp * gap * elem.scale;
      final microOffset = gap * elem.scale * 0.04;

      final glyphX = elem.x * scale + gap * elem.scale * 0.15;
      final glyphY = baselineY - baselineDelta + microOffset;

      tp.paint(canvas, Offset(glyphX, glyphY));
    } else if (elem is core.PositionedTimeSignature) {
      final textStyle = TextStyle(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.bold,
        fontSize: gap * 2.0 * elem.scale,
        color: color,
        height: 1.0,
      );

      final numPainter = TextPainter(
        text: TextSpan(text: '${elem.beats}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final denPainter = TextPainter(
        text: TextSpan(text: '${elem.beatValue}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final double xPx = elem.x * scale;
      final double yPx = elem.y * scale;

      final numX = xPx - numPainter.width / 2;
      final numY = yPx - 1.0 * gap * elem.scale - numPainter.height / 2;

      final denX = xPx - denPainter.width / 2;
      final denY = yPx + 1.0 * gap * elem.scale - denPainter.height / 2;

      numPainter.paint(canvas, Offset(numX, numY));
      denPainter.paint(canvas, Offset(denX, denY));
    } else if (elem is core.PositionedKeySignature) {
      for (var i = 0; i < elem.accidentals.length; i++) {
        final accidental = elem.accidentals[i];
        final tp = TextPainter(
          text: TextSpan(
            text: accidental.glyph.codepoint,
            style: TextStyle(
              fontFamily: 'NotoMusic',
              fontSize: gap * 4.0 * elem.scale,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final baselineDelta =
            tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);

        final ax = elem.x * scale + i * gap * elem.scale * 0.8;
        final ay = accidental.y * scale;
        final glyphY = ay - baselineDelta + gap * elem.scale * 1.0;

        tp.paint(canvas, Offset(ax, glyphY));
      }
    }
  }

  void _drawScrubHUD(Canvas canvas, Size size, String side, String label,
      double linePositionValue, bool isVerticalLine) {
    final activeColor = colorScheme.primary;

    // 1. Draw prominent highlighted guide line
    final highlightPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (isVerticalLine) {
      canvas.drawLine(
        Offset(linePositionValue, 0),
        Offset(linePositionValue, size.height),
        highlightPaint,
      );
    } else {
      canvas.drawLine(
        Offset(0, linePositionValue),
        Offset(size.width, linePositionValue),
        highlightPaint,
      );
    }

    // 2. Configure text painter for the metric label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // 3. Determine positioning of the floating bubble
    final double paddingHorizontal = 8.0;
    final double paddingVertical = 4.0;
    final double bubbleWidth = textPainter.width + paddingHorizontal * 2;
    final double bubbleHeight = textPainter.height + paddingVertical * 2;

    double bubbleX = 0.0;
    double bubbleY = 0.0;

    if (isVerticalLine) {
      bubbleY = size.height / 2 - bubbleHeight / 2;
      if (side == 'left') {
        bubbleX = linePositionValue + 12;
      } else {
        bubbleX = linePositionValue - 12 - bubbleWidth;
      }
    } else {
      bubbleX = size.width / 2 - bubbleWidth / 2;
      if (side == 'top') {
        bubbleY = linePositionValue + 12;
      } else {
        bubbleY = linePositionValue - 12 - bubbleHeight;
      }
    }

    // Keep bubble inside page bounds
    bubbleX = bubbleX.clamp(4.0, size.width - bubbleWidth - 4.0);
    bubbleY = bubbleY.clamp(4.0, size.height - bubbleHeight - 4.0);

    // 4. Draw rounded rectangle background with shadow
    final bgPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleX, bubbleY, bubbleWidth, bubbleHeight),
      const Radius.circular(6.0),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleX, bubbleY + 1.5, bubbleWidth, bubbleHeight),
        const Radius.circular(6.0),
      ),
      shadowPaint,
    );

    canvas.drawRRect(pillRect, bgPaint);

    // 5. Paint text centered inside the pill
    textPainter.paint(
      canvas,
      Offset(
        bubbleX + paddingHorizontal,
        bubbleY + paddingVertical,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ManuscriptPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.scale != scale ||
        oldDelegate.viewState != viewState;
  }
}
