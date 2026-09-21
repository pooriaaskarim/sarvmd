// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'smufl_glyphs.dart';

/// Paints an authentic SMuFL Bravura TAB clef conforming to standard tablature engraving.
///
/// Automatically selects `tabClef4` (U+E06E) for staves with <= 4 lines or `tabClef6` (U+E06D)
/// for staves with > 4 lines.
///
/// Total visual height is scaled to 90% of the staff height, centered vertically
/// between line 1 and line N.
void paintTabClef(
  Canvas canvas,
  double x,
  double topY,
  int lines,
  double gap,
  Color color, {
  double scale = 1.0,
}) {
  final staffHeight = (lines > 1 ? lines - 1 : 1) * gap * scale;
  final staffCenterY = topY + staffHeight / 2.0;
  final tabHeight = staffHeight * 0.90;

  final (String glyph, double glyphHeight) = (lines <= 4)
      ? (SMuFLGlyphs.tabClef4, 1012.0)
      : (SMuFLGlyphs.tabClef6, 1512.0);

  // In Bravura font, 1000 font units = fontSize.
  // The glyph has visual height = glyphHeight font units.
  // To render visual height = tabHeight:
  // fontSize = tabHeight * (1000.0 / glyphHeight).
  final fontSize = tabHeight * (1000.0 / glyphHeight);

  final tp = TextPainter(
    text: TextSpan(
      text: glyph,
      style: TextStyle(
        fontFamily: 'Bravura',
        fontSize: fontSize,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final baselineDelta =
      tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);

  // In SMuFL, the alphabetic baseline (y=0) is positioned at the vertical midpoint of the TAB clef.
  // Aligning the baseline with staffCenterY centers the clef on the staff.
  final glyphY = staffCenterY - baselineDelta;

  tp.paint(canvas, Offset(x.roundToDouble(), glyphY.roundToDouble()));
}
