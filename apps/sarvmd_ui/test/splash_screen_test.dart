// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/core/theme/app_theme.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/specialized/launch_coordinator.dart';
import 'package:sarvmd_ui/src/presentation/widgets/specialized/sarv_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LaunchCoordinator & SplashScreen System Tests', () {
    testWidgets('SplashScreen displays brand assets and localized subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SarvSplashScreen(
            accent: SarvAccent.sage,
            brightness: Brightness.dark,
            isPersian: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SarvSplashScreen), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('MANUSCRIPT DESIGNER'), findsOneWidget);
    });

    testWidgets('SplashScreen displays Persian brand subtitle when locale is fa', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: const Locale('fa'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SarvSplashScreen(
            accent: SarvAccent.sage,
            brightness: Brightness.dark,
            isPersian: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SarvSplashScreen), findsOneWidget);
      expect(find.text('MANUSCRIPT DESIGNER'), findsOneWidget);
    });

    testWidgets('LaunchCoordinator transitions from SplashScreen to EditorScreen after minimum duration', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => LocaleCubit()),
            BlocProvider(create: (_) => DocumentCubit()),
            BlocProvider(create: (_) => ViewCubit()),
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
