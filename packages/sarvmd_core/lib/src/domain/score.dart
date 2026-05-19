// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'measure.dart';

/// Represents a single instrument part's timeline of measures.
///
/// In standard music engraving, a [Part] represents the complete musical timeline
/// for a single instrument or voice part (e.g., "Violin I", "Flute", "Soprano").
///
/// A [Part] contains a sequential list of [Measure]s that must be horizontally
/// aligned with other instrument parts inside a [Score] during rendering.
class Part {
  
  /// Creates a [Part] representing an instrumental timeline.
  ///
  /// * [id]: The unique identifier of this part (e.g. 'violin1', 'pianoRight').
  /// * [name]: The full display name of the instrument (e.g. 'Violin I', 'Piano').
  /// * [measures]: The ordered sequence of measures that make up the part.
  const Part({
    required this.id,
    required this.name,
    this.measures = const [],
  });

  /// Unique identifier of this part (e.g. 'violin1', 'pianoRight').
  final String id;

  /// Display name of the instrument (e.g. 'Violin I', 'Piano').
  ///
  /// Typically printed at the left-hand margin of the first system or abbreviated
  /// on subsequent systems.
  final String name;

  /// Sequence of measures that constitute this part.
  final List<Measure> measures;

  /// Creates a copy of this part with optional field overrides.
  Part copyWith({
    String? id,
    String? name,
    List<Measure>? measures,
  }) =>
      Part(
        id: id ?? this.id,
        name: name ?? this.name,
        measures: measures ?? this.measures,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Part ||
        id != other.id ||
        name != other.name ||
        measures.length != other.measures.length) {
      return false;
    }
    for (int i = 0; i < measures.length; i++) {
      if (measures[i] != other.measures[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(measures));

  @override
  String toString() => 'Part($id, name: $name, measuresCount: ${measures.length})';
}

/// Represents the top-level musical score AST (Abstract Syntax Tree).
///
/// `Score` is the root node of our native engraving domain model. It contains:
/// 1. Top-level metadata like [title] and [composer] which are formatted and rendered on the first page.
/// 2. A list of instrumental [parts] which are engraved as parallel staves system-by-system.
///
/// Downstream compilers (like the LaTeX coordinate emitter or SMuFL vector layout engines)
/// consume this `Score` to perform Gouldian spacing, system breaks, page turns, and layout coordinates.
class Score {
  
  /// Creates a [Score] representing the complete multi-instrumental work.
  ///
  /// * [title]: The title of the composition.
  /// * [composer]: The composer's or arranger's name. Defaults to an empty string.
  /// * [parts]: The list of instrumental parts in this score.
  const Score({
    required this.title,
    this.composer = '',
    this.parts = const [],
  });

  /// The title of the score (e.g., "Symphony No. 5", "Autumn Leaves").
  final String title;

  /// The composer's name (e.g., "L. van Beethoven").
  final String composer;

  /// The list of instrument parts contained within this score.
  final List<Part> parts;

  /// Creates a copy of this score with optional field overrides.
  Score copyWith({
    String? title,
    String? composer,
    List<Part>? parts,
  }) =>
      Score(
        title: title ?? this.title,
        composer: composer ?? this.composer,
        parts: parts ?? this.parts,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Score ||
        title != other.title ||
        composer != other.composer ||
        parts.length != other.parts.length) {
      return false;
    }
    for (int i = 0; i < parts.length; i++) {
      if (parts[i] != other.parts[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(title, composer, Object.hashAll(parts));

  @override
  String toString() => 'Score($title, composer: $composer, partsCount: ${parts.length})';
}
