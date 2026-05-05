/// Sarv CLI — Generate blank manuscript paper as PDF.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'layout',
      abbr: 'l',
      help: 'Layout type.',
      allowed: ['doubleLine', 'singleLine', 'piano', 'standard'],
      defaultsTo: 'singleLine',
    )
    ..addOption(
      'size',
      abbr: 's',
      help: 'Paper size.',
      allowed: ['a4', 'b4'],
      defaultsTo: 'a4',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output directory for generated files.',
      defaultsTo: 'output',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information.',
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage(parser);
    exit(1);
  }

  if (results.flag('help')) {
    _printUsage(parser);
    exit(0);
  }

  final layoutType = switch (results.option('layout')) {
    'doubleLine' || 'piano' => core.LayoutType.doubleLine,
    _ => core.LayoutType.singleLine,
  };

  final pageSize = switch (results.option('size')) {
    'a4' => core.PageSize.a4,
    'b4' => core.PageSize.b4,
    _ => core.PageSize.a4,
  };

  final outputDir = results.option('output')!;

  // Build config.
  final config = core.PageConfig(
    pageSize: pageSize,
    layoutType: layoutType,
  );

  // Compute layout.
  final layout = core.computeLayout(config);

  stdout.writeln(
    'Sarv: ${layoutType.name} layout, '
    '${pageSize.name.toUpperCase()} — '
    '${layout.systemCount} systems',
  );

  // Emit LaTeX source.
  final tex = core.emit(config, layout);
  final fileName = 'sarvmd_${layoutType.name}_${pageSize.name}';
  final texPath = p.join(outputDir, '$fileName.tex');

  Directory(outputDir).createSync(recursive: true);
  File(texPath).writeAsStringSync(tex);
  stdout.writeln('  TeX: $texPath');

  // Compile to PDF.
  try {
    final pdfPath = await core.compile(texPath, outputDir: outputDir);
    stdout.writeln('  PDF: $pdfPath');
    stdout.writeln('Done.');
  } catch (e) {
    stderr.writeln('Compilation failed: $e');
    exit(2);
  }
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: sarv [options]');
  stdout.writeln();
  stdout.writeln('Generate blank manuscript paper as PDF.');
  stdout.writeln();
  stdout.writeln(parser.usage);
}
