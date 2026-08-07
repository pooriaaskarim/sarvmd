// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// LaTeX emitter — generates `.tex` source using `\pdfliteral direct` for
/// drawing.
///
/// All coordinates use PDF big points (bp): 1 bp = 1/72 inch ≈ 0.3528 mm.
/// The PDF coordinate origin is at the bottom-left of the page.
/// Using `\pdfliteral direct` writes operators directly into the page content
/// stream using absolute page coordinates.

import 'config.dart';
import 'engraving_config.dart';
import 'layout.dart';
import 'domain/smufl.dart';
import 'layout/positioned_element.dart';
import 'layout/engraver.dart';

/// Millimeters to PDF big points.
double _mmToBp(double mm) => mm * 72.0 / 25.4;

/// Format a double to 3 decimal places for PDF operators.
String _f(double v) => v.toStringAsFixed(3);

/// Emit a complete `.tex` document string for a blank manuscript layout.
String emit(PageConfig config, PageLayout layout, {int pageCount = 1}) {
  final buf = StringBuffer();

  final pageW = config.effectiveWidth;
  final pageH = config.effectiveHeight;

  // Document preamble.
  buf.writeln(r'\documentclass{article}');
  buf.writeln(
    '\\usepackage[paperwidth=${pageW}mm,paperheight=${pageH}mm,'
    'margin=0mm]{geometry}',
  );
  buf.writeln(r'\pagestyle{empty}');
  buf.writeln(r'\begin{document}');
  buf.writeln(r'\null'); // Ensure the page is shipped out.

  final draw = StringBuffer();
  draw.writeln('q'); // Save graphics state.

  final lineW = config.staffConfig.lineThicknessPt;
  draw.writeln('$lineW w'); // Set line width in points.
  draw.writeln('0 G'); // Black stroke color.

  final staffLeftBp = _mmToBp(config.margins.left);
  final staffRightBp = _mmToBp(pageW - config.margins.right);
  final pageHBp = _mmToBp(pageH);
  final lineGapBp = _mmToBp(config.staffConfig.lineGapMm);

  // Draw each system.
  for (final system in layout.systems) {
    for (final staff in system.staves) {
      final topLinePdfY = pageHBp - _mmToBp(staff.topY);
      for (var line = 0; line < staff.lines; line++) {
        final y = topLinePdfY - line * lineGapBp;
        draw.writeln(
          '${_f(staffLeftBp)} ${_f(y)} m ${_f(staffRightBp)} ${_f(y)} l S',
        );
      }
    }

    // Draw system barline if layout specifies it.
    final connector = config.systemLayout.rootGroup.connector;
    if (connector != SystemConnector.none && system.staves.length > 1) {
      final sysTopPdfY = pageHBp - _mmToBp(system.staves.first.topY);
      final sysBottomPdfY = pageHBp -
          _mmToBp(system.staves.last.topY + system.staves.last.height);

      final bool useBrace = connector == SystemConnector.brace;

      draw.writeln('${_f(lineW * 2.5)} w');
      draw.writeln(
        '${_f(staffLeftBp)} ${_f(sysTopPdfY)} m '
        '${_f(staffLeftBp)} ${_f(sysBottomPdfY)} l S',
      );

      if (useBrace) {
        // Render the standard piano brace using the Bravura path (U+E000).
        // The path is defined in a 1000-unit em; yMin=0, yMax=997.
        // Scale so the glyph height = sysTopPdfY - sysBottomPdfY (in PDF coords
        // Y increases upward, so topPdfY > bottomPdfY).
        final double braceH = sysTopPdfY - sysBottomPdfY; // positive value
        final double scale = braceH / 997.0;
        // Glyph origin (0,0) maps to sysBottomPdfY; translate left so the glyph
        // right edge (x≈82 units) aligns with staffLeftBp.
        final double tx = staffLeftBp - scale * 82.0;
        final double ty = sysBottomPdfY;
        draw.writeln('q ${_f(scale)} 0 0 ${_f(scale)} ${_f(tx)} ${_f(ty)} cm');
        draw.writeln('0 g');
        draw.writeln('$_bracePdf Q');
      } else {
        // Draw bracket "ticks"
        final tickLenBp = _mmToBp(2.0);
        draw.writeln(
          '${_f(staffLeftBp)} ${_f(sysTopPdfY)} m '
          '${_f(staffLeftBp + tickLenBp)} ${_f(sysTopPdfY)} l S',
        );
        draw.writeln(
          '${_f(staffLeftBp)} ${_f(sysBottomPdfY)} m '
          '${_f(staffLeftBp + tickLenBp)} ${_f(sysBottomPdfY)} l S',
        );
      }
      // Reset width for clefs/lines
      draw.writeln('$lineW w');
    }

    // Clefs.
    for (var i = 0; i < system.staves.length; i++) {
      final staff = system.staves[i];
      final clef = staff.definition?.clef;

      if (clef != null) {
        final topLinePdfY = pageHBp - _mmToBp(staff.topY);
        final anchorPdfY = topLinePdfY -
            (staff.lines - clef.anchorLine) * lineGapBp * staff.scale;

        final anchorSp = (clef.symbol == ClefSymbol.percussion && staff.lines > 1)
            ? 1.0
            : 0.0;

        // For TAB, we want it to span the full staff height
        final displayGaps = (clef.symbol == ClefSymbol.tab)
            ? (staff.lines > 0 ? staff.lines - 1 : 1).toDouble() * staff.scale
            : 4.0 * staff.scale;

        // If TAB, force anchor to bottom line for simplicity in scaling
        final effectiveAnchorPdfY = (clef.symbol == ClefSymbol.tab)
            ? (topLinePdfY - (staff.lines - 1) * lineGapBp)
            : anchorPdfY;

        final baselinePdfY =
            effectiveAnchorPdfY - anchorSp * lineGapBp * staff.scale;
        final cx = staffLeftBp + lineGapBp * config.engraving.initialClefClearanceSp;

        final (String path, double upem) = switch (clef.symbol) {
          ClefSymbol.g => (_gClefPdf, 1000.0),
          ClefSymbol.c => (_cClefPdf, 1000.0),
          ClefSymbol.f => (_fClefPdf, 1000.0),
          ClefSymbol.tab => (_tabClefPdf, 1000.0),
          ClefSymbol.percussion => (_percClefPdf, 1000.0),
        };

        final scale = (lineGapBp * displayGaps) / upem;
        draw.writeln(
            'q ${_f(scale)} 0 0 ${_f(scale)} ${_f(cx)} ${_f(baselinePdfY)} cm');
        draw.writeln('0 g');
        draw.writeln('$path Q');
      }
    }
  }

  draw.writeln('Q');

  final pageLiteral = '\\pdfliteral direct {${draw.toString()}}';
  final count = pageCount < 1 ? 1 : pageCount;
  for (var i = 0; i < count; i++) {
    if (i > 0) {
      buf.writeln(r'\newpage');
      buf.writeln(r'\null');
    }
    buf.writeln(pageLiteral);
  }
  buf.writeln(r'\end{document}');

  return buf.toString();
}

