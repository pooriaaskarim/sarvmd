// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/animation.dart';

/// Layout, typography, and animation constants for the [SectionSpine] rail.
abstract final class SectionSpineMetrics {
  // Rail dimensions
  static const double railWidth = 22.0;
  static const double railBorderRadius = 11.0;
  static const double railMarginY = 14.0;

  // Track groove & boundary stops
  static const double trackMarginY = 24.0;
  static const double trackWidth = 2.0;
  static const double terminalStopWidth = 6.0;
  static const double terminalStopHeight = 1.5;

  // Fader Thumb / Handle dimensions
  static const double restingThumbWidth = 8.0;
  static const double bulkedThumbWidth = 22.0;
  static const double restingThumbHeight = 24.0;
  static const double bulkedMinThumbHeight = 30.0;
  static const double minThumbHeight = 28.0;
  static const double maxThumbHeight = 90.0;
  static const double restingThumbRadius = 4.0;
  static const double bulkedThumbRadius = 7.0;

  // Anchor Beads
  static const double beadSize = 18.0;
  static const double beadHitHeight = 28.0;
  static const double beadIconSize = 10.5;
  static const double beadBorderRadius = 5.5;

  // Tooltip
  static const double tooltipOffsetLeft = 30.0;
  static const double tooltipBorderRadius = 10.0;
  static const double tooltipBlurSigma = 12.0;

  // Animations & Physics
  static const Duration scrollDuration = Duration(milliseconds: 320);
  static const Duration trackTapDuration = Duration(milliseconds: 220);
  static const Duration hoverAnimationDuration = Duration(milliseconds: 140);
  static const Curve scrollCurve = Curves.easeOutCubic;
}
