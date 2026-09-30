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
import 'domain/clef.dart';
import 'layout.dart';

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
  buf.writeln(r'\usepackage{helvet}');
  buf.writeln(r'\renewcommand{\familydefault}{\sfdefault}');
  buf.writeln(r'\pagestyle{empty}');
  buf.writeln(r'\begin{document}');

  final draw = StringBuffer();
  draw.writeln('q'); // Save graphics state.

  final lineW = config.staffConfig.lineThicknessPt;
  draw.writeln('$lineW w'); // Set line width in points.
  draw.writeln('0 G'); // Black stroke color.

  final staffRightBp = _mmToBp(pageW - config.margins.right);
  final pageHBp = _mmToBp(pageH);
  final lineGapBp = _mmToBp(config.staffConfig.lineGapMm);

  // Draw each system.
  for (final system in layout.systems) {
    final staffLeftMm = config.margins.left + system.leftIndentMm;
    final staffLeftBp = _mmToBp(staffLeftMm);
    for (final staff in system.staves) {
      final topLinePdfY = pageHBp - _mmToBp(staff.topY);
      for (var line = 0; line < staff.lines; line++) {
        final y = topLinePdfY - line * lineGapBp;
        draw.writeln(
          '${_f(staffLeftBp)} ${_f(y)} m ${_f(staffRightBp)} ${_f(y)} l S',
        );
      }
    }

    // Draw initial barlines and connectors for all groups in this system.
    for (final group in system.groupPlacements) {
      if (group.startStaffIdx < 0 ||
          group.endStaffIdx >= system.staves.length ||
          group.startStaffIdx > group.endStaffIdx) {
        continue;
      }

      final groupStaves =
          system.staves.sublist(group.startStaffIdx, group.endStaffIdx + 1);
      if (groupStaves.isEmpty) continue;

      final topY = groupStaves.first.topY;
      final bottomY = groupStaves.last.topY + groupStaves.last.height;
      final topPdfY = pageHBp - _mmToBp(topY);
      final bottomPdfY = pageHBp - _mmToBp(bottomY);

      final double connectorX = staffLeftMm - group.connectorOffsetMm;
      final double connectorBp = _mmToBp(connectorX);

      // ── Initial barline (at staffLeftBp) ───────────────────────────────
      if (group.initialBarline) {
        draw.writeln('${_f(lineW * 2.5)} w');
        if (group.continuousBarlines && groupStaves.length > 1) {
          draw.writeln(
            '${_f(staffLeftBp)} ${_f(topPdfY)} m '
            '${_f(staffLeftBp)} ${_f(bottomPdfY)} l S',
          );
        } else {
          for (final staff in groupStaves) {
            final sTopPdfY = pageHBp - _mmToBp(staff.topY);
            final sBottomPdfY = pageHBp - _mmToBp(staff.topY + staff.height);
            draw.writeln(
              '${_f(staffLeftBp)} ${_f(sTopPdfY)} m '
              '${_f(staffLeftBp)} ${_f(sBottomPdfY)} l S',
            );
          }
        }
        draw.writeln('$lineW w');
      }

      // ── Connector glyph (at connectorBp) ───────────────────────────────
      switch (group.connector) {
        case SystemConnector.brace when groupStaves.length >= 2:
          final double h = topPdfY - bottomPdfY;
          final double scale = h / 997.0;
          final double tx = connectorBp - scale * 82.0;
          final double ty = bottomPdfY;
          draw.writeln('q ${_f(scale)} 0 0 ${_f(scale)} ${_f(tx)} ${_f(ty)} cm');
          draw.writeln('0 g');
          draw.writeln('$_bracePdf Q');
        case SystemConnector.bracket when groupStaves.length >= 2:
          final tickLenBp =
              _mmToBp(GroupPlacementMetrics.bracketTickLengthMm);
          final endTickBp = connectorBp + tickLenBp;
          draw.writeln('${_f(lineW * 3.0)} w');
          draw.writeln(
            '${_f(connectorBp)} ${_f(topPdfY)} m '
            '${_f(connectorBp)} ${_f(bottomPdfY)} l '
            '${_f(connectorBp)} ${_f(topPdfY)} m '
            '${_f(endTickBp)} ${_f(topPdfY)} l '
            '${_f(connectorBp)} ${_f(bottomPdfY)} m '
            '${_f(endTickBp)} ${_f(bottomPdfY)} l S',
          );
          draw.writeln('$lineW w');
        case SystemConnector.subBracket when groupStaves.length >= 2:
          draw.writeln('${_f(lineW * 1.8)} w');
          draw.writeln(
            '${_f(connectorBp)} ${_f(topPdfY)} m '
            '${_f(connectorBp)} ${_f(bottomPdfY)} l S',
          );
          draw.writeln('$lineW w');
        case SystemConnector.none:
        case SystemConnector.brace:
        case SystemConnector.bracket:
        case SystemConnector.subBracket:
          break;
      }
    }

    // Clefs.
    for (var i = 0; i < system.staves.length; i++) {
      final staff = system.staves[i];
      final clef = staff.definition?.clef;

      if (clef != null) {
        final topLinePdfY = pageHBp - _mmToBp(staff.topY);
        final baselinePdfY = topLinePdfY -
            clef.anchorOffsetInSpaces(staff.lines) * lineGapBp * staff.scale;

        final (String path, double glyphHeight, double displayGaps) = switch (clef.symbol) {
          ClefSymbol.g => (_gClefPdf, 1000.0, 4.0 * staff.scale),
          ClefSymbol.c => (_cClefPdf, 1000.0, 4.0 * staff.scale),
          ClefSymbol.f => (_fClefPdf, 1000.0, 4.0 * staff.scale),
          ClefSymbol.tab => (
              staff.lines <= 4 ? _tabClef4Pdf : _tabClef6Pdf,
              staff.lines <= 4 ? 1012.0 : 1512.0,
              (staff.lines > 1 ? staff.lines - 1 : 1) * 0.90 * staff.scale,
            ),
          ClefSymbol.percussion => (_percClefPdf, 1000.0, 4.0 * staff.scale),
        };

        final scale = (lineGapBp * displayGaps) / glyphHeight;
        final cx = staffLeftBp + lineGapBp * config.engraving.initialClefClearanceSp;
        draw.writeln(
            'q ${_f(scale)} 0 0 ${_f(scale)} ${_f(cx)} ${_f(baselinePdfY)} cm');
        draw.writeln('0 g');
        draw.writeln('$path Q');
      }
    }
  }

  draw.writeln('Q');

  // Text labels (Group labels & Instrument labels)
  final textBuf = StringBuffer();

  for (var sysIdx = 0; sysIdx < layout.systems.length; sysIdx++) {
    final system = layout.systems[sysIdx];
    final staffLeftMm = config.margins.left + system.leftIndentMm;
    final bool isFirstSystem = sysIdx == 0;

    // 1. Group labels (Outer tier)
    for (final group in system.groupPlacements) {
      if (!group.labelVisible) continue;
      final String label = isFirstSystem
          ? group.label.trim()
          : group.abbreviation.trim();
      if (label.isEmpty) continue;

      final groupStaves =
          system.staves.sublist(group.startStaffIdx, group.endStaffIdx + 1);
      if (groupStaves.isEmpty) continue;

      final topY = groupStaves.first.topY;
      final bottomY = groupStaves.last.topY + groupStaves.last.height;
      final midY = (topY + bottomY) / 2.0;

      final double labelOffset = group.labelOffsetMm > 0.0
          ? group.labelOffsetMm
          : group.connectorOffsetMm +
              GroupPlacementMetrics.groupLabelClearanceMm;
      final double labelX = staffLeftMm - labelOffset;

      final styledText = _formatLatexLabel(
        label,
        isBold: true,
        isItalic: false,
        fontPt: 11.0,
      );

      textBuf.writeln(
        '  \\put(${_f(labelX)}, -${_f(midY)}){\\makebox(0,0)[r]{$styledText}}%',
      );
    }

    // 2. Identify which staves sit inside a displaced connector (offset > 0)
    final Set<int> innerStaffIndices = {};
    for (final group in system.groupPlacements) {
      if (group.connector != SystemConnector.none &&
          group.innerStaffLabelWidthMm > 0.0) {
        for (int s = group.startStaffIdx; s <= group.endStaffIdx; s++) {
          innerStaffIndices.add(s);
        }
      }
    }

    // 3. Staff labels (Inner tier when grouped; outer tier when standalone)
    for (int sIdx = 0; sIdx < system.staves.length; sIdx++) {
      final staff = system.staves[sIdx];
      final def = staff.definition;
      if (def != null && def.labelVisible) {
        final String? label = isFirstSystem
            ? def.instrumentName
            : ((def.instrumentAbbreviation != null &&
                    def.instrumentAbbreviation!.trim().isNotEmpty)
                ? def.instrumentAbbreviation
                : def.instrumentName);

        if (label != null && label.trim().isNotEmpty) {
          final double labelX;
          if (innerStaffIndices.contains(sIdx)) {
            // Inner staff label: sits right-aligned between connector and starting barline
            labelX = staffLeftMm -
                GroupPlacementMetrics.staffLabelClearanceMm +
                def.labelHorizontalOffset;
          } else {
            // Standalone / Single-Tier staff: sits to the left of its connector
            double maxConnectorOffset = 0.0;
            for (final g in system.groupPlacements) {
              if (sIdx >= g.startStaffIdx &&
                  sIdx <= g.endStaffIdx &&
                  g.connector != SystemConnector.none &&
                  g.connectorOffsetMm > maxConnectorOffset) {
                maxConnectorOffset = g.connectorOffsetMm;
              }
            }
            labelX = staffLeftMm -
                maxConnectorOffset -
                GroupPlacementMetrics.staffLabelClearanceMm +
                def.labelHorizontalOffset;
          }

          final labelY =
              staff.topY + (staff.height / 2.0) + def.labelVerticalOffset;

          final styledText = _formatLatexLabel(
            label,
            isBold: false,
            isItalic: def.labelItalic,
            fontPt: def.labelFontSize,
          );

          textBuf.writeln(
            '  \\put(${_f(labelX)}, -${_f(labelY)}){\\makebox(0,0)[r]{$styledText}}%',
          );
        }
      }
    }
  }

  final pageLiteral = '\\pdfliteral direct {${draw.toString()}}';
  final count = pageCount < 1 ? 1 : pageCount;
  for (var i = 0; i < count; i++) {
    if (i > 0) {
      buf.writeln(r'\newpage');
    }
    buf.writeln(r'\setlength{\topskip}{0pt}%');
    buf.writeln(r'\setlength{\parindent}{0pt}%');
    buf.writeln(r'\setlength{\unitlength}{1mm}%');
    if (textBuf.isNotEmpty) {
      buf.writeln(r'\noindent\begin{picture}(0,0)(0,0)%');
      buf.write(textBuf.toString());
      buf.writeln(r'\end{picture}%');
    } else {
      buf.writeln(r'\null%');
    }
    buf.writeln(pageLiteral);
  }
  buf.writeln(r'\end{document}');

  return buf.toString();
}

