/// Compiler — shells out to pdflatex to compile .tex → .pdf.

import 'dart:io';

import 'package:logd/logd.dart';
import 'package:path/path.dart' as p;

final _log = Logger.get('sarvmd.core.compiler');

/// Compile a `.tex` file to PDF using pdflatex.
///
/// Returns the path to the generated PDF file.
/// Throws if compilation fails.
Future<String> compile(String texPath, {String? outputDir}) async {
  final texFile = File(texPath);
  if (!texFile.existsSync()) {
    _log.error('TeX source not found', error: texPath);
    throw FileSystemException('TeX file not found', texPath);
  }

  final outDir = outputDir ?? texFile.parent.path;
  Directory(outDir).createSync(recursive: true);

  _log.info('pdflatex started', context: {'source': texPath, 'outDir': outDir});

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
    final errorLines = log
        .split('\n')
        .where((l) => l.startsWith('!') || l.contains('Error'))
        .join('\n');
    _log.error(
      'pdflatex failed',
      error: 'exit ${result.exitCode}',
      context: {'summary': errorLines.isEmpty ? '(no error lines)' : errorLines},
    );
    throw Exception(
      'pdflatex failed (exit ${result.exitCode}):\n$errorLines',
    );
  }

  _log.debug('pdflatex succeeded', context: {'output': pdfPath});
  return pdfPath;
}

