// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/document/document_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/top_bar/menus/file_menu.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/top_bar/widgets/editable_score_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({required Widget child, DocumentCubit? cubit}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: cubit != null
          ? BlocProvider<DocumentCubit>.value(
              value: cubit,
              child: child,
            )
          : child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnsavedChangesDialog Widget Tests', () {
    testWidgets('shows document name and actions', (tester) async {
      UnsavedChangesAction? userAction;

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  userAction = await showUnsavedChangesDialog(
                    context,
                    documentName: 'Quartet_No_1.sarv',
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check document name is rendered
      expect(find.textContaining('Quartet_No_1.sarv'), findsOneWidget);

      // Verify buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text("Don't Save"), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(userAction, equals(UnsavedChangesAction.save));
    });

    testWidgets('tapping Discard returns discard action', (tester) async {
      UnsavedChangesAction? userAction;

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  userAction = await showUnsavedChangesDialog(
                    context,
                    documentName: 'Draft.sarv',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Don't Save"));
      await tester.pumpAndSettle();

      expect(userAction, equals(UnsavedChangesAction.discard));
    });
  });

  group('EditableScoreHeader Dirty Indicator Tests', () {
    late DocumentCubit cubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cubit = DocumentCubit();
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders dirty dot when document is modified', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          child: BlocBuilder<DocumentCubit, DocumentState>(
            builder: (context, state) => EditableScoreHeader(
              score: state.score,
              configState: state.config,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially not dirty -> no dot
      expect(find.byKey(const ValueKey('score_header_dirty_dot')), findsNothing);

      // Mutate title -> dirty
      cubit.setTitle('Edited Score');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('score_header_dirty_dot')), findsOneWidget);

      // Undo -> no longer dirty
      cubit.undo();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('score_header_dirty_dot')), findsNothing);
    });
  });

  group('TopBarFileMenu Widget Tests', () {
    late DocumentCubit cubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cubit = DocumentCubit();
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders all file operations and shortcuts', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          child: BlocBuilder<DocumentCubit, DocumentState>(
            builder: (context, state) => TopBarFileMenu(
              documentState: state,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open menu
      final fileButton = find.text('File');
      expect(fileButton, findsOneWidget);
      await tester.tap(fileButton);
      await tester.pumpAndSettle();

      // Verify menu entries
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Open…'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Save As…'), findsOneWidget);
      expect(find.text('EXPORT'), findsOneWidget);
    });
  });
}
