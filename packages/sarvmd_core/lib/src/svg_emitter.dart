// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// SVG emitter — generates a standalone `.svg` file representing the
/// manuscript layout and notation elements.
///
/// Coordinates use millimetres; the SVG viewBox is set to the page dimensions
/// in mm so the file is scale-accurate at 1 mm = 1 user unit.

import 'config.dart';
import 'domain/clef.dart';
import 'engraving_config.dart';
import 'layout.dart';
import 'domain/svg_layering_mode.dart';

String _f(double v) => v.toStringAsFixed(3);

String _escapeXml(String input) => input
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// Emit a complete standalone SVG string for a blank manuscript layout.
String emitSvg(
  PageConfig config,
  PageLayout layout, {
  SvgLayeringMode layeringMode = SvgLayeringMode.flatByCategory,
}) {
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

  if (layeringMode == SvgLayeringMode.none) {
    buf.writeln('  <rect width="${_f(w)}" height="${_f(h)}" fill="white"/>');
    _drawSystemConnectors(buf, config, layout.systems);
    _drawStaffLines(buf, layout.systems, leftX, rightX, gap, strokeMm);
    _drawClefs(buf, layout.systems, leftX, gap, config.engraving);
    _drawStaffLabels(buf, layout.systems, leftX);
    buf.writeln('</svg>');
    return buf.toString();
  }

  // Layer 1: Page Background
  buf.writeln(
    '  <g id="layer-background" inkscape:groupmode="layer" inkscape:label="Page Background">',
  );
  buf.writeln('    <rect width="${_f(w)}" height="${_f(h)}" fill="white"/>');
  buf.writeln('  </g>');

  if (layeringMode == SvgLayeringMode.hierarchicalBySystem) {
    buf.writeln(
      '  <g id="layer-systems" inkscape:groupmode="layer" inkscape:label="Score Systems">',
    );
    for (var i = 0; i < layout.systems.length; i++) {
      final system = layout.systems[i];
      final sysIdx = i + 1;
      buf.writeln(
        '    <g id="system-$sysIdx" inkscape:groupmode="layer" inkscape:label="System $sysIdx">',
      );
      _drawSystemConnectors(buf, config, [system]);
      _drawStaffLines(buf, [system], leftX, rightX, gap, strokeMm);
      _drawClefs(buf, [system], leftX, gap, config.engraving);
      _drawStaffLabels(buf, [system], leftX);
      buf.writeln('    </g>');
    }
    buf.writeln('  </g>');
  } else {
    // SvgLayeringMode.flatByCategory
    buf.writeln(
      '  <g id="layer-system-structure" inkscape:groupmode="layer" inkscape:label="System Structure">',
    );
    _drawSystemConnectors(buf, config, layout.systems);
    buf.writeln('  </g>');

    buf.writeln(
      '  <g id="layer-staff-lines" inkscape:groupmode="layer" inkscape:label="Staff Lines"'
      ' stroke="black" stroke-width="${_f(strokeMm)}" fill="none">',
    );
    _drawStaffLines(buf, layout.systems, leftX, rightX, gap, strokeMm, wrapGroup: false);
    buf.writeln('  </g>');

    buf.writeln(
      '  <g id="layer-clefs" inkscape:groupmode="layer" inkscape:label="Clefs">',
    );
    _drawClefs(buf, layout.systems, leftX, gap, config.engraving);
    buf.writeln('  </g>');

    buf.writeln(
      '  <g id="layer-labels" inkscape:groupmode="layer" inkscape:label="Instrument Labels">',
    );
    _drawStaffLabels(buf, layout.systems, leftX);
    buf.writeln('  </g>');
  }

  buf.writeln('</svg>');
  return buf.toString();
}

