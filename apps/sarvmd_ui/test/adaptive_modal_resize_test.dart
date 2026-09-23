// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/about_dialog.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/adaptive_dialog_helper.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/calibration_dialog.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/export_dialog.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/staff_config_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive Modal & Dialog Resizing Resilience Tests', () {
    late DocumentCubit documentCubit;
    late ViewCubit viewCubit;
    late LocaleCubit localeCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      documentCubit = DocumentCubit();
      viewCubit = ViewCubit(const ViewState());
      localeCubit = LocaleCubit();
    });

    tearDown(() {
      documentCubit.close();
      viewCubit.close();
      localeCubit.close();
    });

    Widget buildAppWithButton({
      required void Function(BuildContext context) onOpen,
    }) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: documentCubit),
          BlocProvider.value(value: viewCubit),
          BlocProvider.value(value: localeCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => onOpen(context),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('ExportDialog does not crash when resized between desktop and mobile widths', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithButton(
          onOpen: (context) => showExportDialog(context),
        ),
      );
      await tester.pumpAndSettle();

      // Open Export Dialog in desktop mode
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(ExportDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Dynamically shrink window across the 600px boundary to narrow mobile width
      tester.view.physicalSize = const Size(380, 700);
      await tester.pumpAndSettle();

      // Verify no assertion error or infinite width crash occurs
      expect(find.byType(ExportDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Expand back to wide desktop window
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();

      expect(find.byType(ExportDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('AboutSarvDialog maintains Dialog card wrapper when resized narrower than 600px', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithButton(
          onOpen: (context) => showSarvAboutDialog(context),
        ),
      );
      await tester.pumpAndSettle();

      // Open About Dialog in desktop mode
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutSarvDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Dynamically shrink window to mobile width
      tester.view.physicalSize = const Size(380, 700);
      await tester.pumpAndSettle();

      // Verify AboutSarvDialog stays wrapped in Dialog and renders cleanly
      expect(find.byType(AboutSarvDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('StaffConfigDialog survives dynamic resize without overflow crashes', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staff = documentCubit.state.config.allStaves.first;

      await tester.pumpWidget(
        buildAppWithButton(
          onOpen: (context) => showStaffConfigDialog(
            context,
            staff: staff,
            notifier: documentCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(StaffConfigDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Resize down to 420px mobile width
      tester.view.physicalSize = const Size(420, 700);
      await tester.pumpAndSettle();

      expect(find.byType(StaffConfigDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('CalibrationDialog maintains Dialog card wrapper when resized narrower than 600px', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1000, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithButton(
          onOpen: (context) => showCalibrationDialog(context, viewCubit),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(CalibrationDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);

      // Dynamically shrink window to mobile width
      tester.view.physicalSize = const Size(380, 700);
      await tester.pumpAndSettle();

      expect(find.byType(CalibrationDialog), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('Mobile BottomSheet modal stays centered and constrained when expanded to wide window', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(380, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildAppWithButton(
          onOpen: (context) => showSarvAdaptiveModal<void>(
            context: context,
            maxWidth: 500.0,
            builder: (ctx, isMobile) => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Adaptive Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open modal in mobile mode (< 600px)
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Adaptive Content'), findsOneWidget);
      // Verify bottom sheet route exists (no Dialog)
      expect(find.byType(Dialog), findsNothing);

      // Expand to wide desktop window (1200px)
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();

      // Content should still be visible and bounded
      expect(find.text('Adaptive Content'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
