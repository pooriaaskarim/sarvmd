// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import 'document_state.dart';

final _log = AppLogger.score;

/// Unified Cubit managing manuscript document state (Score & PageConfig)
/// and transactional undo/redo execution history.
class DocumentCubit extends Cubit<DocumentState> {
  final core.CommandHistory _history;
  Timer? _saveTimer;

  static const _prefKey = 'sarvmd_config';

  DocumentCubit([core.CommandHistory? history])
      : this._internal(
          history ??
              core.CommandHistory(
                initialDocument: core.SarvDocument(
                  config: core.StaffProfiles.treble.applyTo(const core.PageConfig()),
                ),
              ),
        );

  DocumentCubit._internal(core.CommandHistory history)
      : _history = history,
        super(DocumentState(
          document: history.document,
          undoStack: history.undoStack,
          redoStack: history.redoStack,
        )) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final loadedConfig = core.PageConfig.fromJson(jsonMap);
        _history.execute(core.SetSystemLayoutCommand(
          loadedConfig.systemLayout,
          'Restore Saved Config',
        ));
        // Reset undo history from restored prefs
        _history.clear();
        _syncState();
        _log.debug('Config restored from SharedPreferences');
      } catch (e, st) {
        _log.error('Failed to deserialize config from SharedPreferences',
            error: e, stackTrace: st);
      }
    }
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = jsonEncode(state.config.toJson());
        await prefs.setString(_prefKey, jsonStr);
      } catch (e, st) {
        _log.error('Failed to persist config to SharedPreferences',
            error: e, stackTrace: st);
      }
    });
  }

  void _syncState() {
    emit(state.copyWith(
      document: _history.document,
      undoStack: _history.undoStack,
      redoStack: _history.redoStack,
    ));
    _save();
  }

  @override
  Future<void> close() {
    _saveTimer?.cancel();
    return super.close();
  }

  // --- Transactional Command Execution ---

  void execute(core.DocumentCommand command) {
    _log.debug('Executing command: ${command.runtimeType} (${command.label})');
    _history.execute(command);
    _syncState();
  }

  void undo() {
    if (!state.canUndo) {
      _log.warning('undo() called with empty undo stack');
      return;
    }
    _log.debug('Undoing command: ${state.lastUndoLabel}');
    _history.undo();
    _syncState();
  }

  void redo() {
    if (!state.canRedo) {
      _log.warning('redo() called with empty redo stack');
      return;
    }
    _log.debug('Redoing command: ${state.lastRedoLabel}');
    _history.redo();
    _syncState();
  }

  // --- Computed Fast-Lane Getters ---

  core.Score get score => state.score;
  core.PageConfig get config => state.config;

  core.StaffProfile? get activeProfile {
    for (final p in core.StaffProfiles.all) {
      if (p.systemLayout == state.config.systemLayout) {
        return p;
      }
    }
    return null;
  }

  core.StaffUIHints get uiHints =>
      activeProfile?.uiHints ?? const core.StaffUIHints();

  core.PageLayout get layout => core.computeLayout(state.config);

  core.StaffDefinition? get _primaryDef {
    final root = state.config.systemLayout.rootGroup;
    if (root.children.isEmpty) return null;
    final child = root.children.first;
    return child is core.StaffDefinition ? child : null;
  }

  core.StaffDefinition? get _secondaryDef {
    final root = state.config.systemLayout.rootGroup;
    if (root.children.length < 2) return null;
    final child = root.children[1];
    return child is core.StaffDefinition ? child : null;
  }

  core.Clef? get primaryClef => _primaryDef?.clef;
  core.Clef? get secondaryClef => _secondaryDef?.clef;
  int get primaryLines => _primaryDef?.lines ?? 5;
  int get secondaryLines => _secondaryDef?.lines ?? 5;

  List<core.StaffDefinition> get allStaves =>
      _extractStaves(state.config.systemLayout.rootGroup);

  static List<core.StaffDefinition> _extractStaves(core.StaffNodeGroup group) {
    final list = <core.StaffDefinition>[];
    for (final child in group.children) {
      switch (child) {
        case core.StaffDefinition def:
          list.add(def);
        case core.StaffNodeGroup subGroup:
          list.addAll(_extractStaves(subGroup));
      }
    }
    return list;
  }

  // --- Helper Mutators (Dispatching Transactional Commands) ---

  void updatePageSize(core.PageSize size) {
    execute(core.SetPageSizeCommand(size));
  }

  void updateOrientation(core.PageOrientation orientation) {
    execute(core.SetOrientationCommand(orientation));
  }

  void updateStaffConfig(core.StaffConfig staff) {
    execute(core.SetStaffConfigCommand(staff));
  }

  void updateMargins(core.Margins margins) {
    execute(core.SetMarginsCommand(margins));
  }

  void updateLineGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: mm,
      lineThicknessPt: state.config.staffConfig.lineThicknessPt,
      systemGapMm: state.config.staffConfig.systemGapMm,
      interStaffGapMm: state.config.staffConfig.interStaffGapMm,
    ));
  }

  void updateSystemGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: state.config.staffConfig.lineGapMm,
      lineThicknessPt: state.config.staffConfig.lineThicknessPt,
      systemGapMm: mm,
      interStaffGapMm: state.config.staffConfig.interStaffGapMm,
    ));
  }

  void updateInterStaffGap(double mm) {
    updateStaffConfig(core.StaffConfig(
      lineGapMm: state.config.staffConfig.lineGapMm,
      lineThicknessPt: state.config.staffConfig.lineThicknessPt,
      systemGapMm: state.config.staffConfig.systemGapMm,
      interStaffGapMm: mm,
    ));
  }

  void updateVerticalMargins(double mm) {
    updateMargins(state.config.margins.copyWith(top: mm, bottom: mm));
  }

  void updateHorizontalMargins(double mm) {
    updateMargins(state.config.margins.copyWith(left: mm, right: mm));
  }

  void updateLeftMargin(double mm) {
    updateMargins(state.config.margins.copyWith(left: mm));
  }

  void updateRightMargin(double mm) {
    updateMargins(state.config.margins.copyWith(right: mm));
  }

  void updateTopMargin(double mm) {
    updateMargins(state.config.margins.copyWith(top: mm));
  }

  void updateBottomMargin(double mm) {
    updateMargins(state.config.margins.copyWith(bottom: mm));
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
    final root = state.config.systemLayout.rootGroup;
    final newChildren = root.children.map((c) {
      if (c is core.StaffDefinition) return c.copyWith(clef: () => null);
      return c;
    }).toList();

    execute(core.SetSystemLayoutCommand(
      state.config.systemLayout.copyWith(
        rootGroup: root.copyWith(children: newChildren),
      ),
      'Reset Clefs',
    ));
  }

  void updatePrimaryClef(core.Clef? clef) {
    _updateStaffDefinition(0, (staff) => staff.copyWith(clef: () => clef));
  }

  void updateSecondaryClef(core.Clef? clef) {
    _updateStaffDefinition(1, (staff) => staff.copyWith(clef: () => clef));
  }

  void _updateStaffDefinition(
      int index, core.StaffDefinition Function(core.StaffDefinition) updater) {
    final root = state.config.systemLayout.rootGroup;
    if (index >= root.children.length) return;

    final child = root.children[index];
    if (child is core.StaffDefinition) {
      final newChildren = List<core.StaffNode>.from(root.children);
      newChildren[index] = updater(child);

      execute(core.SetSystemLayoutCommand(
        state.config.systemLayout.copyWith(
          rootGroup: root.copyWith(children: newChildren),
        ),
        'Update Staff Clef',
      ));
    }
  }

  core.StaffDefinition addStaff({core.StaffDefinition? def}) {
    final command = core.AddStaffCommand(def: def);
    execute(command);
    final root = state.config.systemLayout.rootGroup;
    return root.children.last as core.StaffDefinition;
  }

  void removeStaff(int index) {
    execute(core.RemoveStaffCommand(index));
  }

  void removeStaffByUid(String uid) {
    execute(core.RemoveStaffByUidCommand(uid));
  }

  void updateStaffLines(String uid, int lines) {
    updateStaffConfigDetails(uid, lines: lines);
  }

  void updateStaffClef(String uid, core.Clef? clef) {
    updateStaffConfigDetails(uid, clef: () => clef);
  }

  void updateStaffInstrumentName(String uid, String? name) {
    updateStaffConfigDetails(uid, name: () => name);
  }

  void updateStaffConfigDetails(
    String uid, {
    String? Function()? name,
    String? Function()? abbreviation,
    bool? visible,
    int? lines,
    core.Clef? Function()? clef,
    double? horizontalOffset,
    double? verticalOffset,
    String? fontFamily,
    double? fontSize,
    bool? italic,
  }) {
    execute(core.UpdateStaffByUidCommand(
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
      'Update Staff Details',
    ));
  }

  void updateGroupConnector(core.SystemConnector connector) {
    execute(core.UpdateGroupConnectorCommand(connector));
  }

  void updateGroupContinuousBarlines(bool value) {
    execute(core.UpdateGroupContinuousBarlinesCommand(value));
  }

  void reorderGroupChildren(int groupHash, int oldIndex, int newIndex) {
    execute(core.ReorderGroupChildrenCommand(groupHash, oldIndex, newIndex));
  }

  void applyProfile(core.StaffProfile profile) {
    execute(core.ApplyProfileCommand(profile));
  }
}