void _drawStaffLines(
  StringBuffer buf,
  List<StaffSystem> systems,
  double baseLeftX,
  double rightX,
  double gap,
  double strokeMm, {
  bool wrapGroup = true,
}) {
  if (wrapGroup) {
    buf.writeln(
      '  <g stroke="black" stroke-width="${_f(strokeMm)}" fill="none">',
    );
  }
  for (final system in systems) {
    final leftX = baseLeftX + system.leftIndentMm;
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
  if (wrapGroup) {
    buf.writeln('  </g>');
  }
}

void _drawClefs(
  StringBuffer buf,
  List<StaffSystem> systems,
  double baseLeftX,
  double gap,
  EngravingConfig engraving,
) {
  for (final system in systems) {
    final leftX = baseLeftX + system.leftIndentMm;
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final clef = staff.definition?.clef;

      if (clef == null) continue;

      final baselineY =
          staff.topY + clef.anchorOffsetInSpaces(staff.lines) * gap * staff.scale;
      final glyphX = leftX + gap * engraving.initialClefClearanceSp;

      final (String path, double glyphHeight, double displayGaps) = switch (clef.symbol) {
        ClefSymbol.g => (_gClefSvg, 1000.0, 4.0 * staff.scale),
        ClefSymbol.c => (_cClefSvg, 1000.0, 4.0 * staff.scale),
        ClefSymbol.f => (_fClefSvg, 1000.0, 4.0 * staff.scale),
        ClefSymbol.tab => (
            staff.lines <= 4 ? _tabClef4Svg : _tabClef6Svg,
            staff.lines <= 4 ? 1012.0 : 1512.0,
            (staff.lines > 1 ? staff.lines - 1 : 1) * 0.90 * staff.scale,
          ),
        ClefSymbol.percussion => (_percClefSvg, 1000.0, 4.0 * staff.scale),
      };

      final scale = (gap * displayGaps) / glyphHeight;

      buf.writeln(
        '    <g transform="translate(${_f(glyphX)}, ${_f(baselineY)}) '
        'scale(${_f(scale)}, -${_f(scale)})" fill="black" stroke="none">',
      );
      buf.writeln('      <path d="$path"/>');
      buf.writeln('    </g>');
    }
  }
}