/// Emit a complete standalone LaTeX `.tex` document string for an engraved, compiled page.
String emitCompiled(PageConfig config, EngravingPage page) {
  final buf = StringBuffer();

  final pageW = config.effectiveWidth;
  final pageH = config.effectiveHeight;

  // Document preamble.
  buf.writeln(r'\documentclass{article}');
  buf.writeln(
    '\\usepackage[paperwidth=${pageW}mm,paperheight=${pageH}mm,'
    'margin=0mm]{geometry}',
  );
  buf.writeln(r'\pagestyle{empty}');
  buf.writeln(r'\begin{document}');
  buf.writeln(r'\null'); // Ensure the page is shipped out.

  final draw = StringBuffer();
  draw.writeln('q'); // Save graphics state.

  final lineW = config.staffConfig.lineThicknessPt;
  draw.writeln('$lineW w'); // Set line width in points.
  draw.writeln('0 G'); // Black stroke color.

  final staffLeftBp = _mmToBp(config.margins.left);
  final staffRightBp = _mmToBp(pageW - config.margins.right);
  final pageHBp = _mmToBp(pageH);
  final lineGapBp = _mmToBp(config.staffConfig.lineGapMm);

  // 1. Draw physical staff lines
  for (final system in page.pageLayout.systems) {
    for (final staff in system.staves) {
      final topLinePdfY = pageHBp - _mmToBp(staff.topY);
      for (var line = 0; line < staff.lines; line++) {
        final y = topLinePdfY - line * lineGapBp;
        draw.writeln(
          '${_f(staffLeftBp)} ${_f(y)} m ${_f(staffRightBp)} ${_f(y)} l S',
        );
      }
    }
  }

  // 2. Draw all compiled positioned notation elements
  for (final element in page.elements) {
    draw.write(_drawElementPdf(element, pageHBp, lineGapBp, config.engraving));
  }

  draw.writeln('Q');

  buf.writeln('\\pdfliteral direct {${draw.toString()}}');
  buf.writeln(r'\end{document}');

  return buf.toString();
}

