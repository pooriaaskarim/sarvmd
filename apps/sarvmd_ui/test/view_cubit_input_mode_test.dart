// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ViewState InputMode Tests', () {
    test('ViewState defaults to InputMode.pointer', () {
      const state = ViewState();
      expect(state.inputMode, equals(InputMode.pointer));
    });

    test('ViewState copyWith updates inputMode correctly', () {
      const state = ViewState();
      final updated = state.copyWith(inputMode: InputMode.touch);
      expect(updated.inputMode, equals(InputMode.touch));
    });

    test('ViewState copyWith preserves inputMode when omitted', () {
      const state = ViewState(inputMode: InputMode.touch);
      final updated = state.copyWith(showNotation: true);
      expect(updated.inputMode, equals(InputMode.touch));
    });
  });

  group('ViewCubit InputMode Persistence & State Tests', () {
    test('ViewCubit initializes with pointer mode when no prefs exist', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = ViewCubit();
      // Allow async _loadFromPrefs to settle
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.inputMode, equals(InputMode.pointer));
      await cubit.close();
    });

    test('ViewCubit loads saved touch mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'view_input_mode': InputMode.touch.index,
      });
      final cubit = ViewCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.inputMode, equals(InputMode.touch));
      await cubit.close();
    });

    test('ViewCubit loads saved pointer mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'view_input_mode': InputMode.pointer.index,
      });
      final cubit = ViewCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.inputMode, equals(InputMode.pointer));
      await cubit.close();
    });

    test('ViewCubit setInputMode updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = ViewCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      cubit.setInputMode(InputMode.touch);
      expect(cubit.state.inputMode, equals(InputMode.touch));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('view_input_mode'), equals(InputMode.touch.index));

      await cubit.close();
    });

    test('ViewCubit toggleInputMode switches pointer to touch and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = ViewCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.inputMode, equals(InputMode.pointer));

      cubit.toggleInputMode();
      expect(cubit.state.inputMode, equals(InputMode.touch));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('view_input_mode'), equals(InputMode.touch.index));

      await cubit.close();
    });

    test('ViewCubit toggleInputMode switches touch to pointer and persists', () async {
      SharedPreferences.setMockInitialValues({
        'view_input_mode': InputMode.touch.index,
      });
      final cubit = ViewCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.inputMode, equals(InputMode.touch));

      cubit.toggleInputMode();
      expect(cubit.state.inputMode, equals(InputMode.pointer));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('view_input_mode'), equals(InputMode.pointer.index));

      await cubit.close();
    });
  });
}
