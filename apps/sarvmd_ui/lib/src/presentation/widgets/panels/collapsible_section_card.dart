// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../logic/view/view_state.dart';

/// An interactive, collapsible section card used in SarvMD sidebars.
///
/// Features a prominent header with category icon, section title, optional trailing action
/// (e.g. Reset), and an animated chevron toggle. Expanding/collapsing is smoothly animated
/// with zero visual jumps or overflows.
class CollapsibleSectionCard extends StatefulWidget {
  const CollapsibleSectionCard({
    super.key,
    required this.section,
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
    this.action,
    this.anchorKey,
  });

  final SettingsSection section;
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;
  final Widget? action;
  final GlobalKey? anchorKey;

  @override
  State<CollapsibleSectionCard> createState() => _CollapsibleSectionCardState();
}

class _CollapsibleSectionCardState extends State<CollapsibleSectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _chevronController;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isExpanded ? 0.0 : 0.5,
    );
    _chevronTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(CollapsibleSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _chevronController.reverse();
      } else {
        _chevronController.forward();
      }
    }
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      key: widget.anchorKey,
      margin: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sleek Unboxed Header Row
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              borderRadius: BorderRadius.circular(8.0),
              hoverColor: cs.onSurface.withValues(alpha: 0.05),
              splashColor: cs.primary.withValues(alpha: 0.08),
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // Category Icon Pill (minimalist accent)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.isExpanded
                              ? cs.primary.withValues(alpha: 0.12)
                              : cs.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 14,
                          color: widget.isExpanded ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.itemGapSmall),
                      // Title
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            color: widget.isExpanded ? cs.onSurface : cs.onSurfaceVariant,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                      // Optional Header Action (e.g. Reset)
                      if (widget.action != null) ...[
                        widget.action!,
                        const SizedBox(width: 4.0),
                      ],
                      // Animated Chevron
                      RotationTransition(
                        turns: _chevronTurns,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Collapsible Body with Unboxed Full-Width Spacing
          AnimatedBuilder(
            animation: _chevronController,
            builder: (context, child) {
              final isAnimating = _chevronController.isAnimating;
              return ClipRect(
                clipBehavior: isAnimating ? Clip.hardEdge : Clip.none,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  clipBehavior: isAnimating ? Clip.hardEdge : Clip.none,
                  child: widget.isExpanded
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: 6.0,
                            bottom: 14.0,
                          ),
                          child: widget.child,
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          ),
          // Subtle Hairline Divider between sections
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: cs.outlineVariant.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}
