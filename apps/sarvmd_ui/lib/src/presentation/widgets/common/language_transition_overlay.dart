// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/locale/locale_cubit.dart';
import '../../../logic/locale/locale_state.dart';

/// A glassmorphic blur overlay that displays when the application is switching locales.
///
/// Features a smooth backdrop blur filter (`ImageFilter.blur`), dark/light theme tinting,
/// an animated icon emblem, and fade-in/fade-out transitions.
class LanguageTransitionOverlay extends StatelessWidget {
  const LanguageTransitionOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      buildWhen: (previous, current) =>
          previous.isTransitioning != current.isTransitioning ||
          previous.isPersian != current.isPersian,
      builder: (context, localeState) {
        return Stack(
          alignment: Alignment.center,
          children: [
            child,
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              reverseDuration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: localeState.isTransitioning
                  ? _LanguageBlurOverlayView(
                      key: const ValueKey('language_transition_blur_overlay'),
                      isPersian: localeState.isPersian,
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('language_overlay_hidden'),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageBlurOverlayView extends StatelessWidget {
  const _LanguageBlurOverlayView({
    super.key,
    required this.isPersian,
  });

  final bool isPersian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: isPersian ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
            alignment: Alignment.center,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: const _AnimatedLanguageBadge(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLanguageBadge extends StatefulWidget {
  const _AnimatedLanguageBadge();

  @override
  State<_AnimatedLanguageBadge> createState() => _AnimatedLanguageBadgeState();
}

class _AnimatedLanguageBadgeState extends State<_AnimatedLanguageBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surfaceContainerHigh.withValues(alpha: 0.85),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 28,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: cs.primary,
            ),
          ),
          RotationTransition(
            turns: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOutCubic,
              ),
            ),
            child: Icon(
              Icons.translate_rounded,
              size: 22,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
