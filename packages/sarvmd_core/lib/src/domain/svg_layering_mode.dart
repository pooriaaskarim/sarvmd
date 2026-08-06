// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Defines how SVG element groups (layers) are organized in exported SVG files.
enum SvgLayeringMode {
  /// Elements grouped globally by type across the entire page
  /// (Page Background, System Structure, Staff Lines, Barlines, Clefs & Signatures, Notation).
  flatByCategory,

  /// Elements grouped by System and Staff first, then by element category inside each system.
  hierarchicalBySystem,

  /// Unwrapped single-group layout without SVG layer group tags (minimal output).
  none;

  /// Human-readable label for UI options.
  String get label => switch (this) {
        flatByCategory => 'Flat (by Category)',
        hierarchicalBySystem => 'Hierarchical (by System)',
        none => 'Minimal (No Layers)',
      };
}
