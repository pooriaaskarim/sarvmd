// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// SVG emitter — generates a standalone `.svg` file representing the
/// manuscript layout and notation elements.
///
/// Coordinates use millimetres; the SVG viewBox is set to the page dimensions
/// in mm so the file is scale-accurate at 1 mm = 1 user unit.

import 'config.dart';
import 'layout.dart';
import 'domain/smufl.dart';
import 'layout/positioned_element.dart';
import 'layout/engraver.dart';

String _f(double v) => v.toStringAsFixed(3);

/// Emit a complete standalone SVG string for a blank manuscript layout.
String emitSvg(PageConfig config, PageLayout layout) {
  final buf = StringBuffer();
  final w = config.effectiveWidth;
  final h = config.effectiveHeight;

  buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buf.writeln(
    '<svg xmlns="http://www.w3.org/2000/svg"'
    ' xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"'
    ' viewBox="0 0 ${_f(w)} ${_f(h)}"'
    ' width="${_f(w)}mm" height="${_f(h)}mm">',
  );

  final gap = config.staffConfig.lineGapMm;
  final strokeMm = config.staffConfig.lineThicknessPt * 25.4 / 72.0;
  final leftX = config.margins.left;
  final rightX = w - config.margins.right;

  // Layer 1: Page Background
  buf.writeln(
    '  <g id="layer-background" inkscape:groupmode="layer" inkscape:label="Page Background">',
  );
  buf.writeln('    <rect width="${_f(w)}" height="${_f(h)}" fill="white"/>');
  buf.writeln('  </g>');

  // Layer 2: System Structure (System Barlines & Piano Braces)
  buf.writeln(
    '  <g id="layer-system-structure" inkscape:groupmode="layer" inkscape:label="System Structure">',
  );
  _drawSystemConnectors(buf, config, layout.systems);
  buf.writeln('  </g>');

  // Layer 3: Staff Lines
  buf.writeln(
    '  <g id="layer-staff-lines" inkscape:groupmode="layer" inkscape:label="Staff Lines"'
    ' stroke="black" stroke-width="${_f(strokeMm)}" fill="none">',
  );
  for (final system in layout.systems) {
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final topY = staff.topY;
      for (var li = 0; li < staff.lines; li++) {
        final y = topY + li * gap;
        buf.writeln(
          '    <line x1="${_f(leftX)}" y1="${_f(y)}"'
          ' x2="${_f(rightX)}" y2="${_f(y)}"/>',
        );
      }
    }
  }
  buf.writeln('  </g>');

  // Layer 4: Clefs
  buf.writeln(
    '  <g id="layer-clefs" inkscape:groupmode="layer" inkscape:label="Clefs">',
  );
  for (final system in layout.systems) {
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final clef = staff.definition?.clef;

      if (clef == null) continue;

      final anchorY =
          staff.topY + (staff.lines - clef.anchorLine) * gap * staff.scale;
      final anchorSp = (clef.symbol == ClefSymbol.percussion && staff.lines > 1)
          ? 1.0
          : 0.0;

      final displayGaps = (clef.symbol == ClefSymbol.tab)
          ? (staff.lines > 0 ? staff.lines - 1 : 1).toDouble() * staff.scale
          : 4.0 * staff.scale;

      final effectiveAnchorY = (clef.symbol == ClefSymbol.tab)
          ? (staff.topY + (staff.lines - 1) * gap * staff.scale)
          : anchorY;

      final baselineY = effectiveAnchorY + anchorSp * gap * staff.scale;
      final glyphX = leftX + gap * 0.15;

      final (String path, double upem) = switch (clef.symbol) {
        ClefSymbol.g => (_gClefSvg, 1000.0),
        ClefSymbol.c => (_cClefSvg, 1000.0),
        ClefSymbol.f => (_fClefSvg, 1000.0),
        ClefSymbol.tab => (_tabClefSvg, 1000.0),
        ClefSymbol.percussion => (_percClefSvg, 1000.0),
      };

      final scale = (gap * displayGaps) / upem;

      buf.writeln(
        '    <g transform="translate(${_f(glyphX)}, ${_f(baselineY)}) '
        'scale(${_f(scale)}, -${_f(scale)})" fill="black" stroke="none">',
      );
      buf.writeln('      <path d="$path"/>');
      buf.writeln('    </g>');
    }
  }
  buf.writeln('  </g>');

  buf.writeln('</svg>');
  return buf.toString();
}

