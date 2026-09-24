// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/ppi_detector.dart';
import 'view_state.dart';

final _log = AppLogger.view;

/// Cubit controlling theme modes, accent colors, display calibration, and overlay guides.
class ViewCubit extends Cubit<ViewState> {
  ViewCubit([ViewState? initial]) : super(initial ?? const ViewState()) {
    _loadFromPrefs();
  }

  static const String _keyThemeMode = 'view_theme_mode';
  static const String _keyAccent = 'view_accent';
  static const String _keyCalibration = 'view_calibration_factor';
  static const String _keyShowNotation = 'view_show_notation';
  static const String _keyInputMode = 'view_input_mode';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme Mode
    ThemeMode themeMode = state.themeMode;
    final themeIndex = prefs.getInt(_keyThemeMode);
    if (themeIndex != null) {
      themeMode = ThemeMode.values[themeIndex];
    }

    // Load Accent
    SarvAccent accent = state.accent;
    final accentIndex = prefs.getInt(_keyAccent);
    if (accentIndex != null) {
      accent = SarvAccent.values[accentIndex];
    }

    // Load Calibration
    double calibrationFactor = state.calibrationFactor;
    final savedFactor = prefs.getDouble(_keyCalibration);
    if (savedFactor != null) {
      calibrationFactor = savedFactor;
    } else {
      // If no manual calibration exists, attempt to detect physical PPI from host OS.
      final detectedPpi = await detectPhysicalPpi();
      if (detectedPpi != null) {
        // The canvas renders at 96 logical DPI. Flutter scales logical pixels
        // by devicePixelRatio to physical pixels, so the effective physical DPI
        // at calibrationFactor=1.0 is 96 * dpr. To match real-world dimensions
        // we solve:  calibrationFactor * 96 * dpr = physicalPpi
        final dpr = WidgetsBinding
                .instance.platformDispatcher.implicitView?.devicePixelRatio ??
            1.0;
        calibrationFactor = (detectedPpi / (96.0 * dpr)).clamp(0.3, 6.0);
        _log.debug('Auto-detected physical PPI',
            context: {
              'ppi': detectedPpi,
              'dpr': dpr,
              'factor': calibrationFactor,
            });
      } else {
        _log.debug('Physical PPI detection returned null; using default factor');
      }
    }

    // Load Notation Preview
    final showNotation = prefs.getBool(_keyShowNotation) ?? false;

    // Load Input Mode
    InputMode inputMode = state.inputMode;
    final inputModeIndex = prefs.getInt(_keyInputMode);
    if (inputModeIndex != null &&
        inputModeIndex >= 0 &&
        inputModeIndex < InputMode.values.length) {
      inputMode = InputMode.values[inputModeIndex];
    } else {
      // First-run heuristic: If display width is compact/phone (< 600 logical px), default to touch.
      final view = WidgetsBinding.instance.platformDispatcher.implicitView;
      if (view != null) {
        final dpr = view.devicePixelRatio > 0 ? view.devicePixelRatio : 1.0;
        final logicalWidth = view.physicalSize.width / dpr;
        if (logicalWidth > 0 && logicalWidth < 600) {
          inputMode = InputMode.touch;
          _log.debug('Auto-detected compact screen width; defaulting to touch input mode',
              context: {'logicalWidth': logicalWidth});
        }
      }
    }

    if (isClosed) return;
    emit(state.copyWith(
      themeMode: themeMode,
      accent: accent,
      calibrationFactor: calibrationFactor,
      showNotation: showNotation,
      inputMode: inputMode,
    ));
    _log.debug('View state restored from SharedPreferences', context: {
      'themeMode': themeMode.name,
      'accent': accent.name,
      'calibrationFactor': calibrationFactor,
      'inputMode': inputMode.name,
    });
  }

  void updateCalibrationFactor(double factor) async {
    final finalFactor = factor.clamp(0.3, 6.0);
    _log.debug('Calibration updated', context: {'factor': finalFactor});
    emit(state.copyWith(calibrationFactor: finalFactor));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyCalibration, finalFactor);
  }

  void resetCalibration() async {
    emit(state.copyWith(calibrationFactor: 1.0));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCalibration);
  }

  void updateThemeMode(ThemeMode mode) async {
    _log.debug('Theme mode changed', context: {'mode': mode.name});
    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  void toggleThemeMode() async {
    ThemeMode nextMode;
    if (state.themeMode == ThemeMode.system) {
      nextMode = ThemeMode.dark;
    } else if (state.themeMode == ThemeMode.dark) {
      nextMode = ThemeMode.light;
    } else {
      nextMode = ThemeMode.system;
    }

    emit(state.copyWith(themeMode: nextMode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, nextMode.index);
  }

  void updateAccent(SarvAccent accent) async {
    emit(state.copyWith(accent: accent));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccent, accent.index);
  }

  void toggleGuide(GuideType guide, bool active) {
    final newGuides = Set<GuideType>.from(state.activeGuides);
    if (active) {
      newGuides.add(guide);
    } else {
      newGuides.remove(guide);
    }
    emit(state.copyWith(activeGuides: newGuides));
  }

  void setActiveScrubbingMargin(String? side) {
    if (side == null) {
      emit(state.copyWith(clearScrubbingMargin: true));
    } else {
      emit(state.copyWith(activeScrubbingMargin: side));
    }
  }

  void toggleShowNotation() async {
    final nextShow = !state.showNotation;
    emit(state.copyWith(showNotation: nextShow));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowNotation, nextShow);
  }

  void setInputMode(InputMode mode) async {
    _log.debug('Input mode updated', context: {'inputMode': mode.name});
    emit(state.copyWith(inputMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyInputMode, mode.index);
  }

  void toggleInputMode() {
    final nextMode = state.inputMode == InputMode.pointer
        ? InputMode.touch
        : InputMode.pointer;
    setInputMode(nextMode);
  }
}
