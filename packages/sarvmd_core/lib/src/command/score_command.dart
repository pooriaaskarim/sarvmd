// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../domain/document.dart';
import '../domain/measure.dart';
import '../domain/metadata.dart';
import '../domain/score.dart';
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

  SetTitleCommand(this.newTitle, [this._previousTitle = '']);

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
          title: _previousTitle,
          modifiedAt: DateTime.now(),
        ),
      );

  @override
  bool canCoalesceWith(DocumentCommand other) => other is SetTitleCommand;

  @override
  DocumentCommand coalesceWith(DocumentCommand other) {
    final next = other as SetTitleCommand;
    return SetTitleCommand(next.newTitle, _previousTitle);
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

/// Transactional command to add an instrumental part to the score.
class AddPartCommand extends DocumentCommand {
  final Part part;
  final int? targetIndex;

  const AddPartCommand(this.part, {this.targetIndex});

  @override
  String get label => 'Add Part';

  @override
  SarvDocument execute(SarvDocument current) {
    final score = current.score;
    final newParts = List<Part>.from(score.parts);
    if (targetIndex != null && targetIndex! >= 0 && targetIndex! <= newParts.length) {
      newParts.insert(targetIndex!, part);
    } else {
      newParts.add(part);
    }
    return current.copyWith(score: score.copyWith(parts: newParts));
  }

  @override
  SarvDocument undo(SarvDocument current) {
    final score = current.score;
    final newParts = score.parts.where((p) => p.id != part.id).toList();
    return current.copyWith(score: score.copyWith(parts: newParts));
  }
}

/// Transactional command to remove an instrumental part by ID.
class RemovePartCommand extends DocumentCommand {
  final String partId;
  Part? _removedPart;
  int? _removedIndex;

  RemovePartCommand(this.partId);

  @override
  String get label => 'Remove Part';

  @override
  SarvDocument execute(SarvDocument current) {
    final score = current.score;
    final idx = score.parts.indexWhere((p) => p.id == partId);
    if (idx == -1) return current;

    _removedIndex = idx;
    _removedPart = score.parts[idx];

    final newParts = List<Part>.from(score.parts)..removeAt(idx);
    return current.copyWith(score: score.copyWith(parts: newParts));
  }

  @override
  SarvDocument undo(SarvDocument current) {
    if (_removedPart == null || _removedIndex == null) return current;

    final score = current.score;
    final newParts = List<Part>.from(score.parts);
    final insertIdx = _removedIndex!.clamp(0, newParts.length);
    newParts.insert(insertIdx, _removedPart!);
    return current.copyWith(score: score.copyWith(parts: newParts));
  }
}

/// Transactional command to add a measure to a specific part timeline.
class AddMeasureCommand extends DocumentCommand {
  final String partId;
  final Measure measure;

  const AddMeasureCommand(this.partId, this.measure);

  @override
  String get label => 'Add Measure';

  @override
  SarvDocument execute(SarvDocument current) {
    final score = current.score;
    final newParts = score.parts.map((p) {
      if (p.id == partId) {
        final newMeasures = List<Measure>.from(p.measures)..add(measure);
        return p.copyWith(measures: newMeasures);
      }
      return p;
    }).toList();
    return current.copyWith(score: score.copyWith(parts: newParts));
  }

  @override
  SarvDocument undo(SarvDocument current) {
    final score = current.score;
    final newParts = score.parts.map((p) {
      if (p.id == partId) {
        final newMeasures = p.measures.where((m) => m.number != measure.number).toList();
        return p.copyWith(measures: newMeasures);
      }
      return p;
    }).toList();
    return current.copyWith(score: score.copyWith(parts: newParts));
  }
}

/// Transactional command to remove a measure by measure number from a part.
class RemoveMeasureCommand extends DocumentCommand {
  final String partId;
  final int measureNumber;
  Measure? _removedMeasure;
  int? _removedIndex;

  RemoveMeasureCommand(this.partId, this.measureNumber);

  @override
  String get label => 'Remove Measure';

  @override
  SarvDocument execute(SarvDocument current) {
    final score = current.score;
    final partIdx = score.parts.indexWhere((p) => p.id == partId);
    if (partIdx == -1) return current;

    final part = score.parts[partIdx];
    final mIdx = part.measures.indexWhere((m) => m.number == measureNumber);
    if (mIdx == -1) return current;

    _removedIndex = mIdx;
    _removedMeasure = part.measures[mIdx];

    final newMeasures = List<Measure>.from(part.measures)..removeAt(mIdx);
    final updatedPart = part.copyWith(measures: newMeasures);

    final newParts = List<Part>.from(score.parts);
    newParts[partIdx] = updatedPart;
    return current.copyWith(score: score.copyWith(parts: newParts));
  }

  @override
  SarvDocument undo(SarvDocument current) {
    if (_removedMeasure == null || _removedIndex == null) return current;

    final score = current.score;
    final partIdx = score.parts.indexWhere((p) => p.id == partId);
    if (partIdx == -1) return current;

    final part = score.parts[partIdx];
    final newMeasures = List<Measure>.from(part.measures);
    final insertIdx = _removedIndex!.clamp(0, newMeasures.length);
    newMeasures.insert(insertIdx, _removedMeasure!);

    final newParts = List<Part>.from(score.parts);
    newParts[partIdx] = part.copyWith(measures: newMeasures);
    return current.copyWith(score: score.copyWith(parts: newParts));
  }
}
