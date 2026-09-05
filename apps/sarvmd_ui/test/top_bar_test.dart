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
  testWidgets('SarvTopBar renders branding, undo/redo cluster, and status badge in wide mode', (tester) async {
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

    expect(find.text('MD'), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
    expect(find.textContaining('History'), findsOneWidget);

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

  testWidgets('SarvTopBar in compact mode collapses into logo dropdown menu while keeping Undo/Redo beside logo', (tester) async {
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

    // Verify compact logo menu trigger and Undo/Redo presence beside logo
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.redo_rounded), findsOneWidget);

    // Tap logo to open smart dropdown menu
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    // Verify full text logo inside dropdown menu: Sarv + Manuscript Designer
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

    // Verify logo top-left placement in RTL
    final logoFinder = find.byType(InkWell).first;
    final historyFinder = find.textContaining('History');

    final logoTopLeft = tester.getTopLeft(logoFinder);
    final historyTopLeft = tester.getTopLeft(historyFinder);

    expect(logoTopLeft.dx, lessThan(historyTopLeft.dx));

    scoreCubit.close();
    configCubit.close();
  });
}
