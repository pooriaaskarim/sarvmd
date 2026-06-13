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
import 'layout.dart';
import 'domain/smufl.dart';
import 'layout/positioned_element.dart';
import 'layout/engraver.dart';

/// Millimeters to PDF big points.
double _mmToBp(double mm) => mm * 72.0 / 25.4;

/// Format a double to 3 decimal places for PDF operators.
String _f(double v) => v.toStringAsFixed(3);

/// Emit a complete `.tex` document string for a blank manuscript layout.
String emit(PageConfig config, PageLayout layout) {
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

      if (!useBrace) {
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

        final anchorSp = switch (clef.symbol) {
          ClefSymbol.g => 0.876,
          ClefSymbol.c => 2.0,
          ClefSymbol.f => 2.578,
          ClefSymbol.tab => 0.0, // Bottom-aligned
          ClefSymbol.percussion => (staff.lines > 1) ? 1.0 : 0.0,
        };

        // For TAB, we want it to span the full staff height
        final displayGaps = (clef.symbol == ClefSymbol.tab)
            ? (staff.lines > 0 ? staff.lines - 1 : 1).toDouble() * staff.scale
            : 4.0 * staff.scale;

        // If TAB, force anchor to bottom line for simplicity in scaling
        final effectiveAnchorPdfY = (clef.symbol == ClefSymbol.tab)
            ? (topLinePdfY - (staff.lines - 1) * lineGapBp)
            : anchorPdfY;

        final microOffsetBp = lineGapBp * 0.04;
        final baselinePdfY =
            effectiveAnchorPdfY - anchorSp * lineGapBp - microOffsetBp;
        final cx = staffLeftBp + lineGapBp * 0.15;

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

  buf.writeln('\\pdfliteral direct {${draw.toString()}}');
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
    draw.write(_drawElementPdf(element, pageHBp, lineGapBp));
  }

  draw.writeln('Q');

  buf.writeln('\\pdfliteral direct {${draw.toString()}}');
  buf.writeln(r'\end{document}');

  return buf.toString();
}

