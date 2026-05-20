// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

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

  const ViewState({
    this.themeMode = ThemeMode.system,
    this.accent = SarvAccent.sky,
    this.calibrationFactor = 1.0,
    this.activeGuides = const {GuideType.paperEdges, GuideType.rulerWings},
    this.showNotation = false,
  });

  ViewState copyWith({
    ThemeMode? themeMode,
    SarvAccent? accent,
    double? calibrationFactor,
    Set<GuideType>? activeGuides,
    bool? showNotation,
  }) {
    return ViewState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      activeGuides: activeGuides ?? this.activeGuides,
      showNotation: showNotation ?? this.showNotation,
    );
  }

  bool isGuideActive(GuideType guide) => activeGuides.contains(guide);
}