/// Emit a complete standalone SVG string for an engraved, compiled page.
String emitCompiledSvg(PageConfig config, EngravingPage page) {
  final buf = StringBuffer();
  final w = config.effectiveWidth;
  final h = config.effectiveHeight;

  buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buf.writeln(
    '<svg xmlns="http://www.w3.org/2000/svg"'
    ' xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"'
    ' viewBox="0 0 ${_f(w)} ${_f(h)}"'
    ' width="${_f(w)}mm" height="${_f(h)}mm">',
  );

  final gap = config.staffConfig.lineGapMm;
  final strokeMm = config.staffConfig.lineThicknessPt * 25.4 / 72.0;
  final leftX = config.margins.left;
  final rightX = w - config.margins.right;

  // Layer 1: Page Background
  buf.writeln(
    '  <g id="layer-background" inkscape:groupmode="layer" inkscape:label="Page Background">',
  );
  buf.writeln('    <rect width="${_f(w)}" height="${_f(h)}" fill="white"/>');
  buf.writeln('  </g>');

  // Layer 2: System Structure (System Barlines & Piano Braces)
  buf.writeln(
    '  <g id="layer-system-structure" inkscape:groupmode="layer" inkscape:label="System Structure">',
  );
  _drawSystemConnectors(buf, config, page.pageLayout.systems);
  buf.writeln('  </g>');

  // Layer 3: Staff Lines
  buf.writeln(
    '  <g id="layer-staff-lines" inkscape:groupmode="layer" inkscape:label="Staff Lines"'
    ' stroke="black" stroke-width="${_f(strokeMm)}" fill="none">',
  );
  for (final system in page.pageLayout.systems) {
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final topY = staff.topY;
      for (var li = 0; li < staff.lines; li++) {
        final y = topY + li * gap;
        buf.writeln(
          '    <line x1="${_f(leftX)}" y1="${_f(y)}"'
          ' x2="${_f(rightX)}" y2="${_f(y)}"/>',
        );
      }
    }
  }
  buf.writeln('  </g>');

  // Layer 4: Barlines
  buf.writeln(
    '  <g id="layer-barlines" inkscape:groupmode="layer" inkscape:label="Barlines">',
  );
  for (final elem in page.elements.whereType<PositionedBarline>()) {
    buf.write(_drawElement(elem, gap));
  }
  buf.writeln('  </g>');

  // Layer 5: Clefs & Signatures
  buf.writeln(
    '  <g id="layer-clefs-signatures" inkscape:groupmode="layer" inkscape:label="Clefs &amp; Signatures">',
  );
  for (final elem in page.elements.where(
    (e) =>
        e is PositionedClef ||
        e is PositionedKeySignature ||
        e is PositionedTimeSignature,
  )) {
    buf.write(_drawElement(elem, gap));
  }
  buf.writeln('  </g>');

  // Layer 6: Notation Elements (Notes & Rests)
  buf.writeln(
    '  <g id="layer-notation" inkscape:groupmode="layer" inkscape:label="Notation Elements">',
  );
  for (final elem in page.elements.where(
    (e) => e is PositionedNote || e is PositionedRest,
  )) {
    buf.write(_drawElement(elem, gap));
  }
  buf.writeln('  </g>');

  buf.writeln('</svg>');
  return buf.toString();
}

/// Helper method to draw system connectors (braces / connecting barlines).
void _drawSystemConnectors(
  StringBuffer buf,
  PageConfig config,
  List<StaffSystem> systems,
) {
  final strokeMm = config.staffConfig.lineThicknessPt * 25.4 / 72.0;
  final leftX = config.margins.left;
  final connector = config.systemLayout.rootGroup.connector;

  if (connector == SystemConnector.none) return;

  for (final system in systems) {
    if (system.staves.length <= 1) continue;

    final sysTopY = system.staves.first.topY;
    final sysBottomY = system.staves.last.topY + system.staves.last.height;
    final bool useBrace = connector == SystemConnector.brace;

    buf.writeln(
      '    <line x1="${_f(leftX)}" y1="${_f(sysTopY)}"'
      ' x2="${_f(leftX)}" y2="${_f(sysBottomY)}"'
      ' stroke="black" stroke-width="${_f(strokeMm * 2.5)}"/>',
    );

    if (useBrace) {
      final double h = sysBottomY - sysTopY;
      final double scale = h / 997.0;
      final double tx = leftX - scale * 82.0;
      final double ty = sysBottomY;

      buf.writeln(
        '    <g transform="translate(${_f(tx)}, ${_f(ty)})'
        ' scale(${_f(scale)}, -${_f(scale)})" fill="black" stroke="none">'
        '<path d="$_braceSvg"/></g>',
      );
    } else {
      final tickLen = 2.0;
      buf.writeln(
        '    <line x1="${_f(leftX)}" y1="${_f(sysTopY)}"'
        ' x2="${_f(leftX + tickLen)}" y2="${_f(sysTopY)}"'
        ' stroke="black" stroke-width="${_f(strokeMm * 2.5)}"/>',
      );
      buf.writeln(
        '    <line x1="${_f(leftX)}" y1="${_f(sysBottomY)}"'
        ' x2="${_f(leftX + tickLen)}" y2="${_f(sysBottomY)}"'
        ' stroke="black" stroke-width="${_f(strokeMm * 2.5)}"/>',
      );
    }
  }
}

