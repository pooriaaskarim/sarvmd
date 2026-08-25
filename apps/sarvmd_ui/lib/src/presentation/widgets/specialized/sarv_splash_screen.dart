// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/services/changelog_service.dart';

/// A calligraphic, theme-aware landing and splash screen for SarvMD.
///
/// Combines the brand handwriting vector logo with dynamic version indicators,
/// theme paper background, and Hero shared-element transition support.
class SarvSplashScreen extends StatefulWidget {
  const SarvSplashScreen({
    super.key,
    required this.accent,
    required this.brightness,
    this.isPersian = false,
    this.statusText,
    this.progress,
    this.version,
  });

  final SarvAccent accent;
  final Brightness brightness;
  final bool isPersian;
  final String? statusText;
  final double? progress;
  final String? version;

  @override
  State<SarvSplashScreen> createState() => _SarvSplashScreenState();
}

class _SarvSplashScreenState extends State<SarvSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _subtitleFadeAnimation;
  String _displayVersion = AppVersion.version;

  @override
  void initState() {
    super.initState();
    if (widget.version != null && widget.version!.isNotEmpty) {
      _displayVersion = widget.version!;
    } else {
      _resolveVersion();
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOut),
      ),
    );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.30, 0.90, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
  }

  Future<void> _resolveVersion() async {
    final v = await ChangelogService.getLatestVersion();
    if (mounted) {
      setState(() {
        _displayVersion = v;
      });
    }
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

    final onSurfaceColor = theme.colorScheme.onSurface;
    final mutedTextColor = theme.colorScheme.onSurfaceVariant;

    // Responsive scaling based on viewport size
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final scaleFactor = (screenWidth / 1200.0).clamp(0.85, 1.3);

    final logoHeight = 84.0 * scaleFactor;
    final versionFontSize = 10.0 * scaleFactor;

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
                  // Official calligraphic handwriting logo with Hero shared element tag
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: Hero(
                      tag: 'sarv_brand_logo',
                      child: SvgPicture.asset(
                        'assets/handwriting/Sarv Handwriting.svg',
                        height: logoHeight,
                        colorFilter: ColorFilter.mode(
                          onSurfaceColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle Typography with Hero shared element tag
                  FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: Hero(
                      tag: 'sarv_brand_subtitle',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          'MANUSCRIPT DESIGNER',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15.0 * scaleFactor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4.5 * scaleFactor,
                            color: onSurfaceColor.withValues(alpha: 0.90),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dynamic technical version readout at bottom
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
                      if (widget.progress != null) ...[
                        SizedBox(
                          width: 120 * scaleFactor,
                          child: LinearProgressIndicator(
                            value: widget.progress! > 0 ? widget.progress : null,
                            minHeight: 2.0,
                            backgroundColor: mutedTextColor.withValues(alpha: 0.15),
                            color: theme.colorScheme.primary.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'SARVMD  •  v$_displayVersion',
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