/// Helper method to serialize a [PositionedElement] to PDF operators.
String _drawElementPdf(PositionedElement elem, double pageHBp, double gapBp, EngravingConfig config) {
  final buf = StringBuffer();
  final scale = elem.scale;

  if (elem is PositionedNote) {
    final xBp = _mmToBp(elem.x);
    final yBp = pageHBp - _mmToBp(elem.y);
    final rxBp = 0.59 * gapBp * scale;
    final ryBp = 0.40 * gapBp * scale;

    // Draw ledger lines
    buf.writeln('0 G');
    buf.writeln('${_f(0.12 * gapBp)} w');
    for (final ledgerY in elem.ledgerLineYs) {
      final ledgerYBp = pageHBp - _mmToBp(ledgerY);
      final len = gapBp * 1.6 * scale;
      buf.writeln(
        '${_f(xBp - len / 2)} ${_f(ledgerYBp)} m ${_f(xBp + len / 2)} ${_f(ledgerYBp)} l S'
      );
    }

    // Draw notehead (tilted ellipse via graphics matrix rotation)
    buf.writeln('q');
    // Rotate -20 degrees: cos(-20) = 0.9397, sin(-20) = -0.3420
    final a = rxBp * 0.9397;
    final b = rxBp * (-0.3420);
    final c = -ryBp * (-0.3420);
    final d = ryBp * 0.9397;
    buf.writeln('${_f(a)} ${_f(b)} ${_f(c)} ${_f(d)} ${_f(xBp)} ${_f(yBp)} cm');

    // Unit circle Bezier path (centered at origin)
    final circlePath =
        '1 0 m 1 0.552 0.552 1 0 1 c -0.552 1 -1 0.552 -1 0 c -1 -0.552 -0.552 -1 0 -1 c 0.552 -1 1 -0.552 1 0 c h';
    if (elem.glyph == SmuflGlyph.noteheadBlack) {
      buf.writeln('0 g');
      buf.writeln('$circlePath f');
    } else {
      buf.writeln('0 G');
      buf.writeln('${_f(0.18 * gapBp / rxBp)} w'); // Normalize stroke width
      buf.writeln('$circlePath S');
    }
    buf.writeln('Q');

    // Draw stem
    if (elem.hasStem) {
      final stemLenBp = elem.stemLengthSp * gapBp * scale;
      final stemX = elem.stemUp ? xBp + rxBp * 0.95 : xBp - rxBp * 0.95;
      final stemEndY = elem.stemUp ? yBp + stemLenBp : yBp - stemLenBp; // Y goes up

      buf.writeln('0 G');
      buf.writeln('${_f(0.11 * gapBp * scale)} w');
      buf.writeln('${_f(stemX)} ${_f(yBp)} m ${_f(stemX)} ${_f(stemEndY)} l S');

      // Draw flag if present
      if (elem.flagGlyph != null) {
        final flagPath = (elem.flagGlyph == SmuflGlyph.flag8thUp || elem.flagGlyph == SmuflGlyph.flag8thDown)
            ? _flag8thPdf
            : _flag16thPdf;
        
        final flagScale = gapBp * config.smuflGlyphScale * scale;
        final flagScaleY = elem.stemUp ? -flagScale : flagScale;

        buf.writeln('q');
        buf.writeln(
          '${_f(flagScale)} 0 0 ${_f(flagScaleY)} ${_f(stemX)} ${_f(stemEndY)} cm'
        );
        buf.writeln('0 g');
        buf.writeln('$flagPath Q');
      }
    }
  } else if (elem is PositionedRest) {
    final xBp = _mmToBp(elem.x);
    final yBp = pageHBp - _mmToBp(elem.y);

    if (elem.glyph == SmuflGlyph.restWhole) {
      buf.writeln('0 g');
      buf.writeln(
        '${_f(xBp - 0.5 * gapBp * scale)} ${_f(yBp - 0.6 * gapBp * scale)} '
        '${_f(1.0 * gapBp * scale)} ${_f(0.6 * gapBp * scale)} re f'
      );
    } else if (elem.glyph == SmuflGlyph.restHalf) {
      buf.writeln('0 g');
      buf.writeln(
        '${_f(xBp - 0.5 * gapBp * scale)} ${_f(yBp)} '
        '${_f(1.0 * gapBp * scale)} ${_f(0.6 * gapBp * scale)} re f'
      );
    } else {
      final restPath = switch (elem.glyph) {
        SmuflGlyph.restQuarter => _quarterRestPdf,
        SmuflGlyph.restEighth => _eighthRestPdf,
        SmuflGlyph.restSixteenth => _sixteenthRestPdf,
        _ => _quarterRestPdf,
      };
      
      final s = gapBp * config.smuflGlyphScale * scale;
      buf.writeln('q');
      buf.writeln('$s 0 0 $s ${_f(xBp)} ${_f(yBp)} cm');
      buf.writeln('0 g');
      buf.writeln('$restPath Q');
    }
  } else if (elem is PositionedBarline) {
    final xBp = _mmToBp(elem.x);
    final topYBp = pageHBp - _mmToBp(elem.topY);
    final bottomYBp = pageHBp - _mmToBp(elem.bottomY);
    final thicknessBp = _mmToBp(elem.thicknessMm);

    buf.writeln('0 G');
    buf.writeln('$thicknessBp w');
    buf.writeln('${_f(xBp)} ${_f(topYBp)} m ${_f(xBp)} ${_f(bottomYBp)} l S');
  } else if (elem is PositionedClef) {
    final xBp = _mmToBp(elem.x);
    final yBp = pageHBp - _mmToBp(elem.y);

    final (String path, double upem) = switch (elem.glyph) {
      SmuflGlyph.gClef => (_gClefPdf, 1000.0),
      SmuflGlyph.cClef => (_cClefPdf, 1000.0),
      SmuflGlyph.fClef => (_fClefPdf, 1000.0),
      SmuflGlyph.tabClef => (_tabClefPdf, 1000.0),
      SmuflGlyph.percussionClef => (_percClefPdf, 1000.0),
      _ => (_gClefPdf, 1000.0),
    };

    final displayGaps = (elem.glyph == SmuflGlyph.tabClef) ? 3.0 : 4.0;
    final scaleFactor = (gapBp * displayGaps * scale) / upem;
    final anchorSp = switch (elem.glyph) {
      SmuflGlyph.gClef => 0.876,
      SmuflGlyph.cClef => 2.0,
      SmuflGlyph.fClef => 2.578,
      _ => 0.0,
    };
    final baselineY = yBp - anchorSp * gapBp * scale;

    buf.writeln('q');
    buf.writeln(
      '${_f(scaleFactor)} 0 0 ${_f(scaleFactor)} ${_f(xBp)} ${_f(baselineY)} cm'
    );
    buf.writeln('0 g');
    buf.writeln('$path Q');
  } else if (elem is PositionedTimeSignature) {
    final xBp = _mmToBp(elem.x);
    final yBp = pageHBp - _mmToBp(elem.y);
    final sizeBp = gapBp * 2.3 * scale;

    // Minimalist beautiful strokes drawing the digits for the time signature
    buf.writeln('0 G');
    buf.writeln('${_f(0.18 * gapBp)} w');

    // Draw beats (numerator) above
    buf.write(_drawDigitStrokes(elem.beats, xBp, yBp + 0.5 * gapBp, sizeBp * 0.45));
    // Draw beatValue (denominator) below
    buf.write(_drawDigitStrokes(elem.beatValue, xBp, yBp - 0.5 * gapBp, sizeBp * 0.45));
  } else if (elem is PositionedKeySignature) {
    var localXBp = _mmToBp(elem.x);
    for (final acc in elem.accidentals) {
      final accPath = acc.glyph == SmuflGlyph.accidentalFlat ? _flatAccidentalPdf : _sharpAccidentalPdf;
      final accScale = gapBp * config.smuflGlyphScale * scale;
      final accYBp = pageHBp - _mmToBp(acc.y);

      buf.writeln('q');
      buf.writeln('$accScale 0 0 $accScale ${_f(localXBp)} ${_f(accYBp)} cm');
      buf.writeln('0 g');
      buf.writeln('$accPath Q');

      localXBp += acc.glyph.widthSp * gapBp * config.keySignatureAccidentalSpacingSp * scale;
    }
  }

  return buf.toString();
}

