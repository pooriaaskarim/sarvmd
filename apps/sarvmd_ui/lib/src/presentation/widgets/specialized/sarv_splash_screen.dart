// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_theme.dart';

/// A calligraphic, theme-aware landing and splash screen for SarvMD.
///
/// Combines the brand handwriting vector logo with an animated organic calligraphic
/// underline stroke, theme paper background, and bilingual typography.
class SarvSplashScreen extends StatefulWidget {
  const SarvSplashScreen({
    super.key,
    required this.accent,
    required this.brightness,
    this.isPersian = false,
    this.statusText,
    this.progress,
  });

  final SarvAccent accent;
  final Brightness brightness;
  final bool isPersian;
  final String? statusText;
  final double? progress;

  @override
  State<SarvSplashScreen> createState() => _SarvSplashScreenState();
}

class _SarvSplashScreenState extends State<SarvSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _strokeAnimation;
  late Animation<double> _subtitleFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _strokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.brightness == Brightness.dark;

    // Resolve paper background color from SarvThemeExtension or accent defaults
    final paperColor = theme.extension<SarvThemeExtension>()?.paperColor ??
        (isDark ? widget.accent.paperDark : widget.accent.paperLight);

    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final mutedTextColor = theme.colorScheme.onSurfaceVariant;

    // Responsive scaling based on viewport size
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final scaleFactor = (screenWidth / 1200.0).clamp(0.85, 1.3);

    final logoHeight = 76.0 * scaleFactor;
    final strokeWidth = 220.0 * scaleFactor;
    final versionFontSize = 10.0 * scaleFactor;

    final subtitleText = widget.isPersian ? 'دست‌نویس نگار موسیقی' : 'Manuscript Designer';

    return Scaffold(
      backgroundColor: paperColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Official calligraphic handwriting logo
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: SvgPicture.asset(
                      'assets/handwriting/Sarv Handwriting.svg',
                      height: logoHeight,
                      colorFilter: ColorFilter.mode(
                        onSurfaceColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Animated calligraphic bezier stroke line under the logo
                  AnimatedBuilder(
                    animation: _strokeAnimation,
                    builder: (context, _) {
                      return SizedBox(
                        width: strokeWidth,
                        height: 12,
                        child: CustomPaint(
                          painter: _CalligraphicStrokePainter(
                            progress: _strokeAnimation.value,
                            color: primaryColor,
                            scaleFactor: scaleFactor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // Subtitle Calligraphy
                  FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: Text(
                      subtitleText,
                      style: widget.isPersian
                          ? TextStyle(
                              fontFamily: 'IranNastaliq',
                              fontSize: 26.0 * scaleFactor,
                              color: primaryColor.withValues(alpha: 0.88),
                              height: 1.3,
                            )
                          : TextStyle(
                              fontSize: 14.0 * scaleFactor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0 * scaleFactor,
                              color: primaryColor.withValues(alpha: 0.88),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Quiet, technical version readout at bottom
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _subtitleFadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.statusText != null) ...[
                        Text(
                          widget.statusText!,
                          style: TextStyle(
                            fontSize: 11.0 * scaleFactor,
                            color: mutedTextColor.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        'SARVMD  •  v1.0.0',
                        style: TextStyle(
                          fontSize: versionFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4.0 * scaleFactor,
                          color: mutedTextColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter that draws an organic calligraphic stroke expanding symmetrically outward.
class _CalligraphicStrokePainter extends CustomPainter {
  const _CalligraphicStrokePainter({
    required this.progress,
    required this.color,
    required this.scaleFactor,
  });

  final double progress;
  final Color color;
  final double scaleFactor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final totalHalfWidth = w * 0.45;
    final leftX = cx - (totalHalfWidth * progress);
    final rightX = cx + (totalHalfWidth * progress);

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scaleFactor
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(cx, cy);

    // Symmetrical organic curves tracing outward
    path.quadraticBezierTo(
      cx - (totalHalfWidth * progress * 0.5),
      cy - 2.0 * progress * scaleFactor,
      leftX,
      cy,
    );

    path.moveTo(cx, cy);
    path.quadraticBezierTo(
      cx + (totalHalfWidth * progress * 0.5),
      cy - 2.0 * progress * scaleFactor,
      rightX,
      cy,
    );

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CalligraphicStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}
