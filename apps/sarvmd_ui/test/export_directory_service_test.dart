// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_ui/src/logic/services/export_directory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportDirectoryService Path Normalization Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('normalizeDirectoryPath strips file:// URI scheme', () {
      expect(
        ExportDirectoryService.normalizeDirectoryPath('file:///home/user/Music'),
        equals('/home/user/Music'),
      );
    });

    test('normalizeDirectoryPath removes redundant and trailing slashes', () {
      expect(
        ExportDirectoryService.normalizeDirectoryPath('/home/user/Documents/'),
        equals('/home/user/Documents'),
      );
      expect(
        ExportDirectoryService.normalizeDirectoryPath('/home//user///Scores//'),
        equals('/home/user/Scores'),
      );
    });

    test('normalizeDirectoryPath expands ~ to home directory', () {
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        expect(
          ExportDirectoryService.normalizeDirectoryPath('~/Music'),
          equals(p.join(home, 'Music')),
        );
        expect(
          ExportDirectoryService.normalizeDirectoryPath('~'),
          equals(home),
        );
      }
    });

    test('saveExportDirectory stores normalized path in SharedPreferences', () async {
      await ExportDirectoryService.saveExportDirectory('/custom/export/path/');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sarvmd_export_directory'), equals('/custom/export/path'));
    });
  });
}