void _drawStaffLabels(
  StringBuffer buf,
  List<StaffSystem> systems,
  double baseLeftX,
) {
  for (var sysIdx = 0; sysIdx < systems.length; sysIdx++) {
    final system = systems[sysIdx];
    final leftX = baseLeftX + system.leftIndentMm;
    final bool isFirstSystem = sysIdx == 0;

    // 1. Group labels (Outer tier or section header above staff)
    for (final group in system.groupPlacements) {
      if (!group.labelVisible) continue;
      final String label = group.labelPlacement == GroupLabelPlacement.aboveStaff
          ? (group.isAboveStaffVisible ? group.label.trim() : '')
          : (isFirstSystem
              ? group.label.trim()
              : group.abbreviation.trim());
      if (label.isEmpty) continue;

      final groupStaves =
          system.staves.sublist(group.startStaffIdx, group.endStaffIdx + 1);
      if (groupStaves.isEmpty) continue;

      final topY = groupStaves.first.topY;
      final bottomY = groupStaves.last.topY + groupStaves.last.height;
      final midY = (topY + bottomY) / 2.0;

      const fontFamily = 'serif';

      if (group.labelPlacement == GroupLabelPlacement.aboveStaff) {
        final fontSizeMm = 10.0 * (25.4 / 72.0);
        final baselineY =
            topY - GroupPlacementMetrics.aboveStaffHeaderOffsetMm;
        _writeLeftAlignedText(
          buf: buf,
          text: label,
          leftAnchorXMm: leftX,
          baselineYMm: baselineY,
          fontSizeMm: fontSizeMm,
          fontFamily: fontFamily,
          isBold: true,
        );
      } else {
        final double labelOffset = group.labelOffsetMm > 0.0
            ? group.labelOffsetMm
            : group.connectorOffsetMm +
                (group.outerDescriptorWidthMm > 0.0
                    ? group.outerDescriptorWidthMm +
                        GroupPlacementMetrics.staffLabelClearanceMm
                    : 0.0) +
                GroupPlacementMetrics.groupLabelClearanceMm;
        final double labelX = leftX - labelOffset;
        final fontSizeMm = 11.0 * (25.4 / 72.0);

        _writeRightAlignedText(
          buf: buf,
          text: label,
          rightAnchorXMm: labelX,
          centerYMm: midY,
          fontSizeMm: fontSizeMm,
          fontFamily: fontFamily,
          isBold: true,
        );
      }
    }

    // 2. Identify which staves sit inside a displaced connector (offset > 0)
    final Set<int> innerStaffIndices = system.innerStaffIndices;

    // 3. Staff labels (Inner tier when grouped; outer tier when standalone)
    for (int sIdx = 0; sIdx < system.staves.length; sIdx++) {
      final staff = system.staves[sIdx];
      final def = staff.definition;
      if (def != null && def.labelVisible) {
        final String? label = staff.resolvedLabel ??
            (isFirstSystem
                ? def.instrumentName
                : ((def.instrumentAbbreviation != null &&
                        def.instrumentAbbreviation!.trim().isNotEmpty)
                    ? def.instrumentAbbreviation
                    : def.instrumentName));

        if (label != null && label.trim().isNotEmpty) {
          final style = staff.resolvedLabelStyle ?? def.labelStyle;
          final double labelX;
          if (innerStaffIndices.contains(sIdx)) {
            // Inner staff label: sits right-aligned between connector and starting barline
            labelX = leftX -
                GroupPlacementMetrics.staffLabelClearanceMm +
                style.horizontalOffsetMm;
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
            labelX = leftX -
                maxConnectorOffset -
                GroupPlacementMetrics.staffLabelClearanceMm +
                style.horizontalOffsetMm;
          }

          final staffMidY =
              staff.topY + (staff.height / 2.0) + style.verticalOffsetMm;
          final fontFamily =
              style.fontFamily.isNotEmpty ? style.fontFamily : 'serif';
          // Convert labelFontSize in points (pt) to unitless viewBox mm (1 pt = 25.4 / 72 mm).
          // Must remain UNITLESS so SVG viewBox scaling matrix does not double-scale physical units!
          final fontSizeMm = style.fontSizePt * (25.4 / 72.0);

          _writeRightAlignedText(
            buf: buf,
            text: label,
            rightAnchorXMm: labelX,
            centerYMm: staffMidY,
            fontSizeMm: fontSizeMm,
            fontFamily: fontFamily,
            isBold: style.isBold,
            isItalic: style.isItalic,
          );
        }
      }
    }
  }
}

/// Helper method to write left-aligned text (e.g. section headers above staves) in SVG.
void _writeLeftAlignedText({
  required StringBuffer buf,
  required String text,
  required double leftAnchorXMm,
  required double baselineYMm,
  required double fontSizeMm,
  required String fontFamily,
  bool isBold = false,
  bool isItalic = false,
}) {
  final boldAttr = isBold ? ' font-weight="bold"' : '';
  final italicAttr = isItalic ? ' font-style="italic"' : '';
  final lines = text.split('\n');

  if (lines.length == 1) {
    buf.writeln(
      '    <text x="${_f(leftAnchorXMm)}" y="${_f(baselineYMm)}"'
      ' font-family="$fontFamily" font-size="${_f(fontSizeMm)}"$boldAttr$italicAttr'
      ' fill="black" text-anchor="start">'
      '${_escapeXml(lines.first)}'
      '</text>',
    );
  } else {
    final lineHeightMm = fontSizeMm * 1.2;
    buf.writeln(
      '    <text x="${_f(leftAnchorXMm)}" y="${_f(baselineYMm)}"'
      ' font-family="$fontFamily" font-size="${_f(fontSizeMm)}"$boldAttr$italicAttr'
      ' fill="black" text-anchor="start">',
    );
    for (var i = 0; i < lines.length; i++) {
      final dy = i == 0 ? '0' : _f(lineHeightMm);
      buf.writeln(
        '      <tspan x="${_f(leftAnchorXMm)}" dy="$dy">${_escapeXml(lines[i])}</tspan>',
      );
    }
    buf.writeln('    </text>');
  }
}