/// A minimalist vector stroke generator for drawing digits cleanly in LaTeX PDFs.
String _drawDigitStrokes(int number, double x, double y, double size) {
  final buf = StringBuffer();
  final w = size * 0.65;
  final h = size;

  final digits = number.toString().split('');
  var cursorX = x - (digits.length * w) / 2.0;

  for (final char in digits) {
    final digit = int.parse(char);
    final left = cursorX;
    final right = cursorX + w;
    final midX = cursorX + w / 2.0;
    final bottom = y - h / 2.0;
    final top = y + h / 2.0;
    final midY = y;

    switch (digit) {
      case 0:
        buf.writeln('${_f(midX)} ${_f(top)} m');
        buf.writeln('${_f(right)} ${_f(top)} ${_f(right)} ${_f(bottom)} ${_f(midX)} ${_f(bottom)} c');
        buf.writeln('${_f(left)} ${_f(bottom)} ${_f(left)} ${_f(top)} ${_f(midX)} ${_f(top)} c S');
        break;
      case 1:
        buf.writeln('${_f(left)} ${_f(top - size * 0.2)} m ${_f(midX)} ${_f(top)} l ${_f(midX)} ${_f(bottom)} l S');
        break;
      case 2:
        buf.writeln('${_f(left)} ${_f(top)} m ${_f(right)} ${_f(top)} l ${_f(right)} ${_f(midY)} l ${_f(left)} ${_f(midY)} l ${_f(left)} ${_f(bottom)} l ${_f(right)} ${_f(bottom)} l S');
        break;
      case 3:
        buf.writeln('${_f(left)} ${_f(top)} m ${_f(right)} ${_f(top)} l ${_f(right)} ${_f(bottom)} l ${_f(left)} ${_f(bottom)} l S');
        buf.writeln('${_f(left)} ${_f(midY)} m ${_f(right)} ${_f(midY)} l S');
        break;
      case 4:
        buf.writeln('${_f(left)} ${_f(top)} m ${_f(left)} ${_f(midY)} l ${_f(right)} ${_f(midY)} l S');
        buf.writeln('${_f(right)} ${_f(top)} m ${_f(right)} ${_f(bottom)} l S');
        break;
      case 5:
        buf.writeln('${_f(right)} ${_f(top)} m ${_f(left)} ${_f(top)} l ${_f(left)} ${_f(midY)} l ${_f(right)} ${_f(midY)} l ${_f(right)} ${_f(bottom)} l ${_f(left)} ${_f(bottom)} l S');
        break;
      case 6:
        buf.writeln('${_f(right)} ${_f(top)} m ${_f(left)} ${_f(top)} l ${_f(left)} ${_f(bottom)} l ${_f(right)} ${_f(bottom)} l ${_f(right)} ${_f(midY)} l ${_f(left)} ${_f(midY)} l S');
        break;
      case 7:
        buf.writeln('${_f(left)} ${_f(top)} m ${_f(right)} ${_f(top)} l ${_f(left)} ${_f(bottom)} l S');
        break;
      case 8:
        buf.writeln('${_f(left)} ${_f(top)} m ${_f(right)} ${_f(top)} l ${_f(right)} ${_f(bottom)} l ${_f(left)} ${_f(bottom)} l ${_f(left)} ${_f(top)} l S');
        buf.writeln('${_f(left)} ${_f(midY)} m ${_f(right)} ${_f(midY)} l S');
        break;
      case 9:
        buf.writeln('${_f(right)} ${_f(bottom)} m ${_f(right)} ${_f(top)} l ${_f(left)} ${_f(top)} l ${_f(left)} ${_f(midY)} l ${_f(right)} ${_f(midY)} l S');
        break;
    }
    cursorX += w + size * 0.15;
  }

  return buf.toString();
}

