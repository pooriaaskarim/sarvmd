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

    test('exportPdf creates valid PDF output with %PDF header and correct metadata', () async {
      final config = const core.PageConfig();
      final layout = core.computeLayout(config);
      final tempDir = await Directory.systemTemp.createTemp('sarvmd_pdf_test');

      try {
        final result = await ExportService.exportPdf(
          config,
          layout,
          fileName: 'PdfTest',
          pageCount: 2,
          outputDir: tempDir.path,
        );

        expect(result.fileName, equals('PdfTest.pdf'));
        expect(File(result.filePath).existsSync(), isTrue);
        expect(result.fileSizeBytes, greaterThan(100));

        final bytes = await File(result.filePath).readAsBytes();
        final header = String.fromCharCodes(bytes.take(4));
        expect(header, equals('%PDF'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('exportPdf and exportSvg validate two-tier hierarchical presets and labels', () async {
      const f1 = core.StaffDefinition(uid: 'f1', instrumentName: '1');
      const f2 = core.StaffDefinition(uid: 'f2', instrumentName: '2');
      const flutes = core.StaffNodeGroup(
        connector: core.SystemConnector.bracket,
        label: 'Flutes',
        children: [f1, f2],
      );

      const config = core.PageConfig(
        systemLayout: core.SystemLayout(rootGroup: flutes),
      );
      final layout = core.computeLayout(config);
      final tempDir = await Directory.systemTemp.createTemp('sarvmd_hierarchical_export_test');

      try {
        // PDF Export
        final pdfResult = await ExportService.exportPdf(
          config,
          layout,
          fileName: 'FlutesTest',
          outputDir: tempDir.path,
        );
        expect(pdfResult.fileName, equals('FlutesTest.pdf'));
        expect(File(pdfResult.filePath).existsSync(), isTrue);
        final pdfBytes = await File(pdfResult.filePath).readAsBytes();
        expect(String.fromCharCodes(pdfBytes.take(4)), equals('%PDF'));

        // SVG Export across all layering modes
        for (final mode in core.SvgLayeringMode.values) {
          final svgResult = await ExportService.exportSvg(
            config,
            layout,
            fileName: 'FlutesTest_${mode.name}',
            outputDir: tempDir.path,
            layeringMode: mode,
          );
          expect(svgResult.fileName, equals('FlutesTest_${mode.name}.svg'));
          final svgContent = await File(svgResult.filePath).readAsString();
          expect(svgContent, contains('Flutes'));
          expect(svgContent, contains('>1<'));
          expect(svgContent, contains('>2<'));
        }
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('ExportResult formattedSize computes byte/KB/MB string representations correctly', () {
      const bRes = ExportResult(filePath: '/tmp/f.pdf', fileName: 'f.pdf', fileSizeBytes: 512, elapsedMs: 10);
      expect(bRes.formattedSize, equals('512 B'));

      const kbRes = ExportResult(filePath: '/tmp/f.pdf', fileName: 'f.pdf', fileSizeBytes: 2048, elapsedMs: 10);
      expect(kbRes.formattedSize, equals('2.0 KB'));

      const mbRes = ExportResult(filePath: '/tmp/f.pdf', fileName: 'f.pdf', fileSizeBytes: 3 * 1024 * 1024, elapsedMs: 10);
      expect(mbRes.formattedSize, equals('3.0 MB'));
    });
  });
}

