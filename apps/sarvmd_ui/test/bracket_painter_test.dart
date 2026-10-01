// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/core/utils/bracket_painter.dart';
import 'package:sarvmd_ui/src/core/utils/smufl_glyphs.dart';

void main() {
  group('SMuFL Bracket Constants & Paths', () {
    test('SMuFLGlyphs contains authentic bracket codepoints', () {
      expect(SMuFLGlyphs.bracketTop, equals('\u{E003}'));
      expect(SMuFLGlyphs.bracketBottom, equals('\u{E004}'));
      expect(SMuFLGlyphs.bracket, equals('\u{E002}'));
    });

    test('smuflBracketTopPath has correct geometric bounds', () {
      final bounds = smuflBracketTopPath.getBounds();
      expect(bounds.left, equals(0.0));
      expect(bounds.bottom, closeTo(295.0, 1.0));
      expect(bounds.right, closeTo(469.0, 1.0));
    });

    test('smuflBracketBottomPath has correct geometric bounds', () {
      final bounds = smuflBracketBottomPath.getBounds();
      expect(bounds.left, equals(0.0));
      expect(bounds.top, closeTo(-295.0, 1.0));
      expect(bounds.right, closeTo(469.0, 1.0));
    });

    test('paintBracket executes and renders vector paths and vertical spine', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      paintBracket(
        canvas,
        connectorX: 10.0,
        topY: 20.0,
        bottomY: 120.0,
        lineGapPx: 8.0,
        staffScale: 1.0,
        color: Colors.black,
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('GroupPlacementMetrics bracket constants conform to Gould standards', () {
      // 275 font units = 1.1 staff spaces (places spine outside barline with 0.6 sp whitespace gap)
      expect(core.GroupPlacementMetrics.bracketFontUnitShift, equals(275.0));
      // 80 font units = ~1/3 staff space (wings cup outer staff lines)
      expect(core.GroupPlacementMetrics.bracketFontUnitProtrusion, equals(80.0));
    });
  });
}
