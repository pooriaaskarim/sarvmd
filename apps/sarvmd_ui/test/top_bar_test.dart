// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/sarv_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('SarvTopBar renders desktop menu headers, title, and controls in wide mode', (tester) async {
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

  testWidgets('SarvTopBar View menu switches page size presets', (tester) async {
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

    // Open View menu
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    // Open Score Page Sizes sub-menu
    await tester.tap(find.text('SCORE PAGE SIZES'));
    await tester.pumpAndSettle();

    // Select A3
    await tester.tap(find.text('A3 (297×420 mm)'));
    await tester.pumpAndSettle();

    expect(documentCubit.state.config.pageSize, equals(core.PageSize.a3));

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

  testWidgets('SarvTopBar collapses menus into cascading app menu button in compact viewports (<760px)', (tester) async {
    tester.view.physicalSize = const Size(700, 600);
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
    expect(find.text('View'), findsNothing);
    expect(find.text('Help'), findsNothing);

    // Dedicated app menu button should be present
    final menuButton = find.byIcon(Icons.menu_rounded);
    expect(menuButton, findsOneWidget);

    // Brand logo MD is present as brand mark
    expect(find.text('MD'), findsOneWidget);

    // Tap app menu button to open cascading menu
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    expect(find.text('File'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

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

  testWidgets('SarvTopBar Remove Staff from Edit menu removes only targeted staff from grouped ensemble', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final documentCubit = DocumentCubit();
    documentCubit.applyProfile(core.StaffProfiles.chamberOrchestra);
    // chamberOrchestra has 4 staves:
    // Violin I (in subGroup), Violin II (in subGroup), Viola, Cello
    expect(documentCubit.state.config.staffCount, equals(4));

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

    // Open Remove Staff sub-menu
    await tester.tap(find.text('Remove Staff'));
    await tester.pumpAndSettle();

    // Find and tap the first staff item: 1. Staff #1 (5 L)
    final firstStaffFinder = find.widgetWithText(MenuItemButton, '1. Staff #1 (5 L)');
    expect(firstStaffFinder, findsOneWidget);
    await tester.tap(firstStaffFinder);
    await tester.pumpAndSettle();

    // Exactly 3 staves must remain (not 2 from deleting the whole violin sub-group)
    expect(documentCubit.state.config.staffCount, equals(3));
    final root = documentCubit.state.config.systemLayout.rootGroup;
    expect(root.children.first, isA<core.StaffNodeGroup>());
    final subGroup = root.children.first as core.StaffNodeGroup;
    // Sub-group must still exist with Violin II preserved inside it
    expect(subGroup.children.length, equals(1));

    documentCubit.close();
  });
}

