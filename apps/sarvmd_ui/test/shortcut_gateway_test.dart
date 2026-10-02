// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/workspace/workspace_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/shortcut_gateway.dart';
import 'package:sarvmd_ui/src/presentation/screens/pointer_editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/widgets/layout/top_bar/top_bar_menu_header.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SarvShortcutGateway Focus & Desktop Shortcut Reliability', () {
    testWidgets('executes shortcuts on launch via autofocus', (tester) async {
      int zoomInCount = 0;
      int zoomOutCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SarvShortcutGateway(
              onZoomIn: () => zoomInCount++,
              onZoomOut: () => zoomOutCount++,
              child: const SizedBox.expand(
                child: Center(child: Text('Workspace Child')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Trigger Ctrl + =
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.equal);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(zoomInCount, equals(1));

      // Trigger Ctrl + -
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.minus);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(zoomOutCount, equals(1));
    });

    testWidgets('retains and handles shortcuts even after primaryFocus is unfocused', (tester) async {
      int undoCount = 0;
      final textController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SarvShortcutGateway(
              onToggleSidebar: () => undoCount++,
              child: Column(
                children: [
                  TextField(
                    key: const ValueKey('test_input'),
                    controller: textController,
                  ),
                  const Expanded(
                    child: Center(child: Text('Canvas')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap and focus text input
      await tester.tap(find.byKey(const ValueKey('test_input')));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);

      // Explicitly simulate unfocus() as done by PrecisionSliders and Done buttons
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Verify that Ctrl+B (ToggleSidebar) continues to work because FocusScope catches unfocus
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(undoCount, equals(1));
    });

    testWidgets('SarvShortcutGateway.requestFocus restores focus after arbitrary focus loss', (tester) async {
      int togglePanelCount = 0;
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SarvShortcutGateway(
              onToggleViewPanel: () => togglePanelCount++,
              child: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const Center(child: Text('App Content'));
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Force unfocus
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Call static requestFocus
      SarvShortcutGateway.requestFocus(capturedContext);
      await tester.pump();

      // Fire Ctrl + \
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.backslash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(togglePanelCount, equals(1));
    });

    testWidgets('TopBarMenuHeader restores gateway focus when menu closes', (tester) async {
      int zoomResetCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SarvShortcutGateway(
              onZoomReset: () => zoomResetCount++,
              child: Column(
                children: [
                  TopBarMenuHeader(
                    label: 'File',
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {},
                        child: const Text('Dummy Item'),
                      ),
                    ],
                  ),
                  const Expanded(child: Center(child: Text('Workspace Canvas'))),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open menu
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('Dummy Item'), findsOneWidget);

      // Close menu by tapping outside
      await tester.tap(find.text('Workspace Canvas'));
      await tester.pumpAndSettle();
      expect(find.text('Dummy Item'), findsNothing);

      // Test shortcut Ctrl+0 (ZoomReset)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(zoomResetCount, equals(1));
    });

    testWidgets('Tapping on canvas restores focus and allows shortcuts in PointerEditorScreen', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final localeCubit = LocaleCubit(const LocaleState());
      final docCubit = DocumentCubit();
      final workspaceCubit = WorkspaceCubit(initialCubit: docCubit, autoRestoreSession: false);
      final viewCubit = ViewCubit(const ViewState());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<LocaleCubit>.value(value: localeCubit),
            BlocProvider<DocumentCubit>.value(value: docCubit),
            BlocProvider<WorkspaceCubit>.value(value: workspaceCubit),
            BlocProvider<ViewCubit>.value(value: viewCubit),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PointerEditorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify canvas is present
      final canvasFinder = find.byType(InteractiveViewer);
      expect(canvasFinder, findsOneWidget);

      // Tap on canvas with pointer
      await tester.tap(canvasFinder);
      await tester.pump();

      // Trigger Ctrl+T (New Tab in WorkspaceCubit)
      expect(workspaceCubit.state.tabCount, equals(1));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.tabCount, equals(2));

      // Trigger Ctrl+W (Close Tab)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(workspaceCubit.state.tabCount, equals(1));

      // Cleanup
      docCubit.close();
      workspaceCubit.close();
      viewCubit.close();
      localeCubit.close();
    });
  });
}
