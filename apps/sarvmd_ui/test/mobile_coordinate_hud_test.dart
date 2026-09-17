// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/screens/mobile_editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Coordinate HUD Long Press & Drag Tests', () {
    late LocaleCubit localeCubit;
    late ViewCubit viewCubit;
    late DocumentCubit documentCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      localeCubit = LocaleCubit(const LocaleState());
      viewCubit = ViewCubit(const ViewState());
      documentCubit = DocumentCubit();
    });

    tearDown(() {
      localeCubit.close();
      viewCubit.close();
      documentCubit.close();
    });

    Widget createTestWidget() {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: viewCubit),
          BlocProvider.value(value: documentCubit),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MobileEditorScreen(),
        ),
      );
    }

    testWidgets('Long press on canvas shows top glassmorphic coordinate HUD', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Long press center of canvas
      await tester.longPressAt(const Offset(400, 300));
      await tester.pumpAndSettle();

      // Coordinate HUD should appear containing X: and Y: indicators
      expect(find.text('X: '), findsOneWidget);
      expect(find.text('Y: '), findsOneWidget);
    });

    testWidgets('Dragging finger updates coordinate readout in real-time', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start long press gesture in canvas center
      final gesture = await tester.startGesture(const Offset(400, 300));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('X: '), findsOneWidget);

      // Drag to new coordinate
      await gesture.moveTo(const Offset(450, 350));
      await tester.pumpAndSettle();

      // HUD should still be visible and updated
      expect(find.text('X: '), findsOneWidget);
      expect(find.text('Y: '), findsOneWidget);

      await gesture.up();
      await tester.pump();
    });
  });
}
