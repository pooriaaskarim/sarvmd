// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../domain/document.dart';
import '../domain/metadata.dart';
import 'document_command.dart';

/// A dummy/testing command that does nothing, useful for verifying command pipelines.
class NoOpCommand extends DocumentCommand {
  const NoOpCommand();

  @override
  String get label => 'No-op';

  @override
  SarvDocument execute(SarvDocument current) => current;

  @override
  SarvDocument undo(SarvDocument current) => current;
}

/// Transactional command to set the score title.
class SetTitleCommand extends DocumentCommand {
  final String newTitle;
  final String _previousTitle;
  final String _previousMetadataTitle;

  SetTitleCommand(this.newTitle, [this._previousTitle = '', String? previousMetadataTitle])
      : _previousMetadataTitle = previousMetadataTitle ?? _previousTitle;

  @override
  String get label => 'Set Title';

  @override
  SarvDocument execute(SarvDocument current) => current.copyWith(
        score: current.score.copyWith(title: newTitle),
        metadata: current.metadata.copyWith(
          title: newTitle,
          modifiedAt: DateTime.now(),
        ),
      );

  @override
  SarvDocument undo(SarvDocument current) => current.copyWith(
        score: current.score.copyWith(title: _previousTitle),
        metadata: current.metadata.copyWith(
          title: _previousMetadataTitle,
        ),
      );

  @override
  bool canCoalesceWith(DocumentCommand other) => other is SetTitleCommand;

  @override
  DocumentCommand coalesceWith(DocumentCommand other) {
    final next = other as SetTitleCommand;
    return SetTitleCommand(next.newTitle, _previousTitle, _previousMetadataTitle);
  }
}

/// Transactional command to update document metadata.
class SetMetadataCommand extends DocumentCommand {
  final DocumentMetadata newMetadata;
  DocumentMetadata? _previousMetadata;

  SetMetadataCommand(this.newMetadata);

  @override
  String get label => 'Update Metadata';

  @override
  SarvDocument execute(SarvDocument current) {
    _previousMetadata = current.metadata;
    return current.copyWith(
      metadata: newMetadata.copyWith(modifiedAt: DateTime.now()),
      score: current.score.copyWith(title: newMetadata.title),
    );
  }

  @override
  SarvDocument undo(SarvDocument current) {
    if (_previousMetadata == null) return current;
    return current.copyWith(
      metadata: _previousMetadata,
      score: current.score.copyWith(title: _previousMetadata!.title),
    );
  }
}

/// Transactional command to set the document target page count.
class SetPageCountCommand extends DocumentCommand {
  final int newPageCount;
  int? _previousPageCount;

  SetPageCountCommand(this.newPageCount);

  @override
  String get label => 'Set Page Count';

  @override
  SarvDocument execute(SarvDocument current) {
    _previousPageCount = current.pageCount;
    return current.copyWith(
      pageCount: newPageCount.clamp(1, 100),
      metadata: current.metadata.copyWith(modifiedAt: DateTime.now()),
    );
  }

  @override
  SarvDocument undo(SarvDocument current) {
    if (_previousPageCount == null) return current;
    return current.copyWith(
      pageCount: _previousPageCount,
      metadata: current.metadata.copyWith(modifiedAt: DateTime.now()),
    );
  }
}