// --- High-fidelity SMuFL / Bravura Path Glyphs in PDF Format ---

// Bravura brace glyph (U+E000), extracted path. em=1000, yMin=0, yMax=997.
const String _bracePdf =
    '20.000 498.000 m 49.000 516.000 82.000 587.000 82.000 646.000 c '
    '82.000 651.000 82.000 657.000 81.000 662.000 c '
    '74.000 722.000 44.000 815.000 44.000 869.000 c '
    '44.000 921.000 67.000 971.000 72.000 980.000 c '
    '75.000 986.000 77.000 987.000 77.000 990.000 c '
    '77.000 993.000 74.000 997.000 71.000 997.000 c '
    '69.000 997.000 67.000 995.000 63.000 990.000 c '
    '41.000 963.000 14.000 905.000 14.000 805.000 c '
    '14.000 706.000 49.000 666.000 49.000 603.000 c '
    '49.000 556.000 30.000 530.000 2.000 498.000 c '
    '20.000 478.000 49.000 462.000 49.000 397.000 c '
    '49.000 327.000 14.000 265.000 14.000 192.000 c '
    '14.000 92.000 41.000 34.000 63.000 6.000 c '
    '67.000 1.000 69.000 0.000 71.000 0.000 c '
    '74.000 0.000 77.000 3.000 77.000 6.000 c '
    '77.000 9.000 76.000 11.000 72.000 17.000 c '
    '67.000 25.000 44.000 75.000 44.000 128.000 c '
    '44.000 181.000 74.000 275.000 81.000 334.000 c '
    '82.000 339.000 82.000 344.000 82.000 350.000 c '
    '82.000 409.000 49.000 480.000 20.000 498.000 c h f';

