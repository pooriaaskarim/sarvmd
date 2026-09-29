// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:convert';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/workspace/workspace_cubit.dart';
import 'package:sarvmd_ui/src/presentation/screens/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestShell({
  required WorkspaceCubit workspaceCubit,
  required ViewCubit viewCubit,
  required LocaleCubit localeCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<LocaleCubit>.value(value: localeCubit),
      BlocProvider<WorkspaceCubit>.value(value: workspaceCubit),
      BlocProvider<ViewCubit>.value(value: viewCubit),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppShell(),
    ),
  );
}

class _TestWebDropItem extends DropItem {
  final String _name;
  final Uint8List _bytes;
  _TestWebDropItem(Uint8List bytes, {required String name, required String path})
      : _name = name,
        _bytes = bytes,
        super(path, bytes: bytes);

  @override
  String get name => _name;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkspaceCubit workspaceCubit;
  late ViewCubit viewCubit;
  late LocaleCubit localeCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    workspaceCubit = WorkspaceCubit(
      initialCubit: DocumentCubit(null, null, false),
      autoRestoreSession: false,
    );
    viewCubit = ViewCubit();
    localeCubit = LocaleCubit();
  });

  tearDown(() async {
    await workspaceCubit.close();
    await viewCubit.close();
    await localeCubit.close();
  });

  group('AppShell Drag-and-Drop Tests', () {
    testWidgets('shows overlay when drag enters and hides when drag exits', (tester) async {
      await tester.pumpWidget(_buildTestShell(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      final dropTargetFinder = find.byType(DropTarget);
      expect(dropTargetFinder, findsOneWidget);

      final dropTarget = tester.widget<DropTarget>(dropTargetFinder);

      // Initially overlay should not be visible
      expect(find.text('Drop .sarv manuscript to open'), findsNothing);

      // Trigger drag enter
      dropTarget.onDragEntered?.call(
        DropEventDetails(localPosition: Offset.zero, globalPosition: Offset.zero),
      );
      await tester.pump();

      // Overlay should now be visible
      expect(find.text('Drop .sarv manuscript to open'), findsOneWidget);

      // Trigger drag exit
      dropTarget.onDragExited?.call(
        DropEventDetails(localPosition: Offset.zero, globalPosition: Offset.zero),
      );
      await tester.pump();

      // Overlay should be gone
      expect(find.text('Drop .sarv manuscript to open'), findsNothing);
    });

    testWidgets('processes valid dropped .sarv file bytes and opens in new tab', (tester) async {
      await tester.pumpWidget(_buildTestShell(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      const doc = core.SarvDocument(
        score: core.Score(title: 'Dropped Concerto'),
        metadata: core.DocumentMetadata(title: 'Dropped Concerto'),
      );
      final jsonBytes = Uint8List.fromList(utf8.encode(doc.toSarvJson()));

      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));
      final dropItem = DropItemFile.fromData(
        jsonBytes,
        name: 'concerto.sarv',
        path: 'concerto.sarv',
      );

      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [dropItem],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      // Verify new tab was opened with dropped document filename
      expect(workspaceCubit.state.activeSession.title, 'concerto.sarv');
    });

    testWidgets('displays warning notification when non-.sarv file is dropped', (tester) async {
      await tester.pumpWidget(_buildTestShell(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));
      final dropItem = DropItemFile.fromData(
        Uint8List(0),
        name: 'image.png',
        path: 'image.png',
      );

      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [dropItem],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('dragging the same doc after dragging another switches tabs and avoids duplicates', (tester) async {
      await tester.pumpWidget(_buildTestShell(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      const doc1 = core.SarvDocument(
        score: core.Score(title: 'First Concerto'),
        metadata: core.DocumentMetadata(title: 'First Concerto'),
      );
      final bytes1 = Uint8List.fromList(utf8.encode(doc1.toSarvJson()));

      const doc2 = core.SarvDocument(
        score: core.Score(title: 'Second Sonata'),
        metadata: core.DocumentMetadata(title: 'Second Sonata'),
      );
      final bytes2 = Uint8List.fromList(utf8.encode(doc2.toSarvJson()));

      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));

      // 1. Drop doc 1 -> loads into tab
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [DropItemFile.fromData(bytes1, name: 'concerto.sarv', path: 'concerto.sarv')],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(workspaceCubit.state.tabCount, 1);
      expect(workspaceCubit.state.activeSession.title, 'concerto.sarv');

      // 2. Drop doc 2 -> opens new tab 2
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [DropItemFile.fromData(bytes2, name: 'sonata.sarv', path: 'sonata.sarv')],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 1);
      expect(workspaceCubit.state.activeSession.title, 'sonata.sarv');

      // 3. Drop doc 1 again -> switches back to tab 0 and DOES NOT open tab 3!
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [DropItemFile.fromData(bytes1, name: 'concerto.sarv', path: 'concerto.sarv')],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 0);
      expect(workspaceCubit.state.activeSession.title, 'concerto.sarv');
      expect(find.text('Switched to tab "First Concerto"'), findsOneWidget);
    });

    testWidgets('web drag and drop with blob URLs and random UUID paths displays proper file name and deduplicates', (tester) async {
      await tester.pumpWidget(_buildTestShell(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      const doc = core.SarvDocument(
        score: core.Score(title: 'Web Symphony'),
        metadata: core.DocumentMetadata(title: 'Web Symphony'),
      );
      final bytes = Uint8List.fromList(utf8.encode(doc.toSarvJson()));
      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));

      // 1. First drop on Web: browser provides a blob URL with a random UUID as path
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [
              _TestWebDropItem(
                bytes,
                name: 'symphony.sarv',
                path: 'blob:http://localhost:54321/9bf3e8d2-4521-4f1a-b678-0123456789ab',
              ),
            ],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(workspaceCubit.state.tabCount, 1);
      final activeSession = workspaceCubit.state.activeSession;
      expect(activeSession.title, equals('symphony.sarv'));
      expect(activeSession.title, isNot(contains('9bf3e8d2')));
      expect(activeSession.title, isNot(contains('blob:')));
      expect(activeSession.filePath, equals('symphony.sarv'));

      // 2. Second drop on Web with a different transient blob URL: must switch to existing tab
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [
              _TestWebDropItem(
                bytes,
                name: 'symphony.sarv',
                path: 'blob:http://localhost:54321/fedcba98-7654-3210-fedc-ba9876543210',
              ),
            ],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(workspaceCubit.state.tabCount, 1);
      expect(workspaceCubit.state.activeSession.title, equals('symphony.sarv'));
      expect(find.text('Switched to tab "Web Symphony"'), findsOneWidget);
    });

    testWidgets('dropping sample.sarv followed by sample (1).sarv with identical content opens separate tabs', (tester) async {
      await tester.pumpWidget(_buildTestShell(
        workspaceCubit: workspaceCubit,
        viewCubit: viewCubit,
        localeCubit: localeCubit,
      ));
      await tester.pumpAndSettle();

      const doc = core.SarvDocument(
        score: core.Score(title: 'sample'),
        metadata: core.DocumentMetadata(title: 'sample'),
      );
      final bytes = Uint8List.fromList(utf8.encode(doc.toSarvJson()));
      final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));

      // 1. Drop sample.sarv
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [
              _TestWebDropItem(
                bytes,
                name: 'sample.sarv',
                path: 'blob:http://localhost:54321/blob-1',
              ),
            ],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(workspaceCubit.state.tabCount, 1);
      expect(workspaceCubit.state.activeSession.title, equals('sample.sarv'));

      // 2. Drop sample (1).sarv (identical content from Save As, but different file name)
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [
              _TestWebDropItem(
                bytes,
                name: 'sample (1).sarv',
                path: 'blob:http://localhost:54321/blob-2',
              ),
            ],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 1);
      expect(workspaceCubit.state.activeSession.title, equals('sample (1).sarv'));
      expect(find.text('Opened "sample"'), findsOneWidget);

      // 3. Drop sample.sarv again -> switches to tab 0
      await tester.runAsync(() async {
        dropTarget.onDragDone?.call(
          DropDoneDetails(
            files: [
              _TestWebDropItem(
                bytes,
                name: 'sample.sarv',
                path: 'blob:http://localhost:54321/blob-3',
              ),
            ],
            localPosition: Offset.zero,
            globalPosition: Offset.zero,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 0);
      expect(workspaceCubit.state.activeSession.title, equals('sample.sarv'));
      expect(find.text('Switched to tab "sample"'), findsOneWidget);
    });
  });
}
