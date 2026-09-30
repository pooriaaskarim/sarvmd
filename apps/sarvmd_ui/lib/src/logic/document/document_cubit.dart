// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import '../services/sarv_file_service.dart';
import 'document_state.dart';

final _log = AppLogger.score;

/// Unified Cubit managing manuscript document state (Score & PageConfig)
/// and transactional undo/redo execution history.
class DocumentCubit extends Cubit<DocumentState> {
  final core.CommandHistory _history;
  final SarvFileService _fileService;
  final bool _enablePersistence;
  Timer? _saveTimer;

  static const _prefDocKey = 'sarvmd_document';
  static const _prefLegacyKey = 'sarvmd_config';
  static const _prefFilePathKey = 'sarvmd_file_path';

  DocumentCubit([
    core.CommandHistory? history,
    SarvFileService? fileService,
    bool autoLoadFromPrefs = true,
  ]) : this._internal(
          history ??
              core.CommandHistory(
                initialDocument: core.SarvDocument(
                  score: const core.Score(title: ''),
                  config: core.StaffProfiles.treble.applyTo(const core.PageConfig()),
                  metadata: const core.DocumentMetadata(title: ''),
                ).ensureUniqueUids(),
              ),
          fileService ?? SarvFileService(),
          autoLoadFromPrefs: autoLoadFromPrefs,
        );

