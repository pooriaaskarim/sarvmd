// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Represents an exact rational rhythmic duration in music notation.
///
/// In computerized music notation, representing durations as floating-point
/// numbers (`double`) introduces cumulative rounding errors. This is particularly
/// problematic when calculating complex alignments, tuplets, and horizontal
/// spacings (e.g., Gouldian logarithmic spacing).
///
/// To achieve pixel-perfect layout and zero coordinate drift across multiple
/// independent voices and staves, `RhythmicDuration` models time as an exact
/// mathematical fraction composed of a [numerator] and [denominator].
class RhythmicDuration implements Comparable<RhythmicDuration> {
  
  /// Creates a new [RhythmicDuration] with the given [numerator] and [denominator].
  ///
  /// The [denominator] represents the rhythmic division (e.g. 4 for quarter notes,
  /// 8 for eighth notes) and must not be zero.
  const RhythmicDuration(this.numerator, this.denominator)
      : assert(denominator != 0, 'Denominator cannot be zero.');

  /// The numerator of the rhythmic fraction.
  ///
  /// Represents the count of rhythmic subdivisions (e.g., 3 in a 3/8 duration).
  final int numerator;

  /// The denominator of the rhythmic fraction.
  ///
  /// Represents the fundamental rhythmic division (e.g., 8 in a 3/8 duration).
  /// Must be non-zero.
  final int denominator;

  /// Returns the double-precision decimal representation of the fraction.
  ///
  /// Useful for converting exact musical time to visual coordinates or percentages
  /// in layout calculations. E.g., `1/4` becomes `0.25`.
  double get decimal => numerator / denominator;

  /// Simplifies the rhythmic fraction to its lowest terms.
  ///
  /// Divides both the [numerator] and [denominator] by their Greatest Common Divisor (GCD).
  /// Also standardizes negative fractions so that the negative sign is kept solely
  /// on the numerator (e.g. `2/-4` becomes `-1/2`).
  RhythmicDuration simplified() {
    final g = _gcd(numerator.abs(), denominator.abs());
    final sign = denominator < 0 ? -1 : 1;
    return RhythmicDuration(
      sign * (numerator ~/ g),
      sign * (denominator ~/ g),
    );
  }

  /// Calculates the Greatest Common Divisor (GCD) using the Euclidean algorithm.
  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  /// Adds this duration to [other] and returns a new simplified [RhythmicDuration].
  ///
  /// Follows the fractional addition rule:
  /// `(n1/d1) + (n2/d2) = (n1*d2 + n2*d1) / (d1*d2)`
  RhythmicDuration operator +(RhythmicDuration other) {
    return RhythmicDuration(
      numerator * other.denominator + other.numerator * denominator,
      denominator * other.denominator,
    ).simplified();
  }

  /// Subtracts [other] from this duration and returns a new simplified [RhythmicDuration].
  ///
  /// Follows the fractional subtraction rule:
  /// `(n1/d1) - (n2/d2) = (n1*d2 - n2*d1) / (d1*d2)`
  RhythmicDuration operator -(RhythmicDuration other) {
    return RhythmicDuration(
      numerator * other.denominator - other.numerator * denominator,
      denominator * other.denominator,
    ).simplified();
  }

  /// Multiplies this duration by an integer [factor] and returns a new simplified [RhythmicDuration].
  ///
  /// E.g. a quarter note `1/4` multiplied by `2` yields a half note `1/2`.
  RhythmicDuration operator *(int factor) {
    return RhythmicDuration(numerator * factor, denominator).simplified();
  }

  /// Adds augmentation dots to the rhythmic duration.
  ///
  /// Each dot adds half of the remaining duration.
  /// The formula for the multiplier is:
  /// `Multiplier = 2 - (1 / 2^dots)` which can be written as `(2^(dots+1) - 1) / 2^dots`.
  ///
  /// * 0 dots: yields the original duration (e.g. `1/4` -> `1/4`).
  /// * 1 dot (dotted note): yields `1.5x` duration (e.g. dotted quarter = `1/4 + 1/8 = 3/8`).
  /// * 2 dots (double-dotted note): yields `1.75x` duration (e.g. `1/4 + 1/8 + 1/16 = 7/16`).
  RhythmicDuration withDots(int dots) {
    if (dots <= 0) return this;
    final multiplierNumerator = (1 << (dots + 1)) - 1;
    final multiplierDenominator = 1 << dots;
    return RhythmicDuration(
      numerator * multiplierNumerator,
      denominator * multiplierDenominator,
    ).simplified();
  }

  @override
  int compareTo(RhythmicDuration other) {
    return (numerator * other.denominator).compareTo(other.numerator * denominator);
  }

  /// Returns true if this duration is shorter than [other].
  bool operator <(RhythmicDuration other) => compareTo(other) < 0;

  /// Returns true if this duration is shorter than or equal to [other].
  bool operator <=(RhythmicDuration other) => compareTo(other) <= 0;

  /// Returns true if this duration is longer than [other].
  bool operator >(RhythmicDuration other) => compareTo(other) > 0;

  /// Returns true if this duration is longer than or equal to [other].
  bool operator >=(RhythmicDuration other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RhythmicDuration) return false;
    final selfSimp = simplified();
    final otherSimp = other.simplified();
    return selfSimp.numerator == otherSimp.numerator &&
        selfSimp.denominator == otherSimp.denominator;
  }

  @override
  int get hashCode => Object.hash(simplified().numerator, simplified().denominator);

  @override
  String toString() => '$numerator/$denominator';

  /// A whole note duration (1/1).
  static const RhythmicDuration whole = RhythmicDuration(1, 1);

  /// A half note duration (1/2).
  static const RhythmicDuration half = RhythmicDuration(1, 2);

  /// A quarter note duration (1/4).
  static const RhythmicDuration quarter = RhythmicDuration(1, 4);

  /// An eighth note duration (1/8).
  static const RhythmicDuration eighth = RhythmicDuration(1, 8);

  /// A sixteenth note duration (1/16).
  static const RhythmicDuration sixteenth = RhythmicDuration(1, 16);

  /// A thirty-second note duration (1/32).
  static const RhythmicDuration thirtySecond = RhythmicDuration(1, 32);

  /// A sixty-fourth note duration (1/64).
  static const RhythmicDuration sixtyFourth = RhythmicDuration(1, 64);
}
