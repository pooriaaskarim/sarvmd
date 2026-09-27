// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/panels/collapsible_section_card.dart';

void main() {
  group('CollapsibleSectionCard Widget Tests', () {
    testWidgets('renders title, icon, and optional trailing action', (tester) async {
      bool expanded = true;
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSectionCard(
              section: SettingsSection.pageSetup,
              title: 'Page Setup',
              icon: Icons.description_outlined,
              isExpanded: expanded,
              onToggle: () => expanded = !expanded,
              action: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => actionTapped = true,
              ),
              child: const Text('Inner Content'),
            ),
          ),
        ),
      );

      expect(find.text('Page Setup'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Inner Content'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(actionTapped, isTrue);
    });

    testWidgets('toggles expansion when header is tapped', (tester) async {
      bool expanded = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: CollapsibleSectionCard(
                  section: SettingsSection.margins,
                  title: 'Margins',
                  icon: Icons.border_outer,
                  isExpanded: expanded,
                  onToggle: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  child: const SizedBox(
                    height: 100,
                    child: Text('Margin Sliders'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Initially expanded
      expect(find.text('Margin Sliders'), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.text('Margins'));
      await tester.pumpAndSettle();

      expect(expanded, isFalse);

      // Tap header again to expand
      await tester.tap(find.text('Margins'));
      await tester.pumpAndSettle();

      expect(expanded, isTrue);
    });

    testWidgets('animates height smoothly on expansion and collapse', (tester) async {
      bool expanded = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: CollapsibleSectionCard(
                  section: SettingsSection.staffSpacing,
                  title: 'Staff Spacing',
                  icon: Icons.format_line_spacing,
                  isExpanded: expanded,
                  onToggle: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  child: const SizedBox(
                    height: 200,
                    child: Text('Spacing Content'),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Initially collapsed: child content not present
      expect(find.text('Spacing Content'), findsNothing);
      expect(find.byType(AnimatedSize), findsOneWidget);

      // Tap to expand
      await tester.tap(find.text('Staff Spacing'));
      await tester.pumpAndSettle();

      // Expanded: child content is now present
      expect(find.text('Spacing Content'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('Staff Spacing'));
      await tester.pumpAndSettle();

      expect(find.text('Spacing Content'), findsNothing);
    });
  });
}
