import 'package:flutter/material.dart';
import 'src/editor_screen.dart';
import 'src/view_notifier.dart';

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
        return MaterialApp(
          title: 'SarvMD',
          debugShowCheckedModeBanner: false,
          themeMode: _viewNotifier.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFDCDCDC),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              surface: Color(0xFFDCDCDC),
              surfaceContainer: Color(0xFFEFEFEF),
              onSurface: Colors.black87,
              onSurfaceVariant: Colors.black54,
              outline: Colors.black12,
              outlineVariant: Colors.black26,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF64B5F6),
              surface: Color(0xFF121212),
              surfaceContainer: Color(0xFF252525),
              onSurface: Colors.white,
              onSurfaceVariant: Colors.white70,
              outline: Colors.white24,
              outlineVariant: Colors.black26,
            ),
            useMaterial3: true,
            fontFamily: 'Inter',
          ),
          home: EditorScreen(viewNotifier: _viewNotifier),
        );
      },
    );
  }
}
