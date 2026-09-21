// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Extension providing SMuFL (Standard Music Font Layout) glyph mappings for UI rendering.
extension ClefSymbolSMuFLExtension on core.ClefSymbol {
  /// The SMuFL Unicode character for this clef symbol.
  String get smuflGlyph => switch (this) {
        core.ClefSymbol.g => SMuFLGlyphs.gClef,
        core.ClefSymbol.c => SMuFLGlyphs.cClef,
        core.ClefSymbol.f => SMuFLGlyphs.fClef,
        core.ClefSymbol.tab => SMuFLGlyphs.tabClef6,
        core.ClefSymbol.percussion => SMuFLGlyphs.percussionClef,
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

  /// 6-string TAB clef glyph. SMuFL: `6stringTabClef` (U+E06D).
  static const String tabClef6 = '\u{E06D}';

  /// 4-string TAB clef glyph. SMuFL: `4stringTabClef` (U+E06E).
  static const String tabClef4 = '\u{E06E}';

  /// Semipitched percussion clef 1. SMuFL: `semipitchedPercussionClef1` (U+E069).
  static const String percussionClef = '\u{E069}';
}
