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
import 'package:sarvmd_ui/src/presentation/screens/editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/widgets/panels/view_panel.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/profile_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Desktop Responsive Breakpoint & Overlay Drawer Tests', () {
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
          home: EditorScreen(),
        ),
      );
    }

    testWidgets('Wide Desktop (1400x900): both sidebars can dock in Row', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // On wide desktop (>= 1200), both sidebar content and view panel can be docked
      expect(find.byType(ProfilePicker), findsOneWidget);
      expect(find.byType(ViewPanel), findsOneWidget);
      expect(find.byTooltip('Collapse Left Sidebar'), findsOneWidget);
      expect(find.byTooltip('Collapse Settings'), findsOneWidget);
    });

    testWidgets('Medium Desktop (1050x800): docks left sidebar, right panel is overlay drawer', (tester) async {
      tester.view.physicalSize = const Size(1050, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Left sidebar is docked
      expect(find.byType(ProfilePicker), findsOneWidget);

      // Right panel auto-collapsed on medium desktop (< 1200)
      expect(find.byTooltip('Open Settings'), findsOneWidget);

      // Tap right toggle button to open overlay drawer
      await tester.tap(find.byTooltip('Open Settings'));
      await tester.pumpAndSettle();

      // ViewPanel is now visible inside overlay drawer
      expect(find.byType(ViewPanel), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Close the overlay drawer via close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Open Settings'), findsOneWidget);
    });

    testWidgets('Compact Desktop (750x700): both sidebars auto-collapse, no RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(750, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify no overflow occurred and both toggles are in open/expand state
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Open Sidebar'), findsOneWidget);
      expect(find.byTooltip('Open Settings'), findsOneWidget);

      // Open left sidebar overlay drawer
      await tester.tap(find.byTooltip('Open Sidebar'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePicker), findsOneWidget);

      // Close left sidebar overlay drawer via close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Open Sidebar'), findsOneWidget);

      // Open right view panel overlay drawer
      await tester.tap(find.byTooltip('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(ViewPanel), findsOneWidget);

      // Dismiss overlay via tapping backdrop scrim
      // The scrim is positioned at the top-left area not covered by the right drawer
      await tester.tapAt(const Offset(50, 200));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Open Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Resizing down from 1400px to 750px auto-collapses panels without overflow', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePicker), findsOneWidget);

      // Resize window down to compact desktop
      tester.view.physicalSize = const Size(750, 800);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // No overflow exceptions on resize
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Open Sidebar'), findsOneWidget);
      expect(find.byTooltip('Open Settings'), findsOneWidget);
    });

    testWidgets('Compact Desktop (750x700): overlay drawers are draggable and resizable', (tester) async {
      tester.view.physicalSize = const Size(750, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open left sidebar overlay drawer
      await tester.tap(find.byTooltip('Open Sidebar'));
      await tester.pumpAndSettle();

      // Find the resize handle by MouseRegion with resizeLeftRight cursor
      final resizeHandles = find.byWidgetPredicate(
        (widget) => widget is MouseRegion && widget.cursor == SystemMouseCursors.resizeLeftRight,
      );
      expect(resizeHandles, findsOneWidget);

      // Drag resize handle to the right (+60 px)
      await tester.drag(resizeHandles, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
