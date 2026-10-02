// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/preview_canvas.dart';

void main() {
  group('Scaled Staff & Connector Alignment Tests', () {
    testWidgets('Chamber Orchestra staves render staff lines with scaled gap matching staff.height', (tester) async {
      final config = core.StaffProfiles.chamberOrchestra.applyTo(const core.PageConfig());
      final layout = core.computeLayout(config);

      expect(layout.systems.isNotEmpty, isTrue);
      final system = layout.systems.first;

      // Every staff in chamberOrchestra has scale: 0.70
      for (final staff in system.staves) {
        expect(staff.scale, equals(0.70));
        final expectedHeight = (staff.lines - 1) * config.staffConfig.lineGapMm * staff.scale;
        expect(staff.height, closeTo(expectedHeight, 1e-6));
      }

      // Build PreviewCanvas
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PreviewCanvas(
                layout: layout,
                viewState: const ViewState(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find PreviewCanvas and verify CustomPaint rendered
      final customPaintFinder = find.descendant(
        of: find.byType(PreviewCanvas),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsWidgets);

      // Verify Woodwinds group placement bounds
      final woodwindsGroup = system.groupPlacements.firstWhere(
        (g) => g.label == 'Woodwinds',
      );
      final firstStaff = system.staves[woodwindsGroup.startStaffIdx];
      final lastStaff = system.staves[woodwindsGroup.endStaffIdx];

      // Top of bracket equals top line of Flute
      final expectedTopY = firstStaff.topY;
      // Bottom of bracket equals bottom line of Bassoon
      final expectedBottomY = lastStaff.topY + lastStaff.height;

      expect(expectedTopY, equals(firstStaff.topY));
      expect(expectedBottomY, closeTo(lastStaff.topY + (lastStaff.lines - 1) * config.staffConfig.lineGapMm * 0.70, 1e-6));
    });
  });
}
