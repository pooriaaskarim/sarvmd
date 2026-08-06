// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/utils/app_logger.dart';

final _log = AppLogger.export;

/// Holds metadata about a completed export operation.
class ExportResult {
  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.elapsedMs,
  });

  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final int elapsedMs;

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ExportService {
  /// Generates an intelligent, clean default filename based on the page configuration.
  ///
  /// Examples: `Piano_A4_Portrait`, `Treble_A4_Portrait`, `Ensemble_4Staff_A4_Portrait`, `Manuscript_A4_Portrait`.
  static String getDefaultFileName(core.PageConfig config) {
    final size = config.pageSize.name.toUpperCase();
    final orient = config.orientation.name[0].toUpperCase() +
        config.orientation.name.substring(1);

    // Try to match against predefined staff profiles first
    for (final profile in core.StaffProfiles.all) {
      if (config.systemLayout == profile.systemLayout) {
        final cleanLabel = profile.label
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .trim();
        return '${cleanLabel}_${size}_$orient';
      }
    }

    // Infer layout description from staves
    final count = config.staffCount;
    if (count == 0) {
      return 'Manuscript_${size}_$orient';
    }

    if (count == 1) {
      // Find clef of first staff
      final group = config.systemLayout.rootGroup;
      if (group.children.isNotEmpty && group.children.first is core.StaffDefinition) {
        final staff = group.children.first as core.StaffDefinition;
        final clef = staff.clef?.symbol;
        if (clef != null) {
          final clefName = clef.displayName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          return '${clefName}_${size}_$orient';
        }
      }
      return 'Staff_${size}_$orient';
    }

    return 'Ensemble_${count}Staff_${size}_$orient';
  }

  /// Default output directory.
  static String getDefaultOutputDir() {
    return p.join(Directory.current.path, 'output');
  }

  /// Sanitize filename input from user.
  static String _cleanFileName(String name, core.PageConfig config) {
    var trimmed = name.trim();
    if (trimmed.isEmpty) {
      trimmed = getDefaultFileName(config);
    }
    // Remove extension if user entered one
    if (trimmed.endsWith('.tex') || trimmed.endsWith('.pdf') || trimmed.endsWith('.svg')) {
      trimmed = p.basenameWithoutExtension(trimmed);
    }
    // Sanitize illegal characters
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// Export the configuration to a LaTeX file.
  static Future<ExportResult> exportTex(
    core.PageConfig config,
    core.PageLayout layout, {
    String? fileName,
    int pageCount = 1,
    String? outputDir,
  }) async {
    _log.info('Exporting TeX', context: {
      'pageSize': config.pageSize.name,
      'staffCount': config.staffCount,
      'pageCount': pageCount,
    });
    final sw = Stopwatch()..start();
    try {
      final tex = core.emit(config, layout, pageCount: pageCount);
      final dir = outputDir ?? getDefaultOutputDir();
      final name = _cleanFileName(fileName ?? '', config);
      final filePath = p.join(dir, '$name.tex');

      await Directory(dir).create(recursive: true);
      final file = File(filePath);
      await file.writeAsString(tex);
      final size = await file.length();

      _log.debug('TeX written', context: {'path': filePath, 'size': size});
      return ExportResult(
        filePath: filePath,
        fileName: '$name.tex',
        fileSizeBytes: size,
        elapsedMs: sw.elapsedMilliseconds,
      );
    } catch (e, st) {
      _log.error('TeX export failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Export the configuration to a PDF file.
  static Future<ExportResult> exportPdf(
    core.PageConfig config,
    core.PageLayout layout, {
    String? fileName,
    int pageCount = 1,
    String? outputDir,
  }) async {
    _log.info('Exporting PDF', context: {
      'pageSize': config.pageSize.name,
      'staffCount': config.staffCount,
      'pageCount': pageCount,
    });
    final sw = Stopwatch()..start();
    try {
      final dir = outputDir ?? getDefaultOutputDir();
      final name = _cleanFileName(fileName ?? '', config);
      final texResult = await exportTex(
        config,
        layout,
        fileName: name,
        pageCount: pageCount,
        outputDir: dir,
      );
      final pdfPath = await core.compile(texResult.filePath, outputDir: dir);
      final file = File(pdfPath);
      final size = await file.length();

      _log.info('PDF export complete', context: {
        'path': pdfPath,
        'elapsedMs': sw.elapsedMilliseconds,
        'size': size,
      });

      return ExportResult(
        filePath: pdfPath,
        fileName: p.basename(pdfPath),
        fileSizeBytes: size,
        elapsedMs: sw.elapsedMilliseconds,
      );
    } catch (e, st) {
      _log.error('PDF export failed', context: {'elapsedMs': sw.elapsedMilliseconds},
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Export the layout to an SVG file.
  static Future<ExportResult> exportSvg(
    core.PageConfig config,
    core.PageLayout layout, {
    String? fileName,
    String? outputDir,
    core.SvgLayeringMode layeringMode = core.SvgLayeringMode.flatByCategory,
  }) async {
    _log.info('Exporting SVG', context: {
      'pageSize': config.pageSize.name,
      'staffCount': config.staffCount,
      'layeringMode': layeringMode.name,
    });
    final sw = Stopwatch()..start();
    try {
      final svg = core.emitSvg(config, layout, layeringMode: layeringMode);
      final dir = outputDir ?? getDefaultOutputDir();
      final name = _cleanFileName(fileName ?? '', config);
      final filePath = p.join(dir, '$name.svg');

      await Directory(dir).create(recursive: true);
      final file = File(filePath);
      await file.writeAsString(svg);
      final size = await file.length();

      _log.debug('SVG written', context: {'path': filePath, 'size': size});
      return ExportResult(
        filePath: filePath,
        fileName: '$name.svg',
        fileSizeBytes: size,
        elapsedMs: sw.elapsedMilliseconds,
      );
    } catch (e, st) {
      _log.error('SVG export failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}

