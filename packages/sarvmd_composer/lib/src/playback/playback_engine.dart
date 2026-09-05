// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart';

/// Playback event emitted by the playback engine during score playback.
class PlaybackEvent {
  final Score score;
  final Measure measure;
  final MusicalEvent musicalEvent;
  final Duration position;

  const PlaybackEvent({
    required this.score,
    required this.measure,
    required this.musicalEvent,
    required this.position,
  });
}

/// Abstract playback engine interface for scheduling and streaming score events.
abstract interface class PlaybackEngine {
  /// Stream of playback events emitted sequentially during score playback.
  Stream<PlaybackEvent> get eventStream;

  /// Whether the playback engine is currently playing.
  bool get isPlaying;

  /// Current tempo in beats per minute (BPM).
  int get bpm;

  /// Play the provided [score] starting at [startMeasureIndex].
  Future<void> play(Score score, {int startMeasureIndex = 0});

  /// Pause current playback.
  void pause();

  /// Stop current playback and reset position to 0.
  void stop();
}
