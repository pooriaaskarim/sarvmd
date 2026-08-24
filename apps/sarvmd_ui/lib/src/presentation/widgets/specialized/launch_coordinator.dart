// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/locale/locale_cubit.dart';
import '../../../logic/locale/locale_state.dart';
import '../../../logic/view/view_cubit.dart';
import '../../../logic/view/view_state.dart';
import '../specialized/sarv_splash_screen.dart';
import '../../screens/editor_screen.dart';

/// Coordinates application startup and smoothly transitions from the calligraphic
/// splash screen into the main editor workspace.
class LaunchCoordinator extends StatefulWidget {
  const LaunchCoordinator({
    super.key,
    this.minSplashDuration = const Duration(milliseconds: 1100),
  });

  final Duration minSplashDuration;

  @override
  State<LaunchCoordinator> createState() => _LaunchCoordinatorState();
}

class _LaunchCoordinatorState extends State<LaunchCoordinator> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    // Hold splash screen for minSplashDuration to allow logo animation to complete cleanly
    await Future.delayed(widget.minSplashDuration);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Brightness _resolveBrightness(BuildContext context, ThemeMode themeMode) {
    if (themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context);
    }
    return themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        return BlocBuilder<ViewCubit, ViewState>(
          builder: (context, viewState) {
            final brightness = _resolveBrightness(context, viewState.themeMode);

            if (!_isInitialized) {
              return SarvSplashScreen(
                key: const ValueKey('sarv_splash_screen'),
                accent: viewState.accent,
                brightness: brightness,
                isPersian: localeState.isPersian,
              );
            }

            return const AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: EditorScreen(
                key: ValueKey('editor_screen'),
              ),
            );
          },
        );
      },
    );
  }
}