/// Helper method to write single or multi-line right-aligned text in SVG.
void _writeRightAlignedText({
  required StringBuffer buf,
  required String text,
  required double rightAnchorXMm,
  required double centerYMm,
  required double fontSizeMm,
  required String fontFamily,
  bool isBold = false,
  bool isItalic = false,
}) {
  final boldAttr = isBold ? ' font-weight="bold"' : '';
  final italicAttr = isItalic ? ' font-style="italic"' : '';
  final lines = text.split('\n');

  if (lines.length == 1) {
    buf.writeln(
      '    <text x="${_f(rightAnchorXMm)}" y="${_f(centerYMm)}"'
      ' font-family="$fontFamily" font-size="${_f(fontSizeMm)}"$boldAttr$italicAttr'
      ' fill="black" text-anchor="end" dominant-baseline="central" dy="0.1em">'
      '${_escapeXml(lines.first)}'
      '</text>',
    );
  } else {
    final lineHeightMm = fontSizeMm * 1.2;
    final totalHeightMm = (lines.length - 1) * lineHeightMm;
    final startYMm = centerYMm - (totalHeightMm / 2.0);
    buf.writeln(
      '    <text x="${_f(rightAnchorXMm)}" y="${_f(startYMm)}"'
      ' font-family="$fontFamily" font-size="${_f(fontSizeMm)}"$boldAttr$italicAttr'
      ' fill="black" text-anchor="end" dominant-baseline="central" dy="0.1em">',
    );
    for (var i = 0; i < lines.length; i++) {
      final dy = i == 0 ? '0' : _f(lineHeightMm);
      buf.writeln(
        '      <tspan x="${_f(rightAnchorXMm)}" dy="$dy">${_escapeXml(lines[i])}</tspan>',
      );
    }
    buf.writeln('    </text>');
  }
}

/// Helper method to draw system connectors (braces, brackets, sub-brackets,
/// and continuous/broken barline segments) for every [GroupPlacement].
void _drawSystemConnectors(
  StringBuffer buf,
  PageConfig config,
  List<StaffSystem> systems,
) {
  final strokeMm = config.staffConfig.lineThicknessPt * 25.4 / 72.0;
  final leftMarginX = config.margins.left;

  for (final system in systems) {
    if (system.staves.isEmpty) continue;

    // Sort placements outer-first so outer decorations paint beneath inner ones.
    final placements = List<GroupPlacement>.from(system.groupPlacements)
      ..sort((a, b) => a.level.compareTo(b.level));

    for (final group in placements) {
      final groupStaves =
          system.staves.sublist(group.startStaffIdx, group.endStaffIdx + 1);
      if (groupStaves.isEmpty) continue;

      final topY = groupStaves.first.topY;
      final bottomY = groupStaves.last.topY + groupStaves.last.height;

      final double systemLeftX = leftMarginX + system.leftIndentMm;
      final double connectorX = systemLeftX - group.connectorOffsetMm;

      // ── System barline (continuous or per-staff at systemLeftX) ────────
      if (group.initialBarline) {
        if (group.continuousBarlines && groupStaves.length > 1) {
          buf.writeln(
            '    <line x1="${_f(systemLeftX)}" y1="${_f(topY)}"'
            ' x2="${_f(systemLeftX)}" y2="${_f(bottomY)}"'
            ' stroke="black" stroke-width="${_f(strokeMm * 2.5)}"/>',
          );
        } else {
          for (final staff in groupStaves) {
            final sTop = staff.topY;
            final sBottom = staff.topY + staff.height;
            buf.writeln(
              '    <line x1="${_f(systemLeftX)}" y1="${_f(sTop)}"'
              ' x2="${_f(systemLeftX)}" y2="${_f(sBottom)}"'
              ' stroke="black" stroke-width="${_f(strokeMm * 2.5)}"/>',
            );
          }
        }
      }

      // ── Connector glyph ───────────────────────────────────────────────
      switch (group.connector) {
        case SystemConnector.brace when groupStaves.length >= 2:
          final double h = bottomY - topY;
          final double scale = h / 997.0;
          final double tx = connectorX - scale * 82.0;
          final double ty = bottomY;
          buf.writeln(
            '    <g transform="translate(${_f(tx)}, ${_f(ty)})'
            ' scale(${_f(scale)}, -${_f(scale)})" fill="black" stroke="none">'
            '<path d="$_braceSvg"/></g>',
          );
        case SystemConnector.bracket when groupStaves.length >= 2:
          final double endTickX =
              connectorX + GroupPlacementMetrics.bracketTickLengthMm;
          buf.writeln(
            '    <line x1="${_f(connectorX)}" y1="${_f(topY)}"'
            ' x2="${_f(connectorX)}" y2="${_f(bottomY)}"'
            ' stroke="black" stroke-width="${_f(strokeMm * 3.0)}"/>',
          );
          buf.writeln(
            '    <line x1="${_f(connectorX)}" y1="${_f(topY)}"'
            ' x2="${_f(endTickX)}" y2="${_f(topY)}"'
            ' stroke="black" stroke-width="${_f(strokeMm * 3.0)}"/>',
          );
          buf.writeln(
            '    <line x1="${_f(connectorX)}" y1="${_f(bottomY)}"'
            ' x2="${_f(endTickX)}" y2="${_f(bottomY)}"'
            ' stroke="black" stroke-width="${_f(strokeMm * 3.0)}"/>',
          );
        case SystemConnector.subBracket when groupStaves.length >= 2:
          // Thinner secondary bracket, no serif ticks.
          buf.writeln(
            '    <line x1="${_f(connectorX)}" y1="${_f(topY)}"'
            ' x2="${_f(connectorX)}" y2="${_f(bottomY)}"'
            ' stroke="black" stroke-width="${_f(strokeMm * 1.8)}"/>',
          );
        case SystemConnector.none:
        case SystemConnector.brace:
        case SystemConnector.bracket:
        case SystemConnector.subBracket:
          break;
      }
    }
  }
}