String _escapeLatex(String text) {
  return text
      .replaceAll(r'\', r'\textbackslash{}')
      .replaceAll('{', r'\{')
      .replaceAll('}', r'\}')
      .replaceAll('&', r'\&')
      .replaceAll('%', r'\%')
      .replaceAll(r'$', r'\$')
      .replaceAll('#', r'\#')
      .replaceAll('_', r'\_')
      .replaceAll('~', r'\textasciitilde{}')
      .replaceAll('^', r'\textasciicircum{}');
}

String _formatLatexLabel(
  String text, {
  required bool isBold,
  required bool isItalic,
  required double fontPt,
}) {
  final lines = text.split('\n');
  final escapedLines = lines.map(_escapeLatex).toList();
  final lineHeightPt = fontPt * 1.2;
  final content = escapedLines.length > 1
      ? '\\shortstack[r]{${escapedLines.join(r'\\')}}'
      : escapedLines.first;
  var styled = content;
  if (isBold) {
    styled = '\\textbf{$styled}';
  }
  if (isItalic) {
    styled = '\\textit{$styled}';
  }
  return '{\\fontsize{${fontPt.toStringAsFixed(1)}pt}{${lineHeightPt.toStringAsFixed(1)}pt}\\selectfont $styled}';
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

const String _tabClef6Pdf =
    '387.0 711.0 m 387.0 764.0 l 18.0 764.0 l 18.0 711.0 l 173.0 711.0 l 173.0 293.0 l 233.0 293.0 l 233.0 711.0 l h 408.0 -228.0 m 243.0 242.0 l 165.0 242.0 l -3.0 -228.0 l 61.0 -228.0 l 111.0 -87.0 l 292.0 -87.0 l 341.0 -228.0 l h 276.0 -36.0 m 126.0 -36.0 l 203.0 178.0 l h 378.0 -613.0 m 378.0 -557.0 352.0 -522.0 292.0 -499.0 c 335.0 -479.0 357.0 -444.0 357.0 -397.0 c 357.0 -328.0 307.0 -277.0 218.0 -277.0 c 27.0 -277.0 l 27.0 -748.0 l 239.0 -748.0 l 324.0 -748.0 378.0 -691.0 378.0 -613.0 c h 297.0 -405.0 m 297.0 -453.0 270.0 -480.0 203.0 -480.0 c 87.0 -480.0 l 87.0 -330.0 l 203.0 -330.0 l 270.0 -330.0 297.0 -357.0 297.0 -405.0 c h 318.0 -614.0 m 318.0 -659.0 290.0 -695.0 234.0 -695.0 c 87.0 -695.0 l 87.0 -533.0 l 234.0 -533.0 l 290.0 -533.0 318.0 -568.0 318.0 -614.0 c h f';

const String _tabClef4Pdf =
    '258.0 469.0 m 258.0 504.0 l 11.0 504.0 l 11.0 469.0 l 115.0 469.0 l 115.0 189.0 l 155.0 189.0 l 155.0 469.0 l h 272.0 -160.0 m 162.0 155.0 l 110.0 155.0 l -3.0 -160.0 l 40.0 -160.0 l 73.0 -65.0 l 195.0 -65.0 l 227.0 -160.0 l h 184.0 -32.0 m 83.0 -32.0 l 135.0 112.0 l h 252.0 -418.0 m 252.0 -380.0 235.0 -357.0 195.0 -342.0 c 223.0 -328.0 238.0 -305.0 238.0 -273.0 c 238.0 -227.0 205.0 -193.0 145.0 -193.0 c 17.0 -193.0 l 17.0 -508.0 l 159.0 -508.0 l 216.0 -508.0 252.0 -470.0 252.0 -418.0 c h 198.0 -279.0 m 198.0 -311.0 180.0 -329.0 135.0 -329.0 c 57.0 -329.0 l 57.0 -228.0 l 135.0 -228.0 l 180.0 -228.0 198.0 -247.0 198.0 -279.0 c h 212.0 -418.0 m 212.0 -449.0 194.0 -472.0 156.0 -472.0 c 57.0 -472.0 l 57.0 -364.0 l 156.0 -364.0 l 194.0 -364.0 212.0 -388.0 212.0 -418.0 c h f';