const String _gClefPdf =
    '376.0 415.0 m 374.0 427.0 376.0 428.0 382.0 434.0 c 490.0 535.0 572.0 662.0 572.0 815.0 c 572.0 902.0 548.0 988.0 507.0 1048.0 c 492.0 1070.0 466.0 1098.0 455.0 1098.0 c 441.0 1098.0 410.0 1072.0 390.0 1050.0 c 316.0 968.0 292.0 843.0 292.0 739.0 c 292.0 681.0 299.0 616.0 306.0 575.0 c 308.0 563.0 309.0 561.0 297.0 551.0 c 153.0 432.0 0.0 289.0 0.0 87.0 c 0.0 -87.0 119.0 -252.0 364.0 -252.0 c 387.0 -252.0 413.0 -250.0 433.0 -246.0 c 444.0 -244.0 446.0 -243.0 448.0 -255.0 c 460.0 -322.0 475.0 -409.0 475.0 -456.0 c 475.0 -604.0 375.0 -622.0 316.0 -622.0 c 262.0 -622.0 236.0 -606.0 236.0 -593.0 c 236.0 -586.0 245.0 -583.0 268.0 -576.0 c 299.0 -567.0 335.0 -540.0 335.0 -482.0 c 335.0 -427.0 300.0 -380.0 239.0 -380.0 c 172.0 -380.0 132.0 -433.0 132.0 -495.0 c 132.0 -560.0 171.0 -658.0 322.0 -658.0 c 389.0 -658.0 519.0 -628.0 519.0 -458.0 c 519.0 -401.0 501.0 -306.0 490.0 -244.0 c 488.0 -232.0 489.0 -233.0 503.0 -227.0 c 604.0 -187.0 671.0 -102.0 671.0 11.0 c 671.0 139.0 577.0 252.0 430.0 252.0 c 404.0 252.0 404.0 252.0 401.0 270.0 c h 470.0 943.0 m 503.0 943.0 530.0 916.0 530.0 861.0 c 530.0 750.0 435.0 660.0 356.0 591.0 c 349.0 585.0 345.0 586.0 343.0 599.0 c 339.0 625.0 337.0 659.0 337.0 691.0 c 337.0 847.0 409.0 943.0 470.0 943.0 c h 361.0 262.0 m 364.0 243.0 364.0 244.0 346.0 238.0 c 258.0 208.0 201.0 129.0 201.0 44.0 c 201.0 -46.0 248.0 -110.0 316.0 -133.0 c 324.0 -136.0 336.0 -139.0 343.0 -139.0 c 351.0 -139.0 355.0 -134.0 355.0 -128.0 c 355.0 -121.0 347.0 -118.0 340.0 -115.0 c 298.0 -97.0 268.0 -54.0 268.0 -8.0 c 268.0 49.0 307.0 92.0 368.0 109.0 c 384.0 113.0 386.0 112.0 388.0 101.0 c 438.0 -197.0 l 440.0 -208.0 439.0 -208.0 424.0 -211.0 c 408.0 -214.0 388.0 -216.0 368.0 -216.0 c 193.0 -216.0 80.0 -119.0 80.0 20.0 c 80.0 79.0 90.0 158.0 173.0 252.0 c 233.0 319.0 279.0 356.0 326.0 394.0 c 336.0 402.0 338.0 401.0 340.0 390.0 c h 430.0 103.0 m 428.0 115.0 429.0 118.0 441.0 117.0 c 522.0 110.0 589.0 42.0 589.0 -46.0 c 589.0 -109.0 551.0 -160.0 495.0 -188.0 c 483.0 -194.0 481.0 -194.0 479.0 -182.0 c h f';

const String _cClefPdf =
    '230.0 482.0 m 230.0 496.0 223.0 503.0 209.0 503.0 c 208.0 503.0 l 194.0 503.0 187.0 496.0 187.0 482.0 c 187.0 -482.0 l 187.0 -496.0 194.0 -503.0 208.0 -503.0 c 209.0 -503.0 l 223.0 -503.0 230.0 -496.0 230.0 -482.0 c 230.0 -44.0 l 230.0 -36.0 235.0 -37.0 239.0 -38.0 c 265.0 -45.0 307.0 -71.0 328.0 -184.0 c 331.0 -200.0 337.0 -209.0 347.0 -209.0 c 358.0 -209.0 363.0 -199.0 368.0 -182.0 c 381.0 -138.0 404.0 -89.0 475.0 -89.0 c 540.0 -89.0 558.0 -153.0 558.0 -284.0 c 558.0 -415.0 535.0 -474.0 452.0 -474.0 c 438.0 -474.0 367.0 -468.0 367.0 -447.0 c 367.0 -442.0 383.0 -436.0 394.0 -432.0 c 414.0 -425.0 434.0 -405.0 434.0 -367.0 c 434.0 -323.0 405.0 -298.0 366.0 -298.0 c 323.0 -298.0 289.0 -327.0 289.0 -380.0 c 289.0 -443.0 344.0 -506.0 463.0 -506.0 c 627.0 -506.0 699.0 -391.0 699.0 -287.0 c 699.0 -149.0 623.0 -53.0 490.0 -53.0 c 461.0 -53.0 442.0 -58.0 429.0 -62.0 c 419.0 -65.0 409.0 -67.0 400.0 -61.0 c 386.0 -52.0 364.0 -20.0 364.0 0.0 c 364.0 20.0 386.0 52.0 400.0 61.0 c 409.0 67.0 419.0 65.0 429.0 62.0 c 442.0 58.0 461.0 53.0 490.0 53.0 c 623.0 53.0 699.0 149.0 699.0 287.0 c 699.0 391.0 627.0 506.0 463.0 506.0 c 344.0 506.0 289.0 443.0 289.0 380.0 c 289.0 327.0 323.0 298.0 366.0 298.0 c 405.0 298.0 434.0 323.0 434.0 367.0 c 434.0 405.0 414.0 425.0 394.0 432.0 c 383.0 436.0 367.0 442.0 367.0 447.0 c 367.0 468.0 438.0 474.0 452.0 474.0 c 535.0 474.0 558.0 415.0 558.0 284.0 c 558.0 153.0 540.0 89.0 475.0 89.0 c 404.0 89.0 381.0 138.0 368.0 182.0 c 363.0 199.0 358.0 209.0 347.0 209.0 c 337.0 209.0 331.0 200.0 328.0 184.0 c 307.0 71.0 265.0 45.0 239.0 38.0 c 235.0 37.0 230.0 36.0 230.0 44.0 c h 21.0 503.0 m 7.0 503.0 0.0 496.0 0.0 482.0 c 0.0 -482.0 l 0.0 -496.0 7.0 -503.0 21.0 -503.0 c 107.0 -503.0 l 121.0 -503.0 128.0 -496.0 128.0 -482.0 c 128.0 482.0 l 128.0 496.0 121.0 503.0 107.0 503.0 c h f';

