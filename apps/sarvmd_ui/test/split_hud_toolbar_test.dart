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
import 'package:sarvmd_ui/src/presentation/widgets/common/integrated_scale_control.dart';
import 'package:sarvmd_ui/src/presentation/widgets/mobile/conductor_toolbar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Proposal A: Split Dual-Island ConductorToolbar Tests', () {
    late LocaleCubit localeCubit;
    late ViewCubit viewCubit;
    late DocumentCubit documentCubit;
    late TransformationController transformationController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeCubit = LocaleCubit(const LocaleState());
      viewCubit = ViewCubit(const ViewState());
      documentCubit = DocumentCubit();
      transformationController = TransformationController();
    });

    tearDown(() {
      localeCubit.close();
      viewCubit.close();
      documentCubit.close();
      transformationController.dispose();
    });

    Widget createTestWidget({
      bool isVisible = true,
      VoidCallback? onOpenMenu,
      ValueChanged<ZoomPreset>? onZoomPreset,
      double width = 400.0,
      Offset? cursorPosition,
    }) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: viewCubit),
          BlocProvider.value(value: documentCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 100,
                child: ConductorToolbar(
                  transformationController: transformationController,
                  onZoomPreset: onZoomPreset ?? (_) {},
                  isVisible: isVisible,
                  onOpenMenu: onOpenMenu,
                  cursorPosition: cursorPosition,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders separate Left Wing and Right Wing with open center corridor', (tester) async {
      await tester.pumpWidget(createTestWidget(width: 400.0));
      await tester.pump();

      final leftWingFinder = find.byKey(const ValueKey('expanded_left_wing'));
      final rightWingFinder = find.byKey(const ValueKey('expanded_right_wing'));

      expect(leftWingFinder, findsOneWidget);
      expect(rightWingFinder, findsOneWidget);

      final leftWingRect = tester.getRect(leftWingFinder);
      final rightWingRect = tester.getRect(rightWingFinder);

      // Verify clear center corridor between wings
      expect(rightWingRect.left, greaterThan(leftWingRect.right));
      final centerClearance = rightWingRect.left - leftWingRect.right;
      expect(centerClearance, greaterThan(50.0),
          reason: 'There must be a clear center corridor between left and right wings');

      // Left Wing controls
      expect(find.descendant(of: leftWingFinder, matching: find.byIcon(Icons.tune)), findsOneWidget);
      expect(find.descendant(of: leftWingFinder, matching: find.byIcon(Icons.undo)), findsOneWidget);
      expect(find.descendant(of: leftWingFinder, matching: find.byIcon(Icons.redo)), findsOneWidget);

      // Right Wing controls
      expect(find.descendant(of: rightWingFinder, matching: find.byIcon(Icons.remove)), findsOneWidget);
      expect(find.descendant(of: rightWingFinder, matching: find.byIcon(Icons.add)), findsOneWidget);
      expect(find.descendant(of: rightWingFinder, matching: find.text('100%')), findsOneWidget);
      expect(find.descendant(of: rightWingFinder, matching: find.byIcon(Icons.visibility_outlined)), findsOneWidget);
    });

    testWidgets('Left Wing tune button triggers onOpenMenu callback', (tester) async {
      bool menuTriggered = false;
      await tester.pumpWidget(createTestWidget(
        onOpenMenu: () => menuTriggered = true,
      ));
      await tester.pump();

      final tuneFinder = find.byIcon(Icons.tune);
      expect(tuneFinder, findsOneWidget);

      await tester.tap(tuneFinder);
      await tester.pump();

      expect(menuTriggered, isTrue);
    });

    testWidgets('Expanded Menu Wing right drag opens drawer/menu callback', (tester) async {
      bool menuTriggered = false;
      await tester.pumpWidget(createTestWidget(
        onOpenMenu: () => menuTriggered = true,
      ));
      await tester.pump();

      final expandedLeftWing = find.byKey(const ValueKey('expanded_left_wing'));
      expect(expandedLeftWing, findsOneWidget);

      // Drag to the right by 60dp (> 24dp threshold)
      await tester.drag(expandedLeftWing, const Offset(60.0, 0.0));
      await tester.pump();

      expect(menuTriggered, isTrue);
    });

    testWidgets('Collapsed Menu Wing right drag opens drawer/menu callback', (tester) async {
      bool menuTriggered = false;
      await tester.pumpWidget(createTestWidget(
        onOpenMenu: () => menuTriggered = true,
      ));
      await tester.pump();

      // Fast forward past 4-second idle timeout to collapse wings
      await tester.pump(const Duration(seconds: 4, milliseconds: 100));
      await tester.pumpAndSettle();

      final collapsedLeftWing = find.byKey(const ValueKey('collapsed_left_wing'));
      expect(collapsedLeftWing, findsOneWidget);

      // Drag to the right by 60dp (> 24dp threshold)
      await tester.drag(collapsedLeftWing, const Offset(60.0, 0.0));
      await tester.pump();

      expect(menuTriggered, isTrue);
    });

    testWidgets('Left drag on Menu Wing does not trigger onOpenMenu callback', (tester) async {
      bool menuTriggered = false;
      await tester.pumpWidget(createTestWidget(
        onOpenMenu: () => menuTriggered = true,
      ));
      await tester.pump();

      final expandedLeftWing = find.byKey(const ValueKey('expanded_left_wing'));
      expect(expandedLeftWing, findsOneWidget);

      // Drag to the left by -60dp
      await tester.drag(expandedLeftWing, const Offset(-60.0, 0.0));
      await tester.pump();

      expect(menuTriggered, isFalse);
    });

    testWidgets('Right Wing zoom stepper buttons scale transformationController', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final initialScale = transformationController.value.row0[0];
      expect(initialScale, closeTo(1.0, 0.001));

      // Tap zoom in (+)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      final zoomedInScale = transformationController.value.row0[0];
      expect(zoomedInScale, greaterThan(initialScale));

      // Tap zoom out (-)
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      final zoomedOutScale = transformationController.value.row0[0];
      expect(zoomedOutScale, lessThan(zoomedInScale));
    });

    testWidgets('Wings open and close independently and auto-collapse on idle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byKey(const ValueKey('expanded_left_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded_right_wing')), findsOneWidget);

      // Fast forward past 4-second idle timeout
      await tester.pump(const Duration(seconds: 4, milliseconds: 100));
      await tester.pumpAndSettle();

      // Should transition to collapsed pods
      expect(find.byKey(const ValueKey('collapsed_left_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsOneWidget);

      // 1. Tapping collapsed left wing blooms ONLY left wing back out
      await tester.tap(find.byKey(const ValueKey('collapsed_left_wing')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('expanded_left_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsOneWidget,
          reason: 'Right wing must remain collapsed when left wing is opened');

      // 2. Tapping collapsed right wing blooms right wing back out
      await tester.tap(find.byKey(const ValueKey('collapsed_right_wing')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('expanded_left_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded_right_wing')), findsOneWidget);

      // 3. Keep Right Wing active by tapping zoom in, while Left Wing stays idle
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Fast forward past Left Wing's 4-second timeout (total 4.5s since Left Wing was opened)
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();

      // Left Wing has auto-collapsed due to inactivity; Right Wing remains expanded
      expect(find.byKey(const ValueKey('collapsed_left_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded_right_wing')), findsOneWidget,
          reason: 'Left wing must auto-collapse independently when idle while right wing remains active');

      // Fast forward past Right Wing's remaining idle timer
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collapsed_left_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsOneWidget);
    });

    testWidgets('Scrubbing on scale chip adjusts zoom continuously with bi-directional drag', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final initialScale = transformationController.value.row0[0];
      expect(initialScale, closeTo(1.0, 0.001));

      final chipFinder = find.byKey(const ValueKey('scrubbable_zoom_chip'));
      expect(chipFinder, findsOneWidget);

      // 1. Drag right -> zooms in
      await tester.drag(chipFinder, const Offset(60.0, 0.0));
      await tester.pump();

      final rightZoomScale = transformationController.value.row0[0];
      expect(rightZoomScale, greaterThan(initialScale));

      // 2. Drag left -> zooms out
      await tester.drag(chipFinder, const Offset(-100.0, 0.0));
      await tester.pump();

      final leftZoomScale = transformationController.value.row0[0];
      expect(leftZoomScale, lessThan(rightZoomScale));

      // 3. Drag up (-dy) -> zooms in
      await tester.drag(chipFinder, const Offset(0.0, -80.0));
      await tester.pump();

      final upZoomScale = transformationController.value.row0[0];
      expect(upZoomScale, greaterThan(leftZoomScale));

      // 4. Drag down (+dy) -> zooms out
      await tester.drag(chipFinder, const Offset(0.0, 80.0));
      await tester.pump();

      final downZoomScale = transformationController.value.row0[0];
      expect(downZoomScale, lessThan(upZoomScale));
    });

    testWidgets('Collapsed Right Wing renders zoom level indicator and allows direct scrub zooming without expanding', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Fast forward past 4-second idle timeout to collapse wings
      await tester.pump(const Duration(seconds: 4, milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('expanded_right_wing')), findsNothing);

      // Verify no +/- stepper buttons in collapsed state
      expect(find.byKey(const ValueKey('collapsed_zoom_in')), findsNothing);
      expect(find.byKey(const ValueKey('collapsed_zoom_out')), findsNothing);

      final initialScale = transformationController.value.row0[0];

      // 1. Zoom level indicator displays percentage
      final collapsedChipFinder = find.byKey(const ValueKey('collapsed_scrubbable_chip'));
      expect(collapsedChipFinder, findsOneWidget);
      expect(find.descendant(of: collapsedChipFinder, matching: find.text('100%')), findsOneWidget);
      expect(find.descendant(of: collapsedChipFinder, matching: find.byIcon(Icons.search)), findsOneWidget);

      // 2. Drag right -> zooms in
      await tester.drag(collapsedChipFinder, const Offset(60.0, 0.0));
      await tester.pump();

      final scrubbedScale = transformationController.value.row0[0];
      expect(scrubbedScale, greaterThan(initialScale));
      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsOneWidget,
          reason: 'Scrubbing should keep the HUD collapsed');

      // 3. Drag down (+dy) -> zooms out
      await tester.drag(collapsedChipFinder, const Offset(0.0, 80.0));
      await tester.pump();

      final downScale = transformationController.value.row0[0];
      expect(downScale, lessThan(scrubbedScale));
      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsOneWidget,
          reason: 'Dragging down should zoom out and keep HUD collapsed');

      // 4. Drag up (-dy) -> zooms in
      await tester.drag(collapsedChipFinder, const Offset(0.0, -80.0));
      await tester.pump();

      final upScale = transformationController.value.row0[0];
      expect(upScale, greaterThan(downScale));
      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsOneWidget,
          reason: 'Dragging up should zoom in and keep HUD collapsed');

      // 4. Test idle transition: after being left alone, magnifier becomes more visible and text softens
      // Advance past 2.5s active countdown + 600ms animation
      await tester.pump(const Duration(milliseconds: 2600));
      await tester.pump(const Duration(milliseconds: 650));

      final idleOpacityFinder = find.descendant(
        of: collapsedChipFinder,
        matching: find.byType(AnimatedOpacity),
      );
      expect(idleOpacityFinder, findsOneWidget);
      final idleAnimatedOpacity = tester.widget<AnimatedOpacity>(idleOpacityFinder);
      expect(idleAnimatedOpacity.opacity, closeTo(0.46, 0.01),
          reason: 'Magnifier watermark should be more visible in idle state');

      final idleTextFinder = find.descendant(
        of: collapsedChipFinder,
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      expect(idleTextFinder, findsOneWidget);
      final idleDefaultTextStyle = tester.widget<AnimatedDefaultTextStyle>(idleTextFinder);
      expect(idleDefaultTextStyle.style.fontWeight, equals(FontWeight.w600),
          reason: 'Text style should soften in idle state');

      // 5. Tapping the zoom indicator chip expands the right wing into full camera controls
      await tester.tap(collapsedChipFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('expanded_right_wing')), findsOneWidget);
      expect(find.byKey(const ValueKey('collapsed_right_wing')), findsNothing);
    });

    testWidgets('Right Wing morphs into real-time CAD telemetry when cursorPosition is provided', (tester) async {
      // 1. Initial idle state without cursorPosition shows camera controls
      await tester.pumpWidget(createTestWidget(cursorPosition: null));
      await tester.pump();

      expect(find.byKey(const ValueKey('camera_controls_cluster')), findsOneWidget);
      expect(find.byKey(const ValueKey('cad_telemetry_dock')), findsNothing);

      // 2. Touch/drag event provides cursorPosition -> Morphs into CAD telemetry
      await tester.pumpWidget(createTestWidget(cursorPosition: const Offset(300.0, 400.0)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cad_telemetry_dock')), findsOneWidget);
      expect(find.byKey(const ValueKey('camera_controls_cluster')), findsNothing);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
      expect(find.text('PAPER'), findsOneWidget);

      // 3. Touch ends -> Morphs back to camera controls cluster
      await tester.pumpWidget(createTestWidget(cursorPosition: null));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('camera_controls_cluster')), findsOneWidget);
      expect(find.byKey(const ValueKey('cad_telemetry_dock')), findsNothing);
    });

    testWidgets('ConductorToolbar is positioned with left clearance >= 36.0 dp to clear left ruler in MobileEditorScreen', (tester) async {
      await tester.pumpWidget(MultiBlocProvider(
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
      ));
      await tester.pumpAndSettle();

      final toolbarFinder = find.byType(ConductorToolbar);
      expect(toolbarFinder, findsOneWidget);

      final toolbarRect = tester.getRect(toolbarFinder);
      expect(toolbarRect.left, greaterThanOrEqualTo(36.0),
          reason: 'ConductorToolbar must start to the right of the 25.0 dp left ruler with at least 11.0 dp clearance');
    });
  });
}
