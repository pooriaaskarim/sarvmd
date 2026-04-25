import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sarv_core/sarv_core.dart' as core;

class ExportService {
  /// Export the configuration to a LaTeX file.
  static Future<String> exportTex(
      core.PageConfig config, core.PageLayout layout) async {
    final tex = core.emit(config, layout);
    final outputDir = _getOutputDir();
    final fileName = _getFileName(config);
    final filePath = p.join(outputDir, '$fileName.tex');

    await Directory(outputDir).create(recursive: true);
    await File(filePath).writeAsString(tex);
    return filePath;
  }

  /// Export the configuration to a PDF file.
  static Future<String> exportPdf(
      core.PageConfig config, core.PageLayout layout) async {
    final texPath = await exportTex(config, layout);
    final outputDir = _getOutputDir();
    return await core.compile(texPath, outputDir: outputDir);
  }

  static String _getOutputDir() {
    // Current working directory / output
    return p.join(Directory.current.path, 'output');
  }

  static String _getFileName(core.PageConfig config) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'sarv_${config.layoutType.name}_${config.pageSize.name}_$timestamp';
  }
}
