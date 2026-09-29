// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/utils/app_logger.dart';

final _log = AppLogger.get('sarvmd.ui.file_open');

/// Platform service that bridges Android's `ACTION_VIEW` file intents into Dart.
///
/// ## Usage
/// Call [init] once during application startup (before `runApp`), then listen
/// to [filePathStream] to receive filesystem paths of `.sarv` files the user
/// tapped from a file manager, email client, or any other external source.
///
/// If a file intent arrives during cold start (e.g. while the splash screen is
/// displaying and before any widget listens to [filePathStream]), the path is
/// safely queued and automatically dispatched once the first listener attaches.
///
/// On non-Android platforms (Web uses its own flow) this service is a no-op
/// and [filePathStream] never emits.
///
/// ## Channel protocol (`app.sarvmd/file_opener`)
///
/// | Method               | Direction      | Payload        | Description                             |
/// |----------------------|----------------|----------------|-----------------------------------------|
/// | `getInitialFilePath` | Dart → Native  | —              | Fetches cold-start path (null if none)  |
/// | `openFile`           | Native → Dart  | `String path`  | Warm-start path push (app already open) |
class FileOpenService {
  static const _channel = MethodChannel('app.sarvmd/file_opener');

  static String? _pendingPath;

  static final StreamController<String> _controller = StreamController<String>.broadcast(
    onListen: _onStreamListen,
  );

  /// Stream of absolute filesystem paths for `.sarv` files opened from
  /// external sources (file managers, email, Bluetooth, etc.).
  static Stream<String> get filePathStream => _controller.stream;

  static void _onStreamListen() {
    if (_pendingPath != null) {
      final path = _pendingPath!;
      _pendingPath = null;
      scheduleMicrotask(() {
        if (!_controller.isClosed) {
          _controller.add(path);
        }
      });
    }
  }

  @visibleForTesting
  static bool? debugPlatformOverride;

  static bool get _isAndroid => debugPlatformOverride ?? (!kIsWeb && Platform.isAndroid);

  /// Initialises the service: registers the warm-start push handler and
  /// retrieves any cold-start path that arrived before Flutter was ready.
  ///
  /// Safe to call on all platforms — emits nothing on non-Android platforms.
  static Future<void> init() async {
    if (!_isAndroid) return;

    // Register handler for warm-start pushes (app already running).
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openFile') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          _log.info('Received warm-start file open intent', context: {'path': path});
          _emitOrQueuePath(path);
        }
      }
    });

    // Retrieve the cold-start path, if any.
    try {
      final initialPath = await _channel.invokeMethod<String?>('getInitialFilePath');
      if (initialPath != null && initialPath.isNotEmpty) {
        _log.info('Received cold-start file open intent', context: {'path': initialPath});
        _emitOrQueuePath(initialPath);
      }
    } on PlatformException catch (e) {
      _log.warning('Failed to retrieve initial file path from native layer', error: e);
    }
  }

  static void _emitOrQueuePath(String path) {
    if (_controller.hasListener) {
      _controller.add(path);
    } else {
      _pendingPath = path;
    }
  }

  /// Returns and clears any pending file path that arrived before a UI listener was ready.
  static String? consumePendingFilePath() {
    final path = _pendingPath;
    _pendingPath = null;
    return path;
  }

  /// Resets internal state for unit testing.
  @visibleForTesting
  static void resetForTesting() {
    _pendingPath = null;
    debugPlatformOverride = null;
  }

  /// Closes the internal broadcast stream. Call during app teardown if needed.
  static Future<void> dispose() => _controller.close();
}
