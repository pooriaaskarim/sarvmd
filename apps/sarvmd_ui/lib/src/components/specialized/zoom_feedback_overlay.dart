import 'package:flutter/material.dart';
import '../../theme/app_metrics.dart';

class ZoomFeedbackOverlay extends StatefulWidget {
  const ZoomFeedbackOverlay({super.key, required this.controller});
  final TransformationController controller;

  @override
  State<ZoomFeedbackOverlay> createState() => _ZoomFeedbackOverlayState();
}

class _ZoomFeedbackOverlayState extends State<ZoomFeedbackOverlay> {
  double _scale = 1.0;
  bool _visible = false;
  int _lastTick = 0;

  @override
  void initState() {
    super.initState();
    // storage[0] is the X-axis scale. getMaxScaleOnAxis() would return 1.0
    // when zoom < 100% because Z-scale is always 1.0 and it takes the max.
    _scale = widget.controller.value.storage[0];
    widget.controller.addListener(_onScaleChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScaleChanged);
    super.dispose();
  }

  void _onScaleChanged() {
    final newScale = widget.controller.value.storage[0];
    // Only show if scale actually changed to avoid triggering on pure panning.
    if ((newScale - _scale).abs() > 0.001) {
      setState(() {
        _scale = newScale;
        _visible = true;
      });
      final currentTick = ++_lastTick;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _lastTick == currentTick) {
          setState(() => _visible = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: AppOpacities.border),
            ),
          ),
          child: Text(
            '${(_scale * 100).round()}%',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
