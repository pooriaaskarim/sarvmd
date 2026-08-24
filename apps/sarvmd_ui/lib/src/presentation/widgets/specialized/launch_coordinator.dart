// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/locale/locale_cubit.dart';
import '../../../logic/locale/locale_state.dart';
import '../../../logic/view/view_cubit.dart';
import '../../../logic/view/view_state.dart';
import '../../../logic/services/changelog_service.dart';
import '../specialized/sarv_splash_screen.dart';
import '../../screens/editor_screen.dart';

/// Coordinates application startup and smoothly executes a Hero shared-element transition
/// from the calligraphic splash screen into the main editor workspace header.
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
  String _version = '0.6.0';
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    // Perform actual asynchronous boot tasks in parallel with baseline splash threshold
    final versionFuture = ChangelogService.getLatestVersion();
    final baselineDelayFuture = Future.delayed(widget.minSplashDuration);

    final results = await Future.wait([versionFuture, baselineDelayFuture]);
    final resolvedVersion = results[0] as String;

    if (mounted && !_hasNavigated) {
      _hasNavigated = true;
      setState(() {
        _version = resolvedVersion;
      });

      // Execute Hero shared-element transition into EditorScreen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 750),
          reverseTransitionDuration: const Duration(milliseconds: 750),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const EditorScreen(key: ValueKey('editor_screen')),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              ),
              child: child,
            );
          },
        ),
      );
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

            return SarvSplashScreen(
              key: const ValueKey('sarv_splash_screen'),
              accent: viewState.accent,
              brightness: brightness,
              isPersian: localeState.isPersian,
              version: _version,
            );
          },
        );
      },
    );
  }
}
