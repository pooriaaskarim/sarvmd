// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../document/document_cubit.dart';

/// Represents a single active document session / tab within the SarvMD workspace.
///
/// Each session encapsulates its own isolated [DocumentCubit], undo/redo history,
/// file backing, and dirty tracking state.
class DocumentSession {
  /// Unique identifier for this session/tab.
  final String id;

  /// Dedicated [DocumentCubit] managing the manuscript state and command history.
  final DocumentCubit cubit;

  DocumentSession({
    required this.id,
    required this.cubit,
  });

  /// The user-facing display name of the document (file name, title, or "Untitled").
  String get title => cubit.state.displayName;

  /// Whether the session contains unsaved modifications.
  bool get isDirty => cubit.state.isDirty;

  /// The active file system path, if saved to an external file.
  String? get filePath => cubit.state.filePath;

  /// The underlying musical score and layout document.
  core.SarvDocument get document => cubit.state.document;

  /// Disposes the session and closes its isolated [DocumentCubit].
  Future<void> dispose() async {
    await cubit.close();
  }
}
