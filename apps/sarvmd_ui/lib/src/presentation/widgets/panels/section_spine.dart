// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../logic/view/view_state.dart';
import 'spine/section_spine_bead.dart';
import 'spine/section_spine_handle.dart';
import 'spine/section_spine_metrics.dart';
import 'spine/section_spine_track.dart';

export 'spine/section_spine_bead.dart' show SectionSpineEntry;
export 'spine/section_spine_metrics.dart';

/// An interactive semantic section scrollbar rail ("The Section Spine").
///
/// Combines visual scroll progress, draggable scrollbar thumb, and section markers into a unified vertical rail:
/// - At rest: Minimal rail with hairline track groove, compact micro-beads, and a sleek 8px handle pill.
/// - Extended (hover / drag): Rail maintains its compact 22px footprint without bulking up.
/// - Handle bulking: Only the handle bulks up (to 22px width with tactile 3-line ribbed grip and grab cursor).
/// - Section synchronization: Piecewise-linear position mapping ensures the handle is physically aligned
///   with the section bead corresponding to what is at the top of the viewport.
/// - Section jump: Clicking any bead smoothly scrolls it to the top without force-expanding collapsed sections.
class SectionSpine extends StatefulWidget {
  const SectionSpine({
    super.key,
    required this.entries,
    required this.scrollController,
    required this.onJumpToSection,
    this.activeSection,
    this.jumpTargetSection,
    this.onActiveSectionChanged,
  });

  final List<SectionSpineEntry> entries;
  final ScrollController scrollController;
  final ValueChanged<SettingsSection> onJumpToSection;
  final SettingsSection? activeSection;
  final SettingsSection? jumpTargetSection;
  final ValueChanged<SettingsSection>? onActiveSectionChanged;

  @override
  State<SectionSpine> createState() => _SectionSpineState();
}

