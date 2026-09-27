// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../logic/view/view_state.dart';
import 'section_spine_metrics.dart';

/// Data descriptor for an entry on the [SectionSpine].
class SectionSpineEntry {
  const SectionSpineEntry({
    required this.section,
    required this.label,
    required this.icon,
    required this.key,
    required this.isExpanded,
  });

  final SettingsSection section;
  final String label;
  final IconData icon;
  final GlobalKey key;
  final bool isExpanded;
}

/// An interactive section anchor jewel bead with hover scale and floating frosted-glass tooltip.
class SectionSpineBead extends StatelessWidget {
  const SectionSpineBead({
    super.key,
    required this.entry,
    required this.index,
    required this.count,
    required this.beadY,
    required this.isActive,
    required this.isItemHovered,
    required this.showTooltip,
    required this.onTap,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  final SectionSpineEntry entry;
  final int index;
  final int count;
  final double beadY;
  final bool isActive;
  final bool isItemHovered;
  final bool showTooltip;
  final VoidCallback onTap;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      top: beadY - (SectionSpineMetrics.beadHitHeight / 2.0),
      left: 0,
      right: 0,
      height: SectionSpineMetrics.beadHitHeight,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHoverEnter(),
        onExit: (_) => onHoverExit(),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Floating Tooltip Badge on Hover (projects to the right of left-docked rail)
                if (showTooltip)
                  SectionSpineTooltip(
                    entry: entry,
                    index: index,
                    isActive: isActive,
                    onTap: onTap,
                  ),

                // Bead Graphic with Tactile Hover Scale
                AnimatedScale(
                  scale: isItemHovered ? 1.15 : 1.0,
                  duration: SectionSpineMetrics.hoverAnimationDuration,
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: SectionSpineMetrics.beadSize,
                    height: SectionSpineMetrics.beadSize,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                cs.primary,
                                cs.primary.withValues(alpha: 0.88),
                              ],
                            )
                          : null,
                      color: isActive
                          ? null
                          : (entry.isExpanded
                              ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                              : cs.surfaceContainerHigh.withValues(alpha: 0.30)),
                      borderRadius: BorderRadius.circular(SectionSpineMetrics.beadBorderRadius),
                      border: Border.all(
                        color: isActive
                            ? cs.primaryContainer.withValues(alpha: 0.9)
                            : (entry.isExpanded
                                ? cs.outlineVariant.withValues(alpha: 0.40)
                                : cs.outlineVariant.withValues(alpha: 0.18)),
                        width: 0.8,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.45),
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        entry.icon,
                        size: SectionSpineMetrics.beadIconSize,
                        color: isActive
                            ? cs.onPrimary
                            : (entry.isExpanded
                                ? cs.primary
                                : cs.onSurfaceVariant.withValues(alpha: 0.70)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass floating tooltip badge displaying section index, icon, label, and fold state.
class SectionSpineTooltip extends StatelessWidget {
  const SectionSpineTooltip({
    super.key,
    required this.entry,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  final SectionSpineEntry entry;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Positioned(
      left: SectionSpineMetrics.tooltipOffsetLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SectionSpineMetrics.tooltipBorderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: SectionSpineMetrics.tooltipBlurSigma,
            sigmaY: SectionSpineMetrics.tooltipBlurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.surfaceContainerHighest.withValues(alpha: 0.96),
                  cs.surfaceContainerHigh.withValues(alpha: 0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(SectionSpineMetrics.tooltipBorderRadius),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.75),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x38000000), // Colors.black with alpha 0.22
                  blurRadius: 14.0,
                  offset: Offset(4, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(SectionSpineMetrics.tooltipBorderRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left vertical accent indicator notch
                      Container(
                        width: 2.5,
                        height: 14.0,
                        decoration: BoxDecoration(
                          color: isActive ? cs.primary : cs.outlineVariant,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Section numerical index tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                        child: Text(
                          '0${index + 1}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7.0),
                      Icon(
                        entry.icon,
                        size: 13.0,
                        color: isActive ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        entry.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      if (!entry.isExpanded) ...[
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3.5),
                          ),
                          child: Text(
                            'folded',
                            style: TextStyle(
                              fontSize: 9.0,
                              fontStyle: FontStyle.italic,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
