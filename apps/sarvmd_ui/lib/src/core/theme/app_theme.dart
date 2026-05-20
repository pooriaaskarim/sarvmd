import 'package:flutter/material.dart';

/// The four curated accent seeds for SarvMD.
enum SarvAccent {
  lavender,
  lemon,
  sage,
  sky;

  /// The human-readable label shown in the UI.
  String get label => switch (this) {
        SarvAccent.lavender => 'Lavender',
        SarvAccent.lemon => 'Lemon',
        SarvAccent.sage => 'Sage',
        SarvAccent.sky => 'Sky',
      };

  /// The raw seed color (matching the user-supplied swatches).
  Color get seed => switch (this) {
        SarvAccent.lavender => const Color(0xFFE8DFEE),
        SarvAccent.lemon => const Color(0xFFF8F5BE),
        SarvAccent.sage => const Color(0xFFAEC7AD),
        SarvAccent.sky => const Color(0xFFC7DBF1),
      };

  /// A vivid, saturated tone derived from each seed, used as the
  /// `primary` accent in the generated color scheme so that controls
  /// (buttons, sliders, highlights) remain clearly distinguishable.
  /// The primary interactive color. These are high-contrast "Jewel" versions
  /// of the seeds to ensure visibility for text, icons, and thin lines.
  Color get primary => switch (this) {
        SarvAccent.lavender => const Color(0xFF6750A4), // Deep Purple
        SarvAccent.lemon => const Color(0xFF6A6600), // Deep Olive Gold
        SarvAccent.sage => const Color(0xFF2D6A3E), // Deep Forest Green
        SarvAccent.sky => const Color(0xFF00639B), // Deep Sky Blue
      };

  /// The secondary/container color. These use the exact pastel seeds
  /// to provide the "Pastel" aesthetic for large UI surfaces.
  Color get pastelContainer => seed;

  /// High-contrast text color to be used on top of the pastel container.
  Color get onPastelContainer => switch (this) {
        SarvAccent.lavender => const Color(0xFF211044),
        SarvAccent.lemon => const Color(0xFF211B00),
        SarvAccent.sage => const Color(0xFF00210A),
        SarvAccent.sky => const Color(0xFF001D35),
      };

  /// A very faint, warm "paper" tint for the canvas background in light mode.
  Color get paperLight => switch (this) {
        SarvAccent.lavender => const Color(0xFFFBF9FF),
        SarvAccent.lemon => const Color(0xFFFFFDF0),
        SarvAccent.sage => const Color(0xFFF9FBF8),
        SarvAccent.sky => const Color(0xFFF8FBFF),
      };

  /// A deep, slightly tinted neutral for the canvas background in dark mode.
  Color get paperDark => switch (this) {
        SarvAccent.lavender => const Color(0xFF1F1B24),
        SarvAccent.lemon => const Color(0xFF1F1F18),
        SarvAccent.sage => const Color(0xFF181F19),
        SarvAccent.sky => const Color(0xFF181C21),
      };
}

/// Builds a [ThemeData] for a given [SarvAccent] and [Brightness].
///
/// The neutral surface colours are kept intentionally muted so that
/// manuscript content always takes centre stage; the accent colour
/// is applied to interactive controls and highlights only.
abstract final class AppTheme {
  static ThemeData build(SarvAccent accent, Brightness brightness) {
    final scheme = _scheme(accent, brightness);
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      useMaterial3: true,
      fontFamily: 'Roboto',
      // Shared extension for custom colors
      extensions: [
        SarvThemeExtension(
          paperColor: brightness == Brightness.light
              ? accent.paperLight
              : accent.paperDark,
        ),
      ],
    );
  }

  static ColorScheme _scheme(SarvAccent accent, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return _dark(accent);
    }
    return _light(accent);
  }

  // ──────────────────────────────────────────────────────────────────
  // LIGHT variants
  // ──────────────────────────────────────────────────────────────────

  static ColorScheme _light(SarvAccent a) {
    return ColorScheme.light(
      primary: a.primary,
      onPrimary: Colors.white,
      primaryContainer: a.pastelContainer,
      onPrimaryContainer: a.onPastelContainer,
      secondary: a.seed,
      onSecondary: a.onPastelContainer,
      // Sidebar / panel backgrounds
      surface: _lightSurface(a),
      surfaceContainer: _lightContainer(a),
      // Text
      onSurface: const Color(0xFF1A1A1A),
      onSurfaceVariant: const Color(0xFF4A4A4A),
      // Borders
      outline: const Color(0x1F000000), // black 12 %
      outlineVariant: const Color(0x3D000000), // black 24 %
    );
  }

  static Color _lightSurface(SarvAccent a) => switch (a) {
        SarvAccent.lavender => const Color(0xFFF9F7FB),
        SarvAccent.lemon => const Color(0xFFFBFBF6),
        SarvAccent.sage => const Color(0xFFF7F9F7),
        SarvAccent.sky => const Color(0xFFF6F8FB),
      };

  static Color _lightContainer(SarvAccent a) => switch (a) {
        SarvAccent.lavender => const Color(0xFFFCFBFE),
        SarvAccent.lemon => const Color(0xFFFEFEFB),
        SarvAccent.sage => const Color(0xFFFBFEFB),
        SarvAccent.sky => const Color(0xFFFBFEFE),
      };

  // ──────────────────────────────────────────────────────────────────
  // DARK variants
  // ──────────────────────────────────────────────────────────────────

  static ColorScheme _dark(SarvAccent a) {
    return ColorScheme.dark(
      primary: a.primary,
      onPrimary: Colors.white,
      primaryContainer: a.seed.withValues(alpha: 0.2),
      onPrimaryContainer: Colors.white,
      secondary: a.seed.withValues(alpha: 0.5),
      surface: _darkSurface(a),
      surfaceContainer: _darkContainer(a),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white70,
      outline: const Color(0x3DFFFFFF), // white 24 %
      outlineVariant: const Color(0x1FFFFFFF), // white 12 %
    );
  }

  static Color _darkSurface(SarvAccent a) => switch (a) {
        SarvAccent.lavender => const Color(0xFF1B181F),
        SarvAccent.lemon => const Color(0xFF1A1A14),
        SarvAccent.sage => const Color(0xFF141A14),
        SarvAccent.sky => const Color(0xFF14171A),
      };

  static Color _darkContainer(SarvAccent a) => switch (a) {
        SarvAccent.lavender => const Color(0xFF231B2E),
        SarvAccent.lemon => const Color(0xFF26241A),
        SarvAccent.sage => const Color(0xFF1A2419),
        SarvAccent.sky => const Color(0xFF182330),
      };
}

/// Custom theme extension for SarvMD-specific design tokens.
class SarvThemeExtension extends ThemeExtension<SarvThemeExtension> {
  const SarvThemeExtension({required this.paperColor});

  final Color paperColor;

  @override
  SarvThemeExtension copyWith({Color? paperColor}) {
    return SarvThemeExtension(paperColor: paperColor ?? this.paperColor);
  }

  @override
  SarvThemeExtension lerp(ThemeExtension<SarvThemeExtension>? other, double t) {
    if (other is! SarvThemeExtension) return this;
    return SarvThemeExtension(
      paperColor: Color.lerp(paperColor, other.paperColor, t)!,
    );
  }
}
