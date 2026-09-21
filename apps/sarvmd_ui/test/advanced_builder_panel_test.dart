// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
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
  });
}
