# UI State Preservation & Cross-Mode Panel Architecture

## 1. Executive Summary

This document specifies the architecture for preserving user interface state across viewports, input modalities (Pointer vs. Touch), and interactive panel collapses in SarvMD, addressing:
1. **Todo Item 13:** Right/settings panel state preservation (scroll position, active/open section, and deep widget state across collapses and breakpoint resizes).
2. **Todo Item 16:** Mobile virtual keyboard avoidance (preventing the software keyboard from obscuring numeric and textual inputs in drawers, side-sheets, and modals).

---

## 2. Current Architecture & Deficiencies

### 2.1 Pointer Mode vs. Touch Mode Disparity

| Dimension | Pointer Mode (`PointerEditorScreen`) | Touch Mode (`TouchEditorScreen`) |
| :--- | :--- | :--- |
| **Structure** | Monolithic vertical stream (unconditional full expansion of all 5 sections) | Progressive disclosure tree (Main Menu tiles $\to$ animated sub-pages) |
| **Viewport Form** | Docked sidebar ($>1000\text{px}$) or slide-over drawer ($<1000\text{px}$) | Modal `Drawer` (portrait) or anchored frosted side-sheet (landscape) |
| **Lifespan** | Stays mounted when docked; unmounts/rebuilds on dock breakpoint crossings | Completely destroyed on every outside tap, scrim tap, or gesture |
| **Section Addressability** | Unaddressed; relies strictly on arbitrary scroll offset | Addressable via `SettingsPanelSection` enum |

### 2.2 Root Failure Modes

1. **Ephemeral Drawer State:** In `_SettingsPanelState`, `_currentSection` is local to the widget. Closing the drawer or tapping the canvas garbage-collects the state, resetting the user to `mainMenu`.
2. **Lost Scroll Offsets:** Neither `ListView` in `PointerEditorScreen`, `ViewPanel`, nor `SettingsPanel` assigns a `PageStorageKey`. Switching between docked and overlay or rotating screens resets the scroll position to `0.0`.
3. **Deep Widget State Wiping:** In `SystemHierarchyPanel`, `_selectedUids` and `_collapsedGroupHashes` are held in `_SystemHierarchyPanelState`. Navigating sections or closing the panel resets all collapsed groups and selections.
4. **Keyboard Obstruction:** In `SettingsPanel`, the drawer body is wrapped in `SafeArea(top: !widget.isPanelDocked)` without consuming `MediaQuery.viewInsetsOf(context).bottom`. When the keyboard appears (280–360 dp), the lower half of the drawer is covered, and text fields cannot scroll above the keyboard.

---

## 3. The 3-Tier Integration Architecture

```
                  ┌──────────────────────────────────────────────┐
                  │           ViewState / ViewCubit              │
                  │  - activeSettingsSection (enum)             │
                  │  - expandedPointerSections (Set<Section>)   │
                  │  - collapsedGroupHashes (Set<int>)          │
                  │  - selectedStaffUids (Set<String>)          │
                  └──────────────────────┬───────────────────────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 │          Root PageStorageBucket               │
                 │  (Preserves scroll offsets in memory by key)   │
                 └───────────┬───────────────────────┬───────────┘
                             │                       │
                             ▼                       ▼
                  ┌────────────────────┐   ┌────────────────────┐
                  │ Pointer Mode       │   │ Touch Mode         │
                  │ - Addressable Cards│   │ - Main Menu        │
                  │ - Collapsible Sec. │   │ - Section Subpages │
                  └────────────────────┘   └────────────────────┘
```

### Tier 1: Unified Section Addressability
* Define a canonical `SettingsSection` enum shared across pointer and touch:
  * `profiles` (Ensemble Profiles)
  * `pageSetup` (Page Dimensions & Margins)
  * `staffSpacing` (Line Gap, System Gap, Inter-staff Gap)
  * `systemHierarchy` (Parts, Groups & Staff Layout)
  * `export` (Vector SVG, PDF, PNG)
* In **Touch Mode**: Renders as progressive disclosure (Main Menu $\to$ Category Sub-page). Reopening the drawer restores the active category.
* In **Pointer Mode**: Renders as collapsible, addressable accordion section cards with quick-jump headers or jump pills.
* Lift `activeSettingsSection` into `ViewState`.

### Tier 2: Scroll Retention via `PageStorageBucket`
* Mount a persistent `PageStorageBucket` at the application root (`AppShell`).
* Provide deterministic `PageStorageKey` instances:
  * `pointer_sidebar_scroll`
  * `pointer_view_panel_scroll`
  * `touch_settings_main_menu_scroll`
  * `touch_settings_section_${section.name}_scroll`
* Unmounting or resizing widgets preserves scroll offsets across transitions.

### Tier 3: Shared Deep State Synchronization
* Move `collapsedGroupHashes` and `selectedStaffUids` from `_SystemHierarchyPanelState` into `ViewCubit`.
* Folding an instrument family (e.g. "Woodwinds") or selecting a staff remains persistent across section navigations, panel dismissals, and mode switches.

---

## 4. Mobile Software Keyboard Avoidance

1. **Dynamic ViewInsets Insets:**
   * In `SettingsPanel`, wrap the content body with bottom inset padding:
     ```dart
     Padding(
       padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
       child: ...
     )
     ```
   * Enable `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` across all panel scrollables.
2. **ScrollPadding & Auto-Scroll Hooks:**
   * In `PrecisionSlider`, `MarginsSettingsGroup`, `StaffSpacingGroup`, and `AdvancedBuilderPanel`:
     * Set `scrollPadding: EdgeInsets.only(bottom: 80.0, top: 40.0)`.
     * Attach a focus node listener triggering `Scrollable.ensureVisible` on focus to ensure the field clears the software keyboard.
