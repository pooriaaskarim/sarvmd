// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/screens/mobile_editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/widgets/mobile/mobile_top_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Coordinate HUD Long Press & Drag Tests', () {
    late LocaleCubit localeCubit;
    late ViewCubit viewCubit;
    late DocumentCubit documentCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeCubit = LocaleCubit(const LocaleState());
      viewCubit = ViewCubit(const ViewState());
      documentCubit = DocumentCubit();
    });

    tearDown(() {
      localeCubit.close();
      viewCubit.close();
      documentCubit.close();
    });

    Widget createTestWidget() {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: viewCubit),
          BlocProvider.value(value: documentCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MobileEditorScreen(),
        ),
      );
    }

    testWidgets('Long press on canvas shows top glassmorphic coordinate HUD below ruler', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Long press center of canvas
      await tester.longPressAt(const Offset(400, 300));
      await tester.pumpAndSettle();

      // Coordinate HUD should appear containing X: and Y: indicators
      expect(find.text('X: '), findsOneWidget);
      expect(find.text('Y: '), findsOneWidget);

      // Verify top HUD sits completely below the 25.0 dp top ruler
      final hudTop = tester.getTopLeft(find.byKey(const ValueKey('top_coord_hud_active'))).dy;
      expect(hudTop, greaterThanOrEqualTo(30.0),
          reason: 'Top coordinate HUD must sit cleanly below the top ruler without covering it');

      // Verify bottom RulerBox HUD ('TOP' / 'CTR' badge) is suppressed on mobile
      expect(find.text('TOP'), findsNothing,
          reason: 'Redundant bottom RulerBox coordinate HUD must be suppressed on mobile');
      expect(find.text('CTR'), findsNothing,
          reason: 'Redundant bottom RulerBox coordinate HUD must be suppressed on mobile');
    });

    testWidgets('Dragging finger updates coordinate readout in real-time', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start long press gesture in canvas center
      final gesture = await tester.startGesture(const Offset(400, 300));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('X: '), findsOneWidget);

      // Drag to new coordinate
      await gesture.moveTo(const Offset(450, 350));
      await tester.pumpAndSettle();

      // HUD should still be visible and updated
      expect(find.text('X: '), findsOneWidget);
      expect(find.text('Y: '), findsOneWidget);

      // Verify bottom RulerBox HUD remains suppressed during drag
      expect(find.text('TOP'), findsNothing);
      expect(find.text('CTR'), findsNothing);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('In unpinned mode, long-press coordinate dragging hides floating top bar and prevents conflicting visibility', (tester) async {
      tester.view.physicalSize = const Size(800, 400); // Landscape -> unpinned by default
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Top bar compact pill is visible by default in unpinned mode
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);

      // Verify compact pill sits below the 25.0 dp top ruler
      final pillTop = tester.getTopLeft(find.byKey(const ValueKey('top_bar_compact_pill'))).dy;
      expect(pillTop, greaterThanOrEqualTo(25.0),
          reason: 'Compact pill must sit below the top ruler so it does not cover graduation numbers');

      // Expand to floating bar
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);

      // Verify floating bar also sits below top ruler and past left ruler
      final barPos = tester.getTopLeft(find.byKey(const ValueKey('top_bar_floating_bar')));
      expect(barPos.dy, greaterThanOrEqualTo(25.0),
          reason: 'Floating bar must sit below top ruler');
      expect(barPos.dx, greaterThanOrEqualTo(25.0),
          reason: 'Floating bar must sit to the right of left ruler');

      // Now start long-press drag on canvas
      final gesture = await tester.startGesture(const Offset(400, 300));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Coordinate HUD is visible
      expect(find.byKey(const ValueKey('top_coord_hud_active')), findsOneWidget);

      // Floating top bar should be hidden (slid off with opacity 0)
      final topBarSlide = tester.widget<AnimatedSlide>(
        find.ancestor(
          of: find.byType(MobileTopBar),
          matching: find.byType(AnimatedSlide),
        ),
      );
      expect(topBarSlide.offset.dy, lessThan(0.0),
          reason: 'Floating top bar should slide off-screen during coordinate drag');

      final topBarOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(MobileTopBar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(topBarOpacity.opacity, equals(0.0),
          reason: 'Floating top bar should have 0.0 opacity during coordinate drag');

      await gesture.up();
      // Allow dismiss timer to flush cleanly
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });
  });
}
