// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

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

  group('Adaptive Dynamic Header ("Zen Top Bar") Tests', () {
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

    Widget createTestApp() {
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

    testWidgets('Portrait viewport (height >= 500dp) defaults to Pinned top bar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Pinned bar should be active
      expect(find.byKey(const ValueKey('top_bar_pinned_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsNothing);
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsNothing);

      // Pin button indicates pinned state
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('Landscape viewport (height < 500dp) defaults to Unpinned Floating bar', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Unpinned floating bar should be active
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_pinned_bar')), findsNothing);

      // Pin button indicates unpinned state
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byIcon(Icons.unfold_less), findsOneWidget);
    });

    testWidgets('User can pin top bar in landscape mode via pin button', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially unpinned
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);

      // Tap pin button to lock it
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();

      // Now pinned
      expect(find.byKey(const ValueKey('top_bar_pinned_bar')), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('User can minimize unpinned floating bar into compact micro-pill and expand back', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap minimize to pill button
      await tester.tap(find.byIcon(Icons.unfold_less));
      await tester.pumpAndSettle();

      // Compact micro-pill should now be displayed
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsNothing);

      // Menu button is preserved in compact pill
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Tap expand button to restore full floating bar
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsNothing);
    });

    testWidgets('Unpinned top bar auto-slides off-screen during canvas pan/zoom interaction', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially visible at Offset.zero
      final slideFinder = find.ancestor(
        of: find.byType(MobileTopBar),
        matching: find.byType(AnimatedSlide),
      );
      expect(slideFinder, findsOneWidget);
      final initialSlide = tester.widget<AnimatedSlide>(slideFinder);
      expect(initialSlide.offset, equals(Offset.zero));

      // Drag on canvas area to trigger scale/pan interaction
      final gesture = await tester.startGesture(const Offset(400, 200));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // Top bar should now be sliding off-screen (target offset: Offset(0, -1.3))
      final movingSlide = tester.widget<AnimatedSlide>(slideFinder);
      expect(movingSlide.offset.dy, lessThan(0.0));

      // Complete gesture and wait past 600ms debounce
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Top bar returns to Offset.zero
      final settledSlide = tester.widget<AnimatedSlide>(slideFinder);
      expect(settledSlide.offset, equals(Offset.zero));
    });
  });
}
