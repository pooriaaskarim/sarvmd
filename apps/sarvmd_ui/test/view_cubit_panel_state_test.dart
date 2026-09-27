// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_ui/src/logic/view/view_cubit.dart';
import 'package:sarvmd_ui/src/logic/view/view_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ViewState Panel & Section State Tests', () {
    test('defaults to mainMenu touch section and all 5 pointer sections expanded', () {
      const state = ViewState();
      expect(state.activeTouchSection, equals(SettingsSection.mainMenu));
      expect(state.expandedPointerSections, containsAll([
        SettingsSection.profiles,
        SettingsSection.pageSetup,
        SettingsSection.margins,
        SettingsSection.staffSpacing,
        SettingsSection.systemHierarchy,
      ]));
      expect(state.isPointerSectionExpanded(SettingsSection.margins), isTrue);
      expect(state.collapsedHierarchyGroups, isEmpty);
      expect(state.selectedHierarchyStaffUids, isEmpty);
      expect(state.jumpTargetSection, isNull);
    });

    test('copyWith updates panel sections and hierarchy state cleanly', () {
      const state = ViewState();
      final updated = state.copyWith(
        activeTouchSection: SettingsSection.staffSpacing,
        expandedPointerSections: {SettingsSection.staffSpacing},
        collapsedHierarchyGroups: {12345},
        selectedHierarchyStaffUids: {'staff_1', 'staff_2'},
        jumpTargetSection: SettingsSection.systemHierarchy,
      );

      expect(updated.activeTouchSection, equals(SettingsSection.staffSpacing));
      expect(updated.expandedPointerSections, equals({SettingsSection.staffSpacing}));
      expect(updated.isPointerSectionExpanded(SettingsSection.staffSpacing), isTrue);
      expect(updated.isPointerSectionExpanded(SettingsSection.margins), isFalse);
      expect(updated.collapsedHierarchyGroups, contains(12345));
      expect(updated.selectedHierarchyStaffUids, containsAll(['staff_1', 'staff_2']));
      expect(updated.jumpTargetSection, equals(SettingsSection.systemHierarchy));

      final cleared = updated.copyWith(clearJumpTarget: true);
      expect(cleared.jumpTargetSection, isNull);
    });
  });

  group('ViewCubit Panel & Section Actions', () {
    test('setTouchSection updates activeTouchSection', () {
      final cubit = ViewCubit();
      cubit.setTouchSection(SettingsSection.margins);
      expect(cubit.state.activeTouchSection, equals(SettingsSection.margins));
      cubit.close();
    });

    test('togglePointerSection and setPointerSectionExpanded update and persist', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = ViewCubit();

      expect(cubit.state.isPointerSectionExpanded(SettingsSection.profiles), isTrue);

      // Toggle off
      cubit.togglePointerSection(SettingsSection.profiles);
      expect(cubit.state.isPointerSectionExpanded(SettingsSection.profiles), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList('view_expanded_pointer_sections'),
        isNot(contains('profiles')),
      );

      // Set explicitly on
      cubit.setPointerSectionExpanded(SettingsSection.profiles, true);
      expect(cubit.state.isPointerSectionExpanded(SettingsSection.profiles), isTrue);

      // Collapse all
      cubit.collapseAllPointerSections();
      expect(cubit.state.expandedPointerSections, isEmpty);

      // Expand all
      cubit.expandAllPointerSections();
      expect(cubit.state.expandedPointerSections.length, equals(5));

      cubit.close();
    });

    test('jumpToSection expands target section and sets jumpTargetSection', () {
      final cubit = ViewCubit();
      cubit.collapseAllPointerSections();
      expect(cubit.state.isPointerSectionExpanded(SettingsSection.margins), isFalse);

      cubit.jumpToSection(SettingsSection.margins);
      expect(cubit.state.isPointerSectionExpanded(SettingsSection.margins), isTrue);
      expect(cubit.state.jumpTargetSection, equals(SettingsSection.margins));

      cubit.clearJumpTarget();
      expect(cubit.state.jumpTargetSection, isNull);

      cubit.close();
    });

    test('toggleHierarchyGroup and setHierarchySelection manage deep tree state', () {
      final cubit = ViewCubit();
      expect(cubit.state.collapsedHierarchyGroups, isEmpty);

      cubit.toggleHierarchyGroup(999);
      expect(cubit.state.collapsedHierarchyGroups, contains(999));

      cubit.toggleHierarchyGroup(999);
      expect(cubit.state.collapsedHierarchyGroups, isNot(contains(999)));

      cubit.setHierarchySelection({'uid_a', 'uid_b'});
      expect(cubit.state.selectedHierarchyStaffUids, equals({'uid_a', 'uid_b'}));

      cubit.clearHierarchySelection();
      expect(cubit.state.selectedHierarchyStaffUids, isEmpty);

      cubit.close();
    });

    test('cross-mode section retrieval: switching touch to pointer focuses active touch section', () {
      final cubit = ViewCubit();
      cubit.setInputMode(InputMode.touch);
      cubit.setTouchSection(SettingsSection.margins);
      expect(cubit.state.activeTouchSection, equals(SettingsSection.margins));

      // Switch to pointer mode: margins must become jumpTargetSection and be expanded!
      cubit.setInputMode(InputMode.pointer);
      expect(cubit.state.inputMode, equals(InputMode.pointer));
      expect(cubit.state.jumpTargetSection, equals(SettingsSection.margins));
      expect(cubit.state.isPointerSectionExpanded(SettingsSection.margins), isTrue);

      cubit.close();
    });

    test('cross-mode section retrieval: switching pointer to touch navigates into active pointer section', () {
      final cubit = ViewCubit();
      cubit.setInputMode(InputMode.pointer);
      cubit.setActiveSection(SettingsSection.staffSpacing);
      expect(cubit.state.jumpTargetSection, equals(SettingsSection.staffSpacing));

      // Switch to touch mode: activeTouchSection must become staffSpacing!
      cubit.setInputMode(InputMode.touch);
      expect(cubit.state.inputMode, equals(InputMode.touch));
      expect(cubit.state.activeTouchSection, equals(SettingsSection.staffSpacing));

      cubit.close();
    });
  });
}