/// Helper method to serialize a [PositionedElement] to SVG markup.
String _drawElement(PositionedElement elem, double gap) {
  final buf = StringBuffer();
  final scale = elem.scale;

  if (elem is PositionedNote) {
    final x = elem.x;
    final y = elem.y;
    final rx = 0.59 * gap * scale;
    final ry = 0.40 * gap * scale;

    // Draw ledger lines
    for (final ledgerY in elem.ledgerLineYs) {
      final len = gap * 1.6 * scale;
      buf.writeln(
        '    <line x1="${_f(x - len / 2)}" y1="${_f(ledgerY)}"'
        ' x2="${_f(x + len / 2)}" y2="${_f(ledgerY)}"'
        ' stroke="black" stroke-width="${_f(0.12 * gap)}" stroke-linecap="round"/>'
      );
    }

    // Draw notehead
    if (elem.glyph == SmuflGlyph.noteheadBlack) {
      buf.writeln(
        '    <ellipse cx="${_f(x)}" cy="${_f(y)}" rx="${_f(rx)}" ry="${_f(ry)}"'
        ' transform="rotate(-20, $x, $y)" fill="black"/>'
      );
    } else if (elem.glyph == SmuflGlyph.noteheadHalf) {
      buf.writeln(
        '    <ellipse cx="${_f(x)}" cy="${_f(y)}" rx="${_f(rx)}" ry="${_f(ry)}"'
        ' transform="rotate(-20, $x, $y)" stroke="black" stroke-width="${_f(0.18 * gap)}" fill="none"/>'
      );
    } else if (elem.glyph == SmuflGlyph.noteheadWhole) {
      buf.writeln(
        '    <ellipse cx="${_f(x)}" cy="${_f(y)}" rx="${_f(rx * 1.3)}" ry="${_f(ry * 1.1)}"'
        ' transform="rotate(-20, $x, $y)" stroke="black" stroke-width="${_f(0.18 * gap)}" fill="none"/>'
      );
    }

    // Draw stem
    if (elem.hasStem) {
      final stemLen = elem.stemLengthSp * gap * scale;
      final stemThickness = 0.11 * gap * scale;
      final stemX = elem.stemUp ? x + rx * 0.95 : x - rx * 0.95;
      final stemEndY = elem.stemUp ? y - stemLen : y + stemLen;

      buf.writeln(
        '    <line x1="${_f(stemX)}" y1="${_f(y)}"'
        ' x2="${_f(stemX)}" y2="${_f(stemEndY)}"'
        ' stroke="black" stroke-width="${_f(stemThickness)}" stroke-linecap="round"/>'
      );

      // Draw flag if present
      if (elem.flagGlyph != null) {
        final flagPath = (elem.flagGlyph == SmuflGlyph.flag8thUp || elem.flagGlyph == SmuflGlyph.flag8thDown)
            ? _flag8thSvg
            : _flag16thSvg;
        
        final flagScale = gap * 0.0035 * scale;
        final flagTransY = stemEndY;
        final flagScaleY = elem.stemUp ? -flagScale : flagScale;

        buf.writeln(
          '    <g transform="translate(${_f(stemX)}, ${_f(flagTransY)}) scale(${_f(flagScale)}, ${_f(flagScaleY)})" fill="black" stroke="none">'
          '      <path d="$flagPath"/>'
          '    </g>'
        );
      }
    }
  } else if (elem is PositionedRest) {
    final x = elem.x;
    final y = elem.y;

    if (elem.glyph == SmuflGlyph.restWhole) {
      // Hangs below staff line
      buf.writeln(
        '    <rect x="${_f(x - 0.5 * gap * scale)}" y="${_f(y)}" width="${_f(1.0 * gap * scale)}" height="${_f(0.6 * gap * scale)}" fill="black"/>'
      );
    } else if (elem.glyph == SmuflGlyph.restHalf) {
      // Sits on top of staff line
      buf.writeln(
        '    <rect x="${_f(x - 0.5 * gap * scale)}" y="${_f(y - 0.6 * gap * scale)}" width="${_f(1.0 * gap * scale)}" height="${_f(0.6 * gap * scale)}" fill="black"/>'
      );
    } else if (elem.glyph == SmuflGlyph.restQuarter) {
      buf.writeln(
        '    <g transform="translate(${_f(x)}, ${_f(y)}) scale(${_f(gap * 0.0035 * scale)}, -${_f(gap * 0.0035 * scale)})" fill="black" stroke="none">'
        '      <path d="$_quarterRestSvg"/>'
        '    </g>'
      );
    } else if (elem.glyph == SmuflGlyph.restEighth) {
      buf.writeln(
        '    <g transform="translate(${_f(x)}, ${_f(y)}) scale(${_f(gap * 0.0035 * scale)}, -${_f(gap * 0.0035 * scale)})" fill="black" stroke="none">'
        '      <path d="$_eighthRestSvg"/>'
        '    </g>'
      );
    } else {
      buf.writeln(
        '    <g transform="translate(${_f(x)}, ${_f(y)}) scale(${_f(gap * 0.0035 * scale)}, -${_f(gap * 0.0035 * scale)})" fill="black" stroke="none">'
        '      <path d="$_sixteenthRestSvg"/>'
        '    </g>'
      );
    }
  } else if (elem is PositionedBarline) {
    buf.writeln(
      '    <line x1="${_f(elem.x)}" y1="${_f(elem.topY)}"'
      ' x2="${_f(elem.x)}" y2="${_f(elem.bottomY)}"'
      ' stroke="black" stroke-width="${_f(elem.thicknessMm)}"/>'
    );
  } else if (elem is PositionedClef) {
    final x = elem.x;
    final y = elem.y;

    final (String path, double upem) = switch (elem.glyph) {
      SmuflGlyph.gClef => (_gClefSvg, 1000.0),
      SmuflGlyph.cClef => (_cClefSvg, 1000.0),
      SmuflGlyph.fClef => (_fClefSvg, 1000.0),
      SmuflGlyph.tabClef => (_tabClefSvg, 1000.0),
      SmuflGlyph.percussionClef => (_percClefSvg, 1000.0),
      _ => (_gClefSvg, 1000.0),
    };

    final displayGaps = (elem.glyph == SmuflGlyph.tabClef) ? 3.0 : 4.0;
    final svgScale = (gap * displayGaps * scale) / upem;
    final anchorSp = switch (elem.glyph) {
      SmuflGlyph.gClef => 0.876,
      SmuflGlyph.cClef => 2.0,
      SmuflGlyph.fClef => 2.578,
      _ => 0.0,
    };
    final baselineY = y + anchorSp * gap * scale;

    buf.writeln(
      '    <g transform="translate(${_f(x)}, ${_f(baselineY)}) '
      'scale(${_f(svgScale)}, -${_f(svgScale)})" fill="black" stroke="none">'
      '      <path d="$path"/>'
      '    </g>'
    );
  } else if (elem is PositionedTimeSignature) {
    final x = elem.x;
    final y = elem.y;
    final fontSize = gap * 2.3 * scale;

    buf.writeln(
      '    <g fill="black" font-family="Georgia, serif" font-weight="bold" font-size="${_f(fontSize)}" text-anchor="middle">'
      '      <text x="${_f(x)}" y="${_f(y - 0.15 * gap)}">${elem.beats}</text>'
      '      <text x="${_f(x)}" y="${_f(y + 0.95 * gap)}">${elem.beatValue}</text>'
      '    </g>'
    );
  } else if (elem is PositionedKeySignature) {
    var localX = elem.x;
    for (final acc in elem.accidentals) {
      final accPath = acc.glyph == SmuflGlyph.accidentalFlat ? _flatAccidentalSvg : _sharpAccidentalSvg;
      final accScale = gap * 0.0035 * scale;
      buf.writeln(
        '    <g transform="translate(${_f(localX)}, ${_f(acc.y)}) scale(${_f(accScale)}, -${_f(accScale)})" fill="black" stroke="none">'
        '      <path d="$accPath"/>'
        '    </g>'
      );
      localX += acc.glyph.widthSp * gap * 0.6 * scale;
    }
  }

  return buf.toString();
}

