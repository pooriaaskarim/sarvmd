// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

/// Reusable premium dual-control slider with precision numeric spinners.
class PrecisionNumericSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final int fractionDigits;
  final ValueChanged<double> onChanged;

  const PrecisionNumericSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1.0,
    this.fractionDigits = 0,
    required this.onChanged,
  });

  @override
  State<PrecisionNumericSlider> createState() => _PrecisionNumericSliderState();
}

class _PrecisionNumericSliderState extends State<PrecisionNumericSlider> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant PrecisionNumericSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _textController.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    return val.toStringAsFixed(widget.fractionDigits);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _textController.text = _formatValue(widget.value);
    }
  }

  void _updateValue(double newValue) {
    final clamped = newValue.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
    if (_focusNode.hasFocus) {
      final formatted = _formatValue(clamped);
      if (_textController.text != formatted) {
        _textController.text = formatted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_formatValue(widget.value)} pt',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: theme.colorScheme.primary,
                  inactiveTrackColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                  thumbColor: theme.colorScheme.primary,
                  overlayColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  valueIndicatorColor: theme.colorScheme.primary,
                ),
                child: Slider(
                  min: widget.min,
                  max: widget.max,
                  value: widget.value,
                  onChanged: (val) {
                    _updateValue(val);
                    if (!_focusNode.hasFocus) {
                      _textController.text = _formatValue(val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 14),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final target = widget.value - widget.step;
                      _updateValue(target);
                      _textController.text =
                          _formatValue(target.clamp(widget.min, widget.max));
                    },
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(
                    width: 38,
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        if (text.isEmpty) return;
                        final parsed = double.tryParse(text);
                        if (parsed != null) {
                          widget
                              .onChanged(parsed.clamp(widget.min, widget.max));
                        }
                      },
                      onSubmitted: (text) {
                        if (text.isEmpty) {
                          _textController.text = _formatValue(widget.value);
                          return;
                        }
                        final parsed = double.tryParse(text);
                        _updateValue(parsed ?? widget.value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 14),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final target = widget.value + widget.step;
                      _updateValue(target);
                      _textController.text =
                          _formatValue(target.clamp(widget.min, widget.max));
                    },
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
