import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/presentation/screens/pointer_editor_screen.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/staff_spacing_group.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/margins_settings_group.dart';

void main() {
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

  Future<void> pumpEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
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
          home: PointerEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Test 1: Staff spacing slider drag and input reflection', (tester) async {
    await pumpEditor(tester);

    if (!viewCubit.state.isPointerSectionExpanded(SettingsSection.staffSpacing)) {
      viewCubit.togglePointerSection(SettingsSection.staffSpacing);
      await tester.pumpAndSettle();
    }

    await tester.scrollUntilVisible(
      find.byType(StaffSpacingGroup),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final sliders = find.descendant(
      of: find.byType(StaffSpacingGroup),
      matching: find.byType(Slider),
    );
    expect(sliders, findsWidgets);

    final lineGapSlider = tester.widget<Slider>(sliders.first);
    final initialVal = lineGapSlider.value;
    print('Initial lineGap slider value: $initialVal');

    // Also find the lineGap textfield
    final textFields = find.descendant(
      of: find.byType(StaffSpacingGroup),
      matching: find.byType(TextField),
    );
    expect(textFields, findsWidgets);
    final lineGapField = tester.widget<TextField>(textFields.first);
    print('Initial lineGap textfield: ${lineGapField.controller?.text}');

    // Drag slider by a small offset
    await tester.drag(sliders.first, const Offset(30, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final updatedSlider = tester.widget<Slider>(sliders.first);
    final updatedField = tester.widget<TextField>(textFields.first);
    print('After slider drag:');
    print('  Slider: ${updatedSlider.value}');
    print('  Field: ${updatedField.controller?.text}');
    print('  Doc: ${documentCubit.state.config.staffConfig.lineGapMm}');

    expect(updatedSlider.value, equals(documentCubit.state.config.staffConfig.lineGapMm));
    expect(updatedField.controller?.text, equals(documentCubit.state.config.staffConfig.lineGapMm.toStringAsFixed(2)));
  });

  testWidgets('Test 2: Margins input scrub and textfield reflection', (tester) async {
    await pumpEditor(tester);

    if (!viewCubit.state.isPointerSectionExpanded(SettingsSection.margins)) {
      viewCubit.togglePointerSection(SettingsSection.margins);
      await tester.pumpAndSettle();
    }

    await tester.scrollUntilVisible(
      find.byType(MarginsSettingsGroup),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final textFields = find.descendant(
      of: find.byType(MarginsSettingsGroup),
      matching: find.byType(TextField),
    );
    expect(textFields, findsWidgets);
    final vertField = tester.widget<TextField>(textFields.first);
    print('Initial margin textfield: ${vertField.controller?.text}');

    // Scrub the vertical field
    final gesture = await tester.startGesture(tester.getCenter(textFields.first));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final updatedVertField = tester.widget<TextField>(textFields.first);
    print('After margin scrub:');
    print('  Field: ${updatedVertField.controller?.text}');
    print('  Doc: ${documentCubit.state.config.margins.top}');

    expect(updatedVertField.controller?.text, equals(documentCubit.state.config.margins.top.toStringAsFixed(1)));
  });
}
