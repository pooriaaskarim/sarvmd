import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/document/document_cubit.dart';
import 'package:sarvmd_ui/src/logic/workspace/workspace_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkspaceCubit Multi-Document Lifecycle', () {
    late WorkspaceCubit workspaceCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      final docCubit = DocumentCubit(null, null, false);
      workspaceCubit = WorkspaceCubit(initialCubit: docCubit);
    });

    tearDown(() async {
      await workspaceCubit.close();
    });

    test('initial state contains exactly one active session', () {
      expect(workspaceCubit.state.tabCount, 1);
      expect(workspaceCubit.state.activeIndex, 0);
      expect(workspaceCubit.state.hasMultipleTabs, isFalse);
      expect(workspaceCubit.state.activeSession.id, 'tab_0');
      expect(workspaceCubit.state.activeSession.title, 'Treble_A4_Portrait');
    });

    test('openNewTab disambiguates duplicate titles placing number before extension/end', () {
      expect(workspaceCubit.state.sessions[0].title, 'Treble_A4_Portrait');

      final tab2 = workspaceCubit.openNewTab();
      expect(tab2.title, 'Treble_A4_Portrait_1');

      final tab3 = workspaceCubit.openNewTab();
      expect(tab3.title, 'Treble_A4_Portrait_2');

      final pianoTab = workspaceCubit.openNewTab(profile: core.StaffProfiles.piano);
      expect(pianoTab.title, 'Piano_A4_Portrait');

      final pianoTab2 = workspaceCubit.openNewTab(profile: core.StaffProfiles.piano);
      expect(pianoTab2.title, 'Piano_A4_Portrait_1');
    });

    test('openNewTab creates and focuses secondary tab', () {
      final newSession = workspaceCubit.openNewTab(profile: core.StaffProfiles.piano);

      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 1);
      expect(workspaceCubit.state.hasMultipleTabs, isTrue);
      expect(workspaceCubit.state.activeSession.id, newSession.id);
      expect(newSession.cubit.state.staffCount, 2); // Piano has 2 staves
    });

    test('switchTab changes active session without modifying sessions list', () {
      final tab2 = workspaceCubit.openNewTab();
      expect(workspaceCubit.state.activeIndex, 1);

      workspaceCubit.switchTab(0);
      expect(workspaceCubit.state.activeIndex, 0);
      expect(workspaceCubit.state.activeSession.id, 'tab_0');

      workspaceCubit.switchTab(1);
      expect(workspaceCubit.state.activeIndex, 1);
      expect(workspaceCubit.state.activeSession.id, tab2.id);
    });

    test('nextTab and previousTab cycle sequentially across tabs', () {
      workspaceCubit.openNewTab();
      workspaceCubit.openNewTab();
      expect(workspaceCubit.state.tabCount, 3);
      expect(workspaceCubit.state.activeIndex, 2);

      workspaceCubit.nextTab();
      expect(workspaceCubit.state.activeIndex, 0);

      workspaceCubit.previousTab();
      expect(workspaceCubit.state.activeIndex, 2);

      workspaceCubit.previousTab();
      expect(workspaceCubit.state.activeIndex, 1);
    });

    test('editing a document marks session as dirty and updates title reactively', () async {
      final initialTitle = workspaceCubit.state.activeSession.title;
      expect(workspaceCubit.state.activeSession.isDirty, isFalse);

      workspaceCubit.state.activeCubit.setTitle('Symphony No. 5');
      await pumpEventQueue();

      expect(workspaceCubit.state.activeSession.title, 'Symphony No. 5');
      expect(workspaceCubit.state.activeSession.title, isNot(initialTitle));
      expect(workspaceCubit.state.activeSession.isDirty, isTrue);
    });

    test('closeTab with unsaved changes respects guard cancellation', () async {
      workspaceCubit.openNewTab();
      workspaceCubit.state.activeCubit.setTitle('Unsaved Opus');
      await pumpEventQueue();
      expect(workspaceCubit.state.activeSession.isDirty, isTrue);

      bool guardCalled = false;
      final closed = await workspaceCubit.closeTab(1, unsavedGuard: (session) async {
        guardCalled = true;
        return false; // User clicked "Cancel"
      });

      expect(guardCalled, isTrue);
      expect(closed, isFalse);
      expect(workspaceCubit.state.tabCount, 2);
    });

    test('closeTab closes session and adjusts activeIndex', () async {
      final tab2 = workspaceCubit.openNewTab();
      workspaceCubit.openNewTab();

      expect(workspaceCubit.state.tabCount, 3);
      expect(workspaceCubit.state.activeIndex, 2);

      // Close the currently active tab (tab3)
      final closed = await workspaceCubit.closeTab(2);
      expect(closed, isTrue);
      expect(workspaceCubit.state.tabCount, 2);
      expect(workspaceCubit.state.activeIndex, 1);
      expect(workspaceCubit.state.activeSession.id, tab2.id);

      // Close first tab (tab1)
      final closedFirst = await workspaceCubit.closeTab(0);
      expect(closedFirst, isTrue);
      expect(workspaceCubit.state.tabCount, 1);
      expect(workspaceCubit.state.activeIndex, 0);
      expect(workspaceCubit.state.activeSession.id, tab2.id);
    });

    test('closing the sole tab resets to untitled document without destroying workspace', () async {
      expect(workspaceCubit.state.tabCount, 1);
      workspaceCubit.state.activeCubit.setTitle('Single Document');
      await pumpEventQueue();
      expect(workspaceCubit.state.activeSession.isDirty, isTrue);

      final closed = await workspaceCubit.closeTab(0);
      expect(closed, isTrue);
      expect(workspaceCubit.state.tabCount, 1);
      expect(workspaceCubit.state.activeSession.title, 'Treble_A4_Portrait');
      expect(workspaceCubit.state.activeSession.isDirty, isFalse);
    });

    test('reorderTabs moves tab to new position', () {
      final tab1 = workspaceCubit.state.activeSession;
      final tab2 = workspaceCubit.openNewTab();
      final tab3 = workspaceCubit.openNewTab();

      expect(workspaceCubit.state.sessions.map((s) => s.id).toList(), [
        tab1.id,
        tab2.id,
        tab3.id,
      ]);

      // Move tab3 (index 2) to start (index 0)
      workspaceCubit.reorderTabs(2, 0);

      expect(workspaceCubit.state.sessions.map((s) => s.id).toList(), [
        tab3.id,
        tab1.id,
        tab2.id,
      ]);
      expect(workspaceCubit.state.activeIndex, 0);
    });
  });

  group('WorkspaceCubit Session Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('flushes session state to SharedPreferences and restores upon initialization', () async {
      final initialCubit = WorkspaceCubit(autoRestoreSession: false);
      final tab2 = initialCubit.openNewTab(profile: core.StaffProfiles.piano);
      initialCubit.state.activeCubit.setTitle('Persisted Piano Piece');
      await pumpEventQueue();

      await initialCubit.flushSessionSave();
      await initialCubit.close();

      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(WorkspaceCubit.prefSessionKey);
      expect(savedJson, isNotNull);
      expect(savedJson, contains('Persisted Piano Piece'));

      // Now create a new WorkspaceCubit with autoRestoreSession: true
      final restoredCubit = WorkspaceCubit(autoRestoreSession: true);
      // Wait for async session restoration
      await pumpEventQueue();

      expect(restoredCubit.state.tabCount, 2);
      expect(restoredCubit.state.activeIndex, 1);
      expect(restoredCubit.state.sessions[1].id, tab2.id);
      expect(restoredCubit.state.activeSession.title, 'Persisted Piano Piece');

      await restoredCubit.close();
    });

    test('clearSavedSession removes persisted session from SharedPreferences', () async {
      final cubit = WorkspaceCubit(autoRestoreSession: false);
      cubit.openNewTab();
      await cubit.flushSessionSave();

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(WorkspaceCubit.prefSessionKey), isTrue);

      await WorkspaceCubit.clearSavedSession();
      prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(WorkspaceCubit.prefSessionKey), isFalse);

      await cubit.close();
    });
  });
}

