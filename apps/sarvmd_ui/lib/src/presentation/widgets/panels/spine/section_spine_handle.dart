// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'section_spine_metrics.dart';

/// The draggable, fader-style scroll thumb handle for the [SectionSpine].
///
/// Features a minimal 8px pill at rest that bulks up to 22px with tactile ribbed lines
/// and drop shadows upon hover or drag.
class SectionSpineHandle extends StatelessWidget {
  const SectionSpineHandle({
    super.key,
    required this.thumbCenterY,
    required this.thumbWidth,
    required this.thumbHeight,
    required this.totalHeight,
    required this.maxWidth,
    required this.isBulked,
    required this.isDragging,
    required this.onHoverChanged,
  });

  final double thumbCenterY;
  final double thumbWidth;
  final double thumbHeight;
  final double totalHeight;
  final double maxWidth;
  final bool isBulked;
  final bool isDragging;
  final ValueChanged<bool> onHoverChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topY = (thumbCenterY - (thumbHeight / 2.0))
        .clamp(20.0, math.max(20.0, totalHeight - 20.0 - thumbHeight))
        .toDouble();
    final leftX = (maxWidth - thumbWidth) / 2.0;

    return Positioned(
      top: topY,
      left: leftX,
      width: thumbWidth,
      height: thumbHeight,
      child: MouseRegion(
        cursor: isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        onEnter: (_) => onHoverChanged(true),
        onExit: (_) => onHoverChanged(false),
        child: AnimatedContainer(
          key: const ValueKey('section_spine_handle'),
          duration: SectionSpineMetrics.hoverAnimationDuration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isBulked
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDragging
                        ? [
                            cs.primary,
                            cs.primary.withValues(alpha: 0.92),
                          ]
                        : [
                            cs.primary.withValues(alpha: 0.82),
                            cs.primary.withValues(alpha: 0.65),
                          ],
                  )
                : null,
            color: isBulked ? null : cs.primary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(
              isBulked
                  ? SectionSpineMetrics.bulkedThumbRadius
                  : SectionSpineMetrics.restingThumbRadius,
            ),
            border: Border.all(
              color: isBulked
                  ? cs.primaryContainer
                  : cs.primary.withValues(alpha: 0.50),
              width: isBulked ? 1.0 : 0.8,
            ),
            boxShadow: isBulked
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(
                          alpha: isDragging ? 0.45 : 0.28),
                      blurRadius: 8.0,
                      spreadRadius: 0.5,
                    ),
                    const BoxShadow(
                      color: Color(0x1F000000),
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                    ),
                  ]
                : null,
          ),
          child: isBulked
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.0,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Container(
                        width: 12.0,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: cs.onPrimary,
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      ),
                      const SizedBox(height: 2.5),
                      Container(
                        width: 8.0,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(1.0),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Container(
                    width: 4.0,
                    height: 2.0,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
