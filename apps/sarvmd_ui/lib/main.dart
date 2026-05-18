// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'src/editor_screen.dart';
import 'src/view_notifier.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const SarvApp());
}

class SarvApp extends StatefulWidget {
  const SarvApp({super.key});

  @override
  State<SarvApp> createState() => _SarvAppState();
}

class _SarvAppState extends State<SarvApp> {
  final ViewNotifier _viewNotifier = ViewNotifier();

  @override
  void initState() {
    super.initState();
    _viewNotifier.initialize();
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
          home: EditorScreen(viewNotifier: _viewNotifier),
        );
      },
    );
  }
}
