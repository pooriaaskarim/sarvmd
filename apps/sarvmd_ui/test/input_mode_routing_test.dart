// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/screens/editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/screens/mobile_editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/input_mode_toggle_button.dart';
import 'package:sarvmd_ui/src/presentation/widgets/specialized/launch_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('InputMode Routing & Toggle Tests', () {
    testWidgets('LaunchCoordinator routes to EditorScreen when inputMode is pointer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'view_input_mode': InputMode.pointer.index,
      });

      final viewCubit = ViewCubit(const ViewState(inputMode: InputMode.pointer));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LocaleCubit()),
            BlocProvider(create: (_) => DocumentCubit()),
            BlocProvider<ViewCubit>.value(value: viewCubit),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LaunchCoordinator(
              minSplashDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(EditorScreen), findsOneWidget);
      expect(find.byType(MobileEditorScreen), findsNothing);
    });

    testWidgets('LaunchCoordinator routes to MobileEditorScreen when inputMode is touch on wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'view_input_mode': InputMode.touch.index,
      });

      final viewCubit = ViewCubit(const ViewState(inputMode: InputMode.touch));

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LocaleCubit()),
            BlocProvider(create: (_) => DocumentCubit()),
            BlocProvider<ViewCubit>.value(value: viewCubit),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LaunchCoordinator(
              minSplashDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(MobileEditorScreen), findsOneWidget);
      expect(find.byType(EditorScreen), findsNothing);
    });

    testWidgets('InputModeToggleButton displays touch icon in pointer mode and confirms cancellation', (tester) async {
      SharedPreferences.setMockInitialValues({
        'view_input_mode': InputMode.pointer.index,
      });
      final viewCubit = ViewCubit(const ViewState(inputMode: InputMode.pointer));

      await tester.pumpWidget(
        BlocProvider<ViewCubit>.value(
          value: viewCubit,
          child: const MaterialApp(
            home: Scaffold(
              body: InputModeToggleButton(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.touch_app_outlined), findsOneWidget);

      // Tap button to trigger confirmation dialog
      await tester.tap(find.byType(InputModeToggleButton));
      await tester.pumpAndSettle();

      expect(find.text('Switch to Touch Mode?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Switch & Reload'), findsOneWidget);

      // Cancel dismissal
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to Touch Mode?'), findsNothing);
      expect(viewCubit.state.inputMode, equals(InputMode.pointer));
    });
  });
}
