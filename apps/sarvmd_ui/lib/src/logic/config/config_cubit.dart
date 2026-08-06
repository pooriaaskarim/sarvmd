// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';

final _log = AppLogger.config;

/// Cubit managing the physical layout configuration (`PageConfig`) of the score sheet.
class ConfigCubit extends Cubit<core.PageConfig> {
  Timer? _saveTimer;

  ConfigCubit([core.PageConfig? initial])
      : super(initial ??
            core.StaffProfiles.treble.applyTo(const core.PageConfig())) {
    _loadFromPrefs();
  }

  static const _prefKey = 'sarvmd_config';

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final loadedConfig = core.PageConfig.fromJson(jsonMap);
        emit(loadedConfig);
        _log.debug('Config restored from SharedPreferences');
      } catch (e, st) {
        _log.error('Failed to deserialize config from SharedPreferences',
            error: e, stackTrace: st);
      }
    } else {
      _log.debug('No saved config found; using default profile');
    }
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = jsonEncode(state.toJson());
        await prefs.setString(_prefKey, jsonStr);
      } catch (e, st) {
        _log.error('Failed to persist config to SharedPreferences',
            error: e, stackTrace: st);
      }
    });
  }

  @override
  Future<void> close() {
    _saveTimer?.cancel();
    return super.close();
  }

  // --- Computed Getters for UI Fast Lane ---

  core.StaffProfile? get activeProfile {
    for (final p in core.StaffProfiles.all) {
      if (p.systemLayout == state.systemLayout) {
        return p;
      }
    }
    return null;
  }

  core.StaffUIHints get uiHints =>
      activeProfile?.uiHints ?? const core.StaffUIHints();

  core.PageLayout get layout => core.computeLayout(state);

  core.StaffDefinition? get _primaryDef {
    final root = state.systemLayout.rootGroup;
    if (root.children.isEmpty) return null;
    final child = root.children.first;
    return child is core.StaffDefinition ? child : null;
  }

  core.StaffDefinition? get _secondaryDef {
    final root = state.systemLayout.rootGroup;
    if (root.children.length < 2) return null;
    final child = root.children[1];
    return child is core.StaffDefinition ? child : null;
  }

  core.ClefConfig? get primaryClef => _primaryDef?.clef;
  core.ClefConfig? get secondaryClef => _secondaryDef?.clef;
  int get primaryLines => _primaryDef?.lines ?? 5;
  int get secondaryLines => _secondaryDef?.lines ?? 5;

  // --- State Mutator Actions ---

  void updatePageSize(core.PageSize size) {
    emit(state.copyWith(pageSize: size));
    _save();
  }

  void updateOrientation(core.PageOrientation orientation) {
    emit(state.copyWith(orientation: orientation));
    _save();
  }

  void updateStaffConfig(core.StaffConfig staff) {
    emit(state.copyWith(staffConfig: staff));
    _save();
  }

  void updateMargins(core.Margins margins) {
    emit(state.copyWith(margins: margins));
    _save();
  }

  void updateLineGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: mm,
      lineThicknessPt: state.staffConfig.lineThicknessPt,
      systemGapMm: state.staffConfig.systemGapMm,
      interStaffGapMm: state.staffConfig.interStaffGapMm,
    ));
  }

  void updateSystemGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: state.staffConfig.lineGapMm,
      lineThicknessPt: state.staffConfig.lineThicknessPt,
      systemGapMm: mm,
      interStaffGapMm: state.staffConfig.interStaffGapMm,
    ));
  }

  void updateInterStaffGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: state.staffConfig.lineGapMm,
      lineThicknessPt: state.staffConfig.lineThicknessPt,
      systemGapMm: state.staffConfig.systemGapMm,
      interStaffGapMm: mm,
    ));
  }

  void updateVerticalMargins(double mm) {
    updateMargins(state.margins.copyWith(top: mm, bottom: mm));
  }

  void updateHorizontalMargins(double mm) {
    updateMargins(state.margins.copyWith(left: mm, right: mm));
  }

  void updateLeftMargin(double mm) {
    updateMargins(state.margins.copyWith(left: mm));
  }

  void updateRightMargin(double mm) {
    updateMargins(state.margins.copyWith(right: mm));
  }

  void updateTopMargin(double mm) {
    updateMargins(state.margins.copyWith(top: mm));
  }

  void updateBottomMargin(double mm) {
    updateMargins(state.margins.copyWith(bottom: mm));
  }

  void resetToDefaults() {
    applyProfile(core.StaffProfiles.treble);
  }

  void resetMargins() {
    updateMargins(const core.Margins());
  }

  void resetSpacing() {
    updateStaffConfig(const core.StaffConfig());
  }

  void resetClefs() {
    final root = state.systemLayout.rootGroup;
    final newChildren = root.children.map((c) {
      if (c is core.StaffDefinition) return c.copyWith(clef: () => null);
      return c;
    }).toList();

    _updateSystemLayout(state.systemLayout.copyWith(
      rootGroup: root.copyWith(children: newChildren),
    ));
  }

  void updatePrimaryClef(core.ClefConfig? clef) {
    _updateStaffDefinition(0, (staff) => staff.copyWith(clef: () => clef));
  }

  void updateSecondaryClef(core.ClefConfig? clef) {
    _updateStaffDefinition(1, (staff) => staff.copyWith(clef: () => clef));
  }

  void _updateStaffDefinition(
      int index, core.StaffDefinition Function(core.StaffDefinition) updater) {
    final root = state.systemLayout.rootGroup;
    if (index >= root.children.length) return;

    final child = root.children[index];
    if (child is core.StaffDefinition) {
      final newChildren = List<Object>.from(root.children);
      newChildren[index] = updater(child);

      _updateSystemLayout(state.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ));
    }
  }

  // --- Tree Mutation Methods ---

  void addStaff({core.StaffDefinition? def}) {
    final root = state.systemLayout.rootGroup;
    final newDef = (def ?? const core.StaffDefinition()).copyWith(
      uid: DateTime.now().microsecondsSinceEpoch.toString(),
    );
    final newChildren = List<Object>.from(root.children)..add(newDef);
    _updateSystemLayout(state.systemLayout.copyWith(
      rootGroup: root.copyWith(children: newChildren),
    ));
  }

  void removeStaff(int index) {
    final root = state.systemLayout.rootGroup;
    if (index < 0 || index >= root.children.length) return;

    final newChildren = List<Object>.from(root.children)..removeAt(index);
    _updateSystemLayout(state.systemLayout.copyWith(
      rootGroup: root.copyWith(children: newChildren),
    ));
  }

  void updateStaffLines(String uid, int lines) {
    _updateStaffByUid(uid, (staff) => staff.copyWith(lines: lines));
  }

  void updateStaffClef(String uid, core.ClefConfig? clef) {
    _updateStaffByUid(uid, (staff) => staff.copyWith(clef: () => clef));
  }

  void updateStaffInstrumentName(String uid, String? name) {
    _updateStaffByUid(
        uid, (staff) => staff.copyWith(instrumentName: () => name));
  }

  void updateStaffConfigDetails(
    String uid, {
    String? Function()? name,
    String? Function()? abbreviation,
    bool? visible,
    int? lines,
    core.ClefConfig? Function()? clef,
    double? horizontalOffset,
    double? verticalOffset,
    String? fontFamily,
    double? fontSize,
    bool? italic,
  }) {
    _updateStaffByUid(
      uid,
      (staff) => staff.copyWith(
        instrumentName: name,
        instrumentAbbreviation: abbreviation,
        labelVisible: visible,
        lines: lines,
        clef: clef,
        labelHorizontalOffset: horizontalOffset,
        labelVerticalOffset: verticalOffset,
        labelFontFamily: fontFamily,
        labelFontSize: fontSize,
        labelItalic: italic,
      ),
    );
  }

  void _updateStaffByUid(
      String uid, core.StaffDefinition Function(core.StaffDefinition) updater) {
    final root = state.systemLayout.rootGroup;

    Object? findAndUpdate(Object node) {
      if (node is core.StaffDefinition) {
        if (node.uid == uid) return updater(node);
        return node;
      } else if (node is core.StaffGroup) {
        final newChildren =
            node.children.map((c) => findAndUpdate(c)!).toList();
        return node.copyWith(children: newChildren);
      }
      return node;
    }

    final newRoot = findAndUpdate(root) as core.StaffGroup;
    _updateSystemLayout(state.systemLayout.copyWith(rootGroup: newRoot));
  }

  void updateGroupConnector(core.SystemConnector connector) {
    final root = state.systemLayout.rootGroup;
    _updateSystemLayout(state.systemLayout.copyWith(
      rootGroup: root.copyWith(connector: connector),
    ));
  }

  void updateGroupContinuousBarlines(bool value) {
    final root = state.systemLayout.rootGroup;
    _updateSystemLayout(state.systemLayout.copyWith(
      rootGroup: root.copyWith(continuousBarlines: value),
    ));
  }

  void reorderGroupChildren(int groupHash, int oldIndex, int newIndex) {
    final root = state.systemLayout.rootGroup;

    Object? findAndReorder(Object node) {
      if (node is core.StaffGroup) {
        if (node.hashCode == groupHash) {
          final children = List<Object>.from(node.children);
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = children.removeAt(oldIndex);
          children.insert(newIndex, item);
          return node.copyWith(children: children);
        } else {
          final newChildren =
              node.children.map((c) => findAndReorder(c)!).toList();
          return node.copyWith(children: newChildren);
        }
      }
      return node;
    }

    final newRoot = findAndReorder(root) as core.StaffGroup;
    _updateSystemLayout(state.systemLayout.copyWith(rootGroup: newRoot));
  }

  void _updateSystemLayout(core.SystemLayout layout) {
    emit(state.copyWith(systemLayout: layout));
    _save();
  }

  void applyProfile(core.StaffProfile profile) {
    _log.debug('Applying profile', context: {'profile': profile.label});
    final newConfig = profile.applyTo(state);

    // Ensure all staves have unique IDs for stable keying
    final root = newConfig.systemLayout.rootGroup;
    final newChildren = root.children.asMap().entries.map((entry) {
      final index = entry.key;
      final c = entry.value;
      if (c is core.StaffDefinition) {
        return c.copyWith(
          uid: '${DateTime.now().microsecondsSinceEpoch}_$index',
        );
      }
      return c;
    }).toList();

    emit(newConfig.copyWith(
      systemLayout: newConfig.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ),
    ));
    _save();
  }
}