// --- High-fidelity SMuFL / Bravura Path Glyphs ---

// Bravura brace glyph (U+E000), extracted path. em=1000, yMin=0, yMax=997.
const String _braceSvg =
    'M 20.0,498.0 C 49.0,516.0 82.0,587.0 82.0,646.0 C 82.0,651.0 82.0,657.0 81.0,662.0 C 74.0,722.0 44.0,815.0 44.0,869.0 C 44.0,921.0 67.0,971.0 72.0,980.0 C 75.0,986.0 77.0,987.0 77.0,990.0 C 77.0,993.0 74.0,997.0 71.0,997.0 C 69.0,997.0 67.0,995.0 63.0,990.0 C 41.0,963.0 14.0,905.0 14.0,805.0 C 14.0,706.0 49.0,666.0 49.0,603.0 C 49.0,556.0 30.0,530.0 2.0,498.0 C 20.0,478.0 49.0,462.0 49.0,397.0 C 49.0,327.0 14.0,265.0 14.0,192.0 C 14.0,92.0 41.0,34.0 63.0,6.0 C 67.0,1.0 69.0,0.0 71.0,0.0 C 74.0,0.0 77.0,3.0 77.0,6.0 C 77.0,9.0 76.0,11.0 72.0,17.0 C 67.0,25.0 44.0,75.0 44.0,128.0 C 44.0,181.0 74.0,275.0 81.0,334.0 C 82.0,339.0 82.0,344.0 82.0,350.0 C 82.0,409.0 49.0,480.0 20.0,498.0 Z';

