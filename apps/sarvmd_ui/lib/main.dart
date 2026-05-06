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
