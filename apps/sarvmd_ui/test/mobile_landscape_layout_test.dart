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
import 'package:sarvmd_ui/src/presentation/widgets/common/ensemble_summary_widget.dart';
import 'package:sarvmd_ui/src/presentation/widgets/mobile/conductor_drawer.dart';
import 'package:sarvmd_ui/src/presentation/widgets/mobile/conductor_toolbar.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/profile_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Landscape vs Portrait Layout Tests', () {
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

    testWidgets('Portrait mode: renders ConductorDrawer and opens it via hamburger menu', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Scaffold has a non-null drawer
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNotNull, reason: 'Portrait mode must provide a side drawer');
      expect(scaffold.drawerEdgeDragWidth, equals(24.0));

      // Open drawer using top bar hamburger button
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Drawer should be open
      expect(find.byType(ConductorDrawer), findsOneWidget);
    });

    testWidgets('Landscape mode: suppresses scaffold drawer and opens ConductorDrawer as Left Side Sheet via menu button', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Scaffold drawer is null in landscape mode
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNull, reason: 'Landscape mode must omit side drawer to preserve canvas width');
      expect(scaffold.drawerEdgeDragWidth, equals(0.0));
      expect(find.byType(ConductorDrawer), findsNothing);

      // Expand top bar from collapsed title pill
      await tester.tap(find.byKey(const ValueKey('top_bar_compact_pill')));
      await tester.pumpAndSettle();

      // Tap top bar menu button
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // ConductorDrawer should appear as an elevated Left Side Sheet
      expect(find.byType(ConductorDrawer), findsOneWidget);

      // Verify all 5 categories are displayed simultaneously in dense landscape mode without scrolling
      expect(find.text('ENSEMBLE PROFILES'), findsOneWidget);
      expect(find.text('Page Settings'), findsOneWidget);
      expect(find.text('Staff Spacing'), findsOneWidget);
      expect(find.text('System Hierarchy & Clefs'), findsOneWidget);
      expect(find.text('Export Manuscript'), findsOneWidget);

      // Verify that scrolling down inside the side sheet reveals the unpinned Ensemble Summary and About
      await tester.drag(find.text('ENSEMBLE PROFILES'), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(EnsembleSummaryWidget), findsOneWidget);
      expect(find.text('About SarvMD'), findsOneWidget);

      // Scroll back up to tap Ensemble Profiles
      await tester.drag(find.text('Export Manuscript'), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify navigation inside ConductorDrawer: tap Ensemble Profiles
      expect(find.text('ENSEMBLE PROFILES'), findsOneWidget);
      await tester.tap(find.text('ENSEMBLE PROFILES'));
      await tester.pumpAndSettle();

      // Should navigate to ProfilePicker sub-page
      expect(find.byType(ProfilePicker), findsOneWidget);

      // Tap back button
      await tester.tap(find.byTooltip('Back to Menu'));
      await tester.pumpAndSettle();

      // Should return to main menu
      expect(find.text('ENSEMBLE PROFILES'), findsOneWidget);

      // Tap outside the panel on the backdrop scrim (x=600, y=200) to dismiss
      await tester.tapAt(const Offset(600, 200));
      await tester.pumpAndSettle();

      // Side sheet dismissed
      expect(find.byType(ConductorDrawer), findsNothing);
    });

    testWidgets('Landscape mode: ConductorToolbar tune icon opens ConductorDrawer as Left Side Sheet and backdrop closes it', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ConductorDrawer), findsNothing);

      // Find tune icon in ConductorToolbar
      final tuneFinder = find.descendant(
        of: find.byType(ConductorToolbar),
        matching: find.byIcon(Icons.tune),
      );
      expect(tuneFinder, findsOneWidget);

      await tester.tap(tuneFinder);
      await tester.pumpAndSettle();

      // ConductorDrawer should open as side sheet
      expect(find.byType(ConductorDrawer), findsOneWidget);

      // Tap backdrop scrim on the right side of the screen (e.g. x=600, y=200)
      await tester.tapAt(const Offset(600, 200));
      await tester.pumpAndSettle();

      // ConductorDrawer should be dismissed
      expect(find.byType(ConductorDrawer), findsNothing);
    });

    testWidgets('Landscape mode: Guides bottom sheet in ConductorToolbar does not overflow RenderFlex on short viewport', (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pump(const Duration(milliseconds: 300));

      // Find visibility icon (Guides) in ConductorToolbar
      final guidesIconFinder = find.descendant(
        of: find.byType(ConductorToolbar),
        matching: find.byIcon(Icons.visibility_outlined),
      );
      if (guidesIconFinder.evaluate().isEmpty) {
        // Expand collapsed baton if idle timer collapsed it
        await tester.tap(find.descendant(
          of: find.byType(ConductorToolbar),
          matching: find.byIcon(Icons.tune),
        ));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(guidesIconFinder, findsOneWidget);

      await tester.tap(guidesIconFinder);
      await tester.pumpAndSettle();

      // Verify Guides sheet is rendered without overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Mouse Guide Lines'), findsOneWidget);

      // Verify we can scroll to the bottom to see actual size / calibration tile
      await tester.drag(find.text('Mouse Guide Lines'), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Close the sheet
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
    });
  });
}
