// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/foundation.dart';
import 'package:logd/logd.dart';

/// Central logger configuration for SarvMD.
///
/// Call [AppLogger.init] exactly once from [main], **before** [runApp].
/// All subsystems obtain loggers via the named accessors or [AppLogger.get].
///
/// Logger hierarchy:
/// ```
/// sarvmd
/// ├── sarvmd.core
/// │   └── sarvmd.core.compiler      ← pdflatex subprocess
/// ├── sarvmd.ui
/// │   ├── sarvmd.ui.config          ← ConfigCubit (layout persistence)
/// │   ├── sarvmd.ui.score           ← ScoreCubit (undo/redo commands)
/// │   ├── sarvmd.ui.view            ← ViewCubit (theme, calibration)
/// │   └── sarvmd.ui.export          ← export pipeline (TeX/SVG/PDF)
/// └── sarvmd.crash                  ← FlutterError + PlatformDispatcher + runZonedGuarded
/// ```
abstract final class AppLogger {
  AppLogger._();

  // ── Bootstrap ────────────────────────────────────────────────────────────

  /// Initializes the logging pipeline.
  ///
  /// Pass `isDev: kDebugMode` from [main].
  static void init({required bool isDev}) {
    if (kIsWeb) {
      _configureWeb(isDev: isDev);
    } else if (isDev) {
      _configureDevMode();
    } else {
      _configureProdMode();
    }
  }

  // ── Named accessors ──────────────────────────────────────────────────────

  /// Obtain a logger by its full dotted name.
  static Logger get(String name) => Logger.get(name);

  /// Crash logger — [FlutterError.onError], [PlatformDispatcher.onError],
  /// and [runZonedGuarded].
  static Logger get crash => Logger.get('sarvmd.crash');

  /// Core compiler logger — pdflatex subprocess lifecycle.
  static Logger get compiler => Logger.get('sarvmd.core.compiler');

  /// UI config logger — ConfigCubit, prefs persistence.
  static Logger get config => Logger.get('sarvmd.ui.config');

  /// UI score logger — ScoreCubit command execution and undo/redo.
  static Logger get score => Logger.get('sarvmd.ui.score');

  /// UI view logger — ViewCubit theme, calibration, guides.
  static Logger get view => Logger.get('sarvmd.ui.view');

  /// UI export logger — ExportService TeX/SVG/PDF pipeline.
  static Logger get export => Logger.get('sarvmd.ui.export');

  // ── Private configurations ───────────────────────────────────────────────

  static void _configureDevMode() {
    Logger.configureMultiple({
      // Root: pretty console, all levels, HH:mm:ss.SSS timestamps.
      'sarvmd': LoggerConfig(
        logLevel: LogLevel.trace,
        handlers: [_devConsoleHandler()],
        timestamp: Timestamp(formatter: 'HH:mm:ss.SSS'),
      ),
      // Crash is always at error level and never silenced by child tuning.
      'sarvmd.crash': LoggerConfig(
        logLevel: LogLevel.error,
        handlers: [_devConsoleHandler()],
      ),
    });
  }

  static void _configureProdMode() {
    Logger.configureMultiple({
      // Root: warnings+ to file. No handler-level filter — logger-level
      // gates are the single source of truth for what gets written.
      'sarvmd': LoggerConfig(
        logLevel: LogLevel.warning,
        handlers: [_prodFileHandler('logs/sarvmd.log')],
        timestamp: Timestamp(formatter: 'yyyy-MM-dd HH:mm:ss.SSS Z'),
      ),
      // Compiler at INFO: pdflatex start/success/failure must always be
      // recorded in prod, not just warnings.
      'sarvmd.core.compiler': const LoggerConfig(logLevel: LogLevel.info),
      // Export at INFO: every user-initiated export action is recorded.
      'sarvmd.ui.export': const LoggerConfig(logLevel: LogLevel.info),
      // Config at INFO: prefs restore/save outcomes are valuable for
      // diagnosing config-reset bug reports from real users.
      'sarvmd.ui.config': const LoggerConfig(logLevel: LogLevel.info),
      // Crash: always active, both to file and stderr console.
      'sarvmd.crash': LoggerConfig(
        logLevel: LogLevel.error,
        handlers: [
          _prodFileHandler('logs/sarvmd.log'),
          _devConsoleHandler(),
        ],
      ),
    });
  }

  static void _configureWeb({required bool isDev}) {
    // FileSink is not available on the web platform.
    // In dev mode show all levels; in production show warnings only.
    Logger.configureMultiple({
      'sarvmd': LoggerConfig(
        logLevel: isDev ? LogLevel.trace : LogLevel.warning,
        handlers: [_webConsoleHandler()],
        timestamp: Timestamp(formatter: 'HH:mm:ss.SSS'),
      ),
      'sarvmd.crash': LoggerConfig(
        logLevel: LogLevel.error,
        handlers: [_webConsoleHandler()],
      ),
    });
  }

  // ── Handler factories ────────────────────────────────────────────────────

  static Handler _devConsoleHandler() => const Handler(
        formatter: StructuredFormatter(),
        decorators: [
          BoxDecorator(borderStyle: BorderStyle.rounded),
          StyleDecorator(),
        ],
        sink: ConsoleSink(),
      );

  /// Plain text to browser console. No decorators — BoxDecorator and
  /// StyleDecorator operate on StructuredFormatter's semantic document and
  /// produce malformed output when paired with PlainFormatter.
  static Handler _webConsoleHandler() => const Handler(
        formatter: PlainFormatter(),
        sink: ConsoleSink(),
      );

  static Handler _prodFileHandler(String path) => Handler(
        formatter: const JsonFormatter(
          metadata: {LogMetadata.timestamp, LogMetadata.logger},
        ),
        sink: FileSink(
          path,
          fileRotation: SizeRotation(
            maxSize: '5 MB',
            backupCount: 3,
            compress: true,
          ),
        ),
        // No handler-level filter: the logger-level config on each namespace
        // is the sole gate. A redundant handler filter here would silently
        // block INFO logs from sarvmd.core.compiler and sarvmd.ui.export.
      );
}
