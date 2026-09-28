// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/core/theme/app_theme.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/workspace/workspace_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/touch/touch_tab_switcher_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTouchApp({
  required WorkspaceCubit workspaceCubit,
  Size size = const Size(400, 800),
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.build(SarvAccent.lavender, Brightness.light),
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WorkspaceCubit>.value(value: workspaceCubit),
          BlocProvider<DocumentCubit>.value(value: workspaceCubit.state.activeCubit),
        ],
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  key: const ValueKey('open_switcher_button'),
                  onPressed: () => showTouchTabSwitcher(context),
                  child: const Text('Open Switcher'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TouchTabSwitcherModal System Tests', () {
    late WorkspaceCubit workspaceCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      final docCubit = DocumentCubit(null, null, false);
      workspaceCubit = WorkspaceCubit(initialCubit: docCubit);
    });

    tearDown(() async {
      await workspaceCubit.close();
    });

    testWidgets('opens bottom sheet and shows active manuscript card', (tester) async {
      await tester.pumpWidget(_buildTouchApp(workspaceCubit: workspaceCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_switcher_button')));
      await tester.pumpAndSettle();

      expect(find.byType(TouchTabSwitcherModal), findsOneWidget);
      expect(find.text('Manuscripts (1)'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Untitled Manuscript'), findsOneWidget);
    });

    testWidgets('tapping new button opens new tab and dismisses modal', (tester) async {
      await tester.pumpWidget(_buildTouchApp(workspaceCubit: workspaceCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_switcher_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('touch_tab_modal_new_button')));
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.byType(TouchTabSwitcherModal), findsNothing);
      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 1);
    });

    testWidgets('tapping document card switches active tab and dismisses modal', (tester) async {
      final tab2 = workspaceCubit.openNewTab();
      tab2.cubit.setTitle('Trio Sonata');

      await tester.pumpWidget(_buildTouchApp(workspaceCubit: workspaceCubit));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.activeIndex, 1);

      await tester.tap(find.byKey(const ValueKey('open_switcher_button')));
      await tester.pumpAndSettle();

      expect(find.text('Manuscripts (2)'), findsOneWidget);

      // Tap tab 0 card
      await tester.tap(find.byKey(ValueKey('touch_tab_card_${workspaceCubit.state.sessions[0].id}')));
      await tester.pumpAndSettle();

      expect(find.byType(TouchTabSwitcherModal), findsNothing);
      expect(workspaceCubit.state.activeIndex, 0);
    });

    testWidgets('tapping close button removes document card', (tester) async {
      final tab2 = workspaceCubit.openNewTab();

      await tester.pumpWidget(_buildTouchApp(workspaceCubit: workspaceCubit));
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.tabCount, 2);

      await tester.tap(find.byKey(const ValueKey('open_switcher_button')));
      await tester.pumpAndSettle();

      // Tap close button on tab2 (clean document)
      await tester.tap(find.byKey(ValueKey('touch_tab_close_${tab2.id}')));
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.tabCount, 1);
    });
  });
}
