// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_brand.dart';
import '../../../core/theme/app_theme.dart';
import '../dialogs/about_dialog.dart';

/// Supported layout modes for the canonical [SarvBrandHeader] component.
enum SarvBrandHeaderMode {
  /// Vertical stack of handwriting SVG logo + 'Manuscript Designer' tagline (Header, Splash, About).
  full,

  /// Inline horizontal brand widget displaying SVG logo + 'MD' expanding to 'Manuscript Designer' on hover/hold.
  reactive,

  /// Compact header widget for app menu dropdown.
  compactMenu,
}

/// The single canonical visual brand header widget for SarvMD.
///
/// Guarantees that the handwriting SVG logo, untranslated 'Manuscript Designer' brand tagline,
/// 'IranNastaliq' typography, and Hero animation tags render 100% identically across all application surfaces.
class SarvBrandHeader extends StatefulWidget {
  const SarvBrandHeader({
    super.key,
    this.mode = SarvBrandHeaderMode.full,
    this.logoHeight,
    this.scaleFactor = 1.0,
    this.enableHero = true,
    this.showInfoIcon = false,
    this.enableInteractiveAbout = false,
    this.isMenuMode = false,
    this.enableExpandAnimation = true,
    this.onTap,
  });

  final SarvBrandHeaderMode mode;
  final double? logoHeight;
  final double scaleFactor;
  final bool enableHero;
  final bool showInfoIcon;
  final bool enableInteractiveAbout;
  final bool isMenuMode;
  final bool enableExpandAnimation;
  final VoidCallback? onTap;

  @override
  State<SarvBrandHeader> createState() => _SarvBrandHeaderState();
}

class _SarvBrandHeaderState extends State<SarvBrandHeader> {
  bool _isHoveredOrHeld = false;

  void _setExpanded(bool expanded) {
    if (widget.isMenuMode || !widget.enableExpandAnimation) return;
    if (_isHoveredOrHeld != expanded) {
      setState(() => _isHoveredOrHeld = expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<SarvThemeExtension>();
    final baseStyle = themeExt?.brandSubtitleStyle ??
        TextStyle(
          color: cs.primary.withValues(alpha: 0.85),
          fontSize: 13.5,
          fontFamily: 'IranNastaliq',
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          height: 1.35,
        );

    final style = widget.scaleFactor != 1.0
        ? baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 13.5) * widget.scaleFactor,
          )
        : baseStyle;

    final effectiveLogoHeight = widget.logoHeight ??
        (switch (widget.mode) {
          SarvBrandHeaderMode.full => 54.0 * widget.scaleFactor,
          SarvBrandHeaderMode.reactive => AppBrand.defaultLogoHeight,
          SarvBrandHeaderMode.compactMenu => 28.0,
        });

    final logoHeroTag = widget.mode == SarvBrandHeaderMode.compactMenu || widget.isMenuMode
        ? AppBrand.heroTagMenuLogo
        : AppBrand.heroTagLogo;

    final svgLogo = SvgPicture.asset(
      AppBrand.logoHandwritingSvg,
      height: effectiveLogoHeight,
      colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
    );

    final logoWidget = widget.enableHero
        ? Hero(tag: logoHeroTag, child: svgLogo)
        : svgLogo;

    final subtitleWidget = Material(
      type: MaterialType.transparency,
      child: Text(
        AppBrand.tagline,
        textAlign: TextAlign.center,
        style: style,
      ),
    );

    final heroSubtitleWidget = widget.enableHero
        ? Hero(tag: AppBrand.heroTagSubtitle, child: subtitleWidget)
        : subtitleWidget;

    if (widget.mode == SarvBrandHeaderMode.reactive) {
      final isExpanded = !widget.isMenuMode && widget.enableExpandAnimation && _isHoveredOrHeld;

      final reactiveContent = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: widget.isMenuMode && _isHoveredOrHeld
              ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            logoWidget,
            const SizedBox(width: 6.0),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
              sizeCurve: Curves.easeInOut,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                'MD',
                style: style.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              secondChild: Text(
                AppBrand.tagline,
                style: style,
              ),
            ),
            if (widget.isMenuMode) ...[
              const SizedBox(width: 2.0),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 20.0,
                color: cs.primary,
              ),
            ],
          ],
        ),
      );

      if (widget.isMenuMode) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHoveredOrHeld = true),
          onExit: (_) => setState(() => _isHoveredOrHeld = false),
          child: reactiveContent,
        );
      }

      return MouseRegion(
        onEnter: (_) => _setExpanded(true),
        onExit: (_) => _setExpanded(false),
        child: GestureDetector(
          onTapDown: (_) => _setExpanded(true),
          onTapUp: (_) => _setExpanded(false),
          onTapCancel: () => _setExpanded(false),
          child: InkWell(
            onTap: widget.enableInteractiveAbout
                ? () => showSarvAboutDialog(context)
                : widget.onTap,
            borderRadius: BorderRadius.circular(8.0),
            child: reactiveContent,
          ),
        ),
      );
    }

    if (widget.mode == SarvBrandHeaderMode.compactMenu) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          svgLogo,
          const SizedBox(height: 4.0),
          Text(
            AppBrand.tagline,
            style: style,
          ),
        ],
      );
    }

    // Full Vertical Stack Mode (Header, Splash Screen, About Dialog)
    final fullContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        SizedBox(height: 8.0 * widget.scaleFactor),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            heroSubtitleWidget,
            if (widget.showInfoIcon) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline,
                size: 14,
                color: cs.primary.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
      ],
    );

    if (widget.enableInteractiveAbout) {
      return Tooltip(
        message: 'About SarvMD',
        child: InkWell(
          onTap: () => showSarvAboutDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: fullContent,
            ),
          ),
        ),
      );
    }

    return fullContent;
  }
}
