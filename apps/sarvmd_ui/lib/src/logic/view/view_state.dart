// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// The interaction mode determining whether the UI optimizes for mouse/pointer or direct touch.
enum InputMode {
  pointer,
  touch,
}

/// The active guide overlay lines shown on the sheet music manuscript canvas.
enum GuideType {
  paperEdges,
  paperCenters,
  margins,
  staffBounds,
  rulerWings,
}

/// The immutable state container for user interface display preferences.
class ViewState {
  final ThemeMode themeMode;
  final SarvAccent accent;
  final double calibrationFactor;
  final Set<GuideType> activeGuides;
  final bool showNotation;
  final String? activeScrubbingMargin;
  final InputMode inputMode;

  const ViewState({
    this.themeMode = ThemeMode.system,
    this.accent = SarvAccent.sky,
    this.calibrationFactor = 1.0,
    this.activeGuides = const {GuideType.paperEdges, GuideType.rulerWings},
    this.showNotation = false,
    this.activeScrubbingMargin,
    this.inputMode = InputMode.pointer,
  });

  ViewState copyWith({
    ThemeMode? themeMode,
    SarvAccent? accent,
    double? calibrationFactor,
    Set<GuideType>? activeGuides,
    bool? showNotation,
    String? activeScrubbingMargin,
    bool clearScrubbingMargin = false,
    InputMode? inputMode,
  }) {
    return ViewState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      activeGuides: activeGuides ?? this.activeGuides,
      showNotation: showNotation ?? this.showNotation,
      activeScrubbingMargin: clearScrubbingMargin
          ? null
          : (activeScrubbingMargin ?? this.activeScrubbingMargin),
      inputMode: inputMode ?? this.inputMode,
    );
  }

  bool isGuideActive(GuideType guide) => activeGuides.contains(guide);
}
