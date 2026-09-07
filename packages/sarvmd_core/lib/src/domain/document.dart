// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import '../config.dart';
import 'score.dart';

/// Represents the complete, versionable state of a SarvMD manuscript document,
/// combining musical score content ([Score]) and physical layout configuration ([PageConfig]).
class SarvDocument {
  final Score score;
  final PageConfig config;

  const SarvDocument({
    this.score = const Score(title: '', parts: []),
    this.config = const PageConfig(),
  });

  /// Creates a copy of this document with optional field overrides.
  SarvDocument copyWith({
    Score? score,
    PageConfig? config,
  }) {
    return SarvDocument(
      score: score ?? this.score,
      config: config ?? this.config,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SarvDocument &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          config == other.config;

  @override
  int get hashCode => score.hashCode ^ config.hashCode;
}
