import 'package:flutter/painting.dart';

// App Metrics
class AppSpacing {
  static const double sectionGap = 32.0;
  static const double itemGap = 12.0;
  static const double itemGapSmall = 8.0;
  static const double headerBottom = 12.0;
  static const double paddingLarge = 24.0;
  static const double paddingMedium = 16.0;
  static const double paddingSmall = 12.0;

  /// Generous scroll padding for text fields to guarantee comfortable clearance
  /// above on-screen software keyboards on mobile and touch form factors.
  static const EdgeInsets keyboardScrollPadding = EdgeInsets.only(
    bottom: 64.0,
    top: 24.0,
    left: 20.0,
    right: 20.0,
  );
}

class AppOpacities {
  static const double hover = 0.1;
  static const double highlight = 0.2;
  static const double border = 0.05;
  static const double divider = 0.25;
  static const double disabled = 0.4;
  static const double surfaceHint = 0.5;
  static const double surfaceEmphasized = 0.6;
}

class ScaleMetrics {
  static const double minZoom = 0.15; // 15%
  static const double maxZoom = 6.0; // 600%
  static const double defaultZoom = 1.0; // 100%
}
