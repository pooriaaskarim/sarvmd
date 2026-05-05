/// Compiler — shells out to pdflatex to compile .tex → .pdf.

import 'dart:io';

import 'package:path/path.dart' as p;

/// Compile a `.tex` file to PDF using pdflatex.
///
/// Returns the path to the generated PDF file.
/// Throws if compilation fails.
Future<String> compile(String texPath, {String? outputDir}) async {
  final texFile = File(texPath);
  if (!texFile.existsSync()) {
    throw FileSystemException('TeX file not found', texPath);
  }

  final outDir = outputDir ?? texFile.parent.path;
  Directory(outDir).createSync(recursive: true);

  final result = await Process.run(
    'pdflatex',
    [
      '-interaction=nonstopmode',
      '-output-directory=$outDir',
      texPath,
    ],
  );

  final pdfPath = p.join(
    outDir,
    '${p.basenameWithoutExtension(texPath)}.pdf',
  );

  if (result.exitCode != 0 || !File(pdfPath).existsSync()) {
    final log = result.stdout as String;
    // Extract the most useful error lines.
    final errorLines = log
        .split('\n')
        .where((l) => l.startsWith('!') || l.contains('Error'))
        .join('\n');
    throw Exception(
      'pdflatex failed (exit ${result.exitCode}):\n$errorLines',
    );
  }

  return pdfPath;
}
