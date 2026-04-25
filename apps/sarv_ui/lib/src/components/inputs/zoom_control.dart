import 'package:flutter/material.dart';

class ZoomControl extends StatefulWidget {
  const ZoomControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onFit,
    required this.min,
    required this.max,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onFit;
  final double min;
  final double max;

  @override
  State<ZoomControl> createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(ZoomControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _formatValue(widget.value);
    }
  }

  String _formatValue(double value) {
    return '${(value * 100).round()}%';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String? text) {
    if (text == null) return;
    
    // Remove the '%' if present
    final cleanText = text.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleanText);
    
    if (parsed != null) {
      final decimalValue = parsed / 100.0;
      final clamped = decimalValue.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = _formatValue(clamped);
    } else {
      _controller.text = _formatValue(widget.value);
    }
  }

  void _zoomIn() {
    // Zoom in standard steps
    final steps = [0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0];
    double next = steps.firstWhere((s) => s > widget.value + 0.01, orElse: () => widget.max);
    widget.onChanged(next.clamp(widget.min, widget.max));
  }

  void _zoomOut() {
    // Zoom out standard steps
    final steps = [0.1, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0].reversed;
    double next = steps.firstWhere((s) => s < widget.value - 0.01, orElse: () => widget.min);
    widget.onChanged(next.clamp(widget.min, widget.max));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Tooltip(
              message: 'Zoom Out',
              child: IconButton(
                icon: Icon(Icons.remove,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 16),
                onPressed: _zoomOut,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600),
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
            Tooltip(
              message: 'Zoom In',
              child: IconButton(
                icon: Icon(Icons.add,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 16),
                onPressed: _zoomIn,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ],
        ),
        Tooltip(
          message: 'Fit to Viewport',
          child: TextButton.icon(
            onPressed: widget.onFit,
            icon: const Icon(Icons.fit_screen, size: 14),
            label: const Text('Fit', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