const String _gClefSvg =
    'M 376.0,415.0 C 374.0,427.0 376.0,428.0 382.0,434.0 C 490.0,535.0 572.0,662.0 572.0,815.0 C 572.0,902.0 548.0,988.0 507.0,1048.0 C 492.0,1070.0 466.0,1098.0 455.0,1098.0 C 441.0,1098.0 410.0,1072.0 390.0,1050.0 C 316.0,968.0 292.0,843.0 292.0,739.0 C 292.0,681.0 299.0,616.0 306.0,575.0 C 308.0,563.0 309.0,561.0 297.0,551.0 C 153.0,432.0 0.0,289.0 0.0,87.0 C 0.0,-87.0 119.0,-252.0 364.0,-252.0 C 387.0,-252.0 413.0,-250.0 433.0,-246.0 C 444.0,-244.0 446.0,-243.0 448.0,-255.0 C 460.0,-322.0 475.0,-409.0 475.0,-456.0 C 475.0,-604.0 375.0,-622.0 316.0,-622.0 C 262.0,-622.0 236.0,-606.0 236.0,-593.0 C 236.0,-586.0 245.0,-583.0 268.0,-576.0 C 299.0,-567.0 335.0,-540.0 335.0,-482.0 C 335.0,-427.0 300.0,-380.0 239.0,-380.0 C 172.0,-380.0 132.0,-433.0 132.0,-495.0 C 132.0,-560.0 171.0,-658.0 322.0,-658.0 C 389.0,-658.0 519.0,-628.0 519.0,-458.0 C 519.0,-401.0 501.0,-306.0 490.0,-244.0 C 488.0,-232.0 489.0,-233.0 503.0,-227.0 C 604.0,-187.0 671.0,-102.0 671.0,11.0 C 671.0,139.0 577.0,252.0 430.0,252.0 C 404.0,252.0 404.0,252.0 401.0,270.0 Z M 470.0,943.0 C 503.0,943.0 530.0,916.0 530.0,861.0 C 530.0,750.0 435.0,660.0 356.0,591.0 C 349.0,585.0 345.0,586.0 343.0,599.0 C 339.0,625.0 337.0,659.0 337.0,691.0 C 337.0,847.0 409.0,943.0 470.0,943.0 Z M 361.0,262.0 C 364.0,243.0 364.0,244.0 346.0,238.0 C 258.0,208.0 201.0,129.0 201.0,44.0 C 201.0,-46.0 248.0,-110.0 316.0,-133.0 C 324.0,-136.0 336.0,-139.0 343.0,-139.0 C 351.0,-139.0 355.0,-134.0 355.0,-128.0 C 355.0,-121.0 347.0,-118.0 340.0,-115.0 C 298.0,-97.0 268.0,-54.0 268.0,-8.0 C 268.0,49.0 307.0,92.0 368.0,109.0 C 384.0,113.0 386.0,112.0 388.0,101.0 L 438.0,-197.0 C 440.0,-208.0 439.0,-208.0 424.0,-211.0 C 408.0,-214.0 388.0,-216.0 368.0,-216.0 C 193.0,-216.0 80.0,-119.0 80.0,20.0 C 80.0,79.0 90.0,158.0 173.0,252.0 C 233.0,319.0 279.0,356.0 326.0,394.0 C 336.0,402.0 338.0,401.0 340.0,390.0 Z M 430.0,103.0 C 428.0,115.0 429.0,118.0 441.0,117.0 C 522.0,110.0 589.0,42.0 589.0,-46.0 C 589.0,-109.0 551.0,-160.0 495.0,-188.0 C 483.0,-194.0 481.0,-194.0 479.0,-182.0 Z';
