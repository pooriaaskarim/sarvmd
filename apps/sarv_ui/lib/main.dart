import 'package:flutter/material.dart';
import 'src/editor_screen.dart';

void main() {
  runApp(const SarvApp());
}

class SarvApp extends StatelessWidget {
  const SarvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sarv Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF64B5F6),
        useMaterial3: true,
        fontFamily: 'Inter', // Fallback to system font if Inter isn't available
      ),
      home: const EditorScreen(),
    );
  }
}
