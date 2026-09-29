// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/core/theme/app_theme.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/workspace/workspace_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/workspace/pointer_tab_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  required WorkspaceCubit workspaceCubit,
  Size size = const Size(1200, 800),
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
        child: const Scaffold(
          body: PointerTabBar(),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PointerTabBar System Tests', () {
    late WorkspaceCubit workspaceCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      final docCubit = DocumentCubit(null, null, false);
      workspaceCubit = WorkspaceCubit(initialCubit: docCubit);
    });

    tearDown(() async {
      await workspaceCubit.close();
    });

    testWidgets('renders single active tab initially', (tester) async {
      await tester.pumpWidget(_buildTestApp(workspaceCubit: workspaceCubit));
      await tester.pumpAndSettle();

      expect(find.byType(PointerTabBar), findsOneWidget);
      expect(find.text('Treble_A4_Portrait'), findsOneWidget);
      expect(find.byKey(const ValueKey('tab_bar_add_button')), findsOneWidget);
    });

    testWidgets('plus button adds a new tab and focuses it with disambiguated title', (tester) async {
      await tester.pumpWidget(_buildTestApp(workspaceCubit: workspaceCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tab_bar_add_button')));
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 1);
      // Both tabs are visible with disambiguated numeric suffix
      expect(find.text('Treble_A4_Portrait'), findsOneWidget);
      expect(find.text('Treble_A4_Portrait_1'), findsOneWidget);
    });

    testWidgets('switching tabs updates active session', (tester) async {
      final tab2 = workspaceCubit.openNewTab();
      tab2.cubit.setTitle('Sonata in C');

      await tester.pumpWidget(_buildTestApp(workspaceCubit: workspaceCubit));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Sonata in C'), findsOneWidget);
      expect(workspaceCubit.state.activeIndex, 1);

      // Tap tab 0 (first tab item)
      await tester.tap(find.byKey(ValueKey('tab_item_${workspaceCubit.state.sessions[0].id}')));
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.activeIndex, 0);
    });

    testWidgets('shows dirty dot when document has unsaved edits', (tester) async {
      await tester.pumpWidget(_buildTestApp(workspaceCubit: workspaceCubit));
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('tab_dirty_${workspaceCubit.state.activeSession.id}')), findsNothing);

      workspaceCubit.state.activeCubit.setTitle('New Symphony');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('New Symphony'), findsOneWidget);
      expect(find.byKey(ValueKey('tab_dirty_${workspaceCubit.state.activeSession.id}')), findsOneWidget);
    });

    testWidgets('closing a tab removes it', (tester) async {
      final tab2 = workspaceCubit.openNewTab();

      await tester.pumpWidget(_buildTestApp(workspaceCubit: workspaceCubit));
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.tabCount, 2);

      // Tap close button on active tab2 (clean, so closes without modal)
      await tester.tap(find.byKey(ValueKey('tab_close_${tab2.id}')));
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.tabCount, 1);
    });

    testWidgets('overflow dropdown menu displays all tabs and switches tab', (tester) async {
      final tab2 = workspaceCubit.openNewTab();
      tab2.cubit.setTitle('Overture');

      await tester.pumpWidget(_buildTestApp(workspaceCubit: workspaceCubit));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Open overflow dropdown menu
      await tester.tap(find.byKey(const ValueKey('tab_bar_overflow_menu')));
      await tester.pumpAndSettle();

      // In the popup menu, find "Treble_A4_Portrait" and tap it
      await tester.tap(find.text('Treble_A4_Portrait').last);
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.activeIndex, 0);
    });
  });
}
