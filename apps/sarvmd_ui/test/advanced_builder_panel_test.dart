// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/panels/advanced_builder_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SystemHierarchyPanel Widget Tests', () {
    late DocumentCubit cubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cubit = DocumentCubit();
      cubit.execute(core.ApplyProfileCommand(core.StaffProfiles.stringQuartet));
      cubit.updateStaffInstrumentName(cubit.allStaves.first.uid, 'Violin I');
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders hierarchy tree and responds to quick actions',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Main Ensemble title should be present
      expect(find.text('Main Ensemble'), findsOneWidget);

      // Should render instrument name Violin I
      expect(find.textContaining('Violin I'), findsOneWidget);

      // Tap quick add button on group
      final addButtons = find.byIcon(Icons.add_circle_outline);
      expect(addButtons, findsAtLeastNWidgets(1));

      final int initialCount = cubit.allStaves.length;
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(cubit.allStaves.length, equals(initialCount + 1));
    });

    testWidgets('inline editing mode updates instrument name', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the edit icon on the first staff
      final editIcon = find.byTooltip('Edit Instrument Name');
      expect(editIcon, findsAtLeastNWidgets(1));

      await tester.ensureVisible(editIcon.first);
      await tester.tap(editIcon.first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should show TextFields for inline name & abbreviation editing
      expect(find.byType(TextField), findsAtLeastNWidgets(1));

      // Enter new name and submit via Save button
      await tester.enterText(find.byType(TextField).first, 'Solo Violin');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Check cubit updated staff name
      expect(cubit.allStaves.first.instrumentName, equals('Solo Violin'));
    });

    testWidgets(
        'groupTwoStavesTogether combines two staves into a StaffNodeGroup',
        (tester) async {
      final sourceUid = cubit.allStaves[0].uid;
      final targetUid = cubit.allStaves[1].uid;

      cubit.groupTwoStavesTogether(sourceUid, targetUid);
      await tester.pump(const Duration(milliseconds: 500));

      final rootGroup = cubit.config.systemLayout.rootGroup;
      expect(rootGroup.children.first, isA<core.StaffNodeGroup>());
      final nodeGroup = rootGroup.children.first as core.StaffNodeGroup;
      expect(nodeGroup.children.length, equals(2));
    });

    testWidgets(
        'single tap on staff card selects staff and enters selection mode',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no checkmarks
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Single tap on the staff label
      final staffCard = find.textContaining('Violin I');
      expect(staffCard, findsOneWidget);
      await tester.tap(staffCard);
      // Pump past double-tap window so single tap resolves
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Now staff should be selected and checkmark badge visible
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Tapping the checkmark badge directly toggles selection off
      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Selection mode exited
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets(
        'double tap on staff card triggers inline name editing WITHOUT selecting staff',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Double tap on the staff label
      final staffCard = find.textContaining('Violin I');
      expect(staffCard, findsOneWidget);

      await tester.tap(staffCard);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(staffCard);
      await tester.pumpAndSettle();

      // Inline labeling TextField should now be active
      expect(find.byType(TextField), findsAtLeastNWidgets(1));

      // Staff must NOT be selected!
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets(
        'dropping a staff item in a subgroup onto itself cancels action without moving to root',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sourceUid = cubit.allStaves[0].uid;
      final targetUid = cubit.allStaves[1].uid;
      cubit.groupTwoStavesTogether(sourceUid, targetUid);
      await tester.pump(const Duration(milliseconds: 600));

      // Root has 3 children: 1 StaffNodeGroup (with 2 staves) and 2 StaffDefinitions
      expect(
          cubit.state.config.systemLayout.rootGroup.children.length, equals(3));
      expect(cubit.state.config.systemLayout.rootGroup.children.first,
          isA<core.StaffNodeGroup>());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the first drag handle (Violin I, inside the subgroup)
      final handle = find.byIcon(Icons.drag_indicator).first;
      // Drag slightly within itself and drop
      await tester.drag(handle, const Offset(2, 2));
      await tester.pumpAndSettle();

      // Verify Violin I is STILL inside the subgroup and NOT moved to root
      final rootGroup = cubit.state.config.systemLayout.rootGroup;
      expect(rootGroup.children.length, equals(3));
      final subGroup = rootGroup.children.first as core.StaffNodeGroup;
      expect(subGroup.children.length, equals(2));
      expect(subGroup.children.first, isA<core.StaffDefinition>());
      expect((subGroup.children.first as core.StaffDefinition).uid,
          equals(sourceUid));
    });

    testWidgets('quick labeling card auto-saves on outside tap',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editIcon = find.byTooltip('Edit Instrument Name');
      await tester.ensureVisible(editIcon.first);
      await tester.tap(editIcon.first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
      await tester.enterText(find.byType(TextField).first, 'First Violin');

      // Tap outside the card (e.g. at top-left outside the labeling card)
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      expect(cubit.allStaves.first.instrumentName, equals('First Violin'));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
        'quick labeling card cancels on Escape key without updating staff',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editIcon = find.byTooltip('Edit Instrument Name');
      await tester.ensureVisible(editIcon.first);
      await tester.tap(editIcon.first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
      await tester.enterText(find.byType(TextField).first, 'Violino Grande');

      // Press Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Original name remains unchanged
      expect(cubit.allStaves.first.instrumentName, equals('Violin I'));
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
        'clef badge switches between clefs and auto-normalizes line count',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Violin I initially has Treble Clef and Line 2
      expect(find.text('Treble Clef'), findsWidgets);
      expect(find.text('Line 2'), findsWidgets);

      // Tap the Treble Clef badge on the first staff to open clef picker
      final trebleBadge = find.text('Treble Clef').first;
      await tester.ensureVisible(trebleBadge);
      await tester.tap(trebleBadge);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Popup menu shows Tablature option
      final tabOption = find.text('Tablature').last;
      await tester.tap(tabOption);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Verify Cubit updated staff to TabClef with 6 lines
      expect(cubit.allStaves.first.clef, isA<core.TabClef>());
      expect(cubit.allStaves.first.lines, equals(6));

      // UI should now render 'Tablature' and '6 Lines'
      expect(find.text('Tablature'), findsWidgets);
      expect(find.text('6 Lines'), findsWidgets);

      // Now tap the Tablature badge and switch back to Treble Clef
      final tabBadge = find.text('Tablature').first;
      await tester.tap(tabBadge);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final trebleOption = find.text('Treble Clef').last;
      await tester.tap(trebleOption);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Line count auto-snaps back to 5 for audible clef
      expect(cubit.allStaves.first.clef, isA<core.TrebleClef>());
      expect(cubit.allStaves.first.lines, equals(5));
      expect(find.text('Line 2'), findsWidgets);
    });

    testWidgets(
        'anchor line badge allows switching registers for audible clef',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In string quartet, Viola (index 2) starts with Alto Clef on Line 3
      expect(find.text('Alto Clef'), findsOneWidget);
      expect(find.text('Line 3'), findsOneWidget);

      // Tap Line 3 badge
      final line3Badge = find.text('Line 3').first;
      await tester.ensureVisible(line3Badge);
      await tester.tap(line3Badge);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Select Tenor (Line 4) from register presets
      final tenorPreset = find.text('Tenor (Line 4)');
      expect(tenorPreset, findsOneWidget);
      await tester.tap(tenorPreset);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Viola clef is now TenorClef with anchorLine == 4
      final viola = cubit.allStaves[2];
      expect(viola.clef, isA<core.TenorClef>());
      expect(viola.clef?.anchorLine, equals(4));

      // Badges update to 'Tenor Clef', and both Viola and Cello are on Line 4
      expect(find.text('Tenor Clef'), findsOneWidget);
      expect(find.text('Line 4'), findsNWidgets(2));
    });

    testWidgets(
        'dragging a group reorders it among siblings in the parent group',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit.applyProfile(core.StaffProfiles.stringQuartet);
      // Group staves 0 & 1 into first group
      cubit.groupTwoStavesTogether(
          cubit.allStaves[0].uid, cubit.allStaves[1].uid);
      await tester.pump(const Duration(milliseconds: 300));

      // Group staves 2 & 3 into second group
      final staves = cubit.allStaves;
      cubit.groupTwoStavesTogether(staves[2].uid, staves[3].uid);
      await tester.pump(const Duration(milliseconds: 300));

      final rootWithTwoGroups = cubit.state.config.systemLayout.rootGroup;
      expect(rootWithTwoGroups.children.length, equals(2));
      expect(rootWithTwoGroups.children[0], isA<core.StaffNodeGroup>());
      expect(rootWithTwoGroups.children[1], isA<core.StaffNodeGroup>());

      final group0 = rootWithTwoGroups.children[0] as core.StaffNodeGroup;
      final group1 = rootWithTwoGroups.children[1] as core.StaffNodeGroup;

      cubit.updateGroupDetails(groupHash: group0.hashCode, label: 'Violins');
      cubit.updateGroupDetails(groupHash: group1.hashCode, label: 'Low Strings');
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final groupDragHandles = find.byTooltip('Drag to reorder group');
      expect(groupDragHandles, findsAtLeastNWidgets(2));

      final firstHandle = groupDragHandles.at(0);
      final secondHandle = groupDragHandles.at(1);

      final firstHandleCenter = tester.getCenter(firstHandle);
      final secondHandleCenter = tester.getCenter(secondHandle);

      final gesture = await tester.startGesture(secondHandleCenter);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture
          .moveTo(Offset(firstHandleCenter.dx, firstHandleCenter.dy - 10));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      final updatedRoot = cubit.state.config.systemLayout.rootGroup;
      expect((updatedRoot.children[0] as core.StaffNodeGroup).label,
          equals('Low Strings'));
      expect((updatedRoot.children[1] as core.StaffNodeGroup).label,
          equals('Violins'));
    });

    testWidgets(
        'dropping an ancestor group into its own child group is prevented',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit.applyProfile(core.StaffProfiles.stringQuartet);
      cubit.groupTwoStavesTogether(
          cubit.allStaves[0].uid, cubit.allStaves[1].uid);
      await tester.pump(const Duration(milliseconds: 300));

      final rootBefore = cubit.state.config.systemLayout.rootGroup;
      final groupA = rootBefore.children.first as core.StaffNodeGroup;

      final staff0 = groupA.children[0] as core.StaffDefinition;
      final staff1 = groupA.children[1] as core.StaffDefinition;
      cubit.groupTwoStavesTogether(staff0.uid, staff1.uid);
      await tester.pump(const Duration(milliseconds: 300));

      final rootWithSubgroup = cubit.state.config.systemLayout.rootGroup;
      expect(rootWithSubgroup.children.first, isA<core.StaffNodeGroup>());
      final outerGroup = rootWithSubgroup.children.first as core.StaffNodeGroup;
      expect(outerGroup.children.first, isA<core.StaffNodeGroup>());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final groupDragHandles = find.byTooltip('Drag to reorder group');
      expect(groupDragHandles, findsAtLeastNWidgets(2));

      final outerHandleCenter = tester.getCenter(groupDragHandles.at(0));
      final innerHandleCenter = tester.getCenter(groupDragHandles.at(1));

      final gesture = await tester.startGesture(outerHandleCenter);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.moveTo(innerHandleCenter);
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pumpAndSettle();

      final rootAfter = cubit.state.config.systemLayout.rootGroup;
      expect(rootAfter.children.first, isA<core.StaffNodeGroup>());
      final finalOuter = rootAfter.children.first as core.StaffNodeGroup;
      expect(finalOuter.hashCode, equals(outerGroup.hashCode));
      expect(finalOuter.children.first, isA<core.StaffNodeGroup>());
    });

    testWidgets(
        'dragging a group over a leaf staff reorders group relative to the staff',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit.applyProfile(core.StaffProfiles.stringQuartet);
      cubit.updateStaffInstrumentName(cubit.allStaves[2].uid, 'Viola');
      cubit.groupTwoStavesTogether(
          cubit.allStaves[0].uid, cubit.allStaves[1].uid);
      await tester.pump(const Duration(milliseconds: 300));

      final rootBefore = cubit.state.config.systemLayout.rootGroup;
      expect(rootBefore.children[0], isA<core.StaffNodeGroup>());
      expect(rootBefore.children[1], isA<core.StaffDefinition>());
      expect(rootBefore.children[2], isA<core.StaffDefinition>());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final groupHandle = find.byTooltip('Drag to reorder group').first;
      final violaCard = find.byKey(ValueKey('staff_${cubit.allStaves[2].uid}'));
      expect(violaCard, findsOneWidget);

      final groupHandleCenter = tester.getCenter(groupHandle);
      final violaRect = tester.getRect(violaCard);

      final gesture = await tester.startGesture(groupHandleCenter);
      await tester.pump(const Duration(milliseconds: 100));

      // Move into the bottom zone of Viola item (ratio >= 0.5 -> insertAfter = true)
      await gesture.moveTo(Offset(violaRect.center.dx, violaRect.bottom - 5));
      await tester.pump(const Duration(milliseconds: 100));

      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      final rootAfter = cubit.state.config.systemLayout.rootGroup;
      expect(rootAfter.children[0], isA<core.StaffDefinition>());
      expect((rootAfter.children[0] as core.StaffDefinition).instrumentName,
          contains('Viola'));
      expect(rootAfter.children[1], isA<core.StaffNodeGroup>());
    });

    testWidgets(
        'editing group label displays Gould non-redundancy chip and renumbers staves',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit.applyProfile(core.StaffProfiles.stringQuartet);
      // Group Violin I and Violin II
      cubit.groupTwoStavesTogether(
          cubit.allStaves[0].uid, cubit.allStaves[1].uid);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open group label editor
      final editGroupButtons = find.byTooltip('Edit Group Label');
      expect(editGroupButtons, findsAtLeastNWidgets(1));
      await tester.tap(editGroupButtons.first);
      await tester.pumpAndSettle();

      // Gould suggestion chip should appear for the 2 grouped staves
      final gouldChip = find.textContaining('Apply Gould non-redundancy');
      expect(gouldChip, findsOneWidget);

      // Tap the Gould chip to auto-number
      await tester.tap(gouldChip);
      await tester.pumpAndSettle();

      // Verify staves are renumbered to 1 and 2
      final staves = cubit.allStaves;
      expect(staves[0].instrumentName, equals('1'));
      expect(staves[1].instrumentName, equals('2'));

      // Check applied state text
      expect(find.textContaining('Gould non-redundancy applied'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('renders Level 2 badge on sub-groups per Gould standards',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      cubit.applyProfile(core.StaffProfiles.stringQuartet);
      // Nesting: root (0) -> Family Group (1) -> Sub Group (2)
      cubit.groupSelectedStaves(
        {cubit.allStaves[0].uid, cubit.allStaves[1].uid, cubit.allStaves[2].uid, cubit.allStaves[3].uid},
        core.SystemConnector.bracket,
      );
      // Sub-group inside family group
      cubit.groupTwoStavesTogether(
        cubit.allStaves[0].uid,
        cubit.allStaves[1].uid,
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<DocumentCubit>.value(
                value: cubit,
                child: SystemHierarchyPanel(notifier: cubit),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should find the Level 2 badge
      expect(find.text('Level 2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
