// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/logic/services/file_open_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app.sarvmd/file_opener');
  final binaryMessenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    FileOpenService.resetForTesting();
    FileOpenService.debugPlatformOverride = true;
  });

  tearDown(() {
    binaryMessenger.setMockMethodCallHandler(channel, null);
    FileOpenService.resetForTesting();
  });

  group('FileOpenService', () {
    test('is a no-op when platform is not Android', () async {
      FileOpenService.debugPlatformOverride = false;
      bool channelInvoked = false;

      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        channelInvoked = true;
        return null;
      });

      await FileOpenService.init();
      expect(channelInvoked, isFalse);
      expect(FileOpenService.consumePendingFilePath(), isNull);
    });

    test('queues cold-start path and delivers to first listener', () async {
      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInitialFilePath') {
          return '/storage/emulated/0/Download/score.sarv';
        }
        return null;
      });

      // Initialize before any listener subscribes (simulates splash screen)
      await FileOpenService.init();

      final receivedPaths = <String>[];
      final completer = Completer<void>();

      final sub = FileOpenService.filePathStream.listen((path) {
        receivedPaths.add(path);
        completer.complete();
      });

      await completer.future.timeout(const Duration(seconds: 1));
      expect(receivedPaths, equals(['/storage/emulated/0/Download/score.sarv']));

      await sub.cancel();
    });

    test('consumePendingFilePath returns and clears cold-start path', () async {
      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInitialFilePath') {
          return '/data/cache/test.sarv';
        }
        return null;
      });

      await FileOpenService.init();

      expect(FileOpenService.consumePendingFilePath(), equals('/data/cache/test.sarv'));
      expect(FileOpenService.consumePendingFilePath(), isNull);
    });

    test('delivers warm-start openFile events directly to active listeners', () async {
      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInitialFilePath') return null;
        return null;
      });

      await FileOpenService.init();

      final receivedPaths = <String>[];
      final sub = FileOpenService.filePathStream.listen(receivedPaths.add);

      // Simulate native calling openFile method
      final byteData = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('openFile', '/sdcard/Music/warm.sarv'),
      );
      await binaryMessenger.handlePlatformMessage('app.sarvmd/file_opener', byteData, (_) {});

      expect(receivedPaths, equals(['/sdcard/Music/warm.sarv']));

      await sub.cancel();
    });

    test('ignores empty or null file paths', () async {
      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getInitialFilePath') return '';
        return null;
      });

      await FileOpenService.init();
      expect(FileOpenService.consumePendingFilePath(), isNull);

      final receivedPaths = <String>[];
      final sub = FileOpenService.filePathStream.listen(receivedPaths.add);

      final emptyCall = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('openFile', ''),
      );
      await binaryMessenger.handlePlatformMessage('app.sarvmd/file_opener', emptyCall, (_) {});

      expect(receivedPaths, isEmpty);
      await sub.cancel();
    });
  });
}
