// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logd/logd.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import '../document/document_cubit.dart';
import '../services/sarv_file_service.dart';
import 'document_session.dart';
import 'workspace_state.dart';

/// Cubit managing multi-document workspace sessions, active tab routing,
/// and tab lifecycle operations with session persistence.
class WorkspaceCubit extends Cubit<WorkspaceState> {
  static final Logger _log = AppLogger.get('sarvmd.workspace');
  static const String prefSessionKey = 'sarvmd_workspace_session';

  final SarvFileService _fileService;
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  int _tabSequence = 0;
  final bool _autoRestoreSession;
  Timer? _saveDebounceTimer;
  Completer<void>? _restoreCompleter;

  WorkspaceCubit({
    DocumentCubit? initialCubit,
    SarvFileService? fileService,
    bool autoRestoreSession = true,
  })  : _fileService = fileService ?? SarvFileService(),
        _autoRestoreSession = initialCubit == null && autoRestoreSession,
        super(WorkspaceState(
          sessions: [
            DocumentSession(
              id: 'tab_0',
              cubit: initialCubit ?? DocumentCubit(),
            ),
          ],
          activeIndex: 0,
        )) {
    _subscribeSession(state.sessions.first);
    if (_autoRestoreSession) {
      _restoreCompleter = Completer<void>();
      unawaited(_restoreSessionFromPrefs());
    }
  }

  void _subscribeSession(DocumentSession session) {
    _subscriptions[session.id]?.cancel();
    _subscriptions[session.id] = session.cubit.stream.listen((_) {
      if (!isClosed) {
        emit(state.copyWith());
        _debouncedSaveSession();
      }
    });
  }

  String _nextTabId() {
    _tabSequence++;
    return 'tab_${DateTime.now().microsecondsSinceEpoch}_$_tabSequence';
  }

  /// Opens a brand-new manuscript tab initialized with [profile].
  DocumentSession openNewTab({core.StaffProfile? profile}) {
    final prof = profile ?? core.StaffProfiles.treble;
    final dummyDoc = core.SarvDocument(
      score: const core.Score(title: ''),
      config: prof.applyTo(const core.PageConfig()),
    );
    final baseTitle = core.ScoreCompiler.getEffectiveTitle(dummyDoc.score, dummyDoc.config);
    final existingTitles = state.sessions.map((s) => s.title).toList();
    final effectiveTitle = existingTitles.contains(baseTitle)
        ? core.FileNaming.disambiguateFileName(baseTitle, existingTitles)
        : null;

    final newCubit = DocumentCubit(null, null, false);
    newCubit.newDocument(prof, effectiveTitle);

    final session = DocumentSession(
      id: _nextTabId(),
      cubit: newCubit,
    );

    _subscribeSession(session);
    final updatedSessions = List<DocumentSession>.from(state.sessions)..add(session);
    final newIndex = updatedSessions.length - 1;

    emit(state.copyWith(
      sessions: updatedSessions,
      activeIndex: newIndex,
    ));
    _debouncedSaveSession();
    _log.info('Opened new tab: ${session.id} (${session.title})');
    return session;
  }

  /// Opens a [core.SarvDocument] into a tab.
  ///
  /// If the document (or a file with matching path/name/content) is already open, focuses that tab.
  /// If the current active tab is completely pristine and untitled, replaces it.
  /// Otherwise, opens in a new tab.
  Future<DocumentSession> openDocumentTab(
    core.SarvDocument document, {
    String? filePath,
    String? title,
  }) async {
    if (_restoreCompleter != null) {
      await _restoreCompleter!.future;
    }

    final effectiveTargetName = (filePath != null && filePath.isNotEmpty)
        ? p.basename(filePath)
        : (title != null && title.isNotEmpty ? p.basename(title) : null);

    // 1. Check if already open by filePath, filename/title match, or identical document content
    final existingIndex = state.sessions.indexWhere((s) {
      if (filePath != null && filePath.isNotEmpty && s.filePath == filePath) {
        return true;
      }
      if (effectiveTargetName != null) {
        final sessionBase = s.filePath != null ? p.basename(s.filePath!) : null;
        if (sessionBase == effectiveTargetName) return true;
        if (s.title == effectiveTargetName) return true;
      }
      if (s.document.hasSameContent(document)) {
        return true;
      }
      return false;
    });

    if (existingIndex != -1) {
      switchTab(existingIndex);
      return state.sessions[existingIndex];
    }

    final effectivePath = filePath ?? (kIsWeb ? title : null);

    // 2. Check if current active tab is a clean, untouched blank tab
    final current = state.activeSession;
    final isPristineBlank = !current.isDirty &&
        current.filePath == null &&
        current.document.score.title.trim().isEmpty &&
        current.cubit.state.undoStack.isEmpty;

    if (isPristineBlank) {
      current.cubit.loadDocument(document, filePath: effectivePath);
      emit(state.copyWith());
      _debouncedSaveSession();
      return current;
    }

    // 3. Otherwise, open in a new tab
    final newCubit = DocumentCubit(null, null, false);
    newCubit.loadDocument(document, filePath: effectivePath);
    final session = DocumentSession(
      id: _nextTabId(),
      cubit: newCubit,
    );

    _subscribeSession(session);
    final updatedSessions = List<DocumentSession>.from(state.sessions)..add(session);
    final newIndex = updatedSessions.length - 1;

    emit(state.copyWith(
      sessions: updatedSessions,
      activeIndex: newIndex,
    ));
    _debouncedSaveSession();
    _log.info('Opened document tab: ${session.id} -> ${title ?? effectivePath ?? document.metadata.title}');
    return session;
  }

