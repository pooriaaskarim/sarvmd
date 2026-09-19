// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Extension providing SMuFL (Standard Music Font Layout) glyph mappings for UI rendering.
extension ClefSymbolSMuFLExtension on core.ClefSymbol {
  /// The SMuFL Unicode character for this clef symbol.
  /// Returns empty string for unpitched/text clefs like TAB and Percussion.
  String get smuflGlyph => switch (this) {
        core.ClefSymbol.g => '\u{E050}',
        core.ClefSymbol.c => '\u{E05C}',
        core.ClefSymbol.f => '\u{E062}',
        _ => '',
      };
}

/// SMuFL Unicode constants for standard musical font characters.
abstract final class SMuFLGlyphs {
  /// Standard system brace glyph.
  static const String brace = '\u{E000}';

  /// G-clef (Treble clef) glyph.
  static const String gClef = '\u{E050}';

  /// C-clef (Alto/Tenor clef) glyph.
  static const String cClef = '\u{E05C}';

  /// F-clef (Bass clef) glyph.
  static const String fClef = '\u{E062}';
}