// --- High-fidelity SMuFL / Bravura Path Glyphs ---

// Bravura brace glyph (U+E000), extracted path. em=1000, yMin=0, yMax=997.
const String _braceSvg =
    'M 20.0,498.0 C 49.0,516.0 82.0,587.0 82.0,646.0 C 82.0,651.0 82.0,657.0 81.0,662.0 C 74.0,722.0 44.0,815.0 44.0,869.0 C 44.0,921.0 67.0,971.0 72.0,980.0 C 75.0,986.0 77.0,987.0 77.0,990.0 C 77.0,993.0 74.0,997.0 71.0,997.0 C 69.0,997.0 67.0,995.0 63.0,990.0 C 41.0,963.0 14.0,905.0 14.0,805.0 C 14.0,706.0 49.0,666.0 49.0,603.0 C 49.0,556.0 30.0,530.0 2.0,498.0 C 20.0,478.0 49.0,462.0 49.0,397.0 C 49.0,327.0 14.0,265.0 14.0,192.0 C 14.0,92.0 41.0,34.0 63.0,6.0 C 67.0,1.0 69.0,0.0 71.0,0.0 C 74.0,0.0 77.0,3.0 77.0,6.0 C 77.0,9.0 76.0,11.0 72.0,17.0 C 67.0,25.0 44.0,75.0 44.0,128.0 C 44.0,181.0 74.0,275.0 81.0,334.0 C 82.0,339.0 82.0,344.0 82.0,350.0 C 82.0,409.0 49.0,480.0 20.0,498.0 Z';

