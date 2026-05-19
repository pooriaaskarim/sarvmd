// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../view_notifier.dart';
import '../../config_notifier.dart';
import '../../editor_screen.dart';
import 'sarv_splash_screen.dart';

class LaunchCoordinator extends StatefulWidget {
  const LaunchCoordinator({
    super.key,
    required this.viewNotifier,
    required this.prefs,
  });

  final ViewNotifier viewNotifier;
  final SharedPreferences prefs;

  @override
  State<LaunchCoordinator> createState() => _LaunchCoordinatorState();
}

class _LaunchCoordinatorState extends State<LaunchCoordinator> {
  bool _isInitialized = false;
  
  late ConfigNotifier _configNotifier;
  double _sidebarWidth = 320.0;
  double _viewPanelWidth = 280.0;

  @override
  void initState() {
    super.initState();
    // Initialize config and layout parameters synchronously on construction
    _configNotifier = ConfigNotifier(widget.prefs);
    _sidebarWidth = widget.prefs.getDouble('sidebar_width') ?? 320.0;
    _viewPanelWidth = widget.prefs.getDouble('view_panel_width') ?? 280.0;

    _startInitialization();
  }

  Future<void> _startInitialization() async {
    // Wait for the gorgeous calligraphic animation (800ms) to play, then hold for 400ms of appreciation (1200ms total)
    await Future.delayed(const Duration(milliseconds: 1200));

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
    if (!_isInitialized) {
      final brightness = _resolveBrightness(context, widget.viewNotifier.themeMode);
      return SarvSplashScreen(
        statusText: 'Ready',
        progress: 1.0,
        accent: widget.viewNotifier.accent,
        brightness: brightness,
      );
    }

    // Smooth cinematic cross-fade into the ready workspace
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      child: EditorScreen(
        key: const ValueKey('editor_screen'),
        viewNotifier: widget.viewNotifier,
        configNotifier: _configNotifier,
        initialSidebarWidth: _sidebarWidth,
        initialViewPanelWidth: _viewPanelWidth,
      ),
    );
  }
}
