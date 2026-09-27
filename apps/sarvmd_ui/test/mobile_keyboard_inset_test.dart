// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sarvmd_ui/src/core/theme/app_metrics.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/dialogs/adaptive_dialog_helper.dart';
import 'package:sarvmd_ui/src/presentation/widgets/touch/settings_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Keyboard Inset Resilience Tests (Item 16)', () {
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

    Widget createMobileDrawerApp() {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: viewCubit),
          BlocProvider.value(value: documentCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            endDrawer: SettingsPanel(
              transformationController: TransformationController(),
              onZoomPreset: (_) {},
            ),
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                child: const Text('Open Drawer'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Drawer shrinks above keyboard and keeps focused margins TextField visible', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844); // Mobile portrait
      tester.view.viewInsets = FakeViewPadding.zero;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(createMobileDrawerApp());
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      // Navigate to Margins section
      viewCubit.setTouchSection(SettingsSection.margins);
      await tester.pumpAndSettle();

      // Find one of the margin scrubbable TextFields
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Verify text field has keyboardScrollPadding configured
      final firstTextField = tester.widget<TextField>(textFields.first);
      expect(firstTextField.scrollPadding, equals(AppSpacing.keyboardScrollPadding));

      // Simulate soft keyboard opening (300px height)
      const double keyboardHeight = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200)); // Animate padding
      await tester.pumpAndSettle();

      // Tap and focus on the bottom-most text field in margins
      final lastTextFieldFinder = textFields.last;
      await tester.tap(lastTextFieldFinder);
      await tester.pumpAndSettle();

      // Verify the focused TextField's bottom boundary is strictly above the keyboard
      final RenderBox fieldBox = tester.renderObject(lastTextFieldFinder);
      final Offset fieldBottomRight = fieldBox.localToGlobal(fieldBox.size.bottomRight(Offset.zero));
      final double keyboardTopEdge = 844.0 - keyboardHeight;

      // The field's bottom edge must be above the keyboard
      expect(fieldBottomRight.dy, lessThan(keyboardTopEdge));
    });

    testWidgets('Modal bottom sheet dynamically raises above soft keyboard', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844); // Mobile portrait
      tester.view.viewInsets = FakeViewPadding.zero;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: viewCubit),
            BlocProvider.value(value: documentCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showSarvAdaptiveModal<void>(
                    context: context,
                    builder: (modalContext, isMobile) => const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Modal Header'),
                          SizedBox(height: 100),
                          TextField(
                            key: ValueKey('modal_test_input'),
                            scrollPadding: AppSpacing.keyboardScrollPadding,
                          ),
                          SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('modal_test_input')), findsOneWidget);

      // Simulate soft keyboard opening (320px height)
      const double keyboardHeight = 320.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Tap and focus TextField
      await tester.tap(find.byKey(const ValueKey('modal_test_input')));
      await tester.pumpAndSettle();

      // Field must be strictly above the keyboard
      final RenderBox fieldBox = tester.renderObject(find.byKey(const ValueKey('modal_test_input')));
      final Offset fieldBottomRight = fieldBox.localToGlobal(fieldBox.size.bottomRight(Offset.zero));
      final double keyboardTopEdge = 844.0 - keyboardHeight;

      expect(fieldBottomRight.dy, lessThan(keyboardTopEdge));
    });

    testWidgets('Landscape docked SettingsPanel fits within short screen without overflowing', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(700, 360); // Landscape phone
      tester.view.viewInsets = FakeViewPadding.zero;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: localeCubit),
            BlocProvider.value(value: viewCubit),
            BlocProvider.value(value: documentCubit),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 320,
                child: SettingsPanel(
                  transformationController: TransformationController(),
                  onZoomPreset: (_) {},
                  isPanelDocked: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Staff Spacing section
      viewCubit.setTouchSection(SettingsSection.staffSpacing);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
