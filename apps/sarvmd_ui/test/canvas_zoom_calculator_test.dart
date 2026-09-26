// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/presentation/widgets/canvas/canvas_zoom_calculator.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/integrated_scale_control.dart';

void main() {
  group('CanvasZoomCalculator Tests', () {
    const config = core.PageConfig();

    test('actualSize computes scale from calibration factor', () {
      final result = CanvasZoomCalculator.compute(
        preset: ZoomPreset.actualSize,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 1000),
        config: config,
        calibrationFactor: 2.5,
      );

      expect(result.scale, equals(2.5));
      expect(result.matrix, isNotNull);
    });

    test('fitWidth computes correct horizontal scale and centers dx', () {
      final result = CanvasZoomCalculator.compute(
        preset: ZoomPreset.fitWidth,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        config: config,
        calibrationFactor: 1.0,
        padding: 40.0,
      );

      expect(result.scale, greaterThan(0));
      expect(result.dx, isNotNull);
      expect(result.dy, isNotNull);
    });

    test('fitScreen computes scale constrained by both width and height', () {
      final result = CanvasZoomCalculator.compute(
        preset: ZoomPreset.fitScreen,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        config: config,
        calibrationFactor: 1.0,
        padding: 24.0,
      );

      expect(result.scale, greaterThan(0));
      expect(result.dx, isNotNull);
      expect(result.dy, isNotNull);
    });
  });
}
