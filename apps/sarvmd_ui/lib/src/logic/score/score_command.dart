// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// The base command interface for all transactional mutations applied to the musical score AST.
///
/// Encapsulating score mutations in discrete Command objects makes it possible to
/// maintain an execution history stack, enabling robust, developer-grade Undo/Redo
/// commands at zero additional architectural cost.
abstract class ScoreCommand {
  const ScoreCommand();

  /// Applies the mutation to the given [current] score state and returns the new state.
  core.Score execute(core.Score current);

  /// Reverts the mutation applied by this command, returning the previous state.
  core.Score undo(core.Score current);
}

/// A dummy/testing command that does nothing, useful for verifying command pipelines.
class NoOpCommand extends ScoreCommand {
  const NoOpCommand();

  @override
  core.Score execute(core.Score current) => current;

  @override
  core.Score undo(core.Score current) => current;
}
