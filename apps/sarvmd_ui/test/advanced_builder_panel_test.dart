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

    testWidgets('inline editing mode updates instrument name',
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

      // Tap the edit icon on the first staff
      final editIcon = find.byTooltip('Edit Instrument Name');
      expect(editIcon, findsAtLeastNWidgets(1));

      await tester.ensureVisible(editIcon.first);
      await tester.tap(editIcon.first);
      await tester.pumpAndSettle();

      // Should show a TextField for inline name editing
      expect(find.byType(TextField), findsOneWidget);

      // Enter new name and submit
      await tester.enterText(find.byType(TextField), 'Solo Violin');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Check cubit updated staff name
      expect(cubit.allStaves.first.instrumentName, equals('Solo Violin'));
    });

    testWidgets('groupTwoStavesTogether combines two staves into a StaffNodeGroup',
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
  });
}