const String _gClefSvg =
    'M 376.0,415.0 C 374.0,427.0 376.0,428.0 382.0,434.0 C 490.0,535.0 572.0,662.0 572.0,815.0 C 572.0,902.0 548.0,988.0 507.0,1048.0 C 492.0,1070.0 466.0,1098.0 455.0,1098.0 C 441.0,1098.0 410.0,1072.0 390.0,1050.0 C 316.0,968.0 292.0,843.0 292.0,739.0 C 292.0,681.0 299.0,616.0 306.0,575.0 C 308.0,563.0 309.0,561.0 297.0,551.0 C 153.0,432.0 0.0,289.0 0.0,87.0 C 0.0,-87.0 119.0,-252.0 364.0,-252.0 C 387.0,-252.0 413.0,-250.0 433.0,-246.0 C 444.0,-244.0 446.0,-243.0 448.0,-255.0 C 460.0,-322.0 475.0,-409.0 475.0,-456.0 C 475.0,-604.0 375.0,-622.0 316.0,-622.0 C 262.0,-622.0 236.0,-606.0 236.0,-593.0 C 236.0,-586.0 245.0,-583.0 268.0,-576.0 C 299.0,-567.0 335.0,-540.0 335.0,-482.0 C 335.0,-427.0 300.0,-380.0 239.0,-380.0 C 172.0,-380.0 132.0,-433.0 132.0,-495.0 C 132.0,-560.0 171.0,-658.0 322.0,-658.0 C 389.0,-658.0 519.0,-628.0 519.0,-458.0 C 519.0,-401.0 501.0,-306.0 490.0,-244.0 C 488.0,-232.0 489.0,-233.0 503.0,-227.0 C 604.0,-187.0 671.0,-102.0 671.0,11.0 C 671.0,139.0 577.0,252.0 430.0,252.0 C 404.0,252.0 404.0,252.0 401.0,270.0 Z M 470.0,943.0 C 503.0,943.0 530.0,916.0 530.0,861.0 C 530.0,750.0 435.0,660.0 356.0,591.0 C 349.0,585.0 345.0,586.0 343.0,599.0 C 339.0,625.0 337.0,659.0 337.0,691.0 C 337.0,847.0 409.0,943.0 470.0,943.0 Z M 361.0,262.0 C 364.0,243.0 364.0,244.0 346.0,238.0 C 258.0,208.0 201.0,129.0 201.0,44.0 C 201.0,-46.0 248.0,-110.0 316.0,-133.0 C 324.0,-136.0 336.0,-139.0 343.0,-139.0 C 351.0,-139.0 355.0,-134.0 355.0,-128.0 C 355.0,-121.0 347.0,-118.0 340.0,-115.0 C 298.0,-97.0 268.0,-54.0 268.0,-8.0 C 268.0,49.0 307.0,92.0 368.0,109.0 C 384.0,113.0 386.0,112.0 388.0,101.0 L 438.0,-197.0 C 440.0,-208.0 439.0,-208.0 424.0,-211.0 C 408.0,-214.0 388.0,-216.0 368.0,-216.0 C 193.0,-216.0 80.0,-119.0 80.0,20.0 C 80.0,79.0 90.0,158.0 173.0,252.0 C 233.0,319.0 279.0,356.0 326.0,394.0 C 336.0,402.0 338.0,401.0 340.0,390.0 Z M 430.0,103.0 C 428.0,115.0 429.0,118.0 441.0,117.0 C 522.0,110.0 589.0,42.0 589.0,-46.0 C 589.0,-109.0 551.0,-160.0 495.0,-188.0 C 483.0,-194.0 481.0,-194.0 479.0,-182.0 Z';
