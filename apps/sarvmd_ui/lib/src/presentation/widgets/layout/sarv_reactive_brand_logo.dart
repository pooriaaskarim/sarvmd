// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../dialogs/about_dialog.dart';

/// Reactive, interactive SarvMD branding logo widget.
///
/// In standard mode, displays the handwriting SVG logo + 'MD' by default (reading "SarvMD"),
/// expanding on hover or touch hold to 'Manuscript Designer'.
///
/// In menu mode ([isMenuMode] == true), auto-expansion is disabled and a dropdown indicator
/// arrow is displayed, signaling that tapping opens the app menu dropdown. Taps are not
/// intercepted so that parent widgets (like [PopupMenuButton]) receive them cleanly.
class SarvReactiveBrandLogo extends StatefulWidget {
  const SarvReactiveBrandLogo({
    super.key,
    this.logoHeight = 26.0,
    this.isMenuMode = false,
  });

  final double logoHeight;
  final bool isMenuMode;

  @override
  State<SarvReactiveBrandLogo> createState() => _SarvReactiveBrandLogoState();
}

class _SarvReactiveBrandLogoState extends State<SarvReactiveBrandLogo> {
  bool _isHoveredOrHeld = false;

  void _setExpanded(bool expanded) {
    if (widget.isMenuMode) return;
    if (_isHoveredOrHeld != expanded) {
      setState(() => _isHoveredOrHeld = expanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeExt = Theme.of(context).extension<SarvThemeExtension>();
    final style = themeExt?.brandSubtitleStyle ??
        TextStyle(
          color: cs.primary.withValues(alpha: 0.85),
          fontSize: 13.5,
          fontFamily: 'IranNastaliq',
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          height: 1.35,
        );

    final isExpanded = !widget.isMenuMode && _isHoveredOrHeld;

    final content = AnimatedContainer(
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
          Hero(
            tag: widget.isMenuMode ? 'sarv_brand_logo_menu' : 'sarv_brand_logo',
            child: SvgPicture.asset(
              'assets/handwriting/Sarv Handwriting.svg',
              height: widget.logoHeight,
              colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
            ),
          ),
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
              'Manuscript Designer',
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
      // In menu mode, provide hover feedback without intercepting tap gestures
      return MouseRegion(
        onEnter: (_) => setState(() => _isHoveredOrHeld = true),
        onExit: (_) => setState(() => _isHoveredOrHeld = false),
        child: content,
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
          onTap: () => showSarvAboutDialog(context),
          borderRadius: BorderRadius.circular(8.0),
          child: content,
        ),
      ),
    );
  }
}
