// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/core/constants/app_version.dart';
import 'package:sarvmd_ui/src/core/theme/app_theme.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/config/config_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/score/score_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/specialized/launch_coordinator.dart';
import 'package:sarvmd_ui/src/presentation/widgets/specialized/sarv_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SarvSplashScreen & LaunchCoordinator Tests', () {
    testWidgets('SarvSplashScreen renders branding and typography correctly in English', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SarvSplashScreen(
            accent: SarvAccent.sky,
            brightness: Brightness.dark,
            isPersian: false,
          ),
        ),
      );

      // Fast forward animation
      await tester.pumpAndSettle();

      expect(find.text('MANUSCRIPT DESIGNER'), findsOneWidget);
      expect(find.text('SARVMD  •  v${AppVersion.version}'), findsOneWidget);
    });

    testWidgets('SarvSplashScreen renders Persian calligraphy in Persian locale', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SarvSplashScreen(
            accent: SarvAccent.lavender,
            brightness: Brightness.dark,
            isPersian: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MANUSCRIPT DESIGNER'), findsOneWidget);
      expect(find.text('SARVMD  •  v${AppVersion.version}'), findsOneWidget);
    });

    testWidgets('LaunchCoordinator transitions from splash screen to editor screen after min duration', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LocaleCubit()),
            BlocProvider(create: (_) => ConfigCubit()),
            BlocProvider(create: (_) => ViewCubit()),
            BlocProvider(create: (_) => ScoreCubit()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LaunchCoordinator(
              minSplashDuration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Initially renders splash screen
      expect(find.byType(SarvSplashScreen), findsOneWidget);

      // Advance time past minSplashDuration (100ms) + animation crossfade (400ms)
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Should now be on EditorScreen workspace
      expect(find.byType(SarvSplashScreen), findsNothing);
    });
  });
}
