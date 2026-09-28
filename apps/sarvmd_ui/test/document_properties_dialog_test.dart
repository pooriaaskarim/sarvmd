// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/document_properties_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp({
  required Widget child,
  DocumentCubit? cubit,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: cubit != null
        ? BlocProvider<DocumentCubit>.value(
            value: cubit,
            child: Scaffold(body: child),
          )
        : Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DocumentPropertiesDialog Unit & Widget Tests', () {
    testWidgets('renders all metadata fields with initial values', (tester) async {
      const initialMeta = core.DocumentMetadata(
        title: 'Sonata in G minor',
        subtitle: 'BWV 1001',
        composer: 'J. S. Bach',
        arranger: 'P. Askari',
        lyricist: 'Traditional',
        copyright: '© 2026 Pooria Askari Moqaddam',
      );

      core.DocumentMetadata? appliedMeta;

      await tester.pumpWidget(
        _buildTestApp(
          child: DocumentPropertiesDialog(
            initialMetadata: initialMeta,
            filePath: '/home/user/scores/sonata.sarv',
            onApply: (meta) => appliedMeta = meta,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Document Properties'), findsOneWidget);
      expect(find.text('/home/user/scores/sonata.sarv'), findsWidgets);
      expect(find.text('Sonata in G minor'), findsOneWidget);
      expect(find.text('BWV 1001'), findsOneWidget);
      expect(find.text('J. S. Bach'), findsOneWidget);
      expect(find.text('P. Askari'), findsOneWidget);
      expect(find.text('Traditional'), findsOneWidget);
      expect(find.text('© 2026 Pooria Askari Moqaddam'), findsOneWidget);
      expect(appliedMeta, isNull);
    });

    testWidgets('displays Unsaved Manuscript when filePath is null', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: DocumentPropertiesDialog(
            initialMetadata: const core.DocumentMetadata(),
            filePath: null,
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Manuscript'), findsWidgets);
    });

    testWidgets('editing fields and clicking Apply returns updated metadata', (tester) async {
      core.DocumentMetadata? result;

      await tester.pumpWidget(
        _buildTestApp(
          child: DocumentPropertiesDialog(
            initialMetadata: const core.DocumentMetadata(title: 'Original Title'),
            filePath: null,
            onApply: (meta) => result = meta,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter new values into text fields
      final titleFinder = find.widgetWithText(TextField, 'Original Title');
      await tester.enterText(titleFinder, 'Symphony No. 9');

      final composerFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Composer',
      );
      await tester.enterText(composerFinder, 'L. v. Beethoven');

      final subtitleFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Subtitle',
      );
      await tester.enterText(subtitleFinder, 'Op. 125');

      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, equals('Symphony No. 9'));
      expect(result!.composer, equals('L. v. Beethoven'));
      expect(result!.subtitle, equals('Op. 125'));
    });

    testWidgets('canceling dialog leaves onApply uncalled', (tester) async {
      bool called = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: DocumentPropertiesDialog(
            initialMetadata: const core.DocumentMetadata(title: 'To Cancel'),
            filePath: null,
            onApply: (_) => called = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('showDocumentPropertiesDialog integrated with DocumentCubit updates state and supports undo', (tester) async {
      final cubit = DocumentCubit(null, null, false);
      addTearDown(() async => await cubit.close());

      final testContextKey = GlobalKey();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              key: testContextKey,
              onPressed: () => showDocumentPropertiesDialog(ctx),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byKey(testContextKey));
      await tester.pumpAndSettle();

      expect(find.byType(DocumentPropertiesDialog), findsOneWidget);

      // Edit title and composer
      final titleField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Title',
      );
      await tester.enterText(titleField, 'Goldberg Variations');

      final composerField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Composer',
      );
      await tester.enterText(composerField, 'J. S. Bach');

      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Dialog dismissed
      expect(find.byType(DocumentPropertiesDialog), findsNothing);

      // State updated in DocumentCubit
      expect(cubit.state.metadata.title, equals('Goldberg Variations'));
      expect(cubit.state.metadata.composer, equals('J. S. Bach'));
      expect(cubit.state.score.title, equals('Goldberg Variations'));
      expect(cubit.state.canUndo, isTrue);

      // Undo reverts
      cubit.undo();
      await tester.pump();

      expect(cubit.state.metadata.title, equals(''));
      expect(cubit.state.metadata.composer, equals(''));
      expect(cubit.state.score.title, equals(''));
      expect(cubit.state.canRedo, isTrue);

      // Redo restores
      cubit.redo();
      await tester.pump();

      expect(cubit.state.metadata.title, equals('Goldberg Variations'));
      expect(cubit.state.metadata.composer, equals('J. S. Bach'));
    });
  });
}