const String _cClefSvg =
    'M 230.0,482.0 C 230.0,496.0 223.0,503.0 209.0,503.0 L 208.0,503.0 C 194.0,503.0 187.0,496.0 187.0,482.0 L 187.0,-482.0 C 187.0,-496.0 194.0,-503.0 208.0,-503.0 L 209.0,-503.0 C 223.0,-503.0 230.0,-496.0 230.0,-482.0 L 230.0,-44.0 C 230.0,-36.0 235.0,-37.0 239.0,-38.0 C 265.0,-45.0 307.0,-71.0 328.0,-184.0 C 331.0,-200.0 337.0,-209.0 347.0,-209.0 C 358.0,-209.0 363.0,-199.0 368.0,-182.0 C 381.0,-138.0 404.0,-89.0 475.0,-89.0 C 540.0,-89.0 558.0,-153.0 558.0,-284.0 C 558.0,-415.0 535.0,-474.0 452.0,-474.0 C 438.0,-474.0 367.0,-468.0 367.0,-447.0 C 367.0,-442.0 383.0,-436.0 394.0,-432.0 C 414.0,-425.0 434.0,-405.0 434.0,-367.0 C 434.0,-323.0 405.0,-298.0 366.0,-298.0 C 323.0,-298.0 289.0,-327.0 289.0,-380.0 C 289.0,-443.0 344.0,-506.0 463.0,-506.0 C 627.0,-506.0 699.0,-391.0 699.0,-287.0 C 699.0,-149.0 623.0,-53.0 490.0,-53.0 C 461.0,-53.0 442.0,-58.0 429.0,-62.0 C 419.0,-65.0 409.0,-67.0 400.0,-61.0 C 386.0,-52.0 364.0,-20.0 364.0,0.0 C 364.0,20.0 386.0,52.0 400.0,61.0 C 409.0,67.0 419.0,65.0 429.0,62.0 C 442.0,58.0 461.0,53.0 490.0,53.0 C 623.0,53.0 699.0,149.0 699.0,287.0 C 699.0,391.0 627.0,506.0 463.0,506.0 C 344.0,506.0 289.0,443.0 289.0,380.0 C 289.0,327.0 323.0,298.0 366.0,298.0 C 405.0,298.0 434.0,425.0 394.0,432.0 C 383.0,436.0 367.0,442.0 367.0,447.0 C 367.0,468.0 438.0,474.0 452.0,474.0 C 535.0,474.0 558.0,415.0 558.0,284.0 C 558.0,153.0 540.0,89.0 475.0,89.0 C 404.0,89.0 381.0,138.0 368.0,182.0 C 363.0,199.0 358.0,209.0 347.0,209.0 C 337.0,209.0 331.0,200.0 328.0,184.0 C 307.0,71.0 265.0,45.0 239.0,38.0 C 235.0,37.0 230.0,36.0 230.0,44.0 Z M 21.0,503.0 C 7.0,503.0 0.0,496.0 0.0,482.0 L 0.0,-482.0 C 0.0,-496.0 7.0,-503.0 21.0,-503.0 L 107.0,-503.0 C 121.0,-503.0 128.0,-496.0 128.0,-482.0 L 128.0,482.0 C 128.0,496.0 121.0,503.0 107.0,503.0 Z';
const String _fClefSvg =
    'M 252.0,262.0 C 78.0,262.0 0.0,135.0 0.0,39.0 C 0.0,-41.0 42.0,-110.0 123.0,-110.0 C 186.0,-110.0 229.0,-66.0 229.0,-4.0 C 229.0,60.0 182.0,100.0 133.0,100.0 C 106.0,100.0 96.0,93.0 83.0,93.0 C 70.0,93.0 67.0,101.0 67.0,111.0 C 67.0,151.0 127.0,224.0 229.0,224.0 C 335.0,224.0 381.0,120.0 381.0,-37.0 C 381.0,-316.0 243.0,-472.0 10.0,-605.0 C 1.0,-610.0 -5.0,-615.0 -5.0,-623.0 C -5.0,-629.0 -1.0,-635.0 8.0,-635.0 C 13.0,-635.0 19.0,-633.0 25.0,-630.0 C 271.0,-510.0 531.0,-332.0 531.0,-28.0 C 531.0,146.0 425.0,262.0 252.0,262.0 Z M 629.0,180.0 C 598.0,180.0 574.0,156.0 574.0,125.0 C 574.0,94.0 598.0,70.0 629.0,70.0 C 660.0,70.0 684.0,94.0 684.0,125.0 C 684.0,156.0 660.0,180.0 629.0,180.0 Z M 630.0,-71.0 C 599.0,-71.0 576.0,-94.0 576.0,-125.0 C 576.0,-156.0 599.0,-179.0 630.0,-179.0 C 661.0,-179.0 684.0,-156.0 684.0,-125.0 C 684.0,-94.0 661.0,-71.0 630.0,-71.0 Z';
