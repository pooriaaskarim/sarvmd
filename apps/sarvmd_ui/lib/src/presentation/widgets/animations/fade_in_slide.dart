import 'package:flutter/material.dart';

/// A wrapper widget that provides a staggered fade-and-slide entry animation.
///
/// [delay] is an integer used to stagger multiple items. Higher values
/// will start the animation later.
class FadeInSlide extends StatelessWidget {
  const FadeInSlide({
    super.key,
    required this.delay,
    required this.child,
  });

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        // Robust stagger math: ensures all items eventually reach 100% opacity.
        // Each delay unit shifts the start by approximately 30ms (0.05 * 600ms).
        final stagger = delay * 0.05;
        final effectiveValue =
            ((value - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);

        return Opacity(
          opacity: effectiveValue,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - effectiveValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
