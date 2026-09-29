// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/logic/services/native_file_save_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('app.sarvmd/file_opener');
  final binaryMessenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    NativeFileSaveService.resetForTesting();
  });

  tearDown(() {
    binaryMessenger.setMockMethodCallHandler(channel, null);
    NativeFileSaveService.resetForTesting();
  });

  group('NativeFileSaveService', () {
    test('throws UnsupportedError when platform is not Android', () async {
      NativeFileSaveService.debugPlatformOverride = false;

      expect(
        () => NativeFileSaveService.saveFile(
          fileName: 'Treble_A4_Portrait.pdf',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('invokes saveFile on method channel with correct arguments', () async {
      NativeFileSaveService.debugPlatformOverride = true;
      MethodCall? capturedCall;

      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'saveFile') {
          capturedCall = call;
          return '/storage/emulated/0/Download/Treble_A4_Portrait (1).pdf';
        }
        return null;
      });

      final bytes = Uint8List.fromList([10, 20, 30]);
      final result = await NativeFileSaveService.saveFile(
        fileName: 'Treble_A4_Portrait.pdf',
        bytes: bytes,
        mimeType: 'application/pdf',
      );

      expect(capturedCall, isNotNull);
      expect(capturedCall!.method, equals('saveFile'));
      expect(capturedCall!.arguments['fileName'], equals('Treble_A4_Portrait.pdf'));
      expect(capturedCall!.arguments['bytes'], equals(bytes));
      expect(capturedCall!.arguments['mimeType'], equals('application/pdf'));
      expect(result, equals('/storage/emulated/0/Download/Treble_A4_Portrait (1).pdf'));
    });

    test('returns null when save dialog is cancelled by user', () async {
      NativeFileSaveService.debugPlatformOverride = true;

      binaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'saveFile') {
          return null; // user cancelled
        }
        return null;
      });

      final result = await NativeFileSaveService.saveFile(
        fileName: 'score.sarv',
        bytes: Uint8List.fromList([42]),
      );

      expect(result, isNull);
    });

    test('uses debugSaveFileOverride when provided', () async {
      bool overrideInvoked = false;
      NativeFileSaveService.debugSaveFileOverride = ({
        required String fileName,
        required Uint8List bytes,
        String? mimeType,
      }) async {
        overrideInvoked = true;
        return '/mock/path/$fileName';
      };

      final result = await NativeFileSaveService.saveFile(
        fileName: 'test.sarv',
        bytes: Uint8List.fromList([]),
      );

      expect(overrideInvoked, isTrue);
      expect(result, equals('/mock/path/test.sarv'));
    });
  });

  group('Android SAF duplicate name regex disambiguation contract', () {
    // The exact regex pattern implemented in MainActivity.kt
    final duplicateRegex = RegExp(r'^(.+?)\.([a-zA-Z0-9]+)\s*[\(_]([0-9]+)\)?$');

    String fixSafDuplicate(String name) {
      final match = duplicateRegex.firstMatch(name);
      if (match != null) {
        final base = match.group(1);
        final ext = match.group(2);
        final index = match.group(3);
        return '$base ($index).$ext';
      }
      return name;
    }

    test('repositions collision index from after extension to before extension for PDF', () {
      expect(
        fixSafDuplicate('Treble_A4_Portrait.pdf (1)'),
        equals('Treble_A4_Portrait (1).pdf'),
      );
      expect(
        fixSafDuplicate('Treble_A4_Portrait.pdf (2)'),
        equals('Treble_A4_Portrait (2).pdf'),
      );
    });

    test('repositions collision index from after extension to before extension for .sarv', () {
      expect(
        fixSafDuplicate('Treble_A4_Portrait.sarv (1)'),
        equals('Treble_A4_Portrait (1).sarv'),
      );
      expect(
        fixSafDuplicate('Treble_A4_Portrait.sarv (5)'),
        equals('Treble_A4_Portrait (5).sarv'),
      );
    });

    test('handles underscore format if produced by OEM DocumentProviders', () {
      expect(
        fixSafDuplicate('Treble_A4_Portrait.pdf_1'),
        equals('Treble_A4_Portrait (1).pdf'),
      );
    });

    test('preserves files that already have numeric indices before the extension', () {
      expect(
        fixSafDuplicate('Treble_A4_Portrait (1).pdf'),
        equals('Treble_A4_Portrait (1).pdf'),
      );
      expect(
        fixSafDuplicate('Treble_A4_Portrait (1).sarv'),
        equals('Treble_A4_Portrait (1).sarv'),
      );
    });

    test('handles dotted base names properly', () {
      expect(
        fixSafDuplicate('Score.v1.0.svg (3)'),
        equals('Score.v1.0 (3).svg'),
      );
    });

    test('leaves non-duplicate files unchanged', () {
      expect(
        fixSafDuplicate('Treble_A4_Portrait.pdf'),
        equals('Treble_A4_Portrait.pdf'),
      );
      expect(
        fixSafDuplicate('Treble_A4_Portrait.sarv'),
        equals('Treble_A4_Portrait.sarv'),
      );
    });
  });
}