const String _percClefSvg =
    'M 160.0,-235.0 L 160.0,235.0 C 160.0,243.0 154.0,250.0 146.0,250.0 L 14.0,250.0 C 6.0,250.0 0.0,243.0 0.0,235.0 L 0.0,-235.0 C 0.0,-243.0 6.0,-250.0 14.0,-250.0 L 146.0,-250.0 C 154.0,-250.0 160.0,-243.0 160.0,-235.0 Z M 382.0,235.0 C 382.0,243.0 376.0,250.0 368.0,250.0 L 236.0,250.0 C 228.0,250.0 222.0,243.0 222.0,235.0 L 222.0,-235.0 C 222.0,-243.0 228.0,-250.0 236.0,-250.0 L 368.0,-250.0 C 376.0,-250.0 382.0,-243.0 382.0,-235.0 Z';
const String _tabClef6Svg =
    'M 387.0,711.0 L 387.0,764.0 L 18.0,764.0 L 18.0,711.0 L 173.0,711.0 L 173.0,293.0 L 233.0,293.0 L 233.0,711.0 Z M 408.0,-228.0 L 243.0,242.0 L 165.0,242.0 L -3.0,-228.0 L 61.0,-228.0 L 111.0,-87.0 L 292.0,-87.0 L 341.0,-228.0 Z M 276.0,-36.0 L 126.0,-36.0 L 203.0,178.0 Z M 378.0,-613.0 C 378.0,-557.0 352.0,-522.0 292.0,-499.0 C 335.0,-479.0 357.0,-444.0 357.0,-397.0 C 357.0,-328.0 307.0,-277.0 218.0,-277.0 L 27.0,-277.0 L 27.0,-748.0 L 239.0,-748.0 C 324.0,-748.0 378.0,-691.0 378.0,-613.0 Z M 297.0,-405.0 C 297.0,-453.0 270.0,-480.0 203.0,-480.0 L 87.0,-480.0 L 87.0,-330.0 L 203.0,-330.0 C 270.0,-330.0 297.0,-357.0 297.0,-405.0 Z M 318.0,-614.0 C 318.0,-659.0 290.0,-695.0 234.0,-695.0 L 87.0,-695.0 L 87.0,-533.0 L 234.0,-533.0 C 290.0,-533.0 318.0,-568.0 318.0,-614.0 Z';

const String _tabClef4Svg =
    'M 258.0,469.0 L 258.0,504.0 L 11.0,504.0 L 11.0,469.0 L 115.0,469.0 L 115.0,189.0 L 155.0,189.0 L 155.0,469.0 Z M 272.0,-160.0 L 162.0,155.0 L 110.0,155.0 L -3.0,-160.0 L 40.0,-160.0 L 73.0,-65.0 L 195.0,-65.0 L 227.0,-160.0 Z M 184.0,-32.0 L 83.0,-32.0 L 135.0,112.0 Z M 252.0,-418.0 C 252.0,-380.0 235.0,-357.0 195.0,-342.0 C 223.0,-328.0 238.0,-305.0 238.0,-273.0 C 238.0,-227.0 205.0,-193.0 145.0,-193.0 L 17.0,-193.0 L 17.0,-508.0 L 159.0,-508.0 C 216.0,-508.0 252.0,-470.0 252.0,-418.0 Z M 198.0,-279.0 C 198.0,-311.0 180.0,-329.0 135.0,-329.0 L 57.0,-329.0 L 57.0,-228.0 L 135.0,-228.0 C 180.0,-228.0 198.0,-247.0 198.0,-279.0 Z M 212.0,-418.0 C 212.0,-449.0 194.0,-472.0 156.0,-472.0 L 57.0,-472.0 L 57.0,-364.0 L 156.0,-364.0 C 194.0,-364.0 212.0,-388.0 212.0,-418.0 Z';

