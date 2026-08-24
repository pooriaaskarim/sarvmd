// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/calibration_dialog.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CalibrationDialog Tests', () {
    testWidgets('PPI indicator reacts dynamically when nudged or adjusted', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'view_calibration_factor': 1.0});
      final viewCubit = ViewCubit(const ViewState(calibrationFactor: 1.0));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalibrationDialog(viewCubit: viewCubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at default factor (1.0), with devicePixelRatio = 1.0 => 96 PPI
      expect(find.text('96 PPI'), findsOneWidget);

      // Find the add (+)/nudge button and tap it multiple times to change calibration factor
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);

      // Tap add button 10 times to noticeably change factor (+0.05)
      for (var i = 0; i < 10; i++) {
        await tester.tap(addButton);
      }
      await tester.pumpAndSettle();

      // 1.05 * 96 = 100.8 -> 101 PPI. Verify it is no longer stuck at 96 PPI!
      expect(find.text('96 PPI'), findsNothing);
      expect(find.text('101 PPI'), findsOneWidget);

      // Tap reset button to return to default
      final resetButton = find.byIcon(Icons.restart_alt);
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // PPI readout should return to 96 PPI
      expect(find.text('96 PPI'), findsOneWidget);
    });
  });
}
