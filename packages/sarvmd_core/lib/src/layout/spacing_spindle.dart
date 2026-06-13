// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'dart:math' as math;
import '../domain/duration.dart';
import '../domain/measure.dart';
import '../domain/signature.dart';

/// Computes the horizontal visual positions (coordinates) of musical events
/// in a measure using Gouldian logarithmic spacing.
///
/// Logarithmic spacing is the classical music engraving standard (established
/// by Elaine Gould in *Behind Bars*). Rather than spacing notes linearly (where a
/// half note occupies twice the width of a quarter note), spacing is computed
/// using a power law:
///
/// $$S(d) = S_{ref} \cdot \left( \frac{d}{d_{ref}} \right)^\alpha$$
///
/// where:
/// * $d_{ref}$ is the reference rhythmic duration (typically a quarter note).
/// * $S_{ref}$ is the physical spacing width allocated to the reference duration.
/// * $\alpha$ is the scaling exponent (typically between 0.57 and 0.62).
///
/// This prevents visual crowding in dense passages while keeping wider notes in
/// pleasant, readable proportions.
class SpacingSpindle {
  /// Creates a [SpacingSpindle] with pre-computed coordinates.
  const SpacingSpindle({
    required this.coordinates,
    required this.totalWidth,
  });

  /// A mapping of each unique rhythmic onset timestamp (from the start of the measure)
  /// to its absolute horizontal visual coordinate in millimeters.
  final Map<RhythmicDuration, double> coordinates;

  /// The total visual width of the measure in millimeters (including the final slice).
  final double totalWidth;

  /// Computes a [SpacingSpindle] for the given [voices] inside a measure.
  ///
  /// * [voices]: The list of polyphonic timelines in the measure.
  /// * [timeSignature]: Optional metric boundary. If provided, the spindle will
  ///   ensure that the measure's total width extends to the end of the bar's
  ///   capacity, even if voices are under-filled.
  /// * [referenceSpacingMm]: Physical spacing width for the reference duration (defaults to 8.0 mm).
  /// * [referenceDuration]: The reference rhythmic duration (defaults to quarter note).
  /// * [scalingExponent]: Exponent $\alpha$ in the Gouldian formula (defaults to 0.57).
  /// * [minimumWidthMm]: Absolute minimum visual width of a single rhythmic slice (defaults to 3.0 mm).
  factory SpacingSpindle.compute({
    required List<Voice> voices,
    TimeSignature? timeSignature,
    double referenceSpacingMm = 8.0,
    RhythmicDuration referenceDuration = RhythmicDuration.quarter,
    double scalingExponent = 0.57,
    double minimumWidthMm = 3.0,
  }) {
    if (voices.isEmpty) {
      // Fallback for an empty measure
      final defaultCapacity = timeSignature != null
          ? RhythmicDuration(timeSignature.beats, timeSignature.beatValue)
          : RhythmicDuration.quarter;
      final defaultWidth = referenceSpacingMm *
          math.pow(defaultCapacity.decimal / referenceDuration.decimal, scalingExponent);
      return SpacingSpindle(
        coordinates: {const RhythmicDuration(0, 1): 0.0},
        totalWidth: math.max(defaultWidth, minimumWidthMm),
      );
    }

    // Step 1: Collect all unique onset timestamps across all voices
    final onsets = <RhythmicDuration>{const RhythmicDuration(0, 1)};
    var maxDuration = const RhythmicDuration(0, 1);

    for (final voice in voices) {
      var currentPos = const RhythmicDuration(0, 1);
      for (final event in voice.events) {
        onsets.add(currentPos);
        currentPos = (currentPos + event.duration).simplified();
      }
      onsets.add(currentPos);
      if (currentPos > maxDuration) {
        maxDuration = currentPos;
      }
    }

    // If a time signature is given, the measure capacity acts as the ultimate end boundary
    if (timeSignature != null) {
      final capacity = RhythmicDuration(timeSignature.beats, timeSignature.beatValue).simplified();
      onsets.add(capacity);
      if (capacity > maxDuration) {
        maxDuration = capacity;
      }
    }

    // Step 2: Sort the unique timestamps ascendingly
    final sortedOnsets = onsets.toList()..sort();

    // Step 3: Compute non-linear logarithmic widths for each rhythmic interval slice
    final coords = <RhythmicDuration, double>{};
    var currentX = 0.0;

    for (var i = 0; i < sortedOnsets.length - 1; i++) {
      final currentOnset = sortedOnsets[i];
      final nextOnset = sortedOnsets[i + 1];
      coords[currentOnset] = currentX;

      // Slice duration interval
      final sliceDuration = (nextOnset - currentOnset).simplified();
      
      // Calculate Gouldian width: S(d) = S_ref * (d / d_ref) ^ alpha
      var sliceWidth = referenceSpacingMm *
          math.pow(
            sliceDuration.decimal / referenceDuration.decimal,
            scalingExponent,
          );

      // Clamp to ensure legibility of very short/dense values
      if (sliceWidth < minimumWidthMm) {
        sliceWidth = minimumWidthMm;
      }

      currentX += sliceWidth;
    }

    // The final onset timestamp is positioned at the rightmost boundary
    if (sortedOnsets.isNotEmpty) {
      coords[sortedOnsets.last] = currentX;
    }

    return SpacingSpindle(
      coordinates: coords,
      totalWidth: currentX,
    );
  }

  @override
  String toString() {
    final sb = StringBuffer('SpacingSpindle (Total Width: ${totalWidth.toStringAsFixed(2)} mm):\n');
    coordinates.forEach((timestamp, x) {
      sb.writeln('  onset $timestamp -> ${x.toStringAsFixed(2)} mm');
    });
    return sb.toString();
  }
}
