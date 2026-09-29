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

/// The canonical settings sections across Pointer and Touch modes.
enum SettingsSection {
  mainMenu,
  profiles,
  pageSetup,
  margins,
  staffSpacing,
  systemHierarchy,
  export,
}

/// The immutable state container for user interface display preferences.
class ViewState {
  final ThemeMode themeMode;
  final SarvAccent accent;
  final double calibrationFactor;
  final Set<GuideType> activeGuides;
  final String? activeScrubbingMargin;
  final InputMode inputMode;
  final SettingsSection activeTouchSection;
  final Set<SettingsSection> expandedPointerSections;
  final Set<int> collapsedHierarchyGroups;
  final Set<String> selectedHierarchyStaffUids;
  final SettingsSection? jumpTargetSection;

  const ViewState({
    this.themeMode = ThemeMode.system,
    this.accent = SarvAccent.sky,
    this.calibrationFactor = 1.0,
    this.activeGuides = const {GuideType.paperEdges, GuideType.rulerWings},
    this.activeScrubbingMargin,
    this.inputMode = InputMode.pointer,
    this.activeTouchSection = SettingsSection.mainMenu,
    this.expandedPointerSections = const {
      SettingsSection.profiles,
      SettingsSection.pageSetup,
      SettingsSection.margins,
      SettingsSection.staffSpacing,
      SettingsSection.systemHierarchy,
    },
    this.collapsedHierarchyGroups = const {},
    this.selectedHierarchyStaffUids = const {},
    this.jumpTargetSection,
  });

  ViewState copyWith({
    ThemeMode? themeMode,
    SarvAccent? accent,
    double? calibrationFactor,
    Set<GuideType>? activeGuides,
    String? activeScrubbingMargin,
    bool clearScrubbingMargin = false,
    InputMode? inputMode,
    SettingsSection? activeTouchSection,
    Set<SettingsSection>? expandedPointerSections,
    Set<int>? collapsedHierarchyGroups,
    Set<String>? selectedHierarchyStaffUids,
    SettingsSection? jumpTargetSection,
    bool clearJumpTarget = false,
  }) {
    return ViewState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      activeGuides: activeGuides ?? this.activeGuides,
      activeScrubbingMargin: clearScrubbingMargin
          ? null
          : (activeScrubbingMargin ?? this.activeScrubbingMargin),
      inputMode: inputMode ?? this.inputMode,
      activeTouchSection: activeTouchSection ?? this.activeTouchSection,
      expandedPointerSections:
          expandedPointerSections ?? this.expandedPointerSections,
      collapsedHierarchyGroups:
          collapsedHierarchyGroups ?? this.collapsedHierarchyGroups,
      selectedHierarchyStaffUids:
          selectedHierarchyStaffUids ?? this.selectedHierarchyStaffUids,
      jumpTargetSection: clearJumpTarget
          ? null
          : (jumpTargetSection ?? this.jumpTargetSection),
    );
  }

  bool isGuideActive(GuideType guide) => activeGuides.contains(guide);
  bool isPointerSectionExpanded(SettingsSection section) =>
      expandedPointerSections.contains(section);
}