const String _cClefSvg =
    'M 230.0,482.0 C 230.0,496.0 223.0,503.0 209.0,503.0 L 208.0,503.0 C 194.0,503.0 187.0,496.0 187.0,482.0 L 187.0,-482.0 C 187.0,-496.0 194.0,-503.0 208.0,-503.0 L 209.0,-503.0 C 223.0,-503.0 230.0,-496.0 230.0,-482.0 L 230.0,-44.0 C 230.0,-36.0 235.0,-37.0 239.0,-38.0 C 265.0,-45.0 307.0,-71.0 328.0,-184.0 C 331.0,-200.0 337.0,-209.0 347.0,-209.0 C 358.0,-209.0 363.0,-199.0 368.0,-182.0 C 381.0,-138.0 404.0,-89.0 475.0,-89.0 C 540.0,-89.0 558.0,-153.0 558.0,-284.0 C 558.0,-415.0 535.0,-474.0 452.0,-474.0 C 438.0,-474.0 367.0,-468.0 367.0,-447.0 C 367.0,-442.0 383.0,-436.0 394.0,-432.0 C 414.0,-425.0 434.0,-405.0 434.0,-367.0 C 434.0,-323.0 405.0,-298.0 366.0,-298.0 C 323.0,-298.0 289.0,-327.0 289.0,-380.0 C 289.0,-443.0 344.0,-506.0 463.0,-506.0 C 627.0,-506.0 699.0,-391.0 699.0,-287.0 C 699.0,-149.0 623.0,-53.0 490.0,-53.0 C 461.0,-53.0 442.0,-58.0 429.0,-62.0 C 419.0,-65.0 409.0,-67.0 400.0,-61.0 C 386.0,-52.0 364.0,-20.0 364.0,0.0 C 364.0,20.0 386.0,52.0 400.0,61.0 C 409.0,67.0 419.0,65.0 429.0,62.0 C 442.0,58.0 461.0,53.0 490.0,53.0 C 623.0,53.0 699.0,149.0 699.0,287.0 C 699.0,391.0 627.0,506.0 463.0,506.0 C 344.0,506.0 289.0,443.0 289.0,380.0 C 289.0,327.0 323.0,298.0 366.0,298.0 C 405.0,298.0 434.0,323.0 434.0,367.0 C 434.0,405.0 414.0,425.0 394.0,432.0 C 383.0,436.0 367.0,442.0 367.0,447.0 C 367.0,468.0 438.0,474.0 452.0,474.0 C 535.0,474.0 558.0,415.0 558.0,284.0 C 558.0,153.0 540.0,89.0 475.0,89.0 C 404.0,89.0 381.0,138.0 368.0,182.0 C 363.0,199.0 358.0,209.0 347.0,209.0 C 337.0,209.0 331.0,200.0 328.0,184.0 C 307.0,71.0 265.0,45.0 239.0,38.0 C 235.0,37.0 230.0,36.0 230.0,44.0 Z M 21.0,503.0 C 7.0,503.0 0.0,496.0 0.0,482.0 L 0.0,-482.0 C 0.0,-496.0 7.0,-503.0 21.0,-503.0 L 107.0,-503.0 C 121.0,-503.0 128.0,-496.0 128.0,-482.0 L 128.0,482.0 C 128.0,496.0 121.0,503.0 107.0,503.0 Z';
