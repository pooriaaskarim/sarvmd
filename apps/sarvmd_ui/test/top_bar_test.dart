// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/config/config_cubit.dart';
import 'package:sarvmd_ui/src/logic/score/score_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/sarv_top_bar.dart';

void main() {
  testWidgets('SarvTopBar renders desktop menu headers, profile picker, title, and split export CTA in wide mode', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final history = CommandHistory();
    final scoreCubit = ScoreCubit(history);
    final configCubit = ConfigCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ScoreCubit>.value(value: scoreCubit),
          BlocProvider<ConfigCubit>.value(value: configCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SarvTopBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify brand logo & top-level desktop menu headers
    expect(find.text('MD'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

    // Verify ensemble profile picker
    expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);

    // Verify center dual editable metadata (Title & Composer) & status badge
    expect(find.text('New Score'), findsOneWidget);
    expect(find.text('Composer'), findsOneWidget);
    expect(find.textContaining('A4'), findsOneWidget);

    // Verify primary split Export CTA button & undo/redo buttons
    expect(find.byIcon(Icons.file_upload_outlined), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.redo_rounded), findsOneWidget);

    // Hover over brand logo to trigger expansion to 'Manuscript Designer'
    final brandFinder = find.byType(InkWell).first;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(brandFinder));
    await tester.pumpAndSettle();

    expect(find.text('Manuscript Designer'), findsOneWidget);

    await gesture.removePointer();
    scoreCubit.close();
    configCubit.close();
  });

  testWidgets('SarvTopBar Ensemble Profile Picker switches paper presets', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final history = CommandHistory();
    final scoreCubit = ScoreCubit(history);
    final configCubit = ConfigCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ScoreCubit>.value(value: scoreCubit),
          BlocProvider<ConfigCubit>.value(value: configCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SarvTopBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap ensemble profile picker dropdown
    await tester.tap(find.byIcon(Icons.queue_music_rounded));
    await tester.pumpAndSettle();

    // Select Piano profile
    expect(find.text('ENSEMBLE PROFILES'), findsOneWidget);
    await tester.tap(find.text('Piano').last);
    await tester.pumpAndSettle();

    expect(configCubit.activeProfile?.id, equals('piano'));

    scoreCubit.close();
    configCubit.close();
  });

  testWidgets('SarvTopBar allows inline editing of score title and composer in center zone', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final history = CommandHistory();
    final scoreCubit = ScoreCubit(history);
    final configCubit = ConfigCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ScoreCubit>.value(value: scoreCubit),
          BlocProvider<ConfigCubit>.value(value: configCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SarvTopBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Edit Title
    await tester.tap(find.text('New Score'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Persian Classical Suite');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Persian Classical Suite'), findsOneWidget);
    expect(scoreCubit.state.score.title, equals('Persian Classical Suite'));

    // 2. Edit Composer
    await tester.tap(find.text('Composer'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'L. v. Beethoven');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('L. v. Beethoven'), findsOneWidget);
    expect(scoreCubit.state.score.composer, equals('L. v. Beethoven'));

    scoreCubit.close();
    configCubit.close();
  });

  testWidgets('SarvTopBar in compact mode collapses into logo dropdown menu while keeping Undo/Redo and Export', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final history = CommandHistory();
    final scoreCubit = ScoreCubit(history);
    final configCubit = ConfigCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ScoreCubit>.value(value: scoreCubit),
          BlocProvider<ConfigCubit>.value(value: configCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SarvTopBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify compact logo menu trigger, title, and Export CTA button
    expect(find.byType(PopupMenuButton<String>), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
    expect(find.text('New Score'), findsOneWidget);

    // Tap logo to open smart dropdown menu
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    expect(find.text('Manuscript Designer'), findsAtLeastNWidgets(1));

    scoreCubit.close();
    configCubit.close();
  });

  testWidgets('SarvTopBar enforces LTR layout even in RTL locale', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final history = CommandHistory();
    final scoreCubit = ScoreCubit(history);
    final configCubit = ConfigCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ScoreCubit>.value(value: scoreCubit),
          BlocProvider<ConfigCubit>.value(value: configCubit),
        ],
        child: const MaterialApp(
          locale: Locale('fa'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SarvTopBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify logo top-left placement in RTL relative to File menu
    final logoFinder = find.byType(InkWell).first;
    final fileFinder = find.text('File');

    final logoTopLeft = tester.getTopLeft(logoFinder);
    final fileTopLeft = tester.getTopLeft(fileFinder);

    expect(logoTopLeft.dx, lessThan(fileTopLeft.dx));

    scoreCubit.close();
    configCubit.close();
  });

  testWidgets('SarvTopBar Add Staff to System from Edit menu updates ConfigCubit staffCount with correct format', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final history = CommandHistory();
    final scoreCubit = ScoreCubit(history);
    final configCubit = ConfigCubit();

    final initialStaffCount = configCubit.state.staffCount;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ScoreCubit>.value(value: scoreCubit),
          BlocProvider<ConfigCubit>.value(value: configCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SarvTopBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Tap Add Staff to System -> Standard 5-Line Treble Staff
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Add Staff to System'), findsOneWidget);

    await tester.tap(find.text('Add Staff to System'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Standard 5-Line Treble Staff'));
    await tester.pumpAndSettle();

    expect(configCubit.state.staffCount, equals(initialStaffCount + 1));

    // 2. Tap Edit -> Add Staff to System -> Custom Staff... (Configure)
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Staff to System'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom Staff… (Configure)'));
    await tester.pumpAndSettle();

    expect(configCubit.state.staffCount, equals(initialStaffCount + 2));
    expect(find.text('Configure Staff Settings'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 3. Tap Edit -> Edit Staff submenu -> Select staff 1 to configure
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Staff'), findsOneWidget);

    await tester.tap(find.widgetWithText(SubmenuButton, 'Edit Staff'));
    await tester.pumpAndSettle();

    expect(find.text('1. Staff #1 (5 L)'), findsOneWidget);
    await tester.tap(find.text('1. Staff #1 (5 L)'));
    await tester.pumpAndSettle();

    expect(find.text('Configure Staff Settings'), findsOneWidget);

    // Test removing staff via StaffConfigDialog footer button
    final countBeforeDelete = configCubit.state.staffCount;
    await tester.tap(find.byTooltip('Remove Staff'));
    await tester.pumpAndSettle();

    expect(configCubit.state.staffCount, equals(countBeforeDelete - 1));

    // 4. Test Edit -> Remove Staff submenu
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SubmenuButton, 'Remove Staff'));
    await tester.pumpAndSettle();

    expect(find.text('1. Staff #1 (5 L)'), findsOneWidget);
    await tester.tap(find.text('1. Staff #1 (5 L)'));
    await tester.pumpAndSettle();

    expect(configCubit.state.staffCount, equals(countBeforeDelete - 2));

    scoreCubit.close();
    configCubit.close();
  });
}

