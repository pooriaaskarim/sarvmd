// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/panels/section_spine.dart';

void main() {
  group('SectionSpine Widget Tests', () {
    late ScrollController scrollController;
    late GlobalKey key1;
    late GlobalKey key2;
    late GlobalKey key3;
    late List<SectionSpineEntry> entries;

    setUp(() {
      scrollController = ScrollController();
      key1 = GlobalKey();
      key2 = GlobalKey();
      key3 = GlobalKey();
      entries = [
        SectionSpineEntry(
          section: SettingsSection.pageSetup,
          label: 'Page Setup',
          icon: Icons.description_outlined,
          key: key1,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.margins,
          label: 'Margins',
          icon: Icons.border_outer,
          key: key2,
          isExpanded: false,
        ),
        SectionSpineEntry(
          section: SettingsSection.staffSpacing,
          label: 'Staff Spacing',
          icon: Icons.format_line_spacing,
          key: key3,
          isExpanded: true,
        ),
      ];
    });

    tearDown(() {
      scrollController.dispose();
    });

    testWidgets('renders SectionSpine, track gesture detector, and beads for each section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SectionSpine(
                scrollController: scrollController,
                entries: entries,
                onJumpToSection: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SectionSpine), findsOneWidget);
      // Parent drag detector + track tap detector + bead gesture detectors
      expect(find.byType(GestureDetector), findsNWidgets(entries.length + 2));
    });

    testWidgets('triggers onJumpToSection callback when bead is clicked', (tester) async {
      SettingsSection? jumpedSection;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SectionSpine(
                scrollController: scrollController,
                entries: entries,
                onJumpToSection: (sec) {
                  jumpedSection = sec;
                },
              ),
            ),
          ),
        ),
      );

      // The bead detectors are inside the Positioned widgets
      final positionedDetectors = find.descendant(
        of: find.byType(Positioned),
        matching: find.byType(GestureDetector),
      );
      // Index 0 is the track tap detector, index 1 is pageSetup, index 2 is margins
      await tester.tap(positionedDetectors.at(2));
      await tester.pumpAndSettle();

      expect(jumpedSection, SettingsSection.margins);
    });

    testWidgets('rail width stays slender 22px while handle bulks up on pointer hover', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 400,
                child: SectionSpine(
                  scrollController: scrollController,
                  entries: entries,
                  onJumpToSection: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      // Outermost container is the first AnimatedContainer
      final railFinder = find.byType(AnimatedContainer).first;
      final handleFinder = find.byKey(const ValueKey('section_spine_handle'));
      expect(railFinder, findsOneWidget);
      expect(handleFinder, findsOneWidget);

      expect(tester.getSize(railFinder).width, 22.0);
      expect(tester.getSize(handleFinder).width, 8.0);

      // Simulate mouse enter on SectionSpine
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byType(SectionSpine)));
      await tester.pumpAndSettle();

      // Rail must NOT bulk up (stays 22.0), while handle bulks up to 22.0!
      expect(tester.getSize(railFinder).width, 22.0);
      expect(tester.getSize(handleFinder).width, 22.0);

      // Move mouse away
      await gesture.moveTo(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(tester.getSize(railFinder).width, 22.0);
      expect(tester.getSize(handleFinder).width, 8.0);
    });

    testWidgets('renders section icons even when collapsed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: SectionSpine(
                scrollController: scrollController,
                entries: entries,
                onJumpToSection: (_) {},
              ),
            ),
          ),
        ),
      );

      // Section icons must be rendered in collapsed state
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.border_outer), findsOneWidget);
      expect(find.byIcon(Icons.format_line_spacing), findsOneWidget);
    });

    testWidgets('enables scrolling when dragging vertically on SectionSpine', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 300,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        height: 1200,
                        color: Colors.red,
                        child: Column(
                          children: [
                            Container(key: key1, height: 400, color: Colors.blue),
                            Container(key: key2, height: 400, color: Colors.green),
                            Container(key: key3, height: 400, color: Colors.yellow),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: SectionSpine(
                      scrollController: scrollController,
                      entries: entries,
                      onJumpToSection: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scrollController.offset, 0.0);

      // Drag downward along the spine track
      final spineFinder = find.byType(SectionSpine);
      final center = tester.getCenter(spineFinder);
      await tester.dragFrom(center, const Offset(0, 100));
      await tester.pumpAndSettle();

      // Scroll position must have moved down!
      expect(scrollController.offset, greaterThan(0.0));
    });

    testWidgets('handle position synchronizes with section scroll offsets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 300,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [
                          Container(key: key1, height: 400, color: Colors.blue),
                          Container(key: key2, height: 400, color: Colors.green),
                          Container(key: key3, height: 400, color: Colors.yellow),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: SectionSpine(
                      scrollController: scrollController,
                      entries: entries,
                      onJumpToSection: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final handleFinder = find.byKey(const ValueKey('section_spine_handle'));
      final initialHandleY = tester.getCenter(handleFinder).dy;

      // Scroll to key2 offset (400)
      scrollController.jumpTo(400.0);
      await tester.pumpAndSettle();

      final section2HandleY = tester.getCenter(handleFinder).dy;
      expect(section2HandleY, greaterThan(initialHandleY));

      // Scroll to key3 offset (800)
      scrollController.jumpTo(800.0);
      await tester.pumpAndSettle();

      final section3HandleY = tester.getCenter(handleFinder).dy;
      expect(section3HandleY, greaterThan(section2HandleY));
    });

    testWidgets('clicking second item section in ListView correctly aligns handle with second bead', (tester) async {
      final keyProfiles = GlobalKey();
      final keyPageSetup = GlobalKey();
      final keyMargins = GlobalKey();
      final keyStaffSpacing = GlobalKey();
      final keyHierarchy = GlobalKey();

      final fiveEntries = [
        SectionSpineEntry(
          section: SettingsSection.profiles,
          label: 'Profiles',
          icon: Icons.queue_music,
          key: keyProfiles,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.pageSetup,
          label: 'Page Setup',
          icon: Icons.description,
          key: keyPageSetup,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.margins,
          label: 'Margins',
          icon: Icons.space_dashboard,
          key: keyMargins,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.staffSpacing,
          label: 'Staff Spacing',
          icon: Icons.format_line_spacing,
          key: keyStaffSpacing,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.systemHierarchy,
          label: 'System Hierarchy',
          icon: Icons.account_tree,
          key: keyHierarchy,
          isExpanded: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              width: 320,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
                      children: [
                        Container(key: keyProfiles, height: 350, color: Colors.blue),
                        Container(key: keyPageSetup, height: 450, color: Colors.green),
                        Container(key: keyMargins, height: 400, color: Colors.yellow),
                        Container(key: keyStaffSpacing, height: 400, color: Colors.orange),
                        Container(key: keyHierarchy, height: 600, color: Colors.purple),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 2,
                    child: SectionSpine(
                      scrollController: scrollController,
                      entries: fiveEntries,
                      onJumpToSection: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find second bead detector (index 1 in fiveEntries, detector index 2 in stack)
      // Stack has: 0=Track tap detector, 1=Profiles bead, 2=PageSetup bead, 3=Margins bead...
      final positionedDetectors = find.descendant(
        of: find.byType(Positioned),
        matching: find.byType(GestureDetector),
      );
      // Bead 0 is at index 2, Bead 1 (Page Setup) is at index 3
      final pageSetupDetector = positionedDetectors.at(3);

      // Tap second bead (Page Setup)
      await tester.tap(pageSetupDetector);
      await tester.pumpAndSettle();

      final handleFinder = find.byKey(const ValueKey('section_spine_handle'));
      final handleCenterY = tester.getCenter(handleFinder).dy;

      expect((handleCenterY - 174.5).abs(), lessThan(5.0));
    });

    testWidgets('tracking through second item section moves handle between bead 1 and bead 2 without jumping to bottom', (tester) async {
      final keyProfiles = GlobalKey();
      final keyPageSetup = GlobalKey();
      final keyMargins = GlobalKey();
      final keyStaffSpacing = GlobalKey();
      final keyHierarchy = GlobalKey();

      final fiveEntries = [
        SectionSpineEntry(
          section: SettingsSection.profiles,
          label: 'Profiles',
          icon: Icons.queue_music,
          key: keyProfiles,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.pageSetup,
          label: 'Page Setup',
          icon: Icons.description,
          key: keyPageSetup,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.margins,
          label: 'Margins',
          icon: Icons.space_dashboard,
          key: keyMargins,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.staffSpacing,
          label: 'Staff Spacing',
          icon: Icons.format_line_spacing,
          key: keyStaffSpacing,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.systemHierarchy,
          label: 'System Hierarchy',
          icon: Icons.account_tree,
          key: keyHierarchy,
          isExpanded: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              width: 320,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
                      children: [
                        Container(key: keyProfiles, height: 350, color: Colors.blue),
                        Container(key: keyPageSetup, height: 450, color: Colors.green),
                        Container(key: keyMargins, height: 400, color: Colors.yellow),
                        Container(key: keyStaffSpacing, height: 400, color: Colors.orange),
                        Container(key: keyHierarchy, height: 600, color: Colors.purple),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 2,
                    child: SectionSpine(
                      scrollController: scrollController,
                      entries: fiveEntries,
                      onJumpToSection: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final handleFinder = find.byKey(const ValueKey('section_spine_handle'));

      // Jump midway into Page Setup: offset = 350 (Profiles) + 16 (padding) + 200 = 566
      scrollController.jumpTo(566.0);
      await tester.pumpAndSettle();

      final handleCenterY = tester.getCenter(handleFinder).dy;
      expect(handleCenterY, greaterThan(174.5));
      expect(handleCenterY, lessThan(300.0));
    });

    testWidgets('auto-scrolls to activeSection on initial mount when activeSection is set', (tester) async {
      final keyProfiles = GlobalKey();
      final keyPageSetup = GlobalKey();
      final keyMargins = GlobalKey();

      final threeEntries = [
        SectionSpineEntry(
          section: SettingsSection.profiles,
          label: 'Profiles',
          icon: Icons.queue_music,
          key: keyProfiles,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.pageSetup,
          label: 'Page Setup',
          icon: Icons.description,
          key: keyPageSetup,
          isExpanded: true,
        ),
        SectionSpineEntry(
          section: SettingsSection.margins,
          label: 'Margins',
          icon: Icons.space_dashboard,
          key: keyMargins,
          isExpanded: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              width: 320,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
                      children: [
                        Container(key: keyProfiles, height: 400, color: Colors.blue),
                        Container(key: keyPageSetup, height: 500, color: Colors.green),
                        Container(key: keyMargins, height: 600, color: Colors.yellow),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 2,
                    child: SectionSpine(
                      scrollController: scrollController,
                      entries: threeEntries,
                      activeSection: SettingsSection.pageSetup,
                      onJumpToSection: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On initial mount with activeSection: pageSetup, scrollController should auto-scroll to Page Setup (~416)
      expect(scrollController.offset, greaterThan(350.0));
    });
  });
}
