// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/precision_slider.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/margins_settings_group.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/staff_spacing_group.dart';

Widget _wrapWithMaterial(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scrubbable Numeric Inputs - Text Selection and Scrubbing Parity', () {
    testWidgets(
        'MarginsSettingsGroup: text fields have enableInteractiveSelection == false and scrub cleanly',
        (tester) async {
      core.Margins currentMargins = const core.Margins(
        top: 20.0,
        bottom: 20.0,
        left: 20.0,
        right: 20.0,
      );

      String? activeScrubSide;
      bool scrubEnded = false;

      await tester.pumpWidget(
        _wrapWithMaterial(
          StatefulBuilder(
            builder: (context, setState) {
              return MarginsSettingsGroup(
                margins: currentMargins,
                onLeftChanged: (v) => setState(() => currentMargins = currentMargins.copyWith(left: v)),
                onRightChanged: (v) => setState(() => currentMargins = currentMargins.copyWith(right: v)),
                onTopChanged: (v) => setState(() => currentMargins = currentMargins.copyWith(top: v)),
                onBottomChanged: (v) => setState(() => currentMargins = currentMargins.copyWith(bottom: v)),
                onHorizontalChanged: (v) => setState(() => currentMargins = currentMargins.copyWith(left: v, right: v)),
                onVerticalChanged: (v) => setState(() => currentMargins = currentMargins.copyWith(top: v, bottom: v)),
                onReset: () {},
                onScrubStart: (side) => activeScrubSide = side,
                onScrubEnd: () => scrubEnded = true,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all TextFields inside MarginsSettingsGroup
      final textFieldFinders = find.descendant(
        of: find.byType(MarginsSettingsGroup),
        matching: find.byType(TextField),
      );
      expect(textFieldFinders, findsWidgets);

      // Verify all TextFields have interactive selection disabled
      for (final element in tester.widgetList<TextField>(textFieldFinders)) {
        expect(
          element.enableInteractiveSelection,
          isFalse,
          reason: 'Text selection must be disabled so drag scrubs value instead of selecting text',
        );
      }

      // Test tapping selects all text
      final firstTextFieldFinder = textFieldFinders.first;
      await tester.tap(firstTextFieldFinder);
      await tester.pump();

      final firstTextField = tester.widget<TextField>(firstTextFieldFinder);
      expect(firstTextField.controller?.selection.baseOffset, 0);
      expect(
        firstTextField.controller?.selection.extentOffset,
        firstTextField.controller?.text.length,
      );

      // Drag horizontally to scrub the value
      final initialValue = currentMargins.top;
      await tester.drag(firstTextFieldFinder, const Offset(60, 0));
      await tester.pumpAndSettle();

      // Scrub callbacks should have fired
      expect(activeScrubSide, isNotNull);
      expect(scrubEnded, isTrue);
      // Value should have increased
      expect(currentMargins.top, greaterThan(initialValue));

      // After dragging starts, the field should have unfocused
      final focusedChild = FocusScope.of(tester.element(firstTextFieldFinder)).focusedChild;
      expect(focusedChild, isNull);
    });

    testWidgets(
        'StaffSpacingGroup: text fields have enableInteractiveSelection == false and scrub cleanly',
        (tester) async {
      core.StaffConfig config = const core.StaffConfig(
        lineGapMm: 1.75,
        systemGapMm: 12.0,
        interStaffGapMm: 8.0,
      );

      await tester.pumpWidget(
        _wrapWithMaterial(
          StatefulBuilder(
            builder: (context, setState) {
              return StaffSpacingGroup(
                staffConfig: config,
                isDoubleLine: false,
                lines: 5,
                onLineGapChanged: (v) => setState(() => config = core.StaffConfig(
                  lineThicknessPt: config.lineThicknessPt,
                  lineGapMm: v,
                  systemGapMm: config.systemGapMm,
                  interStaffGapMm: config.interStaffGapMm,
                )),
                onSystemGapChanged: (v) => setState(() => config = core.StaffConfig(
                  lineThicknessPt: config.lineThicknessPt,
                  lineGapMm: config.lineGapMm,
                  systemGapMm: v,
                  interStaffGapMm: config.interStaffGapMm,
                )),
                onInterStaffGapChanged: (v) => setState(() => config = core.StaffConfig(
                  lineThicknessPt: config.lineThicknessPt,
                  lineGapMm: config.lineGapMm,
                  systemGapMm: config.systemGapMm,
                  interStaffGapMm: v,
                )),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all TextFields inside StaffSpacingGroup
      final textFieldFinders = find.descendant(
        of: find.byType(StaffSpacingGroup),
        matching: find.byType(TextField),
      );
      expect(textFieldFinders, findsWidgets);

      // Verify all TextFields have interactive selection disabled
      for (final element in tester.widgetList<TextField>(textFieldFinders)) {
        expect(
          element.enableInteractiveSelection,
          isFalse,
          reason: 'Text selection must be disabled on staff spacing inputs',
        );
      }

      // Tap first field and verify all text is selected
      final firstTextFieldFinder = textFieldFinders.first;
      await tester.tap(firstTextFieldFinder);
      await tester.pump();

      final firstTextField = tester.widget<TextField>(firstTextFieldFinder);
      expect(firstTextField.controller?.selection.baseOffset, 0);
      expect(
        firstTextField.controller?.selection.extentOffset,
        firstTextField.controller?.text.length,
      );

      // Drag to scrub
      final initialGap = config.lineGapMm;
      await tester.drag(firstTextFieldFinder, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(config.lineGapMm, greaterThan(initialGap));

      // After dragging, field should be unfocused
      final focusedChild = FocusScope.of(tester.element(firstTextFieldFinder)).focusedChild;
      expect(focusedChild, isNull);
    });

    testWidgets(
        'PrecisionSlider: TextField has enableInteractiveSelection == false and auto-selects on tap',
        (tester) async {
      double sliderVal = 10.0;

      await tester.pumpWidget(
        _wrapWithMaterial(
          StatefulBuilder(
            builder: (context, setState) {
              return PrecisionSlider(
                label: 'Test Slider',
                value: sliderVal,
                min: 0.0,
                max: 100.0,
                onChanged: (v) => setState(() => sliderVal = v),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFieldFinder = find.descendant(
        of: find.byType(PrecisionSlider),
        matching: find.byType(TextField),
      );
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.enableInteractiveSelection, isFalse);

      await tester.tap(textFieldFinder);
      await tester.pump();

      expect(textField.controller?.selection.baseOffset, 0);
      expect(
        textField.controller?.selection.extentOffset,
        textField.controller?.text.length,
      );
    });
  });
}
