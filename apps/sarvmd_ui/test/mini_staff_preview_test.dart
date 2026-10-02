// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/presentation/widgets/staff/mini_staff_preview.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';

void main() {
  group('MiniStaffPreview Widget Tests', () {
    testWidgets('Renders properly for every preset in StaffProfiles.all', (tester) async {
      for (final profile in core.StaffProfiles.all) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 120,
                height: 44,
                child: MiniStaffPreview(
                  systemLayout: profile.systemLayout,
                  active: false,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(MiniStaffPreview), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    testWidgets('Renders Chamber Orchestra and String Orchestra with authentic multi-staff previews', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MiniStaffPreview(
                  systemLayout: core.StaffProfiles.chamberOrchestra.systemLayout,
                  active: true,
                ),
                MiniStaffPreview(
                  systemLayout: core.StaffProfiles.stringOrchestra.systemLayout,
                  active: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MiniStaffPreview), findsNWidgets(2));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('L10n Systems Count Pluralization Tests', () {
    testWidgets('Outputs singular "1 System" when count is 1 and plural "{count} Systems" when count > 1', (tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(l10n.systemsCount(1), equals('1 System'));
      expect(l10n.systemsCount(2), equals('2 Systems'));
      expect(l10n.systemsCount(5), equals('5 Systems'));
    });
  });
}
