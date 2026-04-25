/// SVG emitter — generates a standalone `.svg` file representing the
/// manuscript layout.
///
/// Coordinates use millimetres; the SVG viewBox is set to the page dimensions
/// in mm so the file is scale-accurate at 1 mm = 1 user unit.

import 'config.dart';
import 'layout.dart';

String _f(double v) => v.toStringAsFixed(3);

/// Emit a complete standalone SVG string for the given config and layout.
String emitSvg(PageConfig config, PageLayout layout) {
  final buf = StringBuffer();
  final w = config.pageSize.width;
  final h = config.pageSize.height;

  buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buf.writeln(
    '<svg xmlns="http://www.w3.org/2000/svg"'
    ' viewBox="0 0 ${_f(w)} ${_f(h)}"'
    ' width="${_f(w)}mm" height="${_f(h)}mm">',
  );

  // White page background.
  buf.writeln('  <rect width="${_f(w)}" height="${_f(h)}" fill="white"/>');

  final gap = config.staffConfig.lineGapMm;
  // SVG stroke-width from thickness in pt → mm  (1 pt = 25.4/72 mm)
  final strokeMm = config.staffConfig.lineThicknessPt * 25.4 / 72.0;
  final leftX = config.margins.left;
  final rightX = w - config.margins.right;

  // Clef unicode codepoints and approximate em-based y offsets.
  // We render clefs with a text element using a generic serif fallback;
  // the font-size is set to 4× the line gap so proportions look right.
  const clefFontSizeMultiplier = 4.0;

  buf.writeln('  <g stroke="black" stroke-width="${_f(strokeMm)}" fill="none">');

  for (final system in layout.systems) {
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final topY = staff.topY;

      // 5 staff lines.
      for (var li = 0; li < 5; li++) {
        final y = topY + li * gap;
        buf.writeln(
          '    <line x1="${_f(leftX)}" y1="${_f(y)}"'
          ' x2="${_f(rightX)}" y2="${_f(y)}"/>',
        );
      }
    }

    // Barline connecting all staves in the system.
    final sysTopY = system.staves.first.topY;
    final sysBottomY =
        system.staves.last.topY + config.staffConfig.staffHeightMm;
    buf.writeln(
      '    <line x1="${_f(leftX)}" y1="${_f(sysTopY)}"'
      ' x2="${_f(leftX)}" y2="${_f(sysBottomY)}"/>',
    );

    // Piano brace (SVG cubic bezier, mirroring emitter.dart logic).
    if (config.layoutType == LayoutType.doubleLine) {
      _emitBraceSvg(buf, leftX, sysTopY, sysBottomY, strokeMm);
    }
  }

  buf.writeln('  </g>');

  // Clef glyphs as text elements.
  for (final system in layout.systems) {
    for (var si = 0; si < system.staves.length; si++) {
      final staff = system.staves[si];
      final clef = (config.layoutType == LayoutType.doubleLine && si == 1)
          ? config.secondaryClef
          : config.primaryClef;

      if (clef == null) continue;

      final fontSize = gap * clefFontSizeMultiplier;

      // Map anchor line (1=bottom, 5=top) to a Y position.
      // The "anchor" is the staff line the clef reference point sits on.
      // anchorY = topY + (5 - anchorLine) * gap
      final anchorY = staff.topY + (5 - clef.anchorLine) * gap;

      // Fractional ascent offsets (in staff-spaces) for each clef symbol,
      // matching the UI renderer's anchorSp values in preview_canvas.dart.
      final anchorSp = switch (clef.symbol) {
        ClefSymbol.g => 0.876,
        ClefSymbol.c => 2.0,
        ClefSymbol.f => 2.578,
      };

      // In SVG, text y is the baseline. We want the glyph's reference point
      // at anchorY, so baseline = anchorY + anchorSp * gap.
      final baselineY = anchorY + anchorSp * gap;
      final glyphX = leftX + gap * 0.15;

      final glyph = switch (clef.symbol) {
        ClefSymbol.g => '&#x1D11E;',
        ClefSymbol.c => '&#x1D121;',
        ClefSymbol.f => '&#x1D122;',
      };

      buf.writeln(
        '  <text x="${_f(glyphX)}" y="${_f(baselineY)}"'
        ' font-family="Noto Music,\'Noto Music\',serif"'
        ' font-size="${_f(fontSize)}"'
        ' fill="black"'
        ' dominant-baseline="alphabetic"'
        '>$glyph</text>',
      );
    }
  }

  buf.writeln('</svg>');
  return buf.toString();
}

void _emitBraceSvg(
  StringBuffer buf,
  double barX,
  double topY,
  double bottomY,
  double strokeMm,
) {
  final braceX = barX - 1.5; // 1.5 mm to the left.
  final midY = (topY + bottomY) / 2;
  final height = bottomY - topY;

  // Upper half cubic.
  buf.writeln(
    '  <path d="M ${_f(barX)} ${_f(topY)}'
    ' C ${_f(barX)} ${_f(topY + height * 0.15)}'
    ' ${_f(braceX)} ${_f(midY - height * 0.10)}'
    ' ${_f(braceX)} ${_f(midY)}"'
    ' stroke="black" stroke-width="${_f(strokeMm * 0.6)}" fill="none"/>',
  );

  // Lower half cubic.
  buf.writeln(
    '  <path d="M ${_f(braceX)} ${_f(midY)}'
    ' C ${_f(braceX)} ${_f(midY + height * 0.10)}'
    ' ${_f(barX)} ${_f(bottomY - height * 0.15)}'
    ' ${_f(barX)} ${_f(bottomY)}"'
    ' stroke="black" stroke-width="${_f(strokeMm * 0.6)}" fill="none"/>',
  );
}