/// Helper method to serialize a [PositionedElement] to PDF operators.
String _drawElementPdf(PositionedElement elem, double pageHBp, double gapBp) {
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
        
        final flagScale = gapBp * 0.0035 * scale;
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
      final restPath = elem.glyph == SmuflGlyph.restQuarter
          ? _quarterRestPdf
          : (elem.glyph == SmuflGlyph.restEighth ? _eighthRestPdf : _sixteenthRestPdf);
      
      final s = gapBp * 0.0035 * scale;
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
      final accScale = gapBp * 0.0035 * scale;
      final accYBp = pageHBp - _mmToBp(acc.y);

      buf.writeln('q');
      buf.writeln('$accScale 0 0 $accScale ${_f(localXBp)} ${_f(accYBp)} cm');
      buf.writeln('0 g');
      buf.writeln('$accPath Q');

      localXBp += acc.glyph.widthSp * gapBp * 0.6 * scale;
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

const String _gClefPdf =
    "314.0 801.0 m 304.7 836.3 297.0 871.3 291.0 906.0 c 285.0 940.7 282.0 976.0 282.0 1012.0 c 282.0 1043.3 284.2 1072.8 288.5 1100.5 c 292.8 1128.2 299.0 1153.7 307.0 1177.0 c 315.7 1203.7 327.0 1228.8 341.0 1252.5 c 355.0 1276.2 369.8 1295.7 385.5 1311.0 c 401.2 1326.3 415.0 1334.0 427.0 1334.0 c 443.0 1334.0 465.0 1305.7 493.0 1249.0 c 507.0 1220.3 517.3 1189.3 524.0 1156.0 c 530.7 1122.7 534.0 1087.0 534.0 1049.0 c 534.0 1001.7 527.7 954.5 515.0 907.5 c 502.3 860.5 483.8 816.3 459.5 775.0 c 435.2 733.7 406.0 697.3 372.0 666.0 c 407.0 498.0 l 417.0 499.3 425.3 500.3 432.0 501.0 c 438.7 501.7 443.7 502.0 447.0 502.0 c 487.7 502.0 524.0 490.5 556.0 467.5 c 588.0 444.5 613.5 414.3 632.5 377.0 c 651.5 339.7 661.0 298.7 661.0 254.0 c 661.0 202.7 647.8 156.5 621.5 115.5 c 595.2 74.5 555.7 44.3 503.0 25.0 c 506.3 13.7 516.0 -33.7 532.0 -117.0 c 536.0 -137.0 539.0 -152.8 541.0 -164.5 c 543.0 -176.2 544.3 -186.3 545.0 -195.0 c 545.7 -203.7 546.0 -213.7 546.0 -225.0 c 546.0 -258.3 537.8 -288.2 521.5 -314.5 c 505.2 -340.8 483.2 -361.3 455.5 -376.0 c 427.8 -390.7 397.0 -398.0 363.0 -398.0 c 328.3 -398.0 297.7 -391.5 271.0 -378.5 c 244.3 -365.5 223.3 -347.5 208.0 -324.5 c 192.7 -301.5 185.0 -275.0 185.0 -245.0 c 185.0 -213.0 193.8 -186.3 211.5 -165.0 c 229.2 -143.7 254.3 -133.0 287.0 -133.0 c 315.0 -133.0 337.8 -143.2 355.5 -163.5 c 373.2 -183.8 382.0 -208.0 382.0 -236.0 c 382.0 -260.0 373.7 -281.0 357.0 -299.0 c 340.3 -317.0 318.7 -326.0 292.0 -326.0 c 282.0 -326.0 l 299.3 -352.0 326.7 -365.0 364.0 -365.0 c 410.0 -365.0 446.0 -350.0 472.0 -320.0 c 498.0 -290.0 511.0 -251.7 511.0 -205.0 c 511.0 -193.7 509.7 -178.5 507.0 -159.5 c 504.3 -140.5 499.7 -117.7 493.0 -91.0 c 486.3 -64.3 481.2 -42.3 477.5 -25.0 c 473.8 -7.7 471.3 4.7 470.0 12.0 c 447.3 5.3 420.7 2.0 390.0 2.0 c 332.7 2.0 276.7 18.7 222.0 52.0 c 168.7 85.3 126.7 129.3 96.0 184.0 c 65.3 238.7 50.0 297.7 50.0 361.0 c 50.0 421.0 63.7 477.3 91.0 530.0 c 118.3 582.7 152.2 631.0 192.5 675.0 c 232.8 719.0 273.3 761.0 314.0 801.0 c h 341.0 826.0 m 356.3 834.0 372.7 848.8 390.0 870.5 c 407.3 892.2 424.0 917.0 440.0 945.0 c 456.0 973.0 469.0 1001.2 479.0 1029.5 c 489.0 1057.8 494.0 1083.3 494.0 1106.0 c 494.0 1130.0 490.3 1149.0 483.0 1163.0 c 475.7 1177.0 463.0 1184.0 445.0 1184.0 c 429.0 1184.0 413.5 1176.7 398.5 1162.0 c 383.5 1147.3 370.2 1127.8 358.5 1103.5 c 346.8 1079.2 337.7 1052.0 331.0 1022.0 c 324.3 992.0 321.0 961.3 321.0 930.0 c 321.0 908.7 323.2 889.3 327.5 872.0 c 331.8 854.7 336.3 839.3 341.0 826.0 c h 398.0 379.0 m 380.0 375.0 363.0 366.5 347.0 353.5 c 331.0 340.5 318.2 324.8 308.5 306.5 c 298.8 288.2 294.0 268.7 294.0 248.0 c 294.0 231.3 298.3 214.2 307.0 196.5 c 315.7 178.8 326.3 164.7 339.0 154.0 c 347.7 146.0 356.3 140.0 365.0 136.0 c 375.0 131.3 380.0 127.0 380.0 123.0 c 380.0 121.0 376.7 119.0 370.0 117.0 c 344.7 123.0 321.8 134.3 301.5 151.0 c 281.2 167.7 265.2 187.8 253.5 211.5 c 241.8 235.2 236.0 260.3 236.0 287.0 c 236.0 315.7 241.8 343.3 253.5 370.0 c 265.2 396.7 281.5 420.7 302.5 442.0 c 323.5 463.3 347.3 479.3 374.0 490.0 c 345.0 641.0 l 267.7 578.3 210.8 516.8 174.5 456.5 c 138.2 396.2 120.0 336.3 120.0 277.0 c 120.0 233.7 131.3 193.3 154.0 156.0 c 176.7 118.7 207.7 88.5 247.0 65.5 c 286.3 42.5 330.7 31.0 380.0 31.0 c 393.3 31.0 406.8 32.3 420.5 35.0 c 434.2 37.7 448.7 41.0 464.0 45.0 c h 495.0 55.0 m 560.3 83.0 593.0 140.3 593.0 227.0 c 593.0 255.7 585.7 281.8 571.0 305.5 c 556.3 329.2 536.7 348.0 512.0 362.0 c 487.3 376.0 459.7 383.0 429.0 383.0 c h f";
const String _cClefPdf =
    "226.0 0.0 m 226.0 1000.0 l 263.0 1000.0 l 263.0 510.0 l 275.0 516.0 287.7 528.0 301.0 546.0 c 314.3 564.0 327.0 584.8 339.0 608.5 c 351.0 632.2 361.3 655.8 370.0 679.5 c 378.7 703.2 384.0 724.0 386.0 742.0 c 392.7 696.0 406.3 659.8 427.0 633.5 c 447.7 607.2 473.0 594.0 503.0 594.0 c 533.0 594.0 555.3 606.3 570.0 631.0 c 585.3 655.7 593.0 703.7 593.0 775.0 c 593.0 803.7 592.2 828.2 590.5 848.5 c 588.8 868.8 586.0 885.3 582.0 898.0 c 573.3 927.3 559.7 948.2 541.0 960.5 c 522.3 972.8 498.7 979.0 470.0 979.0 c 454.7 979.0 442.7 975.8 434.0 969.5 c 425.3 963.2 421.0 957.0 421.0 951.0 c 421.0 946.3 423.3 940.7 428.0 934.0 c 432.7 927.3 437.7 920.7 443.0 914.0 c 454.3 900.7 460.0 888.3 460.0 877.0 c 460.0 861.0 454.2 846.5 442.5 833.5 c 430.8 820.5 414.0 814.0 392.0 814.0 c 372.0 814.0 355.5 821.2 342.5 835.5 c 329.5 849.8 323.0 867.0 323.0 887.0 c 323.0 911.7 331.2 933.3 347.5 952.0 c 363.8 970.7 385.2 985.3 411.5 996.0 c 437.8 1006.7 466.3 1012.0 497.0 1012.0 c 539.7 1012.0 578.0 1002.0 612.0 982.0 c 646.0 962.0 673.2 934.3 693.5 899.0 c 713.8 863.7 724.0 823.0 724.0 777.0 c 724.0 748.3 720.8 722.0 714.5 698.0 c 708.2 674.0 698.3 652.3 685.0 633.0 c 667.0 607.7 644.0 587.8 616.0 573.5 c 588.0 559.2 558.3 552.0 527.0 552.0 c 512.3 552.0 497.2 553.8 481.5 557.5 c 465.8 561.2 451.0 566.7 437.0 574.0 c 390.0 500.0 l 437.0 426.0 l 452.3 432.0 468.0 436.7 484.0 440.0 c 500.0 443.3 516.0 445.0 532.0 445.0 c 568.7 445.0 601.5 434.7 630.5 414.0 c 659.5 393.3 682.3 366.0 699.0 332.0 c 715.7 298.0 724.0 260.3 724.0 219.0 c 724.0 177.7 714.0 139.5 694.0 104.5 c 674.0 69.5 647.0 41.7 613.0 21.0 c 579.0 0.3 540.3 -10.0 497.0 -10.0 c 441.0 -10.0 398.0 1.2 368.0 23.5 c 338.0 45.8 323.0 76.3 323.0 115.0 c 323.0 135.0 329.5 152.2 342.5 166.5 c 355.5 180.8 372.0 188.0 392.0 188.0 c 414.0 188.0 430.8 181.5 442.5 168.5 c 454.2 155.5 460.0 141.0 460.0 125.0 c 460.0 112.3 454.3 100.0 443.0 88.0 c 437.0 81.3 431.8 75.0 427.5 69.0 c 423.2 63.0 421.0 57.3 421.0 52.0 c 421.0 44.0 425.3 37.2 434.0 31.5 c 442.7 25.8 454.7 23.0 470.0 23.0 c 511.3 23.0 542.5 38.2 563.5 68.5 c 584.5 98.8 595.0 149.0 595.0 219.0 c 595.0 280.3 588.0 326.8 574.0 358.5 c 560.0 390.2 536.3 406.0 503.0 406.0 c 472.3 406.0 447.0 393.0 427.0 367.0 c 407.0 341.0 394.0 305.3 388.0 260.0 c 382.0 292.7 372.7 324.3 360.0 355.0 c 347.3 385.7 332.7 413.0 316.0 437.0 c 299.3 461.0 281.7 479.3 263.0 492.0 c 263.0 0.0 l h 50.0 0.0 m 50.0 1000.0 l 167.0 1000.0 l 167.0 0.0 l h f 687.0 809.0 m 702.3 809.0 715.3 803.7 726.0 793.0 c 736.7 782.3 742.0 769.3 742.0 754.0 c 742.0 738.7 736.7 725.8 726.0 715.5 c 715.3 705.2 702.3 700.0 687.0 700.0 c 671.7 700.0 658.7 705.2 648.0 715.5 c 637.3 725.8 632.0 738.7 632.0 754.0 c 632.0 769.3 637.3 782.3 648.0 793.0 c 658.7 803.7 671.7 809.0 687.0 809.0 c h 687.0 589.0 m 702.3 589.0 715.3 583.7 726.0 573.0 c 736.7 562.3 742.0 549.3 742.0 534.0 c 742.0 518.7 736.7 505.8 726.0 495.5 c 715.3 480.0 687.0 480.0 c 671.7 480.0 658.7 485.2 648.0 495.5 c 637.3 505.8 632.0 518.7 632.0 534.0 c 632.0 549.3 637.3 562.3 648.0 573.0 c 658.7 583.7 671.7 589.0 687.0 589.0 c h f";
const String _fClefPdf =
    "50.0 123.0 m 160.7 195.0 240.0 254.3 288.0 301.0 c 320.0 332.3 348.3 368.2 373.0 408.5 c 397.7 448.8 417.2 491.3 431.5 536.0 c 445.8 580.7 453.0 625.0 453.0 669.0 c 453.0 708.3 447.0 743.2 435.0 773.5 c 423.0 803.8 405.7 827.7 383.0 845.0 c 360.3 862.3 333.3 871.0 302.0 871.0 c 290.0 871.0 277.5 869.7 264.5 867.0 c 251.5 864.3 238.0 860.3 224.0 855.0 c 195.3 844.3 173.3 830.5 158.0 813.5 c 142.7 796.5 135.0 780.3 135.0 765.0 c 135.0 759.0 137.7 754.7 143.0 752.0 c 148.3 749.3 153.3 748.0 158.0 748.0 c 164.7 748.0 173.0 749.3 183.0 752.0 c 187.7 753.3 192.2 754.3 196.5 755.0 c 200.8 755.7 205.3 756.0 210.0 756.0 c 235.3 756.0 256.0 748.5 272.0 733.5 c 288.0 718.5 296.0 698.7 296.0 674.0 c 296.0 650.0 286.0 629.3 266.0 612.0 c 246.0 594.7 222.3 586.0 195.0 586.0 c 162.3 586.0 134.3 596.3 111.0 617.0 c 87.7 637.7 76.0 664.3 76.0 697.0 c 76.0 736.3 87.0 771.3 109.0 802.0 c 131.0 832.7 160.8 856.7 198.5 874.0 c 236.2 891.3 278.0 900.0 324.0 900.0 c 374.7 900.0 420.0 889.0 460.0 867.0 c 500.0 845.0 531.8 814.8 555.5 776.5 c 579.2 738.2 591.0 694.7 591.0 646.0 c 591.0 582.7 573.3 522.0 538.0 464.0 c 520.0 434.0 499.5 405.7 476.5 379.0 c 453.5 352.3 424.3 325.2 389.0 297.5 c 353.7 269.8 309.3 240.0 256.0 208.0 c 202.7 176.0 136.3 140.3 57.0 101.0 c h 687.0 809.0 m 702.3 809.0 715.3 803.7 726.0 793.0 c 736.7 782.3 742.0 769.3 742.0 754.0 c 742.0 738.7 736.7 725.8 726.0 715.5 c 715.3 705.2 702.3 700.0 687.0 700.0 c 671.7 700.0 658.7 705.2 648.0 715.5 c 637.3 725.8 632.0 738.7 632.0 754.0 c 632.0 769.3 637.3 782.3 648.0 793.0 c 658.7 803.7 671.7 809.0 687.0 809.0 c h 687.0 589.0 m 702.3 589.0 715.3 583.7 726.0 573.0 c 736.7 562.3 742.0 549.3 742.0 534.0 c 742.0 518.7 736.7 505.8 726.0 495.5 c 715.3 485.2 702.3 480.0 687.0 480.0 c 671.7 480.0 658.7 485.2 648.0 495.5 c 637.3 505.8 632.0 518.7 632.0 534.0 c 632.0 549.3 637.3 562.3 648.0 573.0 c 658.7 583.7 671.7 589.0 687.0 589.0 c h f";
const String _percClefPdf =
    "300.0 200.0 m 300.0 800.0 l 400.0 800.0 l 400.0 200.0 l h f 500.0 200.0 m 500.0 800.0 l 600.0 800.0 l 600.0 200.0 l h f";
const String _tabClefPdf =
    "200.0 850.0 m 800.0 850.0 l 800.0 750.0 l 550.0 750.0 l 550.0 650.0 l 450.0 650.0 l 450.0 750.0 l 200.0 750.0 l h f 350.0 600.0 m 500.0 400.0 l 650.0 600.0 l 550.0 600.0 l 500.0 500.0 l 450.0 600.0 l h f 250.0 350.0 m 250.0 50.0 l 550.0 50.0 l 550.0 150.0 l 300.0 150.0 l 300.0 200.0 l 550.0 200.0 l 550.0 350.0 l h f";

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
