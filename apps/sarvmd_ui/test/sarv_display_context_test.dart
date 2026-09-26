// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/core/theme/sarv_display_context.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SarvDisplayData Unit Tests', () {
    test('Correctly classifies phone form factor (< 600 width)', () {
      const data = SarvDisplayData(
        inputMode: InputMode.touch,
        formFactor: SarvFormFactor.phone,
        orientation: Orientation.portrait,
        size: Size(390, 844),
      );

      expect(data.isPhone, isTrue);
      expect(data.isTablet, isFalse);
      expect(data.isDesktop, isFalse);
      expect(data.isTouch, isTrue);
      expect(data.isPointer, isFalse);
      expect(data.isPortrait, isTrue);
      expect(data.isLandscape, isFalse);
      expect(data.preferBottomSheet, isTrue);
      expect(data.isCompactWidth, isTrue);
      expect(data.isNarrowTab, isTrue);
    });

    test('Correctly classifies tablet form factor (600 - 1023 width)', () {
      const data = SarvDisplayData(
        inputMode: InputMode.touch,
        formFactor: SarvFormFactor.tablet,
        orientation: Orientation.landscape,
        size: Size(820, 1180),
      );

      expect(data.isPhone, isFalse);
      expect(data.isTablet, isTrue);
      expect(data.isDesktop, isFalse);
      expect(data.isTouch, isTrue);
      expect(data.isPointer, isFalse);
      expect(data.isLandscape, isTrue);
      expect(data.preferBottomSheet, isFalse);
      expect(data.isCompactWidth, isFalse);
      expect(data.isNarrowTab, isFalse);
    });

    test('Correctly classifies desktop form factor (>= 1024 width)', () {
      const data = SarvDisplayData(
        inputMode: InputMode.pointer,
        formFactor: SarvFormFactor.desktop,
        orientation: Orientation.landscape,
        size: Size(1440, 900),
      );

      expect(data.isPhone, isFalse);
      expect(data.isTablet, isFalse);
      expect(data.isDesktop, isTrue);
      expect(data.isPointer, isTrue);
      expect(data.isTouch, isFalse);
      expect(data.preferBottomSheet, isFalse);
    });

    test('Recommends bottom sheet when height is small (< 600)', () {
      const data = SarvDisplayData(
        inputMode: InputMode.pointer,
        formFactor: SarvFormFactor.desktop,
        orientation: Orientation.landscape,
        size: Size(1200, 500),
      );

      expect(data.isDesktop, isTrue);
      expect(data.preferBottomSheet, isTrue);
    });
  });

  group('SarvDisplayContext Widget Tests', () {
    testWidgets('Provides SarvDisplayData down the widget tree', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SarvDisplayData retrievedData;

      await tester.pumpWidget(
        MaterialApp(
          home: SarvDisplayScope(
            inputModeOverride: InputMode.touch,
            child: Builder(
              builder: (context) {
                retrievedData = context.sarvDisplay;
                return const Scaffold(body: Text('Hello'));
              },
            ),
          ),
        ),
      );

      expect(retrievedData.isPhone, isTrue);
      expect(retrievedData.isTouch, isTrue);
      expect(retrievedData.size.width, equals(400));
    });

    testWidgets('Falls back to dynamic calculation if no SarvDisplayScope', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late SarvDisplayData retrievedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              retrievedData = SarvDisplayContext.of(context);
              return const Scaffold(body: Text('Fallback'));
            },
          ),
        ),
      );

      expect(retrievedData.isDesktop, isTrue);
      expect(retrievedData.isPointer, isTrue);
      expect(retrievedData.size.width, equals(1200));
    });
  });
}