class _SectionSpineState extends State<SectionSpine> {
  bool _isHovered = false;
  bool _isHoveringHandle = false;
  bool _isDragging = false;
  int? _hoveredIndex;
  double _dragOffsetFromThumbCenter = 0.0;
  Timer? _scrollTimer;
  SettingsSection? _detectedSection;
  final Map<SettingsSection, double> _sectionOffsets = {};
  final Map<SettingsSection, double> _knownSectionHeights = {};
  bool _isPostFrameScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSectionOffsets();
        _onScroll();
        _scrollToActiveSectionIfNeeded();
      }
    });
  }

  @override
  void didUpdateWidget(SectionSpine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateSectionOffsets();
          _onScroll();
          _scrollToActiveSectionIfNeeded();
        }
      });
    } else if (widget.jumpTargetSection != null) {
      if (widget.jumpTargetSection != oldWidget.jumpTargetSection) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToActiveSectionIfNeeded();
          }
        });
      }
    } else if (widget.activeSection != oldWidget.activeSection &&
        widget.activeSection != _detectedSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToActiveSectionIfNeeded();
        }
      });
    }
  }

  void _scrollToEntry(
    SectionSpineEntry entry,
    int index, {
    Duration duration = SectionSpineMetrics.scrollDuration,
  }) {
    final ctx = entry.key.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(
        ctx,
        duration: duration,
        curve: SectionSpineMetrics.scrollCurve,
        alignment: 0.0,
      );
    } else if (widget.scrollController.hasClients &&
        widget.scrollController.position.hasContentDimensions &&
        widget.scrollController.position.maxScrollExtent > 0) {
      final offsets = _resolveSectionOffsets(widget.scrollController.position.maxScrollExtent);
      if (index < offsets.length) {
        final target = offsets[index].clamp(0.0, widget.scrollController.position.maxScrollExtent);
        widget.scrollController.animateTo(
          target,
          duration: duration,
          curve: SectionSpineMetrics.scrollCurve,
        );
      }
    }
  }

  void _scrollToActiveSectionIfNeeded() {
    final active = widget.jumpTargetSection ?? widget.activeSection;
    if (active == null ||
        active == SettingsSection.mainMenu ||
        active == SettingsSection.export) {
      return;
    }

    final index = widget.entries.indexWhere((e) => e.section == active);
    if (index < 0) return;

    _scrollToEntry(widget.entries[index], index);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  SettingsSection? _detectActiveSection() {
    if (!widget.scrollController.hasClients || widget.entries.isEmpty) return null;
    final pixels = widget.scrollController.position.pixels;
    final offsets = _resolveSectionOffsets(
      widget.scrollController.position.hasContentDimensions
          ? widget.scrollController.position.maxScrollExtent
          : 0.0,
    );
    if (offsets.length != widget.entries.length) return null;

    int activeIdx = 0;
    for (int i = 0; i < offsets.length; i++) {
      if (pixels >= offsets[i] - 24.0) {
        activeIdx = i;
      } else {
        break;
      }
    }
    return widget.entries[activeIdx].section;
  }

  void _onScroll() {
    if (_isDragging) return;
    if (mounted) {
      setState(() {});
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        final active = _detectActiveSection();
        if (active != null && active != _detectedSection) {
          _detectedSection = active;
          widget.onActiveSectionChanged?.call(active);
        }
      });
    }
  }

  double? _getSectionOffset(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return null;
    final revealed = viewport.getOffsetToReveal(box, 0.0);
    return revealed.offset;
  }

  void _updateSectionOffsets() {
    if (!widget.scrollController.hasClients) return;
    for (final entry in widget.entries) {
      final ctx = entry.key.currentContext;
      if (ctx != null && ctx.mounted) {
        final box = ctx.findRenderObject();
        if (box is RenderBox && box.hasSize && box.size.height > 20.0) {
          _knownSectionHeights[entry.section] = box.size.height;
        }
      }
      final offset = _getSectionOffset(entry.key);
      if (offset != null) {
        _sectionOffsets[entry.section] = offset;
      }
    }
  }

  double _estimateSectionHeight(SectionSpineEntry entry) {
    if (!entry.isExpanded) return 52.0;
    final cached = _knownSectionHeights[entry.section];
    if (cached != null && cached > 50.0) return cached;
    switch (entry.section) {
      case SettingsSection.profiles:
        return 420.0;
      case SettingsSection.pageSetup:
        return 440.0;
      case SettingsSection.margins:
        return 400.0;
      case SettingsSection.staffSpacing:
        return 420.0;
      case SettingsSection.systemHierarchy:
        return 600.0;
      default:
        return 400.0;
    }
  }

  double _getBeadY(int index, int count, double trackHeight) {
    if (count <= 1) return 34.0;
    final usableHeight = math.max(0.0, trackHeight - 20.0);
    final fraction = index / (count - 1);
    return 34.0 + (fraction * usableHeight);
  }

  List<double> _resolveSectionOffsets(double maxScroll) {
    final count = widget.entries.length;
    if (count == 0) return const [];

    final List<double> offsets = [];
    for (int i = 0; i < count; i++) {
      final sec = widget.entries[i].section;
      final measured = _sectionOffsets[sec];
      if (measured != null) {
        offsets.add(measured);
      } else {
        final prev = i > 0 ? offsets[i - 1] : 0.0;
        final estHeight = i > 0 ? _estimateSectionHeight(widget.entries[i - 1]) : 0.0;
        offsets.add(prev + estHeight);
      }
    }

    if (maxScroll > 0 && offsets.isNotEmpty) {
      offsets[0] = 0.0;
      if (offsets.last > maxScroll) {
        final scale = maxScroll / offsets.last;
        for (int i = 1; i < offsets.length; i++) {
          offsets[i] = offsets[i] * scale;
        }
      }
    }

    for (int i = 1; i < offsets.length; i++) {
      if (offsets[i] < offsets[i - 1]) {
        offsets[i] = offsets[i - 1] + 1.0;
      }
    }

    return offsets;
  }

  double _computeThumbCenterY({
    required double currentPixels,
    required List<double> offsets,
    required int count,
    required double trackHeight,
    required double thumbHeight,
    required double maxScroll,
  }) {
    if (count == 0 || trackHeight <= 0) return 24.0 + (thumbHeight / 2.0);
    if (count == 1) return _getBeadY(0, count, trackHeight);

    final firstBeadY = _getBeadY(0, count, trackHeight);
    final lastBeadY = _getBeadY(count - 1, count, trackHeight);
    final trackBottomY = 24.0 + trackHeight - (thumbHeight / 2.0);

    if (currentPixels <= offsets[0]) {
      return firstBeadY;
    }

    for (int i = 0; i < count - 1; i++) {
      final oStart = offsets[i];
      final oEnd = offsets[i + 1];
      if (currentPixels >= oStart && currentPixels <= oEnd) {
        final range = oEnd - oStart;
        final t = range > 0 ? (currentPixels - oStart) / range : 0.0;
        final bStart = _getBeadY(i, count, trackHeight);
        final bEnd = _getBeadY(i + 1, count, trackHeight);
        return bStart + t * (bEnd - bStart);
      }
    }

    if (maxScroll > offsets[count - 1] && trackBottomY > lastBeadY) {
      final t = ((currentPixels - offsets[count - 1]) / (maxScroll - offsets[count - 1])).clamp(0.0, 1.0);
      return lastBeadY + t * (trackBottomY - lastBeadY);
    }

    return lastBeadY;
  }

  double _pixelsFromThumbCenterY({
    required double targetY,
    required List<double> offsets,
    required int count,
    required double trackHeight,
    required double thumbHeight,
    required double maxScroll,
  }) {
    if (count == 0 || maxScroll <= 0) return 0.0;
    if (count == 1) return 0.0;

    final firstBeadY = _getBeadY(0, count, trackHeight);
    final lastBeadY = _getBeadY(count - 1, count, trackHeight);
    final trackBottomY = 24.0 + trackHeight - (thumbHeight / 2.0);

    if (targetY <= firstBeadY) {
      return 0.0;
    }

    for (int i = 0; i < count - 1; i++) {
      final bStart = _getBeadY(i, count, trackHeight);
      final bEnd = _getBeadY(i + 1, count, trackHeight);
      if (targetY >= bStart && targetY <= bEnd) {
        final range = bEnd - bStart;
        final t = range > 0 ? (targetY - bStart) / range : 0.0;
        final oStart = offsets[i];
        final oEnd = offsets[i + 1];
        return (oStart + t * (oEnd - oStart)).clamp(0.0, maxScroll);
      }
    }

    if (targetY > lastBeadY && trackBottomY > lastBeadY && maxScroll > offsets[count - 1]) {
      final t = ((targetY - lastBeadY) / (trackBottomY - lastBeadY)).clamp(0.0, 1.0);
      return (offsets[count - 1] + t * (maxScroll - offsets[count - 1])).clamp(0.0, maxScroll);
    }

    return offsets[count - 1].clamp(0.0, maxScroll);
  }

  void _handleDragStart(
    DragStartDetails details, {
    required double currentThumbCenterY,
    required double thumbHeight,
  }) {
    if (!widget.scrollController.hasClients) return;
    final halfThumb = thumbHeight / 2.0;
    if (details.localPosition.dy >= currentThumbCenterY - halfThumb &&
        details.localPosition.dy <= currentThumbCenterY + halfThumb) {
      _dragOffsetFromThumbCenter = details.localPosition.dy - currentThumbCenterY;
    } else {
      _dragOffsetFromThumbCenter = 0.0;
    }
    setState(() {
      _isDragging = true;
    });
  }

  void _handleDragUpdate(
    DragUpdateDetails details, {
    required List<double> offsets,
    required int count,
    required double trackHeight,
    required double thumbHeight,
    required double maxScroll,
  }) {
    if (!widget.scrollController.hasClients || maxScroll <= 0) return;

    final targetCenterY = details.localPosition.dy - _dragOffsetFromThumbCenter;
    final targetOffset = _pixelsFromThumbCenterY(
      targetY: targetCenterY,
      offsets: offsets,
      count: count,
      trackHeight: trackHeight,
      thumbHeight: thumbHeight,
      maxScroll: maxScroll,
    );
    widget.scrollController.jumpTo(targetOffset);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!mounted) return;
    setState(() {
      _isDragging = false;
    });
    final active = _detectActiveSection();
    if (active != null && active != _detectedSection) {
      _detectedSection = active;
      widget.onActiveSectionChanged?.call(active);
    }
  }

  void _handleTrackTap(
    Offset localPos, {
    required List<double> offsets,
    required int count,
    required double trackHeight,
    required double thumbHeight,
    required double thumbCenterY,
    required double maxScroll,
  }) {
    if (!widget.scrollController.hasClients || maxScroll <= 0) return;

    final halfThumb = thumbHeight / 2.0;
    if (localPos.dy >= thumbCenterY - halfThumb && localPos.dy <= thumbCenterY + halfThumb) {
      return;
    }

    final targetOffset = _pixelsFromThumbCenterY(
      targetY: localPos.dy,
      offsets: offsets,
      count: count,
      trackHeight: trackHeight,
      thumbHeight: thumbHeight,
      maxScroll: maxScroll,
    );

    widget.scrollController.animateTo(
      targetOffset,
      duration: SectionSpineMetrics.trackTapDuration,
      curve: SectionSpineMetrics.scrollCurve,
    );
  }

  void _handleEntryTap(SectionSpineEntry entry, int index, int count) {
    _detectedSection = entry.section;
    widget.onJumpToSection(entry.section);
    _scrollTimer?.cancel();
    _scrollToEntry(entry, index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isHoveredOrDragging = _isHovered || _isDragging;
    final isBulked = isHoveredOrDragging || _isHoveringHandle;

    if (_sectionOffsets.length < widget.entries.length && !_isPostFrameScheduled) {
      _isPostFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isPostFrameScheduled = false;
        if (mounted) _updateSectionOffsets();
      });
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isHoveringHandle = false;
        _hoveredIndex = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: SectionSpineMetrics.railWidth,
        margin: const EdgeInsets.symmetric(vertical: SectionSpineMetrics.railMarginY),
        decoration: BoxDecoration(
          color: isHoveredOrDragging
              ? cs.surfaceContainerHighest.withValues(alpha: 0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(SectionSpineMetrics.railBorderRadius),
          border: Border.all(
            color: isHoveredOrDragging
                ? cs.outlineVariant.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalHeight = constraints.maxHeight;
            final count = widget.entries.length;
            if (count == 0 || totalHeight <= 0) return const SizedBox.shrink();

            final trackHeight = math.max(0.0, totalHeight - (SectionSpineMetrics.trackMarginY * 2.0));

            // Compute dynamic thumb height
            double thumbHeight = 32.0;
            double maxScroll = 0.0;
            double currentPixels = 0.0;
            if (widget.scrollController.hasClients) {
              final pos = widget.scrollController.position;
              if (pos.hasContentDimensions && pos.maxScrollExtent > 0) {
                maxScroll = pos.maxScrollExtent;
                currentPixels = pos.pixels;
                final viewportFraction =
                    (pos.viewportDimension / (pos.viewportDimension + pos.maxScrollExtent))
                        .clamp(0.12, 0.85);
                thumbHeight = (viewportFraction * trackHeight)
                    .clamp(SectionSpineMetrics.minThumbHeight, SectionSpineMetrics.maxThumbHeight);
              }
            }

            final offsets = _resolveSectionOffsets(maxScroll);
            final thumbCenterY = _computeThumbCenterY(
              currentPixels: currentPixels,
              offsets: offsets,
              count: count,
              trackHeight: trackHeight,
              thumbHeight: thumbHeight,
              maxScroll: maxScroll,
            );

            final currentThumbWidth = isBulked
                ? SectionSpineMetrics.bulkedThumbWidth
                : SectionSpineMetrics.restingThumbWidth;
            final currentThumbHeight = isBulked
                ? math.max(SectionSpineMetrics.bulkedMinThumbHeight, thumbHeight)
                : SectionSpineMetrics.restingThumbHeight;

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragStart: (details) => _handleDragStart(
                details,
                currentThumbCenterY: thumbCenterY,
                thumbHeight: currentThumbHeight,
              ),
              onVerticalDragUpdate: (details) => _handleDragUpdate(
                details,
                offsets: offsets,
                count: count,
                trackHeight: trackHeight,
                thumbHeight: currentThumbHeight,
                maxScroll: maxScroll,
              ),
              onVerticalDragEnd: _handleDragEnd,
              onVerticalDragCancel: () {
                if (mounted) setState(() => _isDragging = false);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background Track Groove, Progress Fill, and Boundary Stops
                  SectionSpineTrack(
                    trackHeight: trackHeight,
                    thumbCenterY: thumbCenterY,
                    maxWidth: constraints.maxWidth,
                    isHoveredOrDragging: isHoveredOrDragging,
                    isBulked: isBulked,
                  ),

                  // Track Hit Detector (for clicking on the groove to jump/scroll)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _handleTrackTap(
                        details.localPosition,
                        offsets: offsets,
                        count: count,
                        trackHeight: trackHeight,
                        thumbHeight: currentThumbHeight,
                        thumbCenterY: thumbCenterY,
                        maxScroll: maxScroll,
                      ),
                    ),
                  ),

                  // Dynamic Fader-Style Scroll Thumb Pill
                  if (trackHeight > 0)
                    SectionSpineHandle(
                      thumbCenterY: thumbCenterY,
                      thumbWidth: currentThumbWidth,
                      thumbHeight: currentThumbHeight,
                      totalHeight: totalHeight,
                      maxWidth: constraints.maxWidth,
                      isBulked: isBulked,
                      isDragging: _isDragging,
                      onHoverChanged: (isHovering) => setState(() => _isHoveringHandle = isHovering),
                    ),

                  // Section Anchor Beads
                  ...List.generate(count, (index) {
                    final entry = widget.entries[index];
                    final beadY = _getBeadY(index, count, trackHeight);
                    final currentActive = _detectedSection ?? widget.activeSection;
                    final isActive = currentActive == entry.section;
                    final isItemHovered = _hoveredIndex == index;

                    return SectionSpineBead(
                      entry: entry,
                      index: index,
                      count: count,
                      beadY: beadY,
                      isActive: isActive,
                      isItemHovered: isItemHovered,
                      showTooltip: isHoveredOrDragging && isItemHovered,
                      onTap: () => _handleEntryTap(entry, index, count),
                      onHoverEnter: () => setState(() => _hoveredIndex = index),
                      onHoverExit: () {
                        if (_hoveredIndex == index) {
                          setState(() => _hoveredIndex = null);
                        }
                      },
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
