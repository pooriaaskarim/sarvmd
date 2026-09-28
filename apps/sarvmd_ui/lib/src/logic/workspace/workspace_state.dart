// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/foundation.dart';
import '../document/document_cubit.dart';
import 'document_session.dart';

/// Immutable state of the multi-document workspace.
class WorkspaceState {
  /// All currently open document sessions in tab order.
  final List<DocumentSession> sessions;

  /// Index of the currently focused document tab.
  final int activeIndex;

  /// Internal revision counter ensuring Bloc listeners rebuild on session mutations.
  final int revision;

  const WorkspaceState({
    required this.sessions,
    this.activeIndex = 0,
    this.revision = 0,
  });

  /// The active focused [DocumentSession].
  DocumentSession get activeSession {
    if (sessions.isEmpty) {
      throw StateError('WorkspaceState must contain at least one DocumentSession.');
    }
    final clampedIndex = activeIndex.clamp(0, sessions.length - 1);
    return sessions[clampedIndex];
  }

  /// The [DocumentCubit] belonging to the active session.
  DocumentCubit get activeCubit => activeSession.cubit;

  /// Total number of open document tabs.
  int get tabCount => sessions.length;

  /// Whether more than one tab is open.
  bool get hasMultipleTabs => sessions.length > 1;

  /// Whether any open session in the workspace currently has unpersisted changes.
  bool get hasDirtyTabs => sessions.any((s) => s.isDirty);

  WorkspaceState copyWith({
    List<DocumentSession>? sessions,
    int? activeIndex,
    int? revision,
  }) {
    return WorkspaceState(
      sessions: sessions ?? this.sessions,
      activeIndex: activeIndex ?? this.activeIndex,
      revision: revision ?? (this.revision + 1),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkspaceState &&
        listEquals(other.sessions, sessions) &&
        other.activeIndex == activeIndex &&
        other.revision == revision;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(sessions), activeIndex, revision);
}
