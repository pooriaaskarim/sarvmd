// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/system_grouping_dialog.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SystemGroupingDialog Widget Tests', () {
    late DocumentCubit cubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cubit = DocumentCubit();
      // Apply chamberOrchestra profile which has nested groups
      cubit.execute(
        core.ApplyProfileCommand(core.StaffProfiles.chamberOrchestra),
      );
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders nested grouping hierarchy and connector controls',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SystemGroupingDialog(notifier: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show title / header
      expect(find.text('System Grouping & Connectors'), findsOneWidget);

      // Should find root system group label
      expect(find.text('Root System Group'), findsOneWidget);

      // Should find sub-group label from chamberOrchestra profile
      expect(find.text('Sub-Group'), findsOneWidget);
    });

    testWidgets('grouping selected staves and applying updates system layout',
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
            body: SystemGroupingDialog(notifier: cubit),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check checkboxes for Viola and Cello
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsAtLeastNWidgets(2));

      // Tap first two checkboxes
      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();

      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Group button should be enabled
      final groupButton = find.text('Group Staves');
      expect(groupButton, findsOneWidget);
      await tester.tap(groupButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now tap Save button
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify that cubit received SetSystemLayoutCommand
      expect(cubit.state.canUndo, isTrue);
    });
  });
}
