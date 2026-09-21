// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

/// Centralized brand assets, Hero tags, and typography token constants for SarvMD.
abstract class AppBrand {
  /// Primary handwriting SVG vector logo asset path.
  static const String logoHandwritingSvg =
      'assets/handwriting/Sarv Handwriting.svg';

  /// Standard untranslated brand tagline exception.
  static const String tagline = 'Manuscript Designer';

  /// Standard Hero shared element animation tag for the main brand logo.
  static const String heroTagLogo = 'sarv_brand_logo';

  /// Hero shared element animation tag for the compact menu brand logo.
  static const String heroTagMenuLogo = 'sarv_brand_logo_menu';

  /// Hero shared element animation tag for the brand subtitle text.
  static const String heroTagSubtitle = 'sarv_brand_subtitle';

  /// Standard default logo height across header bars.
  static const double defaultLogoHeight = 26.0;

  /// Large splash screen logo height baseline.
  static const double splashLogoHeight = 84.0;
}
