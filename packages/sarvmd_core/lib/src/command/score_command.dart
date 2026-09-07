// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import '../domain/score.dart';
import '../domain/measure.dart';

/// Base command interface for transactional mutations applied to the musical score AST.
abstract class ScoreCommand {
  const ScoreCommand();

  /// Applies the mutation to the given [current] score state and returns the new state.
  Score execute(Score current);

  /// Reverts the mutation applied by this command, returning the previous state.
  Score undo(Score current);
}

/// A dummy/testing command that does nothing, useful for verifying command pipelines.
class NoOpCommand extends ScoreCommand {
  const NoOpCommand();

  @override
  Score execute(Score current) => current;

  @override
  Score undo(Score current) => current;
}

/// Transactional command to set the score title.
class SetTitleCommand extends ScoreCommand {
  final String newTitle;
  final String _previousTitle;

  SetTitleCommand(this.newTitle, [this._previousTitle = '']);

  @override
  Score execute(Score current) => current.copyWith(title: newTitle);

  @override
  Score undo(Score current) => current.copyWith(title: _previousTitle);
}

/// Transactional command to add an instrumental part to the score.
class AddPartCommand extends ScoreCommand {
  final Part part;
  final int? targetIndex;

  const AddPartCommand(this.part, {this.targetIndex});

  @override
  Score execute(Score current) {
    final newParts = List<Part>.from(current.parts);
    if (targetIndex != null && targetIndex! >= 0 && targetIndex! <= newParts.length) {
      newParts.insert(targetIndex!, part);
    } else {
      newParts.add(part);
    }
    return current.copyWith(parts: newParts);
  }

  @override
  Score undo(Score current) {
    final newParts = current.parts.where((p) => p.id != part.id).toList();
    return current.copyWith(parts: newParts);
  }
}

/// Transactional command to remove an instrumental part by ID.
class RemovePartCommand extends ScoreCommand {
  final String partId;
  Part? _removedPart;
  int? _removedIndex;

  RemovePartCommand(this.partId);

  @override
  Score execute(Score current) {
    final idx = current.parts.indexWhere((p) => p.id == partId);
    if (idx == -1) return current;

    _removedIndex = idx;
    _removedPart = current.parts[idx];

    final newParts = List<Part>.from(current.parts)..removeAt(idx);
    return current.copyWith(parts: newParts);
  }

  @override
  Score undo(Score current) {
    if (_removedPart == null || _removedIndex == null) return current;

    final newParts = List<Part>.from(current.parts);
    final insertIdx = _removedIndex!.clamp(0, newParts.length);
    newParts.insert(insertIdx, _removedPart!);
    return current.copyWith(parts: newParts);
  }
}

/// Transactional command to add a measure to a specific part timeline.
class AddMeasureCommand extends ScoreCommand {
  final String partId;
  final Measure measure;

  const AddMeasureCommand(this.partId, this.measure);

  @override
  Score execute(Score current) {
    final newParts = current.parts.map((p) {
      if (p.id == partId) {
        final newMeasures = List<Measure>.from(p.measures)..add(measure);
        return p.copyWith(measures: newMeasures);
      }
      return p;
    }).toList();
    return current.copyWith(parts: newParts);
  }

  @override
  Score undo(Score current) {
    final newParts = current.parts.map((p) {
      if (p.id == partId) {
        final newMeasures = p.measures.where((m) => m.number != measure.number).toList();
        return p.copyWith(measures: newMeasures);
      }
      return p;
    }).toList();
    return current.copyWith(parts: newParts);
  }
}

/// Transactional command to remove a measure by measure number from a part.
class RemoveMeasureCommand extends ScoreCommand {
  final String partId;
  final int measureNumber;
  Measure? _removedMeasure;
  int? _removedIndex;

  RemoveMeasureCommand(this.partId, this.measureNumber);

  @override
  Score execute(Score current) {
    final partIdx = current.parts.indexWhere((p) => p.id == partId);
    if (partIdx == -1) return current;

    final part = current.parts[partIdx];
    final mIdx = part.measures.indexWhere((m) => m.number == measureNumber);
    if (mIdx == -1) return current;

    _removedIndex = mIdx;
    _removedMeasure = part.measures[mIdx];

    final newMeasures = List<Measure>.from(part.measures)..removeAt(mIdx);
    final updatedPart = part.copyWith(measures: newMeasures);

    final newParts = List<Part>.from(current.parts);
    newParts[partIdx] = updatedPart;
    return current.copyWith(parts: newParts);
  }

  @override
  Score undo(Score current) {
    if (_removedMeasure == null || _removedIndex == null) return current;

    final partIdx = current.parts.indexWhere((p) => p.id == partId);
    if (partIdx == -1) return current;

    final part = current.parts[partIdx];
    final newMeasures = List<Measure>.from(part.measures);
    final insertIdx = _removedIndex!.clamp(0, newMeasures.length);
    newMeasures.insert(insertIdx, _removedMeasure!);

    final newParts = List<Part>.from(current.parts);
    newParts[partIdx] = part.copyWith(measures: newMeasures);
    return current.copyWith(parts: newParts);
  }
}
