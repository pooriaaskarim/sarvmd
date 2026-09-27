// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../core/theme/app_metrics.dart';
import '../common/integrated_scale_control.dart';

/// Calculation result containing scale factor, translation offsets, and the corresponding transform matrix.
class CanvasZoomTransform {
  const CanvasZoomTransform({
    required this.scale,
    required this.dx,
    required this.dy,
    required this.matrix,
  });

  final double scale;
  final double dx;
  final double dy;
  final Matrix4 matrix;
}

/// Standardized calculation utility for canvas zoom presets and viewport centering.
abstract final class CanvasZoomCalculator {
  /// Internal canvas coordinate scale in logical pixels per millimeter (96 dpi / 25.4 mm).
  static const double lpmm = 96.0 / 25.4;

  /// Default physical ruler strip dimension in logical pixels.
  static const double defaultRulerSize = 25.0;

  /// Computes the exact zoom scale factor and translation matrix for a given preset and viewport layout.
  static CanvasZoomTransform compute({
    required ZoomPreset preset,
    required BoxConstraints constraints,
    required core.PageConfig config,
    required double calibrationFactor,
    double rulerSize = defaultRulerSize,
    double padding = 40.0,
    double topSafeArea = 0.0,
    double leftSafeArea = 0.0,
    double bottomPadding = 0.0,
  }) {
    final paperWidth = config.effectiveWidth * lpmm;
    final paperHeight = config.effectiveHeight * lpmm;

    final totalRulerWidth = rulerSize + leftSafeArea;
    final totalRulerHeight = rulerSize + topSafeArea;
    final canvasWidth = constraints.maxWidth - totalRulerWidth;
    final canvasHeight = constraints.maxHeight - totalRulerHeight - bottomPadding;
    final availableWidth = (canvasWidth - padding * 2).clamp(1.0, double.infinity);
    final availableHeight = (canvasHeight - padding * 2).clamp(1.0, double.infinity);

    double fitScale;

    switch (preset) {
      case ZoomPreset.actualSize:
        fitScale = calibrationFactor.clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
      case ZoomPreset.fitWidth:
        fitScale = (availableWidth / paperWidth).clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
      case ZoomPreset.fitScreen:
        final scaleX = availableWidth / paperWidth;
        final scaleY = availableHeight / paperHeight;
        fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
    }

    final double dx = (canvasWidth - paperWidth * fitScale) / 2;
    double dy;

    if (preset == ZoomPreset.fitScreen) {
      dy = (canvasHeight - paperHeight * fitScale) / 2;
    } else {
      final scaledHeight = paperHeight * fitScale;
      if (scaledHeight < availableHeight) {
        dy = (canvasHeight - scaledHeight) / 2;
      } else {
        dy = padding;
      }
    }

    final matrix = Matrix4.translationValues(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(fitScale, fitScale, 1.0));

    return CanvasZoomTransform(
      scale: fitScale,
      dx: dx,
      dy: dy,
      matrix: matrix,
    );
  }
}