const String _fClefSvg =
    'M 252.0,262.0 C 78.0,262.0 0.0,135.0 0.0,39.0 C 0.0,-41.0 42.0,-110.0 123.0,-110.0 C 186.0,-110.0 229.0,-66.0 229.0,-4.0 C 229.0,60.0 182.0,100.0 133.0,100.0 C 106.0,100.0 96.0,93.0 83.0,93.0 C 70.0,93.0 67.0,101.0 67.0,111.0 C 67.0,151.0 127.0,224.0 229.0,224.0 C 335.0,224.0 381.0,120.0 381.0,-37.0 C 381.0,-316.0 243.0,-472.0 10.0,-605.0 C 1.0,-610.0 -5.0,-615.0 -5.0,-623.0 C -5.0,-629.0 -1.0,-635.0 8.0,-635.0 C 13.0,-635.0 19.0,-633.0 25.0,-630.0 C 271.0,-510.0 531.0,-332.0 531.0,-28.0 C 531.0,146.0 425.0,262.0 252.0,262.0 Z M 629.0,180.0 C 598.0,180.0 574.0,156.0 574.0,125.0 C 574.0,94.0 598.0,70.0 629.0,70.0 C 660.0,70.0 684.0,94.0 684.0,125.0 C 684.0,156.0 660.0,180.0 629.0,180.0 Z M 630.0,-71.0 C 599.0,-71.0 576.0,-94.0 576.0,-125.0 C 576.0,-156.0 599.0,-179.0 630.0,-179.0 C 661.0,-179.0 684.0,-156.0 684.0,-125.0 C 684.0,-94.0 661.0,-71.0 630.0,-71.0 Z';
const String _percClefSvg =
    'M 160.0,-235.0 L 160.0,235.0 C 160.0,243.0 154.0,250.0 146.0,250.0 L 14.0,250.0 C 6.0,250.0 0.0,243.0 0.0,235.0 L 0.0,-235.0 C 0.0,-243.0 6.0,-250.0 14.0,-250.0 L 146.0,-250.0 C 154.0,-250.0 160.0,-243.0 160.0,-235.0 Z M 382.0,235.0 C 382.0,243.0 376.0,250.0 368.0,250.0 L 236.0,250.0 C 228.0,250.0 222.0,243.0 222.0,235.0 L 222.0,-235.0 C 222.0,-243.0 228.0,-250.0 236.0,-250.0 L 368.0,-250.0 C 376.0,-250.0 382.0,-243.0 382.0,-235.0 Z';
