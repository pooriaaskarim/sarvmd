import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../theme/app_metrics.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StaffSpacingGroup — the top-level widget that composes all four tiers.
// ─────────────────────────────────────────────────────────────────────────────

class StaffSpacingGroup extends StatefulWidget {
  const StaffSpacingGroup({
    super.key,
    required this.staffConfig,
    required this.layoutType,
    required this.onLineGapChanged,
    required this.onSystemGapChanged,
    required this.onInterStaffGapChanged,
  });

  final core.StaffConfig staffConfig;
  final core.LayoutType layoutType;
  final ValueChanged<double> onLineGapChanged;
  final ValueChanged<double> onSystemGapChanged;
  final ValueChanged<double> onInterStaffGapChanged;

  @override
  State<StaffSpacingGroup> createState() => _StaffSpacingGroupState();
}

class _StaffSpacingGroupState extends State<StaffSpacingGroup> {
  bool _isGuidancePinned = false;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final preset =
        core.StaffSizePreset.fromLineGap(widget.staffConfig.lineGapMm);
    final staffHeight = widget.staffConfig.staffHeightMm;
    final isDoubleLine = widget.layoutType == core.LayoutType.doubleLine;
    final showGuidance = _isGuidancePinned || _isHovering;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.itemGap,
      children: [
        // ── Tier 1 & 2: Live Stats Chip with Integrated Preset Dropdown ───
        _LiveStatsChip(
          selectedPreset: preset,
          lineGapMm: widget.staffConfig.lineGapMm,
          staffHeightMm: staffHeight,
          onPresetSelected: (p) => widget.onLineGapChanged(p.lineGapMm),
        ),

        // ── Tier 4: MOLA Status & Guidance (Integrated Section) ──────────
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MolaGuidanceHeader(
              staffHeightMm: staffHeight,
              isPinned: _isGuidancePinned,
              onToggle: () =>
                  setState(() => _isGuidancePinned = !_isGuidancePinned),
              onHover: (hover) => setState(() => _isHovering = hover),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: showGuidance
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: _SpacingGuidanceCard(staffHeightMm: staffHeight),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),

        // ── Tier 3a: Line Gap Slider ──────────────────────────────────────
        _AnnotatedSlider(
          label: 'Line Gap',
          value: widget.staffConfig.lineGapMm,
          min: 1.2,
          max: 3.8,
          unit: 'mm',
          tickPositions:
              core.StaffSizePreset.values.map((p) => p.lineGapMm).toList(),
          onChanged: widget.onLineGapChanged,
        ),

        // ── Tier 3b: System Gap Slider ────────────────────────────────────
        _AnnotatedSlider(
          label: 'System Gap',
          value: widget.staffConfig.systemGapMm,
          min: 8.0,
          max: 35.0,
          unit: 'mm',
          onChanged: widget.onSystemGapChanged,
        ),

        // ── Tier 3c: Staff Gap (Piano) — greyed when not applicable ───────
        _AnnotatedSlider(
          label: 'Staff Gap (Piano)',
          value: widget.staffConfig.interStaffGapMm,
          min: 4.0,
          max: 20.0,
          unit: 'mm',
          enabled: isDoubleLine,
          onChanged: widget.onInterStaffGapChanged,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier 2: Live stats chip + MOLA compliance badge
// ─────────────────────────────────────────────────────────────────────────────

class _LiveStatsChip extends StatelessWidget {
  const _LiveStatsChip({
    required this.selectedPreset,
    required this.lineGapMm,
    required this.staffHeightMm,
    required this.onPresetSelected,
  });

  final core.StaffSizePreset? selectedPreset;
  final double lineGapMm;
  final double staffHeightMm;
  final ValueChanged<core.StaffSizePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rangeTint = _getRangeTint(staffHeightMm);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        children: [
          // ── Preset Selector (Dropdown) ─────────────────────────────────
          PopupMenuButton<core.StaffSizePreset>(
            onSelected: onPresetSelected,
            tooltip: 'Select Staff Size Preset',
            offset: const Offset(0, 42),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => core.StaffSizePreset.values.map((p) {
              final isSelected = p == selectedPreset;
              return PopupMenuItem<core.StaffSizePreset>(
                value: p,
                child: Row(
                  children: [
                    Text(
                      p.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${p.staffHeightMm.toStringAsFixed(1)} mm',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniStaffIcon(color: rangeTint.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Text(
                    selectedPreset?.label ?? 'Custom',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: rangeTint,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      size: 18, color: rangeTint.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),

          // ── Vertical Divider ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),

          // ── Stats Readout (Non-interactive) ────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                      children: [
                        TextSpan(
                          text: staffHeightMm.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: 'mm staff height'),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      children: [
                        TextSpan(
                          text: lineGapMm.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: 'mm line gap'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRangeTint(double h) {
    if (h >= 10.0) return const Color(0xFF7C3AED); // violet
    if (h >= 7.0) return const Color(0xFF059669); // emerald
    if (h >= 5.8) return const Color(0xFFF59E0B); // amber
    return const Color(0xFFEF4444); // red
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New: MOLA Status Toggle (integrated with guidance)
// ─────────────────────────────────────────────────────────────────────────────

class _MolaGuidanceHeader extends StatelessWidget {
  const _MolaGuidanceHeader({
    required this.staffHeightMm,
    required this.isPinned,
    required this.onToggle,
    required this.onHover,
  });

  final double staffHeightMm;
  final bool isPinned;
  final VoidCallback onToggle;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meetsMola = staffHeightMm >= 7.0;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onToggle,
        onLongPressStart: (_) => onHover(true),
        onLongPressEnd: (_) => onHover(false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPinned
                ? cs.primary.withValues(alpha: 0.08)
                : cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPinned
                  ? cs.primary.withValues(alpha: 0.3)
                  : cs.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              // MOLA Badge with Definition Tooltip
              Tooltip(
                message:
                    'MOLA (Major Orchestra Librarians\' Association) is the global benchmark for professional music manuscript. Their standards ensure that notation remains perfectly legible for orchestral players from a music stand distance, even under challenging stage lighting conditions.',
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints.tightFor(width: 320),
                showDuration: const Duration(seconds: 5),
                triggerMode:
                    TooltipTriggerMode.longPress, // Works for hover too
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outlineVariant, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                textStyle: TextStyle(
                  color: cs.onSurface,
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: meetsMola
                        ? const Color(0xFF059669).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: meetsMola
                          ? const Color(0xFF059669).withValues(alpha: 0.3)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Icon(
                        meetsMola
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        size: 10,
                        color: meetsMola
                            ? const Color(0xFF059669)
                            : const Color(0xFFF59E0B),
                      ),
                      Text(
                        'MOLA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: meetsMola
                              ? const Color(0xFF059669)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                isPinned ? 'Hide Details' : 'Pin Details',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPinned ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              // const Spacer(),
              Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 16,
                color: isPinned
                    ? cs.primary
                    : cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tiny 5-line staff drawn inline
class _MiniStaffIcon extends StatelessWidget {
  const _MiniStaffIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 14,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          5,
          (_) => Container(
            height: 0.9,
            width: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier 3: Slider with label, numeric field, optional tick marks, and
// optional disabled state.
// ─────────────────────────────────────────────────────────────────────────────

class _AnnotatedSlider extends StatefulWidget {
  const _AnnotatedSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.tickPositions,
    this.enabled = true,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;
  final List<double>?
      tickPositions; // positions to draw tick marks on the track
  final bool enabled;

  @override
  State<_AnnotatedSlider> createState() => _AnnotatedSliderState();
}

class _AnnotatedSliderState extends State<_AnnotatedSlider> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(2));
  }

  @override
  void didUpdateWidget(_AnnotatedSlider old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String? text) {
    if (text == null) return;
    final parsed = double.tryParse(text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toStringAsFixed(2);
    } else {
      _controller.text = widget.value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabledAlpha = widget.enabled ? 1.0 : AppOpacities.disabled;

    return Opacity(
      opacity: enabledAlpha,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            // ── Label + numeric field ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  width: 62,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: cs.outline.withValues(alpha: 0.5)),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onSubmitted: _submit,
                    onTapOutside: (_) {
                      _submit(_controller.text);
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
              ],
            ),

            // ── Slider ───────────────────────────────────────────────
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.10),
                thumbColor: cs.primary,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Slider(
                  value: widget.value.clamp(widget.min, widget.max),
                  min: widget.min,
                  max: widget.max,
                  onChanged: widget.enabled ? widget.onChanged : null,
                ),
              ),
            ),

            // ── Tick labels ──────────────────────────────────────────
            if (widget.tickPositions != null)
              _TickLabels(
                min: widget.min,
                max: widget.max,
                ticks: widget.tickPositions!,
                currentValue: widget.value,
              ),
          ],
        ),
      ),
    );
  }
}

// Renders tick mark labels under the slider track
class _TickLabels extends StatelessWidget {
  const _TickLabels({
    required this.min,
    required this.max,
    required this.ticks,
    required this.currentValue,
  });

  final double min;
  final double max;
  final List<double> ticks;
  final double currentValue;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // We match the Slider's internal geometry.
    // Slider horizontal margin is roughly 24 (12 padding from our wrapper + 12 overlay radius)
    const totalHPad = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final trackWidth = availableWidth - totalHPad * 2;

        return SizedBox(
          height: 18,
          child: Stack(
            children: ticks.map((t) {
              final fraction = (t - min) / (max - min);
              // Center the label at the fraction of the track
              final x = totalHPad + fraction * trackWidth;

              final isActive = (t - currentValue).abs() < 0.001;
              return Positioned(
                left: x - 14, // centre a 28-wide label
                width: 28,
                child: Text(
                  t.toStringAsFixed(t == t.roundToDouble() ? 0 : 2),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                    color: isActive
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.4),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier 4: Adaptive guidance card — message changes based on staff height
// ─────────────────────────────────────────────────────────────────────────────

class _SpacingGuidanceCard extends StatelessWidget {
  const _SpacingGuidanceCard({required this.staffHeightMm});
  final double staffHeightMm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, title, message, tint) = _context(staffHeightMm);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tint.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(icon, size: 14, color: tint.withValues(alpha: 0.9)),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: tint.withValues(alpha: 0.9),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, String, Color) _context(double h) {
    if (h >= 10.0) {
      return (
        Icons.school_rounded,
        'Educational Standard',
        'Ideal for children\'s "Teaching Pieces" and beginners. The large scale supports developing motor skills and clear visual recognition of intervals.',
        const Color(0xFF7C3AED), // violet
      );
    } else if (h >= 7.0) {
      return (
        Icons.check_circle_outline_rounded,
        'Professional Performance',
        'Meets the gold standard for orchestral performance. Excellent for handwriting and ensures parts remain clear for players on a busy music stand.',
        const Color(0xFF059669), // emerald
      );
    } else if (h >= 5.8) {
      return (
        Icons.info_outline_rounded,
        'Study & Piano Scores',
        'Optimized for private study and piano scores where space is limited. Note that this scale is below the minimum recommended for professional orchestral parts.',
        const Color(0xFFF59E0B), // amber
      );
    } else {
      return (
        Icons.warning_amber_rounded,
        'Technical Score Only',
        'Below the practical handwriting limit. Engraving at this scale is suitable for printed pocket scores, but becomes difficult to notate by hand (sharps and ornaments collide).',
        const Color(0xFFEF4444), // red
      );
    }
  }
}
