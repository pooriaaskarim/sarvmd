// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/utils/app_logger.dart';

final _log = AppLogger.export;

class ExportService {
  /// Export the configuration to a LaTeX file.
  static Future<String> exportTex(
      core.PageConfig config, core.PageLayout layout) async {
    _log.info('Exporting TeX', context: {
      'pageSize': config.pageSize.name,
      'staffCount': config.staffCount,
    });
    try {
      final tex = core.emit(config, layout);
      final outputDir = _getOutputDir();
      final fileName = _getFileName(config);
      final filePath = p.join(outputDir, '$fileName.tex');

      await Directory(outputDir).create(recursive: true);
      await File(filePath).writeAsString(tex);
      _log.debug('TeX written', context: {'path': filePath});
      return filePath;
    } catch (e, st) {
      _log.error('TeX export failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Export the configuration to a PDF file.
  static Future<String> exportPdf(
      core.PageConfig config, core.PageLayout layout) async {
    _log.info('Exporting PDF', context: {
      'pageSize': config.pageSize.name,
      'staffCount': config.staffCount,
    });
    final sw = Stopwatch()..start();
    try {
      final texPath = await exportTex(config, layout);
      final outputDir = _getOutputDir();
      final pdfPath = await core.compile(texPath, outputDir: outputDir);
      _log.info('PDF export complete', context: {
        'path': pdfPath,
        'elapsedMs': sw.elapsedMilliseconds,
      });
      return pdfPath;
    } catch (e, st) {
      _log.error('PDF export failed', context: {'elapsedMs': sw.elapsedMilliseconds},
          error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Export the layout to an SVG file.
  static Future<String> exportSvg(
      core.PageConfig config, core.PageLayout layout) async {
    _log.info('Exporting SVG', context: {
      'pageSize': config.pageSize.name,
      'staffCount': config.staffCount,
    });
    try {
      final svg = core.emitSvg(config, layout);
      final outputDir = _getOutputDir();
      final fileName = _getFileName(config);
      final filePath = p.join(outputDir, '$fileName.svg');

      await Directory(outputDir).create(recursive: true);
      await File(filePath).writeAsString(svg);
      _log.debug('SVG written', context: {'path': filePath});
      return filePath;
    } catch (e, st) {
      _log.error('SVG export failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  static String _getOutputDir() {
    // Current working directory / output
    return p.join(Directory.current.path, 'output');
  }

  static String _getFileName(core.PageConfig config) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final type = config.staffCount > 1 ? 'ensemble' : 'standard';
    return 'sarvmd_${type}_${config.pageSize.name}_$timestamp';
  }
}