const String _tabClefSvg =
    'M 230.0,482.0 C 230.0,496.0 223.0,503.0 209.0,503.0 L 208.0,503.0 C 194.0,503.0 187.0,496.0 187.0,482.0 L 187.0,-482.0 C 187.0,-496.0 194.0,-503.0 208.0,-503.0 L 209.0,-503.0 C 223.0,-503.0 230.0,-496.0 230.0,-482.0 L 230.0,-44.0 C 230.0,-36.0 235.0,-37.0 239.0,-38.0 C 265.0,-45.0 307.0,-71.0 328.0,-184.0 C 331.0,-200.0 337.0,-209.0 347.0,-209.0 C 358.0,-209.0 363.0,-199.0 368.0,-182.0 C 381.0,-138.0 404.0,-89.0 475.0,-89.0 C 540.0,-89.0 558.0,-153.0 558.0,-284.0 C 558.0,-415.0 535.0,-474.0 452.0,-474.0 C 438.0,-474.0 367.0,-468.0 367.0,-447.0 C 367.0,-442.0 383.0,-436.0 394.0,-432.0 C 414.0,-425.0 434.0,-405.0 434.0,-367.0 C 434.0,-323.0 405.0,-298.0 366.0,-298.0 C 323.0,-298.0 289.0,-327.0 289.0,-380.0 C 289.0,-443.0 344.0,-506.0 463.0,-506.0 C 627.0,-506.0 699.0,-391.0 699.0,-287.0 C 699.0,-149.0 623.0,-53.0 490.0,-53.0 C 461.0,-53.0 442.0,-58.0 429.0,-62.0 C 419.0,-65.0 409.0,-67.0 400.0,-61.0 C 386.0,-52.0 364.0,-20.0 364.0,0.0 C 364.0,20.0 386.0,52.0 400.0,61.0 C 409.0,67.0 419.0,65.0 429.0,62.0 C 442.0,58.0 461.0,53.0 490.0,53.0 C 623.0,53.0 699.0,149.0 699.0,287.0 C 699.0,391.0 627.0,506.0 463.0,506.0 C 344.0,506.0 289.0,443.0 289.0,380.0 C 289.0,327.0 323.0,298.0 366.0,298.0 C 405.0,298.0 434.0,323.0 434.0,367.0 C 434.0,405.0 414.0,425.0 394.0,432.0 C 383.0,436.0 367.0,442.0 367.0,447.0 C 367.0,468.0 438.0,474.0 452.0,474.0 C 535.0,474.0 558.0,415.0 558.0,284.0 C 558.0,153.0 540.0,89.0 475.0,89.0 C 404.0,89.0 381.0,138.0 368.0,182.0 C 363.0,199.0 358.0,209.0 347.0,209.0 C 337.0,209.0 331.0,200.0 328.0,184.0 C 307.0,71.0 265.0,45.0 239.0,38.0 C 235.0,37.0 230.0,36.0 230.0,44.0 Z M 91.0,-580.0 C 84.0,-580.0 82.0,-578.0 82.0,-571.0 L 82.0,-514.0 C 82.0,-505.0 84.0,-503.0 93.0,-503.0 L 107.0,-503.0 C 121.0,-503.0 128.0,-496.0 128.0,-482.0 L 128.0,482.0 C 128.0,496.0 121.0,503.0 107.0,503.0 L 21.0,503.0 C 7.0,503.0 0.0,496.0 0.0,482.0 L 0.0,-482.0 C 0.0,-496.0 7.0,-503.0 21.0,-503.0 L 35.0,-503.0 C 44.0,-503.0 46.0,-505.0 46.0,-514.0 L 46.0,-571.0 C 46.0,-578.0 44.0,-580.0 37.0,-580.0 L -24.0,-580.0 C -30.0,-580.0 -33.0,-581.0 -33.0,-587.0 C -33.0,-588.0 -33.0,-590.0 -32.0,-594.0 L 58.0,-904.0 C 59.0,-908.0 60.0,-911.0 64.0,-911.0 C 68.0,-911.0 69.0,-908.0 70.0,-904.0 L 160.0,-594.0 C 161.0,-590.0 161.0,-588.0 161.0,-587.0 C 161.0,-581.0 158.0,-580.0 152.0,-580.0 Z';

const String _quarterRestSvg =
    "M100 -250 C120 -180 150 -120 180 -70 C190 -40 180 -10 160 20 C130 50 80 100 40 150 C20 180 10 210 20 240 C30 270 60 300 90 320 L15 320 C-10 280 -20 230 -10 180 Q10 110 50 60 C80 20 110 -30 130 -80 Z";
const String _eighthRestSvg =
    "M50 180 C80 180 100 160 100 130 C100 90 70 60 30 60 C10 60 0 70 0 90 C0 120 20 150 50 180 Z M0 0 L80 150 H100 L20 0 Z";
const String _sixteenthRestSvg =
    "M50 180 C80 180 100 160 100 130 C100 90 70 60 30 60 C10 60 0 70 0 90 C0 120 20 150 50 180 Z M50 100 C80 100 100 80 100 50 C100 10 70 -20 30 -20 C10 -20 0 -10 0 10 C0 40 20 70 50 100 Z M0 -80 L80 180 H100 L20 -80 Z";

const String _flatAccidentalSvg =
    "M20 -150 V150 H30 V30 C50 60 80 70 100 40 C120 10 120 -30 100 -60 C80 -90 50 -80 30 -50 V-150 Z M30 -20 C45 -40 65 -45 80 -30 C95 -15 95 15 80 30 C65 45 45 40 30 20 Z";
const String _sharpAccidentalSvg =
    "M30 -100 V100 H45 V35 L75 55 V100 H90 V15 L45 -5 V-100 Z M75 -35 L45 -55 V-15 L75 5 V-35 Z";

const String _flag8thSvg =
    "M 0 0 C 15 -25 35 -35 55 -30 C 45 -45 25 -50 0 -45 C 5 -10 10 15 15 35 Q 25 15 0 0 Z";
const String _flag16thSvg =
    "M 0 0 C 15 -25 35 -35 55 -30 C 45 -45 25 -50 0 -45 Z M 0 -30 C 15 -55 35 -65 55 -60 C 45 -75 25 -80 0 -75 Z";