  /// Opens an existing document from [filePath] in a tab.
  ///
  /// If the file is already open in another tab, focuses that tab.
  /// If the current active tab is completely pristine and untitled, replaces it.
  Future<DocumentSession> openFileTab(String filePath) async {
    if (_restoreCompleter != null) {
      await _restoreCompleter!.future;
    }

    final result = await _fileService.loadFileFromPath(filePath);
    return await openDocumentTab(
      result.document,
      filePath: result.filePath,
      title: result.fileName,
    );
  }

  /// Switches the active document to the tab at [index].
  void switchTab(int index) {
    if (index < 0 || index >= state.sessions.length) return;
    if (index == state.activeIndex) return;

    emit(state.copyWith(activeIndex: index));
    _debouncedSaveSession();
    _log.debug('Switched to tab index: $index (${state.sessions[index].title})');
  }

  /// Cycles to the next tab.
  void nextTab() {
    if (state.sessions.length <= 1) return;
    switchTab((state.activeIndex + 1) % state.sessions.length);
  }

  /// Cycles to the previous tab.
  void previousTab() {
    if (state.sessions.length <= 1) return;
    switchTab((state.activeIndex - 1 + state.sessions.length) % state.sessions.length);
  }

  /// Closes the tab at [index], executing optional [unsavedGuard] if dirty.
  ///
  /// Returns `true` if closed, `false` if cancelled.
  Future<bool> closeTab(
    int index, {
    Future<bool> Function(DocumentSession session)? unsavedGuard,
  }) async {
    if (index < 0 || index >= state.sessions.length) return false;
    final targetSession = state.sessions[index];

    if (targetSession.isDirty && unsavedGuard != null) {
      final canClose = await unsavedGuard(targetSession);
      if (!canClose) return false;
    }

    // If closing the sole tab, replace it with a fresh untitled blank session rather than leaving 0 tabs
    if (state.sessions.length == 1) {
      _subscriptions[targetSession.id]?.cancel();
      _subscriptions.remove(targetSession.id);
      unawaited(targetSession.dispose());

      final freshSession = DocumentSession(
        id: _nextTabId(),
        cubit: DocumentCubit(null, null, false),
      );
      _subscribeSession(freshSession);

      emit(state.copyWith(
        sessions: [freshSession],
        activeIndex: 0,
      ));
      _debouncedSaveSession();
      _log.info('Reset sole tab to fresh untitled session: ${freshSession.id}');
      return true;
    }

    // Unsubscribe and dispose cubit
    _subscriptions[targetSession.id]?.cancel();
    _subscriptions.remove(targetSession.id);
    unawaited(targetSession.dispose());

    final updatedSessions = List<DocumentSession>.from(state.sessions)..removeAt(index);
    int newActiveIndex = state.activeIndex;

    if (index < state.activeIndex) {
      newActiveIndex = state.activeIndex - 1;
    } else if (index == state.activeIndex) {
      newActiveIndex = state.activeIndex.clamp(0, updatedSessions.length - 1);
    }

    emit(state.copyWith(
      sessions: updatedSessions,
      activeIndex: newActiveIndex,
    ));
    _debouncedSaveSession();
    _log.info('Closed tab at index $index, remaining: ${updatedSessions.length}');
    return true;
  }

  /// Closes all tabs except the tab at [keepIndex].
  Future<void> closeOtherTabs(
    int keepIndex, {
    Future<bool> Function(DocumentSession session)? unsavedGuard,
  }) async {
    if (keepIndex < 0 || keepIndex >= state.sessions.length) return;
    final targetSession = state.sessions[keepIndex];

    for (int i = state.sessions.length - 1; i >= 0; i--) {
      if (state.sessions[i].id == targetSession.id) continue;
      final closed = await closeTab(i, unsavedGuard: unsavedGuard);
      if (!closed) break;
    }
  }

