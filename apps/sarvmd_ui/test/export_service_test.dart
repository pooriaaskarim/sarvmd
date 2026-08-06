// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/services/export_service.dart';

void main() {
  group('ExportService Tests', () {
    test('getDefaultFileName generates clean names for profiles', () {
      final pianoConfig = core.StaffProfiles.piano.applyTo(const core.PageConfig());
      final pianoName = ExportService.getDefaultFileName(pianoConfig);
      expect(pianoName, equals('Piano_A4_Portrait'));

      final quartetConfig = core.StaffProfiles.stringQuartet.applyTo(const core.PageConfig());
      final quartetName = ExportService.getDefaultFileName(quartetConfig);
      expect(quartetName, equals('String_Quartet_A4_Portrait'));
    });

    test('exportTex generates multi-page LaTeX content when pageCount > 1', () async {
      final config = const core.PageConfig();
      final layout = core.computeLayout(config);
      final tempDir = await Directory.systemTemp.createTemp('sarvmd_export_test');

      try {
        final result = await ExportService.exportTex(
          config,
          layout,
          fileName: 'MultiPageTest',
          pageCount: 3,
          outputDir: tempDir.path,
        );

        expect(result.fileName, equals('MultiPageTest.tex'));
        expect(File(result.filePath).existsSync(), isTrue);

        final content = await File(result.filePath).readAsString();
        expect(content, contains(r'\newpage'));
        // Should contain \newpage twice for 3 pages
        expect(r'\newpage'.allMatches(content).length, equals(2));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('exportSvg creates valid SVG output file with specified layering mode', () async {
      final config = const core.PageConfig();
      final layout = core.computeLayout(config);
      final tempDir = await Directory.systemTemp.createTemp('sarvmd_svg_test');

      try {
        final result = await ExportService.exportSvg(
          config,
          layout,
          fileName: 'SvgTest',
          outputDir: tempDir.path,
          layeringMode: core.SvgLayeringMode.hierarchicalBySystem,
        );

        expect(result.fileName, equals('SvgTest.svg'));
        expect(File(result.filePath).existsSync(), isTrue);

        final content = await File(result.filePath).readAsString();
        expect(content, contains('<svg'));
        expect(content, contains('</svg>'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
