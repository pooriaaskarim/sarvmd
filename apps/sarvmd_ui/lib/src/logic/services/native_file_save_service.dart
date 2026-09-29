// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/utils/app_logger.dart';

final _log = AppLogger.export;

/// Platform service that bridges native Android Storage Access Framework (SAF)
/// file creation and disambiguation into Dart.
///
/// On Android, standard file pickers pass `*/*` MIME types, causing SAF to append
/// collision numbers after the file extension (e.g. `Score.pdf (1)` or `Score.sarv (1)`).
/// This service invokes the native Android channel handler which sets proper MIME types
/// and automatically renames documents to ensure collision indices are placed
/// immediately before the file extension (e.g. `Score (1).pdf` or `Score (1).sarv`).
class NativeFileSaveService {
  static const MethodChannel _channel = MethodChannel('app.sarvmd/file_opener');

  @visibleForTesting
  static bool? debugPlatformOverride;

  @visibleForTesting
  static Future<String?> Function({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  })? debugSaveFileOverride;

  @visibleForTesting
  static void resetForTesting() {
    debugPlatformOverride = null;
    debugSaveFileOverride = null;
  }

  /// Saves [bytes] with the proposed [fileName] on Android using SAF and automatic
  /// pre-extension disambiguation.
  ///
  /// Returns the saved file path, or `null` if the user cancelled the dialog.
  static Future<String?> saveFile({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    if (debugSaveFileOverride != null) {
      return await debugSaveFileOverride!(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
    }

    final bool isAndroid = debugPlatformOverride ?? (!kIsWeb && Platform.isAndroid);
    if (!isAndroid) {
      throw UnsupportedError('NativeFileSaveService is only supported on Android.');
    }

    try {
      _log.info('Invoking native Android SAF saveFile', context: {
        'fileName': fileName,
        'sizeBytes': bytes.length,
        'mimeType': mimeType ?? 'auto',
      });

      final result = await _channel.invokeMethod<String>('saveFile', {
        'fileName': fileName,
        'bytes': bytes,
        'mimeType': mimeType,
      });

      if (result != null) {
        _log.info('Native Android SAF saveFile succeeded', context: {'resultPath': result});
      } else {
        _log.debug('Native Android SAF saveFile cancelled by user');
      }

      return result;
    } on PlatformException catch (e, st) {
      _log.error('Native Android SAF saveFile failed', error: e, stackTrace: st);
      rethrow;
    }
  }
}
