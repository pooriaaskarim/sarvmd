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
import 'package:sarvmd_ui/src/presentation/widgets/touch/settings_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Touch Settings Panel State Preservation Tests', () {
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

    Widget createTestWidget({required Widget child}) {
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
          home: PageStorage(
            bucket: PageStorageBucket(),
            child: child,
          ),
        ),
      );
    }

    testWidgets('navigates to subpage and back to main menu updating ViewCubit', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: SettingsPanel(
              transformationController: transformationController,
              onZoomPreset: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(viewCubit.state.activeTouchSection, SettingsSection.mainMenu);
      expect(find.text('Page Settings'), findsOneWidget);
      expect(find.text('Margins'), findsOneWidget);

      // Tap on Page Settings tile
      await tester.tap(find.text('Page Settings'));
      await tester.pumpAndSettle();

      expect(viewCubit.state.activeTouchSection, SettingsSection.pageSetup);
      // Back button appears in sub-page
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(viewCubit.state.activeTouchSection, SettingsSection.mainMenu);
      expect(find.text('Page Settings'), findsOneWidget);
    });

    testWidgets('preserves active subpage when SettingsPanel is reconstructed', (tester) async {
      final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

      // Set active section to Margins beforehand
      viewCubit.setTouchSection(SettingsSection.margins);

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            key: scaffoldKey,
            endDrawer: SettingsPanel(
              transformationController: transformationController,
              onZoomPreset: (_) {},
            ),
            body: Center(
              child: ElevatedButton(
                onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      scaffoldKey.currentState?.openEndDrawer();
      await tester.pumpAndSettle();

      // Directly renders Margins sub-page
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(viewCubit.state.activeTouchSection, SettingsSection.margins);

      // Close drawer by tapping scrim
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Reopen drawer
      scaffoldKey.currentState?.openEndDrawer();
      await tester.pumpAndSettle();

      // Remains in Margins sub-page!
      expect(viewCubit.state.activeTouchSection, SettingsSection.margins);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
