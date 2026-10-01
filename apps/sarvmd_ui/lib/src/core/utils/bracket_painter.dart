// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Pre-compiled vector path for the top cap of an authentic SMuFL Bravura bracket (U+E003).
///
/// Coordinate system:
/// * Origin (0,0) connects to the top-left of the vertical bracket spine.
/// * Base width: 125 units (from x=0 to x=125 along y=0).
/// * Wing extends to x=469 (inwards towards staves) and curves upwards to y=295.
final Path smuflBracketTopPath = () {
  final path = Path()
    ..moveTo(0.0, 0.0)
    ..lineTo(125.0, 0.0)
    ..cubicTo(285.0, 30.0, 428.0, 104.0, 468.0, 271.0)
    ..cubicTo(469.0, 275.0, 469.0, 278.0, 469.0, 281.0)
    ..cubicTo(469.0, 289.0, 466.0, 293.0, 461.0, 295.0)
    ..cubicTo(452.0, 295.0, 441.0, 288.0, 436.0, 281.0)
    ..cubicTo(426.0, 270.0, 300.0, 138.0, 109.0, 124.0)
    ..lineTo(8.0, 124.0)
    ..cubicTo(2.0, 124.0, 0.0, 123.0, 0.0, 117.0)
    ..close();
  return path;
}();

/// Pre-compiled vector path for the bottom cap of an authentic SMuFL Bravura bracket (U+E004).
///
/// Coordinate system:
/// * Origin (0,0) connects to the bottom-left of the vertical bracket spine.
/// * Base width: 125 units (from x=0 to x=125 along y=0).
/// * Wing extends to x=469 (inwards towards staves) and curves downwards to y=-295.
final Path smuflBracketBottomPath = () {
  final path = Path()
    ..moveTo(0.0, -117.0)
    ..cubicTo(0.0, -123.0, 2.0, -124.0, 8.0, -124.0)
    ..lineTo(109.0, -124.0)
    ..cubicTo(300.0, -138.0, 426.0, -270.0, 436.0, -281.0)
    ..cubicTo(441.0, -288.0, 452.0, -295.0, 461.0, -295.0)
    ..cubicTo(466.0, -293.0, 469.0, -289.0, 469.0, -281.0)
    ..cubicTo(469.0, -278.0, 469.0, -275.0, 468.0, -271.0)
    ..cubicTo(428.0, -104.0, 285.0, -30.0, 125.0, 0.0)
    ..lineTo(0.0, 0.0)
    ..close();
  return path;
}();

/// Paints an authentic SMuFL Bravura orchestral bracket on [canvas].
///
/// The bracket is composed of:
/// 1. Top terminal cap ([smuflBracketTopPath] / `bracketTop` U+E003)
/// 2. Solid vertical spine of width `125 * scale`
/// 3. Bottom terminal cap ([smuflBracketBottomPath] / `bracketBottom` U+E004)
void paintBracket(
  Canvas canvas, {
  required double connectorX,
  required double topY,
  required double bottomY,
  required double lineGapPx,
  double staffScale = 1.0,
  required Color color,
}) {
  // In SMuFL standard, 1 staff space = 250 Bravura font units
  final double s = (lineGapPx * staffScale) / 250.0;
  final double shiftX = core.GroupPlacementMetrics.bracketFontUnitShift * s;
  final double vProtrusion =
      core.GroupPlacementMetrics.bracketFontUnitProtrusion * s;
  final double bracketX = connectorX - shiftX;
  final double topBracketY = topY - vProtrusion;
  final double bottomBracketY = bottomY + vProtrusion;
  final double spineWidth = 125.0 * s;
  final double spineHeight = bottomBracketY - topBracketY;

  final fillPaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  // 1. Bracket Top Cap (bracketTop U+E003)
  canvas.save();
  canvas.translate(bracketX, topBracketY);
  canvas.scale(s, -s);
  canvas.drawPath(smuflBracketTopPath, fillPaint);
  canvas.restore();

  // 2. Vertical Spine
  canvas.drawRect(
    Rect.fromLTWH(bracketX, topBracketY, spineWidth, spineHeight),
    fillPaint,
  );

  // 3. Bracket Bottom Cap (bracketBottom U+E004)
  canvas.save();
  canvas.translate(bracketX, bottomBracketY);
  canvas.scale(s, -s);
  canvas.drawPath(smuflBracketBottomPath, fillPaint);
  canvas.restore();
}
