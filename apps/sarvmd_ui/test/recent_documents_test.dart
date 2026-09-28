import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/services/recent_documents_service.dart';
import 'package:sarvmd_ui/src/logic/workspace/workspace_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/top_bar/menus/file_menu.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/top_bar/top_bar_menu_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('sarvmd_recent_test_');
    SharedPreferences.setMockInitialValues({});
    RecentDocumentsService.resetForTesting();
  });

  tearDown(() {
    RecentDocumentsService.resetForTesting();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('RecentDocumentsService Unit Tests', () {
    test('init loads saved preferences into reactive notifier', () async {
      final file1 = File('${tempDir.path}/score1.sarv')..writeAsStringSync('{}');
      final file2 = File('${tempDir.path}/score2.sarv')..writeAsStringSync('{}');

      SharedPreferences.setMockInitialValues({
        'sarvmd_recent_documents': [file1.path, file2.path],
      });

      final docs = await RecentDocumentsService.init();
      expect(docs, equals([file1.path, file2.path]));
      expect(RecentDocumentsService.recentDocumentsNotifier.value, equals([file1.path, file2.path]));
    });

    test('addRecentDocument inserts at front and deduplicates', () async {
      final file1 = File('${tempDir.path}/doc_a.sarv')..writeAsStringSync('{}');
      final file2 = File('${tempDir.path}/doc_b.sarv')..writeAsStringSync('{}');

      await RecentDocumentsService.addRecentDocument(file1.path);
      expect(RecentDocumentsService.recentDocumentsNotifier.value, equals([file1.path]));

      await RecentDocumentsService.addRecentDocument(file2.path);
      expect(RecentDocumentsService.recentDocumentsNotifier.value, equals([file2.path, file1.path]));

      // Adding doc_a again promotes it to front without duplicate
      await RecentDocumentsService.addRecentDocument(file1.path);
      expect(RecentDocumentsService.recentDocumentsNotifier.value, equals([file1.path, file2.path]));
    });

    test('addRecentDocument caps at 10 items', () async {
      for (int i = 1; i <= 15; i++) {
        final f = File('${tempDir.path}/piece_$i.sarv')..writeAsStringSync('{}');
        await RecentDocumentsService.addRecentDocument(f.path);
      }

      final recent = RecentDocumentsService.recentDocumentsNotifier.value;
      expect(recent.length, equals(10));
      expect(recent.first, endsWith('piece_15.sarv'));
      expect(recent.last, endsWith('piece_6.sarv'));
    });

    test('removeRecentDocument and clearRecentDocuments modify state and persist', () async {
      final file1 = File('${tempDir.path}/file1.sarv')..writeAsStringSync('{}');
      final file2 = File('${tempDir.path}/file2.sarv')..writeAsStringSync('{}');

      await RecentDocumentsService.addRecentDocument(file1.path);
      await RecentDocumentsService.addRecentDocument(file2.path);

      await RecentDocumentsService.removeRecentDocument(file1.path);
      expect(RecentDocumentsService.recentDocumentsNotifier.value, equals([file2.path]));

      await RecentDocumentsService.clearRecentDocuments();
      expect(RecentDocumentsService.recentDocumentsNotifier.value, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('sarvmd_recent_documents'), isNull);
    });

    test('prunes files that do not exist on disk on init', () async {
      final existingFile = File('${tempDir.path}/exists.sarv')..writeAsStringSync('{}');
      final missingPath = '${tempDir.path}/deleted.sarv';

      SharedPreferences.setMockInitialValues({
        'sarvmd_recent_documents': [missingPath, existingFile.path],
      });

      final docs = await RecentDocumentsService.init();
      expect(docs, equals([existingFile.path]));
    });
  });

  group('Open Recent Menu & Workspace Integration', () {
    testWidgets('TopBarFileMenu shows Empty state when no recent documents exist', (tester) async {
      final docCubit = DocumentCubit();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: TopBarFileMenu(documentState: docCubit.state),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open File menu
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();

      // Hover / tap Open Recent
      expect(find.text('Open Recent'), findsOneWidget);
      await tester.tap(find.text('Open Recent'));
      await tester.pumpAndSettle();

      expect(find.text('No Recent Files'), findsOneWidget);
    });

    testWidgets('handleOpenRecentDocument switches to existing tab if already open', (tester) async {
      final initialCubit = DocumentCubit(null, null, false);
      final workspace = WorkspaceCubit(initialCubit: initialCubit);
      addTearDown(() async => await workspace.close());

      final file = File('${tempDir.path}/existing.sarv');
      const doc = core.SarvDocument(
        score: core.Score(),
        config: core.PageConfig(),
        metadata: core.DocumentMetadata(title: 'Existing Tab Score'),
      );
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(doc.toJson()));

      // Open as tab
      await workspace.openDocumentTab(doc, filePath: file.path, title: 'existing.sarv');
      // Open second tab
      workspace.openNewTab();
      expect(workspace.state.activeIndex, equals(1));

      final testContextKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: BlocProvider<WorkspaceCubit>.value(
            value: workspace,
            child: Scaffold(
              key: testContextKey,
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await handleOpenRecentDocument(testContextKey.currentContext!, file.path);
      await tester.pump(const Duration(milliseconds: 600));

      // Should have switched back to index 0 rather than opening a duplicate tab
      expect(workspace.state.activeIndex, equals(0));
      expect(workspace.state.tabCount, equals(2));
    });

    testWidgets('handleOpenRecentDocument opens new tab if not currently open', (tester) async {
      final initialCubit = DocumentCubit(null, null, false);
      final workspace = WorkspaceCubit(initialCubit: initialCubit);
      addTearDown(() async => await workspace.close());

      // Give initial cubit a modification so it's not a pristine blank tab
      initialCubit.setTitle('First Score');

      final file = File('${tempDir.path}/novel.sarv');
      const doc = core.SarvDocument(
        score: core.Score(),
        config: core.PageConfig(),
        metadata: core.DocumentMetadata(title: 'Novel Piece'),
      );
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(doc.toJson()));

      final testContextKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: BlocProvider<WorkspaceCubit>.value(
            value: workspace,
            child: Scaffold(
              key: testContextKey,
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(workspace.state.tabCount, equals(1));
      await tester.runAsync(() async {
        await handleOpenRecentDocument(testContextKey.currentContext!, file.path);
      });
      await tester.pump();

      expect(workspace.state.tabCount, equals(2));
      expect(workspace.state.activeSession.filePath, equals(file.path));
      expect(workspace.state.activeSession.document.metadata.title, equals('Novel Piece'));
    });
  });
}
