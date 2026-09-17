// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/utils/app_logger.dart';
import 'export_directory_service.dart';
import 'web_download/web_download.dart';

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
  static String getDefaultFileName(core.PageConfig config) {
    return core.ScoreCompiler.getDefaultFileName(config);
  }

  /// Default output directory.
  static Future<String> getDefaultOutputDir() async {
    return await ExportDirectoryService.getExportDirectory();
  }

  /// Sanitize filename input from user.
  static String _cleanFileName(String name, core.PageConfig config) {
    return core.ScoreCompiler.sanitizeFileName(name, config);
  }

  /// Helper to write file using FilePicker saveFile on mobile or when path is System File Picker,
  /// or directly to a specific folder on Desktop when outputDir is explicitly specified.
  static Future<ExportResult> _saveFilePayload({
    required String fileName,
    required Uint8List bytes,
    required String? outputDir,
    required int elapsedMs,
    required String dialogTitle,
  }) async {
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final bool usePicker = isMobile || outputDir == null || outputDir.isEmpty || outputDir == 'System File Picker';

    String filePath;

    if (usePicker) {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        bytes: bytes,
      );

      if (savedPath == null) {
        throw Exception('Export cancelled by user');
      }
      filePath = savedPath;
    } else {
      filePath = p.join(outputDir, fileName);
      await Directory(outputDir).create(recursive: true);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    }

    final file = File(filePath);
    final size = file.existsSync() ? await file.length() : bytes.length;

    return ExportResult(
      filePath: filePath,
      fileName: p.basename(filePath),
      fileSizeBytes: size,
      elapsedMs: elapsedMs,
    );
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
      final tex = core.ScoreCompiler.compileToTex(config, layout, pageCount: pageCount);
      final name = _cleanFileName(fileName ?? '', config);
      final bytes = Uint8List.fromList(utf8.encode(tex));

      if (kIsWeb) {
        downloadFileWeb('$name.tex', bytes, 'text/plain;charset=utf-8');
        _log.info('TeX download triggered for browser', context: {'fileName': '$name.tex', 'size': bytes.length});
        return ExportResult(
          filePath: 'Browser Downloads/$name.tex',
          fileName: '$name.tex',
          fileSizeBytes: bytes.length,
          elapsedMs: sw.elapsedMilliseconds,
        );
      }

      final result = await _saveFilePayload(
        fileName: '$name.tex',
        bytes: bytes,
        outputDir: outputDir,
        elapsedMs: sw.elapsedMilliseconds,
        dialogTitle: 'Save LaTeX Source',
      );

      _log.debug('TeX written', context: {'path': result.filePath, 'size': result.fileSizeBytes});
      return result;
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
    bool useLatexCompiler = false,
  }) async {
    _log.info('Exporting PDF', context: {
      'pageSize': config.pageSize.name,
      'staffCount': config.staffCount,
      'pageCount': pageCount,
      'useLatexCompiler': useLatexCompiler,
    });
    final sw = Stopwatch()..start();
    try {
      final name = _cleanFileName(fileName ?? '', config);

      if (kIsWeb || !useLatexCompiler) {
        final pdfBytes = await core.ScoreCompiler.compileToPdf(config, layout, pageCount: pageCount);

        if (kIsWeb) {
          downloadFileWeb('$name.pdf', pdfBytes, 'application/pdf');
          _log.info('PDF download triggered for browser', context: {'fileName': '$name.pdf', 'size': pdfBytes.length});
          return ExportResult(
            filePath: 'Browser Downloads/$name.pdf',
            fileName: '$name.pdf',
            fileSizeBytes: pdfBytes.length,
            elapsedMs: sw.elapsedMilliseconds,
          );
        }

        final result = await _saveFilePayload(
          fileName: '$name.pdf',
          bytes: pdfBytes,
          outputDir: outputDir,
          elapsedMs: sw.elapsedMilliseconds,
          dialogTitle: 'Save PDF Manuscript',
        );

        _log.info('PDF export complete (native vector)', context: {
          'path': result.filePath,
          'elapsedMs': sw.elapsedMilliseconds,
          'size': result.fileSizeBytes,
        });

        return result;
      }

      final dir = (outputDir != null && outputDir.isNotEmpty && outputDir != 'System File Picker')
          ? outputDir
          : await ExportDirectoryService.getExportDirectory();
      final texResult = await exportTex(
        config,
        layout,
        fileName: name,
        pageCount: pageCount,
        outputDir: dir,
      );
      final pdfPath = await core.ScoreCompiler.compileTexFileToPdf(texResult.filePath, outputDir: dir);
      final file = File(pdfPath);
      final size = await file.length();

      _log.info('PDF export complete (pdflatex)', context: {
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
      final svg = core.ScoreCompiler.compileToSvg(config, layout, layeringMode: layeringMode);
      final name = _cleanFileName(fileName ?? '', config);
      final bytes = Uint8List.fromList(utf8.encode(svg));

      if (kIsWeb) {
        downloadFileWeb('$name.svg', bytes, 'image/svg+xml;charset=utf-8');
        _log.info('SVG download triggered for browser', context: {'fileName': '$name.svg', 'size': bytes.length});
        return ExportResult(
          filePath: 'Browser Downloads/$name.svg',
          fileName: '$name.svg',
          fileSizeBytes: bytes.length,
          elapsedMs: sw.elapsedMilliseconds,
        );
      }

      final result = await _saveFilePayload(
        fileName: '$name.svg',
        bytes: bytes,
        outputDir: outputDir,
        elapsedMs: sw.elapsedMilliseconds,
        dialogTitle: 'Save SVG Manuscript',
      );

      _log.debug('SVG written', context: {'path': result.filePath, 'size': result.fileSizeBytes});
      return result;
    } catch (e, st) {
      _log.error('SVG export failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
