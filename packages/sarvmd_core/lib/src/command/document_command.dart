// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../domain/document.dart';

/// Base command interface for transactional mutations applied to the [SarvDocument].
abstract class DocumentCommand {
  const DocumentCommand();

  /// User-visible label describing this action (e.g., "Set Title", "Add Staff").
  String get label;

  /// Applies the mutation to the given [current] document state and returns the new state.
  SarvDocument execute(SarvDocument current);

  /// Reverts the mutation applied by this command, returning the previous document state.
  SarvDocument undo(SarvDocument current);

  /// Returns true if [other] can be merged into this command instance.
  bool canCoalesceWith(DocumentCommand other) => false;

  /// Combines the initial state of this command with the final state of [other].
  DocumentCommand coalesceWith(DocumentCommand other) => other;
}

/// Deprecated alias for [DocumentCommand].
@Deprecated('Use DocumentCommand from package:sarvmd_core instead')
typedef ScoreCommand = DocumentCommand;
