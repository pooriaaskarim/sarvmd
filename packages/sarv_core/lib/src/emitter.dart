/// LaTeX emitter — generates `.tex` source using `\pdfliteral direct` for
/// drawing.
///
/// All coordinates use PDF big points (bp): 1 bp = 1/72 inch ≈ 0.3528 mm.
/// The PDF coordinate origin is at the bottom-left of the page.
/// Using `\pdfliteral direct` writes operators directly into the page content
/// stream using absolute page coordinates.

import 'config.dart';
import 'layout.dart';

/// Millimeters to PDF big points.
double _mmToBp(double mm) => mm * 72.0 / 25.4;

/// Format a double to 2 decimal places for PDF operators.
String _f(double v) => v.toStringAsFixed(2);

/// Emit a complete `.tex` document string for the given config and layout.
String emit(PageConfig config, PageLayout layout) {
  final buf = StringBuffer();

  final pageW = config.pageSize.width;
  final pageH = config.pageSize.height;

  // Document preamble.
  buf.writeln(r'\documentclass{article}');
  buf.writeln(
    '\\usepackage[paperwidth=${pageW}mm,paperheight=${pageH}mm,'
    'margin=0mm]{geometry}',
  );
  buf.writeln(r'\pagestyle{empty}');
  buf.writeln(r'\begin{document}');

  // Build the PDF drawing commands using absolute page coordinates.
  // pdfliteral direct writes into the content stream at the page level,
  // using the PDF coordinate system (origin = bottom-left, y up).
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
      // staff.topY is from page top in mm. Convert to PDF y (from bottom).
      final topLinePdfY = pageHBp - _mmToBp(staff.topY);

      // Draw 5 lines, top to bottom.
      for (var line = 0; line < 5; line++) {
        final y = topLinePdfY - line * lineGapBp;
        draw.writeln(
          '${_f(staffLeftBp)} ${_f(y)} m ${_f(staffRightBp)} ${_f(y)} l S',
        );
      }
    }

    // Draw barline at the start of each system (thin vertical line).
    final sysTopPdfY = pageHBp - _mmToBp(system.staves.first.topY);
    final sysBottomPdfY = pageHBp -
        _mmToBp(
          system.staves.last.topY + config.staffConfig.staffHeightMm,
        );
    draw.writeln(
      '${_f(staffLeftBp)} ${_f(sysTopPdfY)} m '
      '${_f(staffLeftBp)} ${_f(sysBottomPdfY)} l S',
    );

    // Piano brace.
    if (config.layoutType == LayoutType.doubleLine) {
      _emitBrace(draw, staffLeftBp, sysTopPdfY, sysBottomPdfY);
    }
  }

  draw.writeln('Q'); // Restore graphics state.

  // 1) Empty hbox to set current point (top-left for 0 margin).
  buf.writeln('\\hbox{}');
  
  // 2) Emitted text labels (Clefs) via picture environment
  // We place it at (0,0) so it doesn't disrupt the flow.
  buf.writeln('\\unitlength 1bp');
  buf.writeln('\\begin{picture}(0,0)');
  for (final system in layout.systems) {
    for (var i = 0; i < system.staves.length; i++) {
      final staff = system.staves[i];
      final clef = (config.layoutType == LayoutType.doubleLine && i == 1)
          ? config.secondaryClef
          : config.primaryClef;
      
      if (clef != null) {
        final topLinePdfY = pageHBp - _mmToBp(staff.topY);
        // Anchor line: 1 is bottom, 5 is top.
        // Line 5 = topLinePdfY
        // Line 4 = topLinePdfY - lineGapBp
        // Line y = topLinePdfY - (5 - anchorLine) * lineGapBp
        final cy = topLinePdfY - (5 - clef.anchorLine) * lineGapBp;
        
        // Place just right of the barline. Left margin + roughly 15 bp.
        final cx = staffLeftBp + 15.0;
        
        // Use a stylized text.
        final latexScale = switch (clef.symbol) {
          ClefSymbol.g => r'\huge',
          ClefSymbol.c => r'\LARGE',
          ClefSymbol.f => r'\Large',
        };
        
        buf.writeln(
          '\\put(${_f(cx)},${_f(cy)}){'
          '\\makebox(0,0){$latexScale\\textit{${clef.symbol.label}}}}'
        );
      }
    }
  }
  buf.writeln('\\end{picture}');

  // 3) Use \pdfliteral direct to write graphics at absolute page coordinates.
  buf.writeln('\\pdfliteral direct {${draw.toString()}}');
  buf.writeln(r'\end{document}');

  return buf.toString();
}

/// Emit a piano brace as a Bézier curve to the left of the barline.
void _emitBrace(
  StringBuffer draw,
  double barX,
  double topY,
  double bottomY,
) {
  // Brace sits to the left of the barline.
  final braceX = barX - 6.0; // 6bp to the left.
  final midY = (topY + bottomY) / 2;
  final height = topY - bottomY;

  // Thin stroke for the brace.
  draw.writeln('0.6 w');

  // Upper half: from top down to middle, curving left.
  draw.writeln(
    '${_f(barX)} ${_f(topY)} m '
    '${_f(barX)} ${_f(topY - height * 0.15)} '
    '${_f(braceX)} ${_f(midY + height * 0.10)} '
    '${_f(braceX)} ${_f(midY)} c S',
  );

  // Lower half: from middle down to bottom, curving right.
  draw.writeln(
    '${_f(braceX)} ${_f(midY)} m '
    '${_f(braceX)} ${_f(midY - height * 0.10)} '
    '${_f(barX)} ${_f(bottomY + height * 0.15)} '
    '${_f(barX)} ${_f(bottomY)} c S',
  );
}
