// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/sarv_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('SarvTopBar renders desktop menu headers, profile picker, title, and split export CTA in wide mode', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final documentCubit = DocumentCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DocumentCubit>.value(value: documentCubit),
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

    // Verify center editable metadata (Title) & status badge
    expect(find.text('Treble_A4_Portrait'), findsOneWidget);
    expect(find.text('A4 • PORTRAIT'), findsOneWidget);

    // Verify undo/redo buttons
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.redo_rounded), findsOneWidget);

    // Hover over brand logo to trigger expansion to 'Manuscript Designer'
    final brandFinder = find.byType(InkWell).first;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(brandFinder));
    await tester.pump();

    expect(find.text('Manuscript Designer'), findsOneWidget);

    await gesture.removePointer();
    documentCubit.close();
  });

  testWidgets('SarvTopBar Ensemble Profile Picker switches paper presets', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final documentCubit = DocumentCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DocumentCubit>.value(value: documentCubit),
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

    // Open ensemble picker
    await tester.tap(find.byIcon(Icons.queue_music_rounded));
    await tester.pumpAndSettle();

    // Select Piano
    await tester.tap(find.text('Piano').last);
    await tester.pumpAndSettle();

    expect(documentCubit.activeProfile?.id, equals('piano'));

    documentCubit.close();
  });

  testWidgets('SarvTopBar allows inline editing of score title in center zone', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final documentCubit = DocumentCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DocumentCubit>.value(value: documentCubit),
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

    // Tap title to edit
    await tester.tap(find.text('Treble_A4_Portrait'));
    await tester.pumpAndSettle();

    // Enter new title
    await tester.enterText(find.byType(TextField), 'Persian Classical Suite');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(documentCubit.state.score.title, equals('Persian Classical Suite'));

    documentCubit.close();
  });

  testWidgets('SarvTopBar collapses menus into logo dropdown menu in compact viewports (<960px)', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final documentCubit = DocumentCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DocumentCubit>.value(value: documentCubit),
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

    // Top desktop menu headers should be hidden in compact mode
    expect(find.text('File'), findsNothing);
    expect(find.text('Edit'), findsNothing);

    // Tap brand logo to open compact popup menu
    await tester.tap(find.text('MD'));
    await tester.pumpAndSettle();

    expect(find.text('File'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);

    documentCubit.close();
  });

  testWidgets('SarvTopBar Add Staff to System from Edit menu updates DocumentCubit staffCount with correct format', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final documentCubit = DocumentCubit();

    final initialStaffCount = documentCubit.state.config.staffCount;

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<DocumentCubit>.value(value: documentCubit),
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

    // Open Edit menu
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Hover over Add Staff to open sub-menu
    await tester.tap(find.text('Add Staff to System'));
    await tester.pumpAndSettle();

    // Select Standard Treble Staff
    await tester.tap(find.text('Standard 5-Line Treble Staff'));
    await tester.pumpAndSettle();

    expect(documentCubit.state.config.staffCount, equals(initialStaffCount + 1));
    expect(documentCubit.state.lastUndoLabel, equals('Add Part'));

    documentCubit.close();
  });
}
