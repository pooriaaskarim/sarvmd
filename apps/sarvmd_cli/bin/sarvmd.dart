// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Sarv CLI — Generate blank manuscript paper as PDF.

import 'dart:io';

import 'package:args/args.dart';
import 'package:logd/logd.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;

final _log = Logger.get('sarvmd.core.compiler');

void main(List<String> arguments) async {
  // Configure logd for CLI: plain text to stdout, INFO+.
  Logger.configure('sarvmd', handlers: [
    const Handler(
      formatter: PlainFormatter(),
      sink: ConsoleSink(),
      filters: [LevelFilter(LogLevel.info)],
    ),
  ]);

  final parser = ArgParser()
    ..addOption(
      'layout',
      abbr: 'l',
      help: 'Layout type / نوع چیدمان.',
      allowed: ['doubleLine', 'singleLine', 'piano', 'standard'],
      defaultsTo: 'singleLine',
    )
    ..addOption(
      'size',
      abbr: 's',
      help: 'Paper size / ابعاد برگه.',
      allowed: ['a4', 'b4'],
      defaultsTo: 'a4',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output directory / مسیر خروجی.',
      defaultsTo: 'output',
    )
    ..addOption(
      'lang',
      abbr: 'g',
      help: 'Language / زبان (fa, en).',
      allowed: ['fa', 'en'],
      defaultsTo: 'fa',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show usage information / نمایش راهنما.',
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error / خطا: ${e.message}');
    stderr.writeln();
    _printUsage(parser, isFa: true);
    exit(1);
  }

  final isFa = results.option('lang') == 'fa';

  if (results.flag('help')) {
    _printUsage(parser, isFa: isFa);
    exit(0);
  }

  final profile = switch (results.option('layout')) {
    'doubleLine' || 'piano' => core.StaffProfiles.piano,
    _ => core.StaffProfiles.treble,
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
    systemLayout: profile.systemLayout,
  );

  // Compute layout.
  final layout = core.computeLayout(config);

  if (isFa) {
    _log.info(
      '[اطلاع] چیدمان ${profile.label}، ابعاد ${pageSize.name.toUpperCase()} — تعداد سیستم‌ها: ${layout.systemCount}',
    );
  } else {
    _log.info(
      '[INFO] ${profile.label} layout, ${pageSize.name.toUpperCase()} — ${layout.systemCount} systems',
    );
  }

  // Emit LaTeX source.
  final tex = core.emit(config, layout);
  final fileName = 'sarvmd_${profile.id}_${pageSize.name}';
  final texPath = p.join(outputDir, '$fileName.tex');

  Directory(outputDir).createSync(recursive: true);
  File(texPath).writeAsStringSync(tex);

  if (isFa) {
    _log.info('[اطلاع] کدهای TeX با موفقیت ذخیره شد.', context: {'مسیر': texPath});
  } else {
    _log.info('[INFO] TeX written.', context: {'path': texPath});
  }

  // Compile to PDF.
  try {
    final pdfPath = await core.compile(texPath, outputDir: outputDir);
    if (isFa) {
      _log.info('[موفقیت] فایل PDF با موفقیت کامپایل شد.', context: {'مسیر': pdfPath});
    } else {
      _log.info('[INFO] PDF compiled successfully.', context: {'path': pdfPath});
    }
  } catch (e) {
    if (isFa) {
      _log.error('[خطا] خطا در کامپایل فایل LaTeX.', error: e);
    } else {
      _log.error('[ERROR] LaTeX compilation failed.', error: e);
    }
    exit(2);
  }
}

void _printUsage(ArgParser parser, {bool isFa = true}) {
  if (isFa) {
    stdout.writeln('طریقه استفاده: sarv [گزینه‌ها]');
    stdout.writeln();
    stdout.writeln('تولید برگه‌های نت موسیقی (کاغذ دست‌نویس) به صورت PDF.');
    stdout.writeln();
  } else {
    stdout.writeln('Usage: sarv [options]');
    stdout.writeln();
    stdout.writeln('Generate blank manuscript paper as PDF.');
    stdout.writeln();
  }
  stdout.writeln(parser.usage);
}