const String _fClefPdf =
    '252.0 262.0 m 78.0 262.0 0.0 135.0 0.0 39.0 c 0.0 -41.0 42.0 -110.0 123.0 -110.0 c 186.0 -110.0 229.0 -66.0 229.0 -4.0 c 229.0 60.0 182.0 100.0 133.0 100.0 c 106.0 100.0 96.0 93.0 83.0 93.0 c 70.0 93.0 67.0 101.0 67.0 111.0 c 67.0 151.0 127.0 224.0 229.0 224.0 c 335.0 224.0 381.0 120.0 381.0 -37.0 c 381.0 -316.0 243.0 -472.0 10.0 -605.0 c 1.0 -610.0 -5.0 -615.0 -5.0 -623.0 c -5.0 -629.0 -1.0 -635.0 8.0 -635.0 c 13.0 -635.0 19.0 -633.0 25.0 -630.0 c 271.0 -510.0 531.0 -332.0 531.0 -28.0 c 531.0 146.0 425.0 262.0 252.0 262.0 c h 629.0 180.0 m 598.0 180.0 574.0 156.0 574.0 125.0 c 574.0 94.0 598.0 70.0 629.0 70.0 c 660.0 70.0 684.0 94.0 684.0 125.0 c 684.0 156.0 660.0 180.0 629.0 180.0 c h 630.0 -71.0 m 599.0 -71.0 576.0 -94.0 576.0 -125.0 c 576.0 -156.0 599.0 -179.0 630.0 -179.0 c 661.0 -179.0 684.0 -156.0 684.0 -125.0 c 684.0 -94.0 661.0 -71.0 630.0 -71.0 c h f';

const String _percClefPdf =
    '160.0 -235.0 m 160.0 235.0 l 160.0 243.0 154.0 250.0 146.0 250.0 c 14.0 250.0 l 6.0 250.0 0.0 243.0 0.0 235.0 c 0.0 -235.0 l 0.0 -243.0 6.0 -250.0 14.0 -250.0 c 146.0 -250.0 l 154.0 -250.0 160.0 -243.0 160.0 -235.0 c h 382.0 235.0 m 382.0 243.0 376.0 250.0 368.0 250.0 c 236.0 250.0 l 228.0 250.0 222.0 243.0 222.0 235.0 c 222.0 -235.0 l 222.0 -243.0 228.0 -250.0 236.0 -250.0 c 368.0 -250.0 l 376.0 -250.0 382.0 -243.0 382.0 -235.0 c h f';

