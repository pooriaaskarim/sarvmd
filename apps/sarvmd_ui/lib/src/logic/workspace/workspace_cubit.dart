// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logd/logd.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/utils/app_logger.dart';
import '../document/document_cubit.dart';
import '../services/sarv_file_service.dart';
import 'document_session.dart';
import 'workspace_state.dart';

/// Cubit managing multi-document workspace sessions, active tab routing,
/// and tab lifecycle operations.
class WorkspaceCubit extends Cubit<WorkspaceState> {
  static final Logger _log = AppLogger.get('sarvmd.workspace');

  final SarvFileService _fileService;
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  int _tabSequence = 0;

  WorkspaceCubit({
    DocumentCubit? initialCubit,
    SarvFileService? fileService,
  })  : _fileService = fileService ?? SarvFileService(),
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
  }

  void _subscribeSession(DocumentSession session) {
    _subscriptions[session.id]?.cancel();
    _subscriptions[session.id] = session.cubit.stream.listen((_) {
      if (!isClosed) {
        emit(state.copyWith());
      }
    });
  }

  String _nextTabId() {
    _tabSequence++;
    return 'tab_${DateTime.now().microsecondsSinceEpoch}_$_tabSequence';
  }

  /// Opens a brand-new manuscript tab initialized with [profile].
  DocumentSession openNewTab({core.StaffProfile? profile}) {
    final newCubit = DocumentCubit(null, null, false);
    if (profile != null) {
      newCubit.newDocument(profile);
    }
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
    _log.info('Opened new tab: ${session.id} (${session.title})');
    return session;
  }

  /// Opens a [core.SarvDocument] into a tab.
  ///
  /// If the document's [filePath] is already open in another tab, focuses that tab.
  /// If the current active tab is completely pristine and untitled, replaces it.
  /// Otherwise, opens in a new tab.
  Future<DocumentSession> openDocumentTab(
    core.SarvDocument document, {
    String? filePath,
    String? title,
  }) async {
    // 1. Check if already open by filePath
    if (filePath != null && filePath.isNotEmpty) {
      final existingIndex = state.sessions.indexWhere((s) => s.filePath == filePath);
      if (existingIndex != -1) {
        switchTab(existingIndex);
        return state.sessions[existingIndex];
      }
    }

    // 2. Check if current active tab is a clean, untouched blank tab
    final current = state.activeSession;
    final isPristineBlank = !current.isDirty &&
        current.filePath == null &&
        current.document.score.title.trim().isEmpty &&
        current.cubit.state.undoStack.isEmpty;

    if (isPristineBlank) {
      current.cubit.loadDocument(document, filePath: filePath);
      emit(state.copyWith());
      return current;
    }

    // 3. Otherwise, open in a new tab
    final newCubit = DocumentCubit(null, null, false);
    newCubit.loadDocument(document, filePath: filePath);
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
    _log.info('Opened document tab: ${session.id} -> ${title ?? filePath ?? document.metadata.title}');
    return session;
  }

  /// Opens an existing document from [filePath] in a tab.
  ///
  /// If the file is already open in another tab, focuses that tab.
  /// If the current active tab is completely pristine and untitled, replaces it.
  Future<DocumentSession> openFileTab(String filePath) async {
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

    // If closing the sole tab, reset it to an untitled blank score rather than leaving 0 tabs
    if (state.sessions.length == 1) {
      targetSession.cubit.newDocument();
      emit(state.copyWith());
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
  }

  @override
  Future<void> close() async {
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
