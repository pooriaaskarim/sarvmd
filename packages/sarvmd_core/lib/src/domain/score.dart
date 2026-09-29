// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Represents top-level score/manuscript title and metadata in SarvMD.
class Score {
  /// The title of the score/manuscript (e.g., "Symphony No. 5", "Piano Notebook").
  final String title;

  /// Creates a [Score] with an optional title.
  const Score({
    this.title = '',
  });

  /// Creates a copy of this score with an optional title override.
  Score copyWith({
    String? title,
  }) =>
      Score(
        title: title ?? this.title,
      );

  /// Serializes this score to a JSON map.
  Map<String, dynamic> toJson() => {
        'title': title,
      };

  /// Deserializes a [Score] from a JSON map.
  factory Score.fromJson(Map<String, dynamic> json) => Score(
        title: json['title'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Score && runtimeType == other.runtimeType && title == other.title;

  @override
  int get hashCode => title.hashCode;

  @override
  String toString() => 'Score($title)';
}