  /// Reorders tabs for drag-and-drop tab interactions.
  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.sessions.length) return;
    if (newIndex < 0 || newIndex > state.sessions.length) return;

    final updated = List<DocumentSession>.from(state.sessions);
    final moved = updated.removeAt(oldIndex);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    updated.insert(targetIndex, moved);

    int newActiveIndex = state.activeIndex;
    if (state.activeIndex == oldIndex) {
      newActiveIndex = targetIndex;
    } else if (oldIndex < state.activeIndex && targetIndex >= state.activeIndex) {
      newActiveIndex--;
    } else if (oldIndex > state.activeIndex && targetIndex <= state.activeIndex) {
      newActiveIndex++;
    }

    emit(state.copyWith(
      sessions: updated,
      activeIndex: newActiveIndex,
    ));
    _debouncedSaveSession();
  }

  /// Restores persisted workspace sessions from [SharedPreferences] upon startup.
  Future<void> _restoreSessionFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefSessionKey);
      if (raw == null || raw.trim().isEmpty) return;

      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final Map<String, dynamic> data = decoded.cast<String, dynamic>();

      final rawTabs = data['tabs'] as List<dynamic>?;
      final savedActiveIndex = (data['activeIndex'] as num?)?.toInt() ?? 0;

      if (rawTabs == null || rawTabs.isEmpty) return;

      final restoredSessions = <DocumentSession>[];
      for (int i = 0; i < rawTabs.length; i++) {
        final tabEntry = rawTabs[i];
        if (tabEntry is! Map) continue;
        final tabMap = tabEntry.cast<String, dynamic>();
        final filePath = tabMap['filePath'] as String?;
        core.SarvDocument? doc;

        if (!kIsWeb && filePath != null && filePath.isNotEmpty && File(filePath).existsSync()) {
          try {
            final loadResult = await _fileService.loadFileFromPath(filePath);
            doc = loadResult.document;
          } catch (e) {
            _log.warning('Could not reload persisted file path: $filePath', error: e);
          }
        }

        if (doc == null && tabMap['document'] is Map) {
          try {
            doc = core.SarvDocument.fromJson((tabMap['document'] as Map).cast<String, dynamic>());
          } catch (e) {
            _log.warning('Could not parse persisted document JSON for tab $i', error: e);
          }
        }

        if (doc != null) {
          final cubit = DocumentCubit(null, null, false);
          cubit.loadDocument(doc, filePath: filePath);
          final tabId = tabMap['id'] as String? ?? _nextTabId();
          restoredSessions.add(DocumentSession(id: tabId, cubit: cubit));
        }
      }

      if (restoredSessions.isNotEmpty && !isClosed) {
        for (final s in state.sessions) {
          _subscriptions[s.id]?.cancel();
          unawaited(s.dispose());
        }
        _subscriptions.clear();

        for (final session in restoredSessions) {
          _subscribeSession(session);
        }

        final clampedIndex = savedActiveIndex.clamp(0, restoredSessions.length - 1);
        emit(state.copyWith(
          sessions: restoredSessions,
          activeIndex: clampedIndex,
        ));
        _log.info('Restored workspace session with ${restoredSessions.length} tabs');
      }
    } catch (e, st) {
      _log.warning('Failed to restore workspace session', error: e, stackTrace: st);
    } finally {
      if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
        _restoreCompleter!.complete();
      }
      _restoreCompleter = null;
    }
  }

  void _debouncedSaveSession() {
    if (!_autoRestoreSession) return;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveSessionToPrefs();
    });
  }

  /// Immediately flushes any pending debounced session save to [SharedPreferences].
  Future<void> flushSessionSave() async {
    _saveDebounceTimer?.cancel();
    await _saveSessionToPrefs();
  }

  Future<void> _saveSessionToPrefs() async {
    if (isClosed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabsData = <Map<String, dynamic>>[];
      for (final s in state.sessions) {
        tabsData.add({
          'id': s.id,
          'filePath': s.filePath,
          'document': s.document.toJson(),
        });
      }
      final data = {
        'version': 1,
        'activeIndex': state.activeIndex,
        'tabs': tabsData,
      };
      await prefs.setString(prefSessionKey, jsonEncode(data));
      _log.debug('Saved workspace session (${tabsData.length} tabs)');
    } catch (e) {
      _log.warning('Failed to save workspace session', error: e);
    }
  }

  /// Clears persisted workspace session state from [SharedPreferences].
  static Future<void> clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefSessionKey);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    _saveDebounceTimer?.cancel();
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
    for (final session in state.sessions) {
      await session.dispose();
    }
    return super.close();
  }
}
