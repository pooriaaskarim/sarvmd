// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../common/section_header.dart';

/// A professional, highly elegant page margin control widget that adapts fluidly
/// to resizable sidebars using 2x2 quad layouts, capsule fields, and direction-specific icons.
class MarginsSettingsGroup extends StatefulWidget {
  const MarginsSettingsGroup({
    super.key,
    required this.margins,
    required this.onLeftChanged,
    required this.onRightChanged,
    required this.onTopChanged,
    required this.onBottomChanged,
    required this.onHorizontalChanged,
    required this.onVerticalChanged,
    required this.onReset,
    required this.onScrubStart,
    required this.onScrubEnd,
  });

  final core.Margins margins;
  final ValueChanged<double> onLeftChanged;
  final ValueChanged<double> onRightChanged;
  final ValueChanged<double> onTopChanged;
  final ValueChanged<double> onBottomChanged;
  final ValueChanged<double> onHorizontalChanged;
  final ValueChanged<double> onVerticalChanged;
  final VoidCallback onReset;
  final ValueChanged<String> onScrubStart;
  final VoidCallback onScrubEnd;

  @override
  State<MarginsSettingsGroup> createState() => _MarginsSettingsGroupState();
}

class _MarginsSettingsGroupState extends State<MarginsSettingsGroup> {
  bool _isLinked = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(
                title: 'Margins (mm)',
                onReset: widget.onReset,
              ),
            ),
            IconButton(
              icon: Icon(
                _isLinked ? Icons.link : Icons.link_off,
                size: 16,
                color: _isLinked
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              tooltip: _isLinked
                  ? 'Margins Linked (Click to Unlink)'
                  : 'Margins Independent (Click to Link)',
              onPressed: () {
                setState(() {
                  _isLinked = !_isLinked;
                  if (_isLinked) {
                    // Sync values on link (sync Top/Bottom and Left/Right)
                    widget.onHorizontalChanged(widget.margins.left);
                    widget.onVerticalChanged(widget.margins.top);
                  }
                });
              },
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(4),
                minimumSize: Size.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _isLinked
              ? Row(
                  key: const ValueKey('linked_margins_row'),
                  children: [
                    Expanded(
                      child: _ScrubbableField(
                        label: 'Vertical',
                        value: widget.margins.top,
                        min: 5.0,
                        max: 40.0,
                        onChanged: widget.onVerticalChanged,
                        onScrubStart: () => widget.onScrubStart('vertical'),
                        onScrubEnd: widget.onScrubEnd,
                        icon: Icons.swap_vert,
                        shortLabel: 'VERT',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ScrubbableField(
                        label: 'Horizontal',
                        value: widget.margins.left,
                        min: 5.0,
                        max: 40.0,
                        onChanged: widget.onHorizontalChanged,
                        onScrubStart: () => widget.onScrubStart('horizontal'),
                        onScrubEnd: widget.onScrubEnd,
                        icon: Icons.swap_horiz,
                        shortLabel: 'HORZ',
                      ),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('independent_margins_grid'),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ScrubbableField(
                            label: 'Top',
                            value: widget.margins.top,
                            min: 5.0,
                            max: 40.0,
                            onChanged: widget.onTopChanged,
                            onScrubStart: () => widget.onScrubStart('top'),
                            onScrubEnd: widget.onScrubEnd,
                            icon: Icons.vertical_align_top,
                            shortLabel: 'TOP',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ScrubbableField(
                            label: 'Bottom',
                            value: widget.margins.bottom,
                            min: 5.0,
                            max: 40.0,
                            onChanged: widget.onBottomChanged,
                            onScrubStart: () => widget.onScrubStart('bottom'),
                            onScrubEnd: widget.onScrubEnd,
                            icon: Icons.vertical_align_bottom,
                            shortLabel: 'BTM',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ScrubbableField(
                            label: 'Left',
                            value: widget.margins.left,
                            min: 5.0,
                            max: 60.0,
                            onChanged: widget.onLeftChanged,
                            onScrubStart: () => widget.onScrubStart('left'),
                            onScrubEnd: widget.onScrubEnd,
                            icon: Icons.align_horizontal_left,
                            shortLabel: 'LFT',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ScrubbableField(
                            label: 'Right',
                            value: widget.margins.right,
                            min: 5.0,
                            max: 40.0,
                            onChanged: widget.onRightChanged,
                            onScrubStart: () => widget.onScrubStart('right'),
                            onScrubEnd: widget.onScrubEnd,
                            icon: Icons.align_horizontal_right,
                            shortLabel: 'RGT',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// A highly polished, compact properties input widget featuring click-to-edit
/// and mouse-scrubbing interactions inside an integrated capsule card.
class _ScrubbableField extends StatefulWidget {
  const _ScrubbableField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onScrubStart,
    required this.onScrubEnd,
    this.icon,
    this.shortLabel,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback onScrubStart;
  final VoidCallback onScrubEnd;
  final IconData? icon;
  final String? shortLabel;

  @override
  State<_ScrubbableField> createState() => _ScrubbableFieldState();
}

class _ScrubbableFieldState extends State<_ScrubbableField> {
  late final TextEditingController _controller;
  double _dragStartValue = 0.0;
  double _cumulativeDelta = 0.0;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(_ScrubbableField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final parsed = double.tryParse(text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toStringAsFixed(1);
    } else {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onHorizontalDragStart: (details) {
              _dragStartValue = widget.value;
              _cumulativeDelta = 0.0;
              widget.onScrubStart();
            },
            onHorizontalDragUpdate: (details) {
              _cumulativeDelta += details.delta.dx;
              final double newValue = (_dragStartValue + _cumulativeDelta * 0.1)
                  .clamp(widget.min, widget.max);
              widget.onChanged(double.parse(newValue.toStringAsFixed(1)));
            },
            onHorizontalDragEnd: (details) => widget.onScrubEnd(),
            onHorizontalDragCancel: () => widget.onScrubEnd(),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: Tooltip(
                message: '${widget.label}: drag left/right to scrub',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 14,
                          color: _isHovering
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        widget.shortLabel ?? widget.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _isHovering
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 1,
            height: 14,
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
    );
  }
}
