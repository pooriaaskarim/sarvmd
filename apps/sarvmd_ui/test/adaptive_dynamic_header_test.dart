// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/screens/mobile_editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/widgets/canvas/ruler_box.dart';
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

    testWidgets('Landscape viewport (height < 500dp) defaults to Unpinned Collapsed Title Pill and expands on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Unpinned collapsed title pill should be active by default
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsNothing);
      expect(find.byKey(const ValueKey('top_bar_pinned_bar')), findsNothing);

      // Collapsed pill contains only document title text, leaving canvas clear
      final expectedTitle = core.ScoreCompiler.getEffectiveTitle(
        documentCubit.state.score,
        documentCubit.state.config,
      );
      expect(find.text(expectedTitle), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing);

      // Tap compact title pill to expand normal top bar
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();

      // Normal top bar is now expanded with all controls
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('User can pin top bar in landscape mode via pin button', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially unpinned and collapsed
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);

      // Tap title pill to expand
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);

      // Tap pin button to lock it
      await tester.tap(find.byIcon(Icons.push_pin_outlined));
      await tester.pumpAndSettle();

      // Now pinned
      expect(find.byKey(const ValueKey('top_bar_pinned_bar')), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('User can collapse expanded unpinned floating bar back into compact title pill and auto-collapse on idle', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Initially collapsed
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);

      // Tap title pill to expand
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);

      // Tap collapse to title button
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      // Compact micro-pill should now be displayed
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsNothing);

      // Tap title pill to expand again and test auto-collapse after idle
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);

      // Advance clock past 5000ms idle timer
      await tester.pump(const Duration(milliseconds: 5100));
      await tester.pumpAndSettle();

      // Auto-collapsed back to title pill
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsNothing);
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

    testWidgets('Editing title in expanded unpinned top bar prevents auto-collapse during idle and saves on click outside', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap title pill to expand floating bar
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();

      // Tap title to begin editing
      final expectedDefaultTitle = core.ScoreCompiler.getEffectiveTitle(
        documentCubit.state.score,
        documentCubit.state.config,
      );
      await tester.tap(find.text(expectedDefaultTitle));
      await tester.pumpAndSettle();

      // TextField is now active
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Symphony No. 5');
      await tester.pump();

      // Advance clock past 5000ms idle timer
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pump();

      // Header must NOT collapse while editing
      expect(find.byKey(const ValueKey('top_bar_floating_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      // Tap outside the text field on the canvas area
      await tester.tapAt(const Offset(400, 300));
      await tester.pumpAndSettle();

      // Title should be saved in document state and rendered in expanded header
      expect(documentCubit.state.score.title, equals('Symphony No. 5'));
      expect(find.text('Symphony No. 5'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // Advance clock past idle timer to verify auto-collapse to title pill
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);
    });

    testWidgets('Editing title in expanded top bar saves name on system back button', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap title pill to expand
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();

      // Tap title to edit
      final expectedDefaultTitle = core.ScoreCompiler.getEffectiveTitle(
        documentCubit.state.score,
        documentCubit.state.config,
      );
      await tester.tap(find.text(expectedDefaultTitle));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Nocturne in C Minor');
      await tester.pump();

      // Simulate system back button
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Title should be saved in document state and edit mode exited
      expect(documentCubit.state.score.title, equals('Nocturne in C Minor'));
      expect(find.text('Nocturne in C Minor'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // Advance clock past idle timer
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);
    });

    testWidgets('Portrait mode title editing expands text field and hides flanking controls', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // In portrait pinned bar, all controls are initially present
      expect(find.byKey(const ValueKey('top_bar_pinned_bar')), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_title_edit_done_button_pinned')), findsNothing);

      // Tap title to begin editing
      final expectedDefaultTitle = core.ScoreCompiler.getEffectiveTitle(
        documentCubit.state.score,
        documentCubit.state.config,
      );
      await tester.tap(find.text(expectedDefaultTitle));
      await tester.pumpAndSettle();

      // Flanking controls must be hidden to give maximum room to title field
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(find.byIcon(Icons.push_pin), findsNothing);
      expect(find.byIcon(Icons.ios_share), findsNothing);

      // Done checkmark button must be displayed
      expect(find.byKey(const ValueKey('top_bar_title_edit_done_button_pinned')), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Enter new title
      await tester.enterText(find.byType(TextField), 'Sonata in F Major');
      await tester.pump();

      // Tap the Done checkmark button
      await tester.tap(find.byKey(const ValueKey('top_bar_title_edit_done_button_pinned')));
      await tester.pumpAndSettle();

      // Flanking controls must smoothly return
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_title_edit_done_button_pinned')), findsNothing);

      // Title updated
      expect(documentCubit.state.score.title, equals('Sonata in F Major'));
      expect(find.text('Sonata in F Major'), findsOneWidget);

      // Clean timer flush
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pumpAndSettle();
    });

    testWidgets('Narrow unpinned floating bar hides controls and displays Done button while editing title', (tester) async {
      tester.view.physicalSize = const Size(500, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Expand floating bar from compact pill
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();

      // Tap title to edit
      final expectedDefaultTitle = core.ScoreCompiler.getEffectiveTitle(
        documentCubit.state.score,
        documentCubit.state.config,
      );
      await tester.tap(find.text(expectedDefaultTitle));
      await tester.pumpAndSettle();

      // Flanking controls hidden in tight space (< 560dp width)
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.byIcon(Icons.ios_share), findsNothing);
      expect(find.byKey(const ValueKey('top_bar_title_edit_done_button')), findsOneWidget);

      // Tap Done
      await tester.tap(find.byKey(const ValueKey('top_bar_title_edit_done_button')));
      await tester.pumpAndSettle();

      // Controls restored
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar_title_edit_done_button')), findsNothing);

      // Wait past idle timer to complete clean tear down
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pumpAndSettle();
    });

    testWidgets('Unpinned canvas rulers respect top and left safe area (Proposal 2)', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 36.0, left: 24.0, bottom: 20.0, right: 0.0);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Top bar is unpinned by default in landscape (<500dp height)
      expect(find.byKey(const ValueKey('top_bar_compact_pill')), findsOneWidget);

      // Verify RulerBox received safe areas
      final rulerBoxFinder = find.byType(RulerBox);
      expect(rulerBoxFinder, findsOneWidget);
      final rulerBox = tester.widget<RulerBox>(rulerBoxFinder);
      expect(rulerBox.topSafeArea, equals(36.0));
      expect(rulerBox.leftSafeArea, equals(24.0));

      // Clean timer flush
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pumpAndSettle();
    });

    testWidgets('Collapsed floating top bar standardizes height to 40dp and has reactive width with min and max bounds', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Collapsed pill is active by default
      final pillFinder = find.byKey(const ValueKey('top_bar_compact_pill'));
      expect(pillFinder, findsOneWidget);

      // Verify standardized height matches 40.0dp
      final initialSize = tester.getSize(pillFinder);
      expect(initialSize.height, equals(40.0),
          reason: 'Collapsed pill height must be standardized to 40.0dp to match expanded bar and coordinates HUD');

      // Default title width is reactive and within [120.0, 340.0]
      expect(initialSize.width, greaterThanOrEqualTo(120.0));
      expect(initialSize.width, lessThanOrEqualTo(340.0));

      // Test short title: shrinks to minWidth (120.0)
      documentCubit.execute(core.SetTitleCommand('A'));
      await tester.pumpAndSettle();
      final shortSize = tester.getSize(pillFinder);
      expect(shortSize.height, equals(40.0));
      expect(shortSize.width, equals(120.0),
          reason: 'Short title should clamp to minimum width of 120.0dp');

      // Test long title: expands up to maximum width (<= 340.0)
      const longTitle = 'Symphony No. 9 in D Minor, Op. 125 "Choral" - Ludwig van Beethoven - Full Orchestral Score Edition';
      documentCubit.execute(core.SetTitleCommand(longTitle));
      await tester.pumpAndSettle();
      final longSize = tester.getSize(pillFinder);
      expect(longSize.height, equals(40.0));
      expect(longSize.width, greaterThan(shortSize.width),
          reason: 'Width must expand reactively with longer document title');
      expect(longSize.width, equals(340.0),
          reason: 'Very long title should clamp to maximum width of 340.0dp');

      // Expand to floating bar and verify height matches standardized 40.0dp
      await tester.tap(pillFinder);
      await tester.pumpAndSettle();
      final expandedBarFinder = find.byKey(const ValueKey('top_bar_floating_bar'));
      expect(expandedBarFinder, findsOneWidget);
      final expandedSize = tester.getSize(expandedBarFinder);
      expect(expandedSize.height, equals(40.0),
          reason: 'Expanded floating bar height must also be 40.0dp');

      // Clean timer flush
      await tester.pump(const Duration(milliseconds: 6000));
      await tester.pumpAndSettle();
    });
  });
}
