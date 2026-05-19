// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

class SarvSplashScreen extends StatefulWidget {
  const SarvSplashScreen({
    super.key,
    required this.statusText,
    required this.progress,
    required this.accent,
    required this.brightness,
  });

  final String statusText;
  final double progress; // 0.0 to 1.0 for load progress
  final SarvAccent accent;
  final Brightness brightness;

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

    // Highly synchronized, snappy calligraphic animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _strokeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOutCubic),
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
    final isDark = theme.brightness == Brightness.dark;
    
    // Resolve theme colors dynamically from context for 100% visual color continuity
    final paperColor = theme.extension<SarvThemeExtension>()?.paperColor ??
        (isDark ? widget.accent.paperDark : widget.accent.paperLight);
    
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final mutedTextColor = theme.colorScheme.onSurfaceVariant;

    // Responsive scaling based on viewport size
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final scaleFactor = (screenWidth / 1200.0).clamp(0.85, 1.3);

    final logoHeight = 72.0 * scaleFactor;
    final strokeWidth = 200.0 * scaleFactor;
    final subtitleFontSize = 22.0 * scaleFactor;
    final versionFontSize = 10.0 * scaleFactor;

    return Scaffold(
      backgroundColor: paperColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
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
                  const SizedBox(height: 12),
                  // Animated calligraphic accent line drawing under the logo
                  AnimatedBuilder(
                    animation: _strokeAnimation,
                    builder: (context, _) {
                      return SizedBox(
                        width: strokeWidth,
                        height: 10,
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
                  const SizedBox(height: 12),
                  // IranNastaliq calligraphy subtitle
                  FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: Text(
                      'Manuscript Designer',
                      style: TextStyle(
                        fontFamily: 'IranNastaliq',
                        fontSize: subtitleFontSize,
                        color: primaryColor.withValues(alpha: 0.85),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Quiet, premium version label at the very bottom
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'SARVMD  •  v1.0.0',
                  style: TextStyle(
                    fontSize: versionFontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4.0 * scaleFactor,
                    color: mutedTextColor,
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

    final totalHalfWidth = w * 0.45; // Extend line symmetrically
    final leftX = cx - (totalHalfWidth * progress);
    final rightX = cx + (totalHalfWidth * progress);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scaleFactor
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(cx, cy);

    // Draw left calligraphic stroke with a slight organic curve
    path.quadraticBezierTo(
      cx - (totalHalfWidth * progress * 0.5),
      cy - 1.5 * progress * scaleFactor,
      leftX,
      cy,
    );

    // Draw right calligraphic stroke symmetrically
    path.moveTo(cx, cy);
    path.quadraticBezierTo(
      cx + (totalHalfWidth * progress * 0.5),
      cy - 1.5 * progress * scaleFactor,
      rightX,
      cy,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CalligraphicStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}