  DocumentCubit._internal(
    core.CommandHistory history,
    SarvFileService fileService, {
    bool autoLoadFromPrefs = true,
  })  : _history = history,
        _fileService = fileService,
        _enablePersistence = autoLoadFromPrefs,
        super(DocumentState(
          document: history.document.ensureUniqueUids(),
          undoStack: history.undoStack,
          redoStack: history.redoStack,
          lastSavedDocument: history.document.ensureUniqueUids(),
        )) {
    if (_history.document != state.document) {
      _history.setDocument(state.document, clearHistory: true);
    }
    if (autoLoadFromPrefs) {
      _loadFromPrefs();
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Try restoring full SarvDocument
    final docJsonStr = prefs.getString(_prefDocKey);
    final savedFilePath = prefs.getString(_prefFilePathKey);
    if (docJsonStr != null) {
      try {
        final jsonMap = jsonDecode(docJsonStr) as Map<String, dynamic>;
        final loadedDoc = core.SarvDocument.fromJson(jsonMap).ensureUniqueUids();
        _history.setDocument(loadedDoc, clearHistory: true);
        emit(DocumentState(
          document: loadedDoc,
          undoStack: const [],
          redoStack: const [],
          filePath: savedFilePath,
          lastSavedDocument: loadedDoc,
        ));
        _log.debug('SarvDocument restored from SharedPreferences');
        return;
      } catch (e, st) {
        _log.error('Failed to deserialize document from SharedPreferences',
            error: e, stackTrace: st);
      }
    }

    // 2. Fall back to legacy config if present
    final jsonStr = prefs.getString(_prefLegacyKey);
    if (jsonStr != null) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final loadedConfig = core.PageConfig.fromJson(jsonMap).ensureUniqueUids();
        final restoredDoc = _history.document.copyWith(config: loadedConfig);
        _history.setDocument(restoredDoc, clearHistory: true);
        _syncState();
        _log.debug('Legacy config restored from SharedPreferences');
      } catch (e, st) {
        _log.error('Failed to deserialize legacy config from SharedPreferences',
            error: e, stackTrace: st);
      }
    }
  }

  void _save() {
    if (!_enablePersistence) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final docJson = jsonEncode(state.document.toJson());
        await prefs.setString(_prefDocKey, docJson);
      } catch (e, st) {
        _log.error('Failed to persist document to SharedPreferences',
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

  // --- Document Lifecycle & File Persistence Operations ---

  /// Creates a clean, new document initialized with [profile] (or treble solo).
  void newDocument([core.StaffProfile? profile, String? title]) {
    final prof = profile ?? core.StaffProfiles.treble;
    final initialTitle = title ?? '';
    final newDoc = core.SarvDocument(
      score: core.Score(title: initialTitle),
      config: prof.applyTo(const core.PageConfig()),
      metadata: core.DocumentMetadata(title: initialTitle),
    ).ensureUniqueUids();
    _history.setDocument(newDoc, clearHistory: true);
    emit(DocumentState(
      document: newDoc,
      undoStack: const [],
      redoStack: const [],
      filePath: null,
      lastSavedDocument: newDoc,
    ));
    _save();
    SharedPreferences.getInstance().then((p) => p.remove(_prefFilePathKey));
    _log.info('New document created with profile: ${prof.id}');
  }

  /// Sets the title of the score/document with undo/redo support.
  void setTitle(String title) {
    execute(core.SetTitleCommand(title, state.score.title, state.metadata.title));
  }

  /// Updates the metadata of the document with undo/redo support.
  void updateMetadata(core.DocumentMetadata metadata) {
    execute(core.SetMetadataCommand(metadata));
  }

  /// Loads an external [document] into the editor session.
  void loadDocument(core.SarvDocument document, {String? filePath}) {
    final sanitizedDoc = document.ensureUniqueUids();
    _history.setDocument(sanitizedDoc, clearHistory: true);
    emit(DocumentState(
      document: sanitizedDoc,
      undoStack: const [],
      redoStack: const [],
      filePath: filePath,
      lastSavedDocument: sanitizedDoc,
    ));
    _save();
    SharedPreferences.getInstance().then((p) {
      if (filePath != null) {
        p.setString(_prefFilePathKey, filePath);
      } else {
        p.remove(_prefFilePathKey);
      }
    });
    _log.info('Document loaded into editor session', context: {
      'filePath': filePath ?? 'unsaved',
      'title': document.metadata.title,
    });
  }

  /// Saves the current document. If [filePath] is already set, writes directly;
  /// otherwise prompts the system save dialog (Save As).
  ///
  /// Returns `true` on successful save, `false` if cancelled.
  Future<bool> save({SarvFileService? fileService}) async {
    final service = fileService ?? _fileService;
    final savedPath = await service.saveSarvFile(
      document: state.document,
      filePath: state.filePath,
      defaultFileName: state.displayName,
    );
    if (savedPath != null) {
      emit(state.copyWith(
        filePath: savedPath,
        lastSavedDocument: state.document,
      ));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFilePathKey, savedPath);
      return true;
    }
    return false;
  }

  /// Always prompts the system save dialog to save the current document to a new location.
  ///
  /// Returns `true` on successful save, `false` if cancelled.
  Future<bool> saveAs({SarvFileService? fileService}) async {
    final service = fileService ?? _fileService;
    final savedPath = await service.saveAsSarvFile(
      document: state.document,
      defaultFileName: state.displayName,
    );
    if (savedPath != null) {
      emit(state.copyWith(
        filePath: savedPath,
        lastSavedDocument: state.document,
      ));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFilePathKey, savedPath);
      return true;
    }
    return false;
  }

  /// Prompts the system file picker to select a `.sarv` file, then loads it into the editor session.
  ///
  /// Returns `true` on successful load, `false` if cancelled.
  Future<bool> openFile({SarvFileService? fileService}) async {
    final service = fileService ?? _fileService;
    final result = await service.openSarvFile();
    if (result != null) {
      loadDocument(result.document, filePath: result.filePath);
      return true;
    }
    return false;
  }

  /// Directly loads a `.sarv` file from [path] into the editor session.
  Future<bool> loadFromPath(String path, {SarvFileService? fileService}) async {
    final service = fileService ?? _fileService;
    final result = await service.loadFileFromPath(path);
    loadDocument(result.document, filePath: result.filePath);
    return true;
  }

  /// Marks the current state as clean / saved.
  void markSaved({String? filePath}) {
    emit(state.copyWith(
      filePath: filePath,
      lastSavedDocument: state.document,
    ));
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
      if (p.matches(state.config)) {
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

  /// Sequentially renumbers the staves in [uids] ('1', '2', ...) following Gould's non-redundancy principle.
  void batchRenumberStaves(List<String> uids) {
    if (uids.isEmpty) return;
    for (int i = 0; i < uids.length; i++) {
      updateStaffInstrumentName(uids[i], '${i + 1}');
    }
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
    bool? bold,
    core.StaffLabelStyle? labelStyle,
  }) {
    execute(core.UpdateStaffByUidCommand(
      uid,
      (staff) => staff.copyWith(
        instrumentName: name,
        instrumentAbbreviation: abbreviation,
        labelVisible: visible,
        lines: lines,
        clef: clef,
        labelStyle: labelStyle,
        labelHorizontalOffset: horizontalOffset,
        labelVerticalOffset: verticalOffset,
        labelFontFamily: fontFamily,
        labelFontSize: fontSize,
        labelItalic: italic,
        labelBold: bold,
      ),
      'Update Staff Details',
    ));
  }

  void updateGroupConnector(core.SystemConnector connector, {int? groupHash}) {
    execute(core.UpdateGroupConnectorCommand(connector, groupHash: groupHash));
  }

  void updateGroupContinuousBarlines(bool value, {int? groupHash}) {
    execute(
        core.UpdateGroupContinuousBarlinesCommand(value, groupHash: groupHash));
  }

  void updateGroupInitialBarline(bool value, {int? groupHash}) {
    execute(core.UpdateGroupInitialBarlineCommand(value, groupHash: groupHash));
  }

  void updateGroupDetails({
    int? groupHash,
    String? label,
    String? abbreviation,
    bool? labelVisible,
    core.GroupLabelPlacement? labelPlacement,
    core.GroupNumberingStyle? numberingStyle,
    core.DescriptorPlacement? descriptorPlacement,
    core.GroupHeaderVisibility? headerVisibility,
  }) {
    execute(core.UpdateGroupDetailsCommand(
      groupHash: groupHash,
      labelText: label,
      abbreviation: abbreviation,
      labelVisible: labelVisible,
      labelPlacement: labelPlacement,
      numberingStyle: numberingStyle,
      descriptorPlacement: descriptorPlacement,
      headerVisibility: headerVisibility,
    ));
  }

  void reorderGroupChildren(int groupHash, int oldIndex, int newIndex) {
    execute(core.ReorderGroupChildrenCommand(groupHash, oldIndex, newIndex));
  }

  core.StaffDefinition addStaffToGroup(
      {int? groupHash, core.StaffDefinition? def, int? insertIndex}) {
    final command = core.AddStaffToGroupCommand(
      groupHash: groupHash,
      def: def,
      insertIndex: insertIndex,
    );
    execute(command);
    final root = state.config.systemLayout.rootGroup;
    return root.children.last as core.StaffDefinition;
  }

  void moveStaffNode({
    required int sourceGroupHash,
    required int targetGroupHash,
    required int sourceIndex,
    required int targetIndex,
  }) {
    execute(core.MoveStaffNodeCommand(
      sourceGroupHash: sourceGroupHash,
      targetGroupHash: targetGroupHash,
      sourceIndex: sourceIndex,
      targetIndex: targetIndex,
    ));
  }

  void ungroupSubGroup(int groupHash) {
    execute(core.UngroupSubGroupCommand(groupHash));
  }

  void groupSelectedStaves(Set<String> uids,
      [core.SystemConnector connector = core.SystemConnector.bracket]) {
    if (uids.length < 2) return;
    final currentRoot = state.config.systemLayout.rootGroup;
    final updatedRoot = currentRoot.groupSelected(uids, connector);
    execute(core.SetSystemLayoutCommand(
      core.SystemLayout(rootGroup: updatedRoot),
      'Group Selected Staves',
    ));
  }

  void groupTwoStavesTogether(String sourceUid, String targetUid,
      [core.SystemConnector connector = core.SystemConnector.bracket]) {
    if (sourceUid == targetUid) return;
    final currentRoot = state.config.systemLayout.rootGroup;
    final updatedRoot =
        currentRoot.groupSelected({sourceUid, targetUid}, connector);
    execute(core.SetSystemLayoutCommand(
      core.SystemLayout(rootGroup: updatedRoot),
      'Group Staves',
    ));
  }

  void batchDeleteStaves(Set<String> uids) {
    if (uids.isEmpty) return;
    for (final uid in uids) {
      execute(core.RemoveStaffByUidCommand(uid));
    }
  }

  void batchToggleVisibility(Set<String> uids, bool visible) {
    if (uids.isEmpty) return;
    for (final uid in uids) {
      updateStaffConfigDetails(uid, visible: visible);
    }
  }

  void batchDuplicateStaves(Set<String> uids) {
    if (uids.isEmpty) return;
    final staves = allStaves;
    for (final uid in uids) {
      final match = staves.where((s) => s.uid == uid).firstOrNull;
      if (match != null) {
        final clone = match.copyWith(
          uid: 'staff_${DateTime.now().microsecondsSinceEpoch}_${match.uid}',
          instrumentName: () => match.instrumentName != null
              ? '${match.instrumentName}'
              : null,
        );
        execute(core.AddStaffToGroupCommand(def: clone));
      }
    }
  }

  void applyProfile(core.StaffProfile profile) {
    execute(core.ApplyProfileCommand(profile));
  }
}
