// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/view_notifier.dart';
import 'src/theme/app_theme.dart';
import 'src/components/specialized/launch_coordinator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SarvApp(prefs: prefs));
}

class SarvApp extends StatefulWidget {
  const SarvApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<SarvApp> createState() => _SarvAppState();
}

class _SarvAppState extends State<SarvApp> {
  late final ViewNotifier _viewNotifier;

  @override
  void initState() {
    super.initState();
    _viewNotifier = ViewNotifier(widget.prefs);
    _viewNotifier.initializeSync();
  }

  @override
  void dispose() {
    _viewNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewNotifier,
      builder: (context, _) {
        final accent = _viewNotifier.accent;
        return MaterialApp(
          title: 'SarvMD',
          debugShowCheckedModeBanner: false,
          themeMode: _viewNotifier.themeMode,
          theme: AppTheme.build(accent, Brightness.light),
          darkTheme: AppTheme.build(accent, Brightness.dark),
          home: LaunchCoordinator(
            viewNotifier: _viewNotifier,
            prefs: widget.prefs,
          ),
        );
      },
    );
  }
}
