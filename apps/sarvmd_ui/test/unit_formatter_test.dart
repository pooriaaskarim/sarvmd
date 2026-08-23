// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/core/utils/unit_formatter.dart';

void main() {
  group('UnitFormatter Unit Tests', () {
    test('formatMm formats millimeters with unit and ASCII digits', () {
      expect(UnitFormatter.formatMm(210.0), equals('210.0 mm'));
      expect(UnitFormatter.formatMm(7.54, decimals: 2), equals('7.54 mm'));
      expect(UnitFormatter.formatMm(50.0, includeUnit: false), equals('50.0'));
    });

    test('formatPt formats points with unit and ASCII digits', () {
      expect(UnitFormatter.formatPt(7.0), equals('7.0 pt'));
      expect(UnitFormatter.formatPt(12.5, includeUnit: false), equals('12.5'));
    });

    test('formatPercent formats percentages correctly', () {
      expect(UnitFormatter.formatPercent(1.0), equals('100%'));
      expect(UnitFormatter.formatPercent(0.75), equals('75%'));
      expect(UnitFormatter.formatPercent(1.25, includeSymbol: false), equals('125'));
    });

    test('formatDimensions formats paper dimension pairs', () {
      expect(UnitFormatter.formatDimensions(210.0, 297.0), equals('210.0 × 297.0 mm'));
    });

    test('formatResolution formats pixel resolution with and without DPI', () {
      expect(UnitFormatter.formatResolution(1920, 1080), equals('1920 × 1080 px'));
      expect(UnitFormatter.formatResolution(1920, 1080, dpi: 300), equals('1920 × 1080 px (300 DPI)'));
    });

    test('formatPpi formats display density', () {
      expect(UnitFormatter.formatPpi(96), equals('96 PPI'));
    });
  });
}
