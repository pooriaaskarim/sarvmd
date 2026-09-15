// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_ui/src/core/constants/app_version.dart';
import 'package:sarvmd_ui/src/core/theme/app_theme.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/sarv_reactive_brand_logo.dart';
import 'package:sarvmd_ui/src/presentation/widgets/mobile/conductor_drawer.dart';
import 'package:sarvmd_ui/src/presentation/widgets/mobile/mobile_language_button.dart';
import 'package:sarvmd_ui/src/presentation/widgets/mobile/mobile_theme_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConductorDrawer Header & Mobile Controls Tests', () {
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
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            endDrawer: ConductorDrawer(
              transformationController: TransformationController(),
              onZoomPreset: (_) {},
            ),
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                child: const Text('Open Drawer'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('ConductorDrawer renders solid SarvReactiveBrandLogo and AppVersion', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Verify SarvReactiveBrandLogo exists with enableExpandAnimation == false
      final logoFinder = find.byType(SarvReactiveBrandLogo);
      expect(logoFinder, findsOneWidget);
      final logoWidget = tester.widget<SarvReactiveBrandLogo>(logoFinder);
      expect(logoWidget.enableExpandAnimation, isFalse);

      // Verify version string is present under the logo
      expect(find.text('v${AppVersion.version}'), findsOneWidget);

      // Verify MobileLanguageButton and MobileThemeButton are present
      expect(find.byType(MobileLanguageButton), findsOneWidget);
      expect(find.byType(MobileThemeButton), findsOneWidget);
    });

    testWidgets('MobileLanguageButton opens horizontal context menu and selects language', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Tap language button to open context menu
      await tester.tap(find.byType(MobileLanguageButton));
      await tester.pumpAndSettle();

      // Verify horizontal options English and فارسی are visible
      expect(find.text('English'), findsOneWidget);
      expect(find.text('فارسی'), findsOneWidget);

      // Tap فارسی option
      await tester.tap(find.text('فارسی'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify locale changed to Persian
      expect(localeCubit.state.isPersian, isTrue);
    });

    testWidgets('MobileThemeButton opens double-rowed context menu and updates theme mode & accent', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Tap theme button to open context menu
      await tester.tap(find.byType(MobileThemeButton));
      await tester.pumpAndSettle();

      // Verify Row 1 (MODE) and Row 2 (ACCENT) headers exist
      expect(find.text('MODE'), findsOneWidget);
      expect(find.text('ACCENT'), findsOneWidget);

      // Verify mode options exist: Auto, Light, Dark
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Verify accent options exist: Lavender, Lemon, Sage, Sky
      expect(find.text('Lavender'), findsOneWidget);
      expect(find.text('Lemon'), findsOneWidget);
      expect(find.text('Sage'), findsOneWidget);
      expect(find.text('Sky'), findsOneWidget);

      // Select Dark mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(viewCubit.state.themeMode, ThemeMode.dark);

      // Open theme menu again to select accent
      await tester.tap(find.byType(MobileThemeButton));
      await tester.pumpAndSettle();

      // Select Sage accent
      await tester.tap(find.text('Sage'));
      await tester.pumpAndSettle();
      expect(viewCubit.state.accent, SarvAccent.sage);
    });
  });
}
