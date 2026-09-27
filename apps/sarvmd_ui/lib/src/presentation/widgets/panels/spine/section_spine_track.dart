// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'section_spine_metrics.dart';

/// Renders the vertical track groove, illuminated progress fill, and terminal boundary stops.
class SectionSpineTrack extends StatelessWidget {
  const SectionSpineTrack({
    super.key,
    required this.trackHeight,
    required this.thumbCenterY,
    required this.maxWidth,
    required this.isHoveredOrDragging,
    required this.isBulked,
  });

  final double trackHeight;
  final double thumbCenterY;
  final double maxWidth;
  final bool isHoveredOrDragging;
  final bool isBulked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trackLeft = (maxWidth - SectionSpineMetrics.trackWidth) / 2.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Track Groove
        Positioned(
          top: SectionSpineMetrics.trackMarginY,
          bottom: SectionSpineMetrics.trackMarginY,
          left: trackLeft,
          width: SectionSpineMetrics.trackWidth,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.outlineVariant.withValues(alpha: 0.10),
                  cs.outlineVariant.withValues(alpha: isHoveredOrDragging ? 0.35 : 0.18),
                  cs.outlineVariant.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(1.0),
            ),
          ),
        ),

        // Illuminated Active Scroll Fill
        if (trackHeight > 0)
          Positioned(
            top: SectionSpineMetrics.trackMarginY,
            height: (thumbCenterY - SectionSpineMetrics.trackMarginY).clamp(0.0, trackHeight),
            left: trackLeft,
            width: SectionSpineMetrics.trackWidth,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    cs.primary.withValues(alpha: 0.10),
                    cs.primary.withValues(alpha: isBulked ? 0.50 : 0.28),
                  ],
                ),
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),

        // Precision terminal stops at track boundaries
        if (trackHeight > 10) ...[
          Positioned(
            top: SectionSpineMetrics.trackMarginY - 1.0,
            left: (maxWidth - SectionSpineMetrics.terminalStopWidth) / 2.0,
            width: SectionSpineMetrics.terminalStopWidth,
            height: SectionSpineMetrics.terminalStopHeight,
            child: Container(
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
          Positioned(
            top: SectionSpineMetrics.trackMarginY + trackHeight - 0.5,
            left: (maxWidth - SectionSpineMetrics.terminalStopWidth) / 2.0,
            width: SectionSpineMetrics.terminalStopWidth,
            height: SectionSpineMetrics.terminalStopHeight,
            child: Container(
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(1.0),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
