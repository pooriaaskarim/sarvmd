// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/presentation/widgets/staff/margins_settings_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MarginsSettingsGroup & State Preservation Tests', () {
    late DocumentCubit cubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      cubit = DocumentCubit();
    });

    tearDown(() {
      cubit.close();
    });

    Widget buildTestHarness(core.Margins margins, {ValueChanged<bool>? onLinkChanged}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MarginsSettingsGroup(
            margins: margins,
            onLeftChanged: cubit.updateLeftMargin,
            onRightChanged: cubit.updateRightMargin,
            onTopChanged: cubit.updateTopMargin,
            onBottomChanged: cubit.updateBottomMargin,
            onHorizontalChanged: cubit.updateHorizontalMargins,
            onVerticalChanged: cubit.updateVerticalMargins,
            onReset: cubit.resetMargins,
            onLinkChanged: onLinkChanged ?? cubit.setMarginsLinked,
            onScrubStart: (_) {},
            onScrubEnd: () {},
          ),
        ),
      );
    }

    testWidgets('defaults to linked mode when margins are uniform', (tester) async {
      await tester.pumpWidget(buildTestHarness(const core.Margins()));
      await tester.pumpAndSettle();

      // In linked mode, VERT and HORZ are visible
      expect(find.byKey(const ValueKey('linked_margins_row')), findsOneWidget);
      expect(find.byKey(const ValueKey('independent_margins_grid')), findsNothing);
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('toggling link button unlocks margins and renders quad inputs', (tester) async {
      bool? lastReportedLinkState;
      await tester.pumpWidget(
        buildTestHarness(
          const core.Margins(),
          onLinkChanged: (val) => lastReportedLinkState = val,
        ),
      );
      await tester.pumpAndSettle();

      // Tap link button to unlock
      await tester.tap(find.byIcon(Icons.link));
      await tester.pumpAndSettle();

      expect(lastReportedLinkState, isFalse);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
      expect(find.byKey(const ValueKey('independent_margins_grid')), findsOneWidget);
      expect(find.text('TOP'), findsOneWidget);
      expect(find.text('BTM'), findsOneWidget);
      expect(find.text('LFT'), findsOneWidget);
      expect(find.text('RGT'), findsOneWidget);
    });

    testWidgets('preserves and immediately displays unlocked quad inputs when re-visited with asymmetric margins',
        (tester) async {
      // User set asymmetric margins: top=20, bottom=30, left=15, right=15, isLinked=false
      const asymmetric = core.Margins(
        top: 20.0,
        bottom: 30.0,
        left: 15.0,
        right: 15.0,
        isLinked: false,
      );

      await tester.pumpWidget(buildTestHarness(asymmetric));
      await tester.pumpAndSettle();

      // UI must immediately open in independent mode with 4 fields
      expect(find.byKey(const ValueKey('independent_margins_grid')), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
      expect(find.text('TOP'), findsOneWidget);
      expect(find.text('BTM'), findsOneWidget);
    });

    test('DocumentCubit updates and preserves isLinked state correctly', () {
      expect(cubit.state.config.margins.isLinked, isTrue);

      // Unlinking
      cubit.setMarginsLinked(false);
      expect(cubit.state.config.margins.isLinked, isFalse);

      // Updating individual top margin keeps isLinked false
      cubit.updateTopMargin(25.0);
      expect(cubit.state.config.margins.top, equals(25.0));
      expect(cubit.state.config.margins.bottom, equals(15.0));
      expect(cubit.state.config.margins.isLinked, isFalse);

      // Re-linking syncs bottom to top (25.0) and sets isLinked true
      cubit.setMarginsLinked(true);
      expect(cubit.state.config.margins.isLinked, isTrue);
      expect(cubit.state.config.margins.top, equals(25.0));
      expect(cubit.state.config.margins.bottom, equals(25.0));
    });
  });
}
