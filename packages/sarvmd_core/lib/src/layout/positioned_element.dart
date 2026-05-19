// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import '../domain/pitch.dart';
import '../domain/smufl.dart';

/// A sealed base class for all physically positioned, visual musical elements.
///
/// Each element has absolute coordinates relative to the top-left corner of the page
/// (measured in millimeters) to decouple layout computation from rendering.
sealed class PositionedElement {
  const PositionedElement();

  /// The absolute horizontal coordinate from the left edge of the page (in millimeters).
  double get x;

  /// The absolute vertical coordinate from the top edge of the page (in millimeters).
  double get y;

  /// The scale factor applied to this element's glyph size.
  double get scale;
}

/// Represents a physically positioned notehead, complete with stems, flags,
/// and necessary ledger lines.
class PositionedNote extends PositionedElement {
  /// Creates a [PositionedNote] at the specified coordinates.
  const PositionedNote({
    required this.x,
    required this.y,
    required this.scale,
    required this.pitch,
    required this.glyph,
    required this.hasStem,
    required this.stemUp,
    this.stemLengthSp = 3.5,
    this.flagGlyph,
    this.ledgerLineYs = const [],
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double scale;

  /// The logical pitch of the note.
  final Pitch pitch;

  /// The notehead glyph symbol to be rendered.
  final SmuflGlyph glyph;

  /// Whether a vertical stem should be rendered for this note.
  final bool hasStem;

  /// The vertical direction of the stem: `true` for up, `false` for down.
  final bool stemUp;

  /// The physical length of the stem in staff-space units (`sp`). Defaults to `3.5`.
  final double stemLengthSp;

  /// The flag glyph (e.g. `flag8thUp`), or null if no flag is needed.
  final SmuflGlyph? flagGlyph;

  /// The absolute Y-coordinates (in millimeters) where horizontal ledger lines
  /// must be drawn for this note if it lies outside the standard staff lines.
  final List<double> ledgerLineYs;
}

/// Represents a physically positioned musical rest.
class PositionedRest extends PositionedElement {
  /// Creates a [PositionedRest] at the specified coordinates.
  const PositionedRest({
    required this.x,
    required this.y,
    required this.scale,
    required this.glyph,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double scale;

  /// The rest glyph symbol to be rendered.
  final SmuflGlyph glyph;
}

/// Represents a physically positioned vertical barline.
class PositionedBarline extends PositionedElement {
  /// Creates a [PositionedBarline] spanning a specific vertical range.
  const PositionedBarline({
    required this.x,
    required this.topY,
    required this.bottomY,
    this.thicknessMm = 0.5,
  });

  @override
  final double x;

  /// The absolute top vertical coordinate (in millimeters).
  final double topY;

  /// The absolute bottom vertical coordinate (in millimeters).
  final double bottomY;

  @override
  double get y => topY;

  @override
  double get scale => 1.0;

  /// The physical thickness of the line (in millimeters).
  final double thicknessMm;
}

/// Represents a physically positioned clef.
class PositionedClef extends PositionedElement {
  /// Creates a [PositionedClef] at the specified coordinates.
  const PositionedClef({
    required this.x,
    required this.y,
    required this.scale,
    required this.glyph,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double scale;

  /// The clef glyph symbol to be rendered.
  final SmuflGlyph glyph;
}

/// Represents a physically positioned Time Signature change.
class PositionedTimeSignature extends PositionedElement {
  /// Creates a [PositionedTimeSignature] at the specified coordinates.
  const PositionedTimeSignature({
    required this.x,
    required this.y,
    required this.scale,
    required this.beats,
    required this.beatValue,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double scale;

  /// The numerator of the time signature (number of beats in a measure).
  final int beats;

  /// The denominator of the time signature (rhythmic value of each beat).
  final int beatValue;
}

/// Represents a single accidental in a key signature drawn on a staff.
class KeySignatureAccidental {
  /// Creates a key signature accidental placement.
  const KeySignatureAccidental({
    required this.glyph,
    required this.y,
  });

  /// The accidental glyph (flat, sharp, natural).
  final SmuflGlyph glyph;

  /// The absolute Y-coordinate (in millimeters) on the staff.
  final double y;
}

/// Represents a physically positioned Key Signature.
class PositionedKeySignature extends PositionedElement {
  /// Creates a [PositionedKeySignature] with all its positioned accidentals.
  const PositionedKeySignature({
    required this.x,
    required this.y,
    required this.scale,
    required this.accidentals,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double scale;

  /// The list of individual accidentals that comprise this key signature.
  final List<KeySignatureAccidental> accidentals;
}
