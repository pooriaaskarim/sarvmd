// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/services/recent_documents_service.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/logic/workspace/workspace_cubit.dart';
import 'package:sarvmd_ui/src/presentation/screens/app_shell.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/language_switch_control.dart';
import 'package:sarvmd_ui/src/presentation/widgets/workspace/empty_workspace_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  required WorkspaceCubit workspaceCubit,
  required ViewCubit viewCubit,
  required LocaleCubit localeCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<LocaleCubit>.value(value: localeCubit),
      BlocProvider<WorkspaceCubit>.value(value: workspaceCubit),
      BlocProvider<ViewCubit>.value(value: viewCubit),
    ],
    child: BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        return MaterialApp(
          locale: localeState.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkspaceCubit workspaceCubit;
  late ViewCubit viewCubit;
  late LocaleCubit localeCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RecentDocumentsService.recentDocumentsNotifier.value = [];
    workspaceCubit = WorkspaceCubit(autoRestoreSession: false);
    viewCubit = ViewCubit();
    localeCubit = LocaleCubit();
  });

  tearDown(() async {
    await workspaceCubit.close();
    await viewCubit.close();
    await localeCubit.close();
  });

  group('EmptyWorkspaceView Tests', () {
    testWidgets('closing the sole tab switches AppShell to EmptyWorkspaceView', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      // Initially starts with 1 default tab, rendering the editor
      expect(workspaceCubit.state.tabCount, equals(1));
      expect(find.byType(EmptyWorkspaceView), findsNothing);

      // Close the sole tab
      final closed = await workspaceCubit.closeTab(0);
      expect(closed, isTrue);
      expect(workspaceCubit.state.tabCount, equals(0));
      expect(workspaceCubit.state.hasActiveSession, isFalse);

      await tester.pumpAndSettle();

      // Now EmptyWorkspaceView is rendered
      expect(find.byType(EmptyWorkspaceView), findsOneWidget);
      expect(find.text('Start New Manuscript'), findsOneWidget);
      expect(find.text('Recent Manuscripts'), findsOneWidget);
      expect(find.text('Solo Treble'), findsOneWidget);
      expect(find.text('Grand Staff'), findsOneWidget);
      expect(find.text('Guitar + TAB'), findsOneWidget);
      expect(find.text('Chamber Orchestra'), findsOneWidget);
      expect(find.text('Browse all templates…'), findsOneWidget);
    });

    testWidgets('tapping a starter preset in EmptyWorkspaceView opens a new manuscript tab', (tester) async {
      // Start in empty state
      await workspaceCubit.closeTab(0);

      await tester.pumpWidget(_buildTestApp(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyWorkspaceView), findsOneWidget);

      // Tap Piano Grand Staff preset
      await tester.tap(find.text('Grand Staff'));
      await tester.pumpAndSettle();

      // Workspace transitions back to editor with 1 active session
      expect(workspaceCubit.state.tabCount, equals(1));
      expect(workspaceCubit.state.hasActiveSession, isTrue);
      expect(workspaceCubit.state.activeSession.title, equals('Piano_A4_Portrait'));
      expect(find.byType(EmptyWorkspaceView), findsNothing);
    });

    testWidgets('displays recent files when available and opens on tap', (tester) async {
      RecentDocumentsService.recentDocumentsNotifier.value = [
        '/home/user/Music/Symphony.sarv',
        '/home/user/Scores/Sonata.sarv',
      ];

      // Start in empty state
      await workspaceCubit.closeTab(0);

      await tester.pumpWidget(_buildTestApp(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyWorkspaceView), findsOneWidget);
      expect(find.text('Symphony.sarv'), findsOneWidget);
      expect(find.text('Sonata.sarv'), findsOneWidget);
    });

    testWidgets('hides keyboard shortcuts and shows tap prompt in touch mode', (tester) async {
      await workspaceCubit.closeTab(0);
      viewCubit.setInputMode(InputMode.touch);

      await tester.pumpWidget(_buildTestApp(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyWorkspaceView), findsOneWidget);
      // Keyboard shortcuts must not be shown in touch mode
      expect(find.textContaining('Ctrl+N'), findsNothing);
      expect(find.textContaining('Ctrl+O'), findsNothing);
      // Touch-specific open prompt should be visible
      expect(find.text('Tap to open an existing .sarv manuscript'), findsOneWidget);
    });

    testWidgets('shows keyboard shortcuts and drag prompt in pointer mode', (tester) async {
      await workspaceCubit.closeTab(0);
      viewCubit.setInputMode(InputMode.pointer);

      await tester.pumpWidget(_buildTestApp(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyWorkspaceView), findsOneWidget);
      expect(find.textContaining('Ctrl+N'), findsOneWidget);
      expect(find.textContaining('Ctrl+O'), findsOneWidget);
      expect(find.text('Drag and drop a .sarv manuscript anywhere to start editing'), findsOneWidget);
    });

    testWidgets('renders Persian localized titles and keeps top bar LTR in Persian mode', (tester) async {
      await workspaceCubit.closeTab(0);
      await localeCubit.setLocale(
        const Locale('fa'),
        fadeInDuration: Duration.zero,
        blurSettleDuration: Duration.zero,
      );

      await tester.pumpWidget(_buildTestApp(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyWorkspaceView), findsOneWidget);
      // Localized Persian titles
      expect(find.text('شروع دست‌نویس جدید'), findsOneWidget);
      expect(find.text('تک‌خط حامل سل'), findsOneWidget);
      expect(find.text('حامل پیانو (بزرگ)'), findsOneWidget);

      // Verify top bar directionality is LTR
      final directionalityFinder = find.ancestor(
        of: find.byType(LanguageToggleButton),
        matching: find.byType(Directionality),
      );
      final directionalityWidget = tester.widget<Directionality>(directionalityFinder.first);
      expect(directionalityWidget.textDirection, equals(TextDirection.ltr));
    });
  });
}
