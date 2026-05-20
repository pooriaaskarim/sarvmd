// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ppi_detector.dart';
import 'view_state.dart';

/// Cubit controlling theme modes, accent colors, display calibration, and overlay guides.
class ViewCubit extends Cubit<ViewState> {
  ViewCubit([ViewState? initial]) : super(initial ?? const ViewState()) {
    _loadFromPrefs();
  }

  static const String _keyThemeMode = 'view_theme_mode';
  static const String _keyAccent = 'view_accent';
  static const String _keyCalibration = 'view_calibration_factor';
  static const String _keyShowNotation = 'view_show_notation';

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
        calibrationFactor = (detectedPpi / 96.0).clamp(0.5, 4.0);
      }
    }

    // Load Notation Preview
    final showNotation = prefs.getBool(_keyShowNotation) ?? false;

    emit(state.copyWith(
      themeMode: themeMode,
      accent: accent,
      calibrationFactor: calibrationFactor,
      showNotation: showNotation,
    ));
  }

  void updateCalibrationFactor(double factor) async {
    final finalFactor = factor.clamp(0.3, 5.0);
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

  void toggleShowNotation() async {
    final nextShow = !state.showNotation;
    emit(state.copyWith(showNotation: nextShow));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowNotation, nextShow);
  }
}