const String _tabClefPdf =
    '230.0 482.0 m 230.0 496.0 223.0 503.0 209.0 503.0 c 208.0 503.0 l 194.0 503.0 187.0 496.0 187.0 482.0 c 187.0 -482.0 l 187.0 -496.0 194.0 -503.0 208.0 -503.0 c 209.0 -503.0 l 223.0 -503.0 230.0 -496.0 230.0 -482.0 c 230.0 -44.0 l 230.0 -36.0 235.0 -37.0 239.0 -38.0 c 265.0 -45.0 307.0 -71.0 328.0 -184.0 c 331.0 -200.0 337.0 -209.0 347.0 -209.0 c 358.0 -209.0 363.0 -199.0 368.0 -182.0 c 381.0 -138.0 404.0 -89.0 475.0 -89.0 c 540.0 -89.0 558.0 -153.0 558.0 -284.0 c 558.0 -415.0 535.0 -474.0 452.0 -474.0 c 438.0 -474.0 367.0 -468.0 367.0 -447.0 c 367.0 -442.0 383.0 -436.0 394.0 -432.0 c 414.0 -425.0 434.0 -405.0 434.0 -367.0 c 434.0 -323.0 405.0 -298.0 366.0 -298.0 c 323.0 -298.0 289.0 -327.0 289.0 -380.0 c 289.0 -443.0 344.0 -506.0 463.0 -506.0 c 627.0 -506.0 699.0 -391.0 699.0 -287.0 c 699.0 -149.0 623.0 -53.0 490.0 -53.0 c 461.0 -53.0 442.0 -58.0 429.0 -62.0 c 419.0 -65.0 409.0 -67.0 400.0 -61.0 c 386.0 -52.0 364.0 -20.0 364.0 0.0 c 364.0 20.0 386.0 52.0 400.0 61.0 c 409.0 67.0 419.0 65.0 429.0 62.0 c 442.0 58.0 461.0 53.0 490.0 53.0 c 623.0 53.0 699.0 149.0 699.0 287.0 c 699.0 391.0 627.0 506.0 463.0 506.0 c 344.0 506.0 289.0 443.0 289.0 380.0 c 289.0 327.0 323.0 298.0 366.0 298.0 c 405.0 298.0 434.0 323.0 434.0 367.0 c 434.0 405.0 414.0 425.0 394.0 432.0 c 383.0 436.0 367.0 442.0 367.0 447.0 c 367.0 468.0 438.0 474.0 452.0 474.0 c 535.0 474.0 558.0 415.0 558.0 284.0 c 558.0 153.0 540.0 89.0 475.0 89.0 c 404.0 89.0 381.0 138.0 368.0 182.0 c 363.0 199.0 358.0 209.0 347.0 209.0 c 337.0 209.0 331.0 200.0 328.0 184.0 c 307.0 71.0 265.0 45.0 239.0 38.0 c 235.0 37.0 230.0 36.0 230.0 44.0 c h 91.0 -580.0 m 84.0 -580.0 82.0 -578.0 82.0 -571.0 c 82.0 -514.0 l 82.0 -505.0 84.0 -503.0 93.0 -503.0 c 107.0 -503.0 l 121.0 -503.0 128.0 -496.0 128.0 -482.0 c 128.0 482.0 l 128.0 496.0 121.0 503.0 107.0 503.0 c 21.0 503.0 l 7.0 503.0 0.0 496.0 0.0 482.0 c 0.0 -482.0 l 0.0 -496.0 7.0 -503.0 21.0 -503.0 c 35.0 -503.0 l 44.0 -503.0 46.0 -505.0 46.0 -514.0 c 46.0 -571.0 l 46.0 -578.0 44.0 -580.0 37.0 -580.0 c -24.0 -580.0 l -30.0 -580.0 -33.0 -581.0 -33.0 -587.0 c -33.0 -588.0 -33.0 -590.0 -32.0 -594.0 c 58.0 -904.0 l 59.0 -908.0 60.0 -911.0 64.0 -911.0 c 68.0 -911.0 69.0 -908.0 70.0 -904.0 c 160.0 -594.0 l 161.0 -590.0 161.0 -588.0 161.0 -587.0 c 161.0 -581.0 158.0 -580.0 152.0 -580.0 c h f';

const String _quarterRestPdf =
    "100 -250 m 120 -180 150 -120 180 -70 c 190 -40 180 -10 160 20 c 130 50 80 100 40 150 c 20 180 10 210 20 240 c 30 270 60 300 90 320 c 15 320 l -10 280 -20 230 -10 180 c 10 110 50 60 c 80 20 110 -30 130 -80 c 130 -80 l f";
const String _eighthRestPdf =
    "50 180 m 80 180 100 160 100 130 c 100 90 70 60 30 60 c 10 60 0 70 0 90 c 0 120 20 150 50 180 c h 0 0 m 80 150 l 100 150 l 20 0 l h f";
const String _sixteenthRestPdf =
    "50 180 m 80 180 100 160 100 130 c 100 90 70 60 30 60 c 10 60 0 70 0 90 c 0 120 20 150 50 180 c h 50 100 m 80 100 100 80 100 50 c 100 10 70 -20 30 -20 c 10 -20 0 -10 0 10 c 0 40 20 70 50 100 c h 0 -80 m 80 180 l 100 180 l 20 -80 l h f";

const String _flatAccidentalPdf =
    "20 -150 m 20 150 l 30 150 l 30 30 l 50 60 80 70 100 40 c 120 10 120 -30 100 -60 c 80 -90 50 -80 30 -50 c 30 -150 l h 30 -20 m 45 -40 65 -45 80 -30 c 95 -15 95 15 80 30 c 65 45 45 40 30 20 c h f";
const String _sharpAccidentalPdf =
    "30 -100 m 30 100 l 45 100 l 45 35 l 75 55 l 75 100 l 90 100 l 90 15 l 45 -5 l 45 -100 l h 75 -35 m 45 -55 l 45 -15 l 75 5 l h f";

const String _flag8thPdf =
    "0 0 m 15 -25 35 -35 55 -30 c 45 -45 25 -50 0 -45 c 5 -10 10 15 15 35 c 25 15 0 0 c h f";
const String _flag16thPdf =
    "0 0 m 15 -25 35 -35 55 -30 c 45 -45 25 -50 0 -45 c h 0 -30 m 15 -55 35 -65 55 -60 c 45 -75 25 -80 0 -75 c h f";
