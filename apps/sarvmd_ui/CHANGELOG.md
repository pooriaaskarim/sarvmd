# Changelog - SarvMD UI

All notable changes to the `sarvmd_ui` application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Master Engraving Bracket Cluster Architecture (`layout.dart`)**:
  - Replaced horizontal multi-column bracket staggering ("Russian-doll tiering") with classical master engraving cluster architecture (Bärenreiter, Breitkopf, Gould): outer brackets cluster tightly adjacent to inner brackets with standard 3.0mm spacing (`connectorLevelSpacingMm`).
  - Hierarchical outer-column group label positioning: group labels and section titles sit outside all covering connectors in a unified, aligned outer column, eliminating over 41mm of wasted horizontal margin space on nested woodwind/brass scores.
  - Hierarchical label offset delegation (`GroupPlacement.labelOffsetMm`): accurately tracks child group label widths to position parent family labels (e.g. *Woodwinds*, *Strings*) strictly outside nested sub-group labels without bracket displacement.
- **LaTeX Vector Emitter Hierarchical Labeling & Connectors (`emitter.dart`)**:
  - Full structural parity with Flutter Canvas, PDF, and SVG emitters: traverses all `SystemGroupPlacement` nodes in `system.groupPlacements` instead of only the root group.
  - Generates authentic bracket backbones, sub-brackets (without serif ticks), piano braces, and initial barlines with precise SMuFL offsets.
  - Integrated standard LaTeX zero-dependency `picture` text environment (`\put(x, -y){\makebox(0,0)[r]{...}}`) placing right-aligned group labels and staff instrument names/abbreviations with exact micrometer coordinates, Helvetica typography, and multi-line (`\shortstack[r]`) support.
- **Engraving Standards Research & 32-Scenario QA Visual Validation Gallery**:
  - Conducted comparative music engraving research (`standard_score_examples_and_subgroup_labeling.md`) benchmarking master publisher editions (Bärenreiter Urtext, Breitkopf & Härtel, Boosey & Hawkes, Durand, Gould) for sub-group space conservation (Model A flat inline, Model B centered names with inner numbers, and Model C section headers above staves).
  - Built an automated 32-scenario QA visual validation test generator (`tool/generate_qa_gallery.dart`) outputting side-by-side SVG, PDF, TeX, and an interactive HTML comparison gallery (`export_gallery.html`) covering all 14 presets, paper sizes (A3, A4, A5, Letter), orientations, layering modes, and complex hierarchical groupings.

### Changed
- **Gouldian Space-Efficient Hierarchical Labeling Architecture (`sarvmd_core` & `sarvmd_ui`)**:
  - **Local Inner Descriptor Scoping**: Scoped inner staff descriptor widths strictly to their immediate group branch, eliminating system-wide margin bloat where long instrument names (e.g. *Double Bass*) previously displaced unrelated sub-brackets (e.g. *Flutes 1 & 2*) by dozens of millimeters.
  - **Single-Tier vs Two-Tier Differentiation**: Single-tier groups without group labels (e.g. Piano grand staff, String Quartet) place connectors flush against the initial barline (`connectorOffsetMm = 0.0`) with staff names positioned outside, saving 6–10mm of margin width. Two-tier groups with outer labels properly enclose inner descriptors between the connector and staves.
  - **Subsequent System Compaction (Gould p. 515)**: Automatically omits family group labels (e.g. *Strings*, *Woodwinds*) on system 2+ when no explicit abbreviation is specified, reclaiming 20mm–48mm of printable notation width across subsequent systems and pages.
  - **Row-Aware Vertical Disjointness**: Replaced additive connector level offset accumulation across vertically separated instrument families with row-aware maximum indent calculations.
  - **Calibrated Gould/SMuFL Clearances (`GroupPlacementMetrics`)**: Tightened connector level spacing to 3.0mm, bracket tick length to 1.8mm, staff label clearance to 2.0mm, and connector inner clearance to 1.5mm.
  - **Unified Cross-Emitter Parity**: Identical geometry and alignment verified across Flutter Canvas (`preview_canvas.dart`), Vector PDF (`pdf_emitter.dart`), Vector SVG (`svg_emitter.dart`), and LaTeX (`emitter.dart`).

### Fixed
- **Sidebar Collapsible Sections & Scrollbar State Synchronization (`ViewCubit` & `SectionSpine`)**:
  - Fixed an issue where collapsing all sidebar sections in pointer mode caused them to randomly expand during scrolling or when selecting sections from the custom scrollbar.
  - Decoupled viewport scroll detection (`ViewCubit.setActiveSection`) from section expansion mutations: scrolling now only tracks the active touch section for custom scrollbar handle alignment without expanding collapsed cards or overriding `jumpTargetSection`.
  - Configured custom scrollbar bead selection (`ViewCubit.jumpToSection`) to explicitly expand the clicked section if collapsed, persist expansion state to `SharedPreferences`, and smoothly scroll into position while preserving the collapsed state of all other sections.
  - Added dedicated unit tests in `view_cubit_panel_state_test.dart` verifying that scrolling preserves collapsed states and bead clicks expand only the targeted section.

## [0.11.0] - 2026-09-30

### Added
- **Keyboard Shortcuts Cheat-Sheet Modal (`KeyboardShortcutsDialog`)**:
  - Comprehensive, categorized shortcut reference (File & Tabs, Edit & History, View & Navigation, Panels & Dialogs, General) accessible via `F1`, `Ctrl+?` (`⌘?` on macOS), and the Help top-bar menu.
  - Real-time search and category filtering with localized shortcut descriptions and keycap displays.
  - Native platform keycaps (⌘, ⌥, ⇧ for macOS; Ctrl, Alt, Shift for Windows/Linux) with strict LTR isolation under RTL/Persian locales.
- **Desktop Keyboard Shortcuts Suite & Gateway Expansion (`SarvShortcutGateway` & `PointerEditorScreen`)**:
  - Canvas Zooming: Added `Ctrl+=` / `⌘=` (Zoom In), `Ctrl+-` / `⌘-` (Zoom Out), and `Ctrl+0` / `⌘0` (Reset to 100% / Actual Size) with viewport center focal anchoring.
  - Panels & Layout Toggles: Added `Ctrl+B` / `⌘B` (Toggle Left Inspector/Sidebar), `Ctrl+\` / `⌘\` (Toggle Right View Panel), and `F11` (Toggle Zen Mode / Hide all sidebars).
  - Connected `Ctrl+N` / `⌘N` and `Ctrl+T` / `⌘T` directly to `WorkspaceCubit.openNewTab()` for instant tab creation in multi-document workspace mode.
  - Multi-entry Help Shortcuts: Bound `F1` and `Ctrl+?` / `⌘?` to open the Keyboard Shortcuts modal.
- **Top Bar Help Menu Shortcuts Entry (`TopBarHelpMenu` & `TopBarMenuHandler`)**:
  - Added "Keyboard Shortcuts" menu item with `F1` / `Ctrl+?` accelerator to the desktop Help menu and compact cascading menu.
- **Zero-Document Empty Workspace & Welcome Hub (`EmptyWorkspaceView`)**:
  - Seamless transition into a sleek, state-of-the-art "No Document / Welcome Hub" when all open tabs/manuscripts are closed (0 open sessions).
  - Minimal top navigation bar enforced with strict LTR orientation across all locales (anchoring `SarvBrandHeader` on the left and `InputModeToggleButton`, `LanguageToggleButton`, and theme toggle on the right).
  - Input-mode awareness: automatically suppresses desktop keyboard shortcut legends (`Ctrl+N`, `Ctrl+O`) when operating in Touch mode, and adapts the drop-target card prompt into a tap-to-open button ("Tap to open an existing .sarv manuscript").
  - Fully bilingual localized starter presets (Solo Treble, Grand Staff, Guitar + TAB, Chamber Orchestra) in both English and Persian (`app_en.arb`, `app_fa.arb`) with custom-vector `MiniStaffPreview` staves.
  - Interactive touch ergonomics: wrapped preset and history cards in Material `InkWell` ripples, mirrored forward chevrons in RTL layouts, allowed two-line subtitle wraps on mobile screens, and padded scrolling areas above OS navigation bars.
  - Centered hero section featuring full `SarvBrandHeader` with handwriting logo and Gouldian engraving typography.
  - "Browse all templates…" action launching `ProfilePicker` within an adaptive modal (`showSarvAdaptiveModal`).
  - "Recent Manuscripts" history card consuming `RecentDocumentsService` with path tooltips, click-to-open, and history clearing.
  - "Open other file…" primary action and full-window drag-and-drop landing prompt card with border highlighting.
  - Responsive single-column (portrait/narrow) and two-column (wide/desktop) adaptive layouts with zero layout overflow.
- **Desktop CLI Launch Argument Support (`FileOpenService`)**:
  - Direct opening of `.sarv` files from terminal command line or desktop launcher invocation (`sarvmd <file.sarv>`).
  - Integrated command-line argument passing from `main(List<String> args)` to `FileOpenService.init(launchArgs: args)`.
- **Multi-Tab Session State Persistence & Restoration (`WorkspaceCubit`)**:
  - Automatic persistence of multi-tab workspace sessions (all open tab document states, active tab index, and metadata) to `SharedPreferences` (`sarvmd_workspace_session`) with 500ms debouncing.
  - Transparent workspace session restoration upon application cold-start with concurrency lock coordination.
  - Added programmatic cache controls: `flushSessionSave()` and `clearSavedSession()`.
- **Canvas & Tab Bar File Drag-and-Drop (`desktop_drop`)**:
  - Native file drag-and-drop support across canvas and tab strip allowing users to drag `.sarv` files directly from OS file managers into the window to open in new tabs.
  - Responsive visual feedback overlay with glowing accent border and localized drop prompt (`dragDropOverlayHint`).
  - Resilient name/path resolution and error reporting for invalid or corrupted dropped files.
- **Native `.sarv` Document Persistence & Schema Architecture (`packages/sarvmd_core`)**:
  - Standardized native JSON document format (v1 schema) capturing complete manuscript layouts (`PageConfig`, nested `SystemLayout`, `Score`, and `DocumentMetadata`) with guaranteed zero data loss.
  - Comprehensive document metadata domain model capturing `title`, `composer`, `subtitle`, `arranger`, `lyricist`, `copyright`, `license`, `creationDate`, and `modificationDate`.
  - Resilient cross-platform deserialization supporting dynamic type coercion and UTF-8 Byte Order Mark (`\uFEFF`) detection and stripping.
- **Cross-Platform Document Persistence Engine (`SarvFileService`)**:
  - Direct file saving and opening for desktop platforms (Linux, macOS, Windows) and web browser integration via native file pickers and File System Access API.
  - Automatic `.sarv` extension enforcement, schema validation, and structured error reporting.
- **Transactional Persistence Lifecycle in `DocumentCubit`**:
  - Added `newDocument`, `loadDocument`, `openFile`, `save`, and `saveAs` transactional methods.
  - Intelligent dirty state tracking (`isDirty`) linked to command history clean marks (`CommandHistory.cleanMark`) and deep value-equality checking across undo and redo operations.
- **UI Persistence Controls & Unsaved Changes Guard**:
  - Sleek reactive dirty indicator dot (`●`) in `EditableScoreHeader` indicating unsaved changes.
  - Responsive `UnsavedChangesDialog` guarding New, Open, and Close workflows with localized HIG actions (Save, Don't Save, Cancel).
  - Top Bar File menu (`New`, `Open...`, `Save`, `Save As...`) and standard keyboard shortcuts (`Ctrl+N`, `Ctrl+O`, `Ctrl+S`, `Ctrl+Shift+S`).
- **Multi-Document Tabbed Workspace (`WorkspaceCubit` & `DocumentSession`)**:
  - Isolated multi-document state architecture managing independent `DocumentCubit` instances, file paths, and dirty state tracking without cross-tab interference.
  - Complete tab lifecycle operations: `openNewTab`, `openFileTab`, `openDocumentTab`, `switchTab`, `closeTab`, `closeOtherTabs`, `nextTab`, `previousTab`, and `reorderTabs`.
  - Dynamic facade in `AppShell` providing `activeCubit` to the entire widget tree with transparent fallback to ambient single-document setups.
- **Portrait-Optimized Pointer Tab Bar (`PointerTabBar` & `PointerTabItem`)**:
  - IDE-grade compact horizontal tab strip with dynamic sizing (30dp in portrait/narrow viewports, 32dp in landscape) and smooth horizontal scrolling with automatic scroll-to-active.
  - Enhanced close accessibility: active tabs expose both dirty indicator dots and 1-click close buttons, eliminating hover friction on touch/pointer hybrid devices and narrow portrait screens.
  - Tab overflow dropdown `[ ▾ ]` displaying a vertical tab picker with active checkmarks and dirty indicators when tabs exceed viewport width.
  - Complete keyboard shortcut gateway integration: `Ctrl+T` (new tab), `Ctrl+W` (close tab), `Ctrl+Tab` / `Ctrl+PageDown` (next tab), and `Ctrl+Shift+Tab` / `Ctrl+PageUp` (previous tab).
- **Touch Mode Zen Tab Switcher (`TouchTabSwitcherModal` & `TouchTopBar`)**:
  - Minimalist Zen top bar tab count pill (`[ 📑 N ]`), automatically suppressed during inline title editing to prevent horizontal crowding.
  - Frosted glassmorphic bottom sheet card switcher with drag handle, manuscript cards, staff count chips, dirty dots, swipe-to-dismiss closure, and "+ New Manuscript" button.
- **Bilingual File & Workspace Localization**:
  - Added comprehensive English (`app_en.arb`) and Persian (`app_fa.arb`) localization keys for all document management, file menus, unsaved changes dialogs, and tab actions.
- **Recent Documents History & Menu Integration (`RecentDocumentsService`)**:
  - Persistent recent documents history backed by `SharedPreferences` (`sarvmd_recent_documents`) capped at 10 items with deduplication, top promotion, and automatic pruning of non-existent files on native platforms.
  - Cascading `Open Recent ▸` submenu in desktop wide mode, compact application menu, and touch file menus with path tooltips, ellipsis truncation, and "Clear Recent Files" action.
  - Smart tab handling: opening a recent document that is already open focuses its existing tab rather than opening a duplicate session.
- **Score Metadata / Document Properties Dialog (`DocumentPropertiesDialog`)**:
  - Adaptive modal dialog (`showDocumentPropertiesDialog`) and bottom sheet on mobile for viewing and editing extended `.sarv` score metadata fields (`title`, `subtitle`, `composer`, `arranger`, `lyricist`, `copyright`).
  - Read-only document properties card showing exact file location on disk, creation timestamp, and last modified timestamp.
  - Transactional undo/redo integration with `DocumentCubit` via `core.SetMetadataCommand`, synchronized with `core.Score.title`.
  - Dedicated `Ctrl+I` / `Cmd+I` global keyboard shortcut and File menu item (`Document Properties…`).
- **Web `beforeunload` Unsaved Changes Protection**:
  - Registered browser-native `beforeunload` event handler via Dart JS-interop in `web_download_web.dart` triggered dynamically whenever any open tab has unsaved changes (`hasDirtyTabs`) to protect against accidental browser tab close or refresh data loss.
- **Cross-Platform Pre-Extension File Disambiguation Engine (`packages/sarvmd_core`)**:
  - Introduced zero-dependency `FileNaming` utility module (`appendSuffix`, `appendIndex`, `stripExtension`, `getExtension`, `disambiguateFileName`, `ensureUniquePath`).
  - Standardized collision disambiguation across platforms to strictly insert numeric indices immediately before file extensions (e.g. `Score (1).pdf` or `Score_1.pdf`) rather than trailing after the extension.
- **Editable Destination Folder & Path Normalization in Export Dialog (`ExportDialog` & `ExportDirectoryService`)**:
  - Upgraded the Destination Folder field to an interactive monospace text input supporting direct typing, path pasting, focus management, and automatic normalization.
  - Implemented `ExportDirectoryService.normalizeExportPath` with user tilde (`~`) expansion to home directory, stripping of `file://` URI schemes, redundant and trailing slash cleanup, and Windows drive letter path support, resolving file picker ambiguity on Linux desktop environments.
- **Comprehensive Persistence & Workspace Test Suites**:
  - Added end-to-end unit and widget test suites covering document serialization, file service operations, persistence cubit workflows, dirty state tracking, pointer tab bar interactions, touch tab switcher modal flows, recent documents service and UI integration, export directory path normalization, native Android SAF save contract, and document properties dialog workflows (`document_persistence_test.dart`, `sarv_file_service_test.dart`, `file_ui_components_test.dart`, `workspace_cubit_test.dart`, `pointer_tab_bar_test.dart`, `touch_tab_switcher_test.dart`, `recent_documents_test.dart`, `export_directory_service_test.dart`, `native_file_save_service_test.dart`, `document_properties_dialog_test.dart`).

### Changed
- **Document Model Decoupling**:
  - Decoupled `DocumentCubit` and `DocumentState` to carry file path and dirty state directly alongside `PageConfig`.
  - Streamlined `ScoreCommand` architecture to support non-mutating clean marks on document saving.

### Removed
- **Obsolete Notation AST & Experimental Composer**:
  - Purged legacy, incomplete music notation AST types (`clef.dart`, `pitch.dart`, `duration.dart`, `measure.dart`, `musical_event.dart`, `signature.dart`, `engraver.dart`, `spacing_spindle.dart`) and retired the experimental `sarvmd_composer` package.
  - Consolidated codebase strictly around high-performance blank canvas manuscript design and vector engraving.

### Fixed
- **Center-Focal Touch HUD Zoom (`FloatingHud`)**:
  - Fixed issue where touch HUD stepper zoom buttons (`+` and `-`) and scrubbable scale chips (`_CollapsedScrubbableChip`, `_ScrubbableZoomChip`) scaled the canvas from the world-space top-left origin `(0, 0)`.
  - Replaced naive translation retention with center-anchored affine transformation (`_applyScaleAtCenter`) using `MediaQuery.sizeOf(context)` to zoom smoothly into the viewport center.
- **Affine Scale Vector Component Sizing (`PointerEditorScreen`)**:
  - Corrected `scaleByDouble` invocation in `PointerEditorScreen._zoomBy` by supplying 4 positional vector parameters (`targetScale, targetScale, 1.0, 1.0`), resolving static analysis errors.
- **Zero-Document Action Safety (`SarvShortcutGateway`)**:
  - Guarded document shortcut callback handlers (`UndoIntent`, `RedoIntent`, `SaveDocumentIntent`, `SaveAsDocumentIntent`, `ExportIntent`, `DocumentPropertiesIntent`) against null `DocumentCubit` when operating within the zero-document empty workspace state.
- **Distinct File Deduplication for Copies & Identical Content (`WorkspaceCubit` & `AppShell`)**:
  - Fixed issue where distinct files with identical score contents (e.g. `sample.sarv` and `sample (1).sarv` created via "Save As" or copy-paste) were erroneously treated as the same document and deduplicated into a single tab due to indiscriminate score title and content equality matching.
  - Refined file deduplication criteria in `WorkspaceCubit.openDocumentTab` and `AppShell._handleDroppedFiles` to strictly require matching file identities (path or filename) when both documents have explicit file backings, reserving deep content equivalence matching (`hasSameContent`) strictly for untitled in-memory manuscripts.
- **Web Blob URL Sanitization & Document Name Parity (`DocumentState`, `WorkspaceCubit`, & `AppShell`)**:
  - Resolved issue where opening or dropping files on Web displayed random UUID hashes (e.g. `9bf3e8d2-4521-4f1a-b678-0123456789ab`) as the document tab title and default save name instead of the actual file name.
  - Guarded `DocumentState.displayName`, `WorkspaceCubit.openDocumentTab`, `SarvFileService.openSarvFile`, and `RecentDocumentsService.addRecentDocument` against Web `blob:` and `http:` object URLs, strictly normalizing to the genuine file name (`file.name`).
- **Web & Desktop Document Tab Deduplication & Drag-and-Drop Parity (`WorkspaceCubit` & `AppShell`)**:
  - Resolved issue in Web where dragging or opening an already-open `.sarv` document created redundant duplicate tabs rather than switching to the existing open tab.
  - Added robust multi-criteria deduplication in `WorkspaceCubit.openDocumentTab` matching by exact file path, filename/basename, and document content equivalence across desktop and web.
  - Ensured Web dropped files and opened files retain their file identity (`filePath: fileName`) so loaded documents are never mistaken for blank placeholder tabs or duplicated upon subsequent drag-and-drop operations.
  - Added "Switched to tab" visual feedback and icon indicator parity when dragging already-open documents on Web.
- **Android SAF Pre-Extension Duplicate Numbering (`NativeFileSaveService` & `MainActivity.kt`)**:
  - Resolved Android Storage Access Framework (SAF) issue where filename collision numbers were placed after the extension (e.g. `Treble_A4_Portrait.pdf (1)` or `Treble_A4_Portrait.sarv (1)`).
  - Implemented `NativeFileSaveService` bridging to native Android `ACTION_CREATE_DOCUMENT` with explicit MIME types (`application/pdf`, `image/svg+xml`, `text/plain`, `application/octet-stream`).
  - Added native post-creation regex inspection and `DocumentsContract.renameDocument` handling in `MainActivity.kt` to ensure collision indices are strictly positioned immediately before the extension (`Treble_A4_Portrait (1).pdf` and `Treble_A4_Portrait (1).sarv`).
- **Touch Tab Switcher Synchronous Dismissal & Empty Workspace Recovery (`TouchTabSwitcherModal` & `WorkspaceCubit`)**:
  - Fixed Flutter framework crash `A dismissed Dismissible widget is still part of the tree` in `TouchTabSwitcherModal` by synchronously removing dismissed items from local state prior to awaiting asynchronous tab closure operations.
  - Hardened `WorkspaceCubit` when dismissing or closing the final active tab, automatically initializing a fresh default manuscript session (`createDefaultSession`) rather than corrupting state or leaving an empty workspace.
- **Web Build File Saving & Destination Selection (`saveFileWeb`)**:
  - Upgraded Web file saving to utilize the modern File System Access API (`window.showSaveFilePicker`), prompting users with the native OS file picker to select a destination directory and customize or confirm the file name.
  - Automatically populated the save dialog with the document's intelligent default display name (`ScoreTitle.sarv` or `Untitled Manuscript.sarv`).
  - Fixed premature `URL.revokeObjectURL` invocation in `downloadFileWeb`, eliminating browser download truncation to 0 bytes and loss of default filenames during browser downloads.
- **Web Build `.sarv` Document Loading & Parity (`openFileWeb`)**:
  - Resolved issue where loading `.sarv` documents in Web failed with corrupt file errors by bypassing `file_picker`'s web `JSArrayBuffer` casting limitation in favor of direct `window.showOpenFilePicker` and `FileReader.readAsText`.
  - Added automatic UTF-8 BOM (`\uFEFF`) stripping and dynamic Map deserialization resilience to guarantee full cross-platform compatibility with documents created on Linux or Windows.
  - Added `WorkspaceCubit.openDocumentTab` to mount parsed documents into tabs directly without attempting unsupported direct filesystem reads on Web.
- **Recent Documents Menu Activation & Deactivated Ancestor Error (`TopBarFileMenu`)**:
  - Fixed a crash (`Looking up a deactivated widget's ancestor is unsafe`) when opening a document from the Open Recent submenu caused by `BuildContext` shadowing inside `RecentDocumentsService`'s `ValueListenableBuilder`.
- **Android File Picker Extension Filter & Storage Resilience (`SarvFileService`)**:
  - Resolved `PlatformException(FilePicker, Unsupported filter...)` on Android caused by Android OS `MimeTypeMap` failing to resolve unregistered custom `.sarv` file extensions.
  - Configured `FileType.any` on Android and mobile platforms, paired with graceful `PlatformException` recovery and strict JSON/schema content validation.
  - Hardened `saveAsSarvFile` against Storage Access Framework (SAF) direct file write exceptions.
  - Re-routed `handleOpenRecentDocument` to bind to the persistent top bar widget's `BuildContext` instead of the transient menu popup overlay element tree that is deactivated upon item tap.
  - Hardened cubit resolution in `top_bar_menu_handler.dart` by resolving `WorkspaceCubit` and `DocumentCubit` synchronously before asynchronous suspension points, and guarded UI dialog and snackbar feedback with `context.mounted`.

## [0.10.0] - 2026-09-27

### Changed
- **Intent-Based Nomenclature & Touch/Pointer Architecture**:
  - Renamed `mobile/` directory to `touch/` and established intent-first component naming (`TouchCanvasArea`, `TouchTopBar`, `FloatingHud`, `SettingsPanel`).
  - Renamed screens to `PointerEditorScreen` and `TouchEditorScreen`, and top bar to `PointerTopBar`.
  - Replaced ambiguous breakpoint names in `SarvBreakpoints` with explicit layout event names (`bothSidebarsDockedMinWidth`, `primarySidebarDockedMinWidth`, `fullMenuBarMinWidth`).
- **Standardized Responsive Display Contract (`SarvDisplayContext`)**:
  - Introduced `SarvDisplayData`, `SarvDisplayContext`, `SarvDisplayScope`, and `SarvFormFactor` (`phone`, `tablet`, `desktop`) to decouple input modality from viewport classification.
  - Migrated modal dialogs (`showSarvAdaptiveModal`, `AboutSarvDialog`, `ExportDialog`, `StaffConfigDialog`, and configuration tabs) away from raw `MediaQuery` checks.
- **Unified Canvas Geometry Engine (`CanvasZoomCalculator`)**:
  - Centralized zoom preset calculations, safe-area offsets, and transformation matrices into `CanvasZoomCalculator`, eliminating duplicate zoom math across editor shells.
- **Reboot-Free Input Mode Switching (`AppShell`)**:
  - Introduced `AppShell` as the root adaptive shell listening to `ViewCubit.state.inputMode` via `AnimatedSwitcher`.
  - Upgraded `InputModeToggleButton` to switch modes instantaneously without destroying the navigator history stack or replaying the splash screen.

### Added
- **Mobile Keyboard Inset Resilience & Comfortable Input Clearance**:
  - Wrapped `SettingsPanel` drawer content in `AnimatedPadding` reacting to `MediaQuery.viewInsetsOf(context).bottom`, shrinking the inner `ListView` scroll viewport and ensuring focused inputs remain visible when the soft keyboard appears.
  - Adapted modal bottom sheets and dialogs in `showSarvAdaptiveModal` to constrain `maxHeight` by available height (`screenHeight - viewInsets.bottom`) and lift the sheet cleanly above the keyboard.
  - Standardized `AppSpacing.keyboardScrollPadding` (64px bottom clearance) across numeric scrubbers, margins, staff spacing, precision sliders, export dialogs, and hierarchy labeling fields, guaranteeing generous headroom above on-screen software keyboards.
  - Added comprehensive widget test suite (`mobile_keyboard_inset_test.dart`) covering drawer shrinking, text field visibility, and modal bottom sheet positioning under soft keyboard view insets.
- **Cross-Mode Panel State Synchronization & "The Section Spine" Navigation Rail**:
  - Implemented bidirectional active section handoff between Pointer Mode (desktop sidebar with `SectionSpine`) and Touch Mode (drawer subpages), maintaining focused section context across mode toggles and window resizes.
  - Built "The Section Spine" (`SectionSpine`): a slender, constant 22px scroll rail featuring piecewise-linear handle mapping, dynamic top-section viewport detection, and click-to-jump-and-expand navigation.
  - Modularized spine rail architecture into focused components: `SectionSpineTrack` (groove, progress fill, boundary stops), `SectionSpineHandle` (fader thumb with tactile 3-line ribbed grip and grab cursor), and `SectionSpineBead` (jewel buttons with frosted-glass floating badges and fold chips).
  - Unboxed sidebar sections (`CollapsibleSectionCard`): removed heavy card containers and borders for a spacious full-width layout with dynamic, non-clipping stationary states.
  - Reclaimed 16px of horizontal space on Pointer sidebar by reducing right padding to 8px, and reserved 4px safety margins around profile cards to prevent hover clipping.
- **Progressive Multi-Tier Desktop Top Bar & Cascading App Menu**:
  - Implemented progressive multi-tier compaction for desktop viewports (`SarvBreakpoints.desktopTopBarMenuThreshold = 760.0`).
  - Added a dedicated application menu button `[ ☰ ]` (`TopBarCompactAppMenu`) for viewports narrower than 760px that opens a clean cascading `MenuAnchor` with 4 submenus (*File ❯*, *Edit ❯*, *View ❯*, *Help ❯*).
  - Standardized all desktop menus (`TopBarFileMenu`, `TopBarEditMenu`, `TopBarViewMenu`, `TopBarHelpMenu`) to use unified `MenuAnchor`, `MenuItemButton`, and `SubmenuButton` structures, exposing reusable static `buildChildren` builders.
  - Reorganized page size presets in the View menu under a cascading `Score Page Sizes ▸` submenu with active selection indicators.
- **Adaptive Dynamic Header ("Zen Top Bar") in Touch Mode**:
  - Implemented smart viewport-aware top bar pinning: defaults to pinned in portrait (`height >= 500dp`) and unpinned in landscape/compact screens (`height < 500dp`), reclaiming 15–20% of vertical canvas space.
  - Added an interactive pin/unpin toggle button (`Icons.push_pin` / `Icons.push_pin_outlined`) in the top bar with persistent user overrides.
  - Added full canvas gesture immersion: when unpinned, the top bar smoothly slides up off-screen (`Offset(0, -1.3)`) in sync with the bottom Conductor HUD on pan/zoom, restoring borderless score visibility.
  - Standardized the collapsed floating top bar to a 40dp capsule height (matching the expanded toolbar and coordinate HUD) with a reactive intrinsic width dynamically sized to document title length with clamped bounds (`120dp` to `340dp`).
  - Added dynamic ruler clearance: positioned unpinned top bar (both collapsed capsule and expanded toolbar) 6dp below the top ruler and 8dp past the left ruler, preventing any ruler occlusion or origin-switcher blocking.
  - Implemented conflict-free coordinate HUD visibility: long-pressing and dragging on the canvas to inspect coordinates automatically collapses and dismisses the floating top bar off-screen, giving unobstructed visibility to the top glassmorphic coordinate HUD.
  - Enhanced inline title editing: temporarily hides flanking top bar controls in tight/portrait screens to maximize text field room, complete with a dedicated Done button, click-outside auto-save, and system back navigation handling.
- **Safe-Area Aware Rulers & Edge-to-Edge Bleed**:
  - Top and left manuscript canvas rulers now dynamically adapt to device notches, status bars, and display cutouts.
  - The canvas background bleeds edge-to-edge under the status bar, while `RulerBox` expands its top and left background strips and positions graduation numbers, ticks, and the `mm` origin switcher safely below cutouts.
- **Dual-Island Mobile Conductor Toolbar & Gestural Drawer Trigger**:
  - Decoupled the mobile bottom HUD into independent Left (menu, undo, redo) and Right (zoom, telemetry, guides) wings with 11dp ruler clearance and independent idle auto-collapse timers.
  - Implemented continuous bi-directional drag zoom on both collapsed and expanded zoom chips (drag up/right to zoom in, down/left to zoom out) with tactile haptic selection clicks.
  - Added smooth idle visual transitions on the collapsed zoom chip: active interaction renders prominent percentage text with a subtle background watermark; after 2.5s of inactivity, the percentage softens and the magnifier watermark smoothly fades in.
  - Added a horizontal right-drag gesture on the Menu HUD in both collapsed and expanded states to intuitively open the navigation drawer (or landscape side sheet) with tactile haptic feedback.
- **Adaptive Desktop Responsive Layout**:
  - Automatically transitions sidebars between docked mode on wide monitors, floating canvas overlays on medium screens, and auto-collapsing slide-out drawers on split or compact windows, ensuring the manuscript canvas remains fully visible.
  - Added high-visibility edge resize handles with smooth dragging and persistent panel widths.
- **Pointer vs. Touch Interaction Toggle**:
  - Added an input mode toggle in the top bar to freely switch between precision desktop pointer controls and touch-first mobile navigation on any screen size.
- **Automated Android CI Pipeline**:
  - Added automated build workflows to package and attach signed release APKs on Git version tags.

### Changed
- **Decoupled Brand Logo From Dropdown Trigger**:
  - `SarvReactiveBrandLogo` now consistently operates as a pure interactive brand mark (`isMenuMode: false`) across wide and compact desktop modes, preserving hover expansion to *"Manuscript Designer"* and tap-to-About interactions.
  - Replaced the legacy 416-line flat popup menu (`compact_menu.dart`) with native cascading submenus sharing the exact desktop menu tree.
- **Mobile Landscape Side Navigation**:
  - Transformed the landscape menu into an on-demand, thumb-friendly side drawer with backdrop dismissal, keeping over 60% of the manuscript score in view.
  - Redesigned menu categories into a compact, single-screen layout with an integrated score summary below.
  - Automatically recalculates score fitting when rotating between portrait and landscape orientations.

### Removed
- **Obsolete Top-Bar Ensemble Profile Picker**:
  - Permanently removed `EnsembleProfilePicker` from the top bar and codebase, reclaiming ~130px of horizontal top bar real estate and eliminating redundant profile switching controls since profile configuration is fully handled in the sidebar.

### Fixed
- **Canvas Hold-and-Drag Coordinate HUD in Touch Mode**:
  - Suppressed duplicate bottom coordinate readout during canvas hold-and-drag inspection in `TouchEditorScreen`, maintaining focus on the top coordinate HUD.
- **Top Bar Title Editing Space & Padding**:
  - Re-enabled flexible title field expansion (`expandInEditMode`) in `EditableScoreHeader` across both `PointerTopBar` and `TouchTopBar`, eliminating artificial 240/300px width bottlenecks and large empty gaps during inline title editing.
- **Dialog Ergonomics on Compact & Landscape Screens**:
  - Resolved cramped layout and overflow issues in staff configuration, calibration, and export dialogs on short viewports and dynamically resized windows.
  - Added adaptive preview scaling and compact tab bars to the staff configuration modal.
- **Grouped Staff Removal Integrity**:
  - Fixed an issue where removing an individual instrument within an ensemble group could unintentionally delete the entire parent section.

---

## [0.9.0] - 2026-09-22

### Highlights
- **Professional Two-Tier Hierarchical Labeling**: Create orchestral and ensemble scores with publication-ready section labels (*Flutes*, *Violins*) and inner staff identifiers (*1, 2*, *I, II*) that automatically calculate dynamic margins to prevent connector collisions.
- **Unified Drag-and-Drop System Builder**: Structure complex ensemble layouts directly from the sidebar with drag-and-drop grouping, multi-staff selection, and instant inline label editing.
- **Authentic Engraving Standards (Gould & MOLA)**: Enhanced initial system barlines, secondary sub-brackets, and SMuFL Bravura tablature clefs for exact print and export parity.

### Added
- **Hierarchical System Labeling & Smart Clearance**:
  - **Two-Tier Section & Staff Names**: Assign overarching group names (e.g., *Woodwinds*, *Brass*) alongside individual instrument descriptors.
  - **Dynamic Page Indentation**: The first system automatically indents to accommodate multi-line and long instrument names without clipping or manual margin guessing.
  - **Collision-Free Brackets**: Outer section brackets and inner sub-brackets automatically maintain a clean safety buffer around instrument labels and abbreviations.
- **Streamlined System Hierarchy Workspace**:
  - **Direct Drag-and-Drop Reordering**: Move staves, reorder sections, or nest instruments into sub-groups directly on the canvas sidebar.
  - **Batch Selection Bar**: Check multiple staves simultaneously to group them or adjust their properties together in a single click.
  - **Agile Inline Renaming**: Click directly on any staff or section label to edit it in place, with automatic save when clicking away or pressing Enter.
  - **Context-Sensitive Quick Pickers**: Change clefs, line counts, and bracket connectors right from each staff card without navigating deep setting menus.
- **Authentic Engraving & Export Fidelity**:
  - **Initial System Barlines**: Multi-staff ensembles and standalone TAB systems now cleanly close at the left edge, while solo classical staves remain authentically open per Elaine Gould's *Behind Bars* engraving guidelines.
  - **Bravura Tablature Clefs**: Authentic SMuFL vector glyphs for 4-string and 6-string TAB staves, perfectly proportioned and centered across PDF, SVG, and live display.
  - **Standardized Multi-Format Export Dialog**: Redesigned tabbed export center for PDF, SVG, and LaTeX with customizable page count and real-time dimension readouts.

### Changed
- **Frictionless Numeric Scrubbing**:
  - Dragging to adjust margins or staff spacing now feels completely fluid and uninterrupted, removing text selection highlights and handles.
  - Clicking any numeric input selects the whole value so you can type a new number in a single keystroke.
- **Refined Mobile Coordinate HUD**:
  - Positioned inspection coordinates clear of ruler markings for effortless reading on touchscreen devices.
  - Cleaned up redundant bottom readouts during long-press canvas inspection.
- **Enhanced Dark Mode Contrast**:
  - Improved color contrast across cards, badges, and headers for fatigue-free manuscript editing in low-light environments.
- **Modular Staff Settings**:
  - Reorganized staff configuration into dedicated tabs (Clef & Lines, Typography, Fine-Tuning) for a cleaner, less cluttered interface.

### Fixed
- **Connector Alignment on Live Preview**: Fixed alignment gaps between system brackets and measure barlines during real-time layout resizing.
- **Header Overflow Protection**: Eliminated badge and text overflows on narrow phone displays and compact sidebars.

---

## [0.8.0] - 2026-09-17

### Added
- **Redesigned Mobile Interface & Workspace**:
  - **Full-Bleed Canvas & Ultra-Minimal Header**: Maximized manuscript view on mobile screens with quick document title editing and instant export access.
  - **Floating Baton Control Dock**: Combined drawer triggers, undo/redo, real-time zoom steppers, preset shortcuts (`Fit Width`, `Fit Screen`), and overlay guide toggles into a single floating frosted-glass dock.
  - **Smart Toolbar Auto-Collapse**: Floating baton dock automatically collapses after 4s of inactivity into a compact FAB and temporarily hides during active canvas gestures to keep the screen uncluttered.
- **Interactive Measurement & Touch Inspection Tools**:
  - **Real-Time Glassmorphic Coordinate HUD**: Interactive floating HUD bar displaying live millimeter dimensions (X, Y) and physical `PAPER` vs `MARGIN` status badges on hold & drag.
  - **Touch-Guided Ruler Wings**: Real-time crosshair indicator lines on the top and left rulers tracking finger movement on hold & drag.
- **Enhanced Mobile Navigation Drawer**:
  - **Categorized Workspace Sections**: Dedicated navigation sections for profile presets, page setup, staff spacing, system hierarchy, and manuscript export.
  - **Manuscript Summary Metrics Card**: Live readout of total systems count, staves count, system height, density, and physical page size.
  - **Touch-Friendly Control Group**: Quick theme mode, accent color picker, and application language selector.
- **Adaptive Modal Bottom Sheets**:
  - Settings dialogs now seamlessly render as drag-to-dismiss bottom sheets on mobile devices and centered modals on desktop.
  - Enhanced layout boundaries to ensure smooth scrolling and prevent keyboard overlap across screen sizes.

### Changed
- **Unified Manuscript Metrics**: Consolidated document layout summary calculations into a single shared component across desktop and mobile.
- **Refined Touch Feedback**: Improved touch target areas and added subtle haptic feedback for long-press coordinate inspection.

### Fixed
- **Physical "Actual Size" DPI Auto-Calibration**: Fixed physical 1:1 scale calculation logic on mobile and high-DPI displays by factoring `devicePixelRatio` into auto-detected screen density math, ensuring 100% "Actual Size" zoom precisely matches real-world physical millimeter dimensions across devices.
- **Android Export Path Permission**: Resolved file export issues on Android devices using native file picker saving.
- **Landscape Zoom Boundaries**: Optimized minimum scale limits for landscape viewport fitting.

---

## [0.7.0] - 2026-09-07

### Added
- **Core Domain & Engraving Abstractions (`sarvmd_core`)**:
  - **Sealed `Clef` Hierarchy**: Polymorphic sealed `Clef` class hierarchy (`TrebleClef`, `BassClef`, `AltoClef`, `TenorClef`, `PercussionClef`, `TabClef`) replacing procedural string/enum switches with reference pitch (`referencePitch`), anchor line (`anchorLine`), and octave shift (`octaveShift`) properties.
  - **Sealed `StaffNode` Tree Hierarchy**: Structural system layout representation using composable `StaffNodeGroup` and `StaffDefinition` tree nodes supporting system connectors (`brace`, `bracket`, `line`, `none`) and continuous barlines.
  - **Unified `SarvDocument` Value Model**: Combined immutable domain snapshot encapsulating `Score` notation AST and `PageConfig` physical layout into a single source of truth.
  - **Engraving Token Abstraction (`EngravingConfig`)**: Centralized layout spacing, Gouldian engraving rules, SMuFL glyph scales, and barline overhang tokens embedded in `PageConfig`.
  - **Layout Policy Abstraction (`LayoutPolicyMode`)**: Core policy modes (`bilingualFluid`, `canvasStrict`, `documentRtl`) abstracting physical CAD boundaries, canvas orientation, and BiDi parameter enforcement.
  - **Direct PDF Vector Emitter Abstraction (`pdf_emitter.dart`)**: Pure Dart zero-dependency vector PDF compilation engine operating in memory.
- **Unified Document State & Transactional Undo/Redo Engine**: Introduced `SarvDocument` domain model (combining `Score` AST and `PageConfig` physical layout) and `DocumentCubit` to manage unified document state and transactional undo/redo across both score notation and page layout mutations (`Ctrl+Z`, `Ctrl+Y`, top bar cluster, and Edit menu).
- **Command Coalescing Engine**: Automatic time-window command merging (`coalesceThreshold: 600ms`) in `CommandHistory` and drag-end commit callbacks (`onChangeStart`, `onChangeEnd`) in `PrecisionSlider`, ensuring continuous slider/stepper adjustments do not pollute the undo stack.
- **Instrument Preset Registry**: Introduced `InstrumentRegistry` featuring 5 instrument families, presets with exact line counts and default clefs, and `LayoutPolicyMode` support.
- **`ScoreCompiler` Service**: Centralized service in `sarvmd_core` for LaTeX/PDF/SVG compilation, effective title resolution (`getEffectiveTitle`), default file name generation, and query sanitization.
- **Top Bar Staff Management Sub-Menus**: Added standard **Add Staff to System** sub-menu (Treble, Bass, Grand Staff, Guitar TAB, Rhythm, Custom), **Edit Staff** sub-menu (launches `StaffConfigDialog` for any active staff), and **Remove Staff** sub-menu with safety checks in `TopBarEditMenu`.
- **Global Keyboard Shortcut Gateway**: Integrated `SarvShortcutGateway` wrapping the application layout to catch global `Ctrl+Z` (Undo) and `Ctrl+Y` (Redo) keyboard shortcuts seamlessly.
- **Calligraphic Reactive Brand Logo**: Created `SarvReactiveBrandLogo` with mouse hover expansion animation, compact menu trigger, and calligraphic vector branding.
- **`sarvmd_composer` Monorepo Package**: Initialized `packages/sarvmd_composer` housing `PlaybackEngine` for audio synthesis and `MusicXMLTranscriber` for score transcription.
- **Complete Top Bar Persian Localization**: Added Persian ARB translations for all top bar menus, headers, status badges, profile names, sub-menus, and tooltips in `app_fa.arb`.
- **Monorepo Validation Gate Script**: Added executable `scripts/full_validation_gate.sh` bash script to automate full multi-package static analysis and test suite verification.

### Changed
- **Modular Top Bar Architecture**: Refactored `SarvTopBar` into decoupled modular components (`top_bar_menu_header.dart`, `top_bar_menu_handler.dart`, `editable_score_header.dart`, `ensemble_profile_picker.dart`, `undo_redo_cluster.dart`, `file_menu.dart`, `edit_menu.dart`, `view_menu.dart`, `help_menu.dart`, `compact_menu.dart`).
- **Compact Viewport Menu Parity**: Ported all desktop menu bar features (Add/Edit/Remove Staff, View settings, Export, About, Language switch) to the compact logo dropdown menu (<960px).
- **Single Source of Truth Title Synchronization**: Synchronized score title with file export names via `EditableScoreHeader` center-zone inline editing and `ScoreCompiler.getEffectiveTitle`.
- **Score AST Streamlining**: Removed obsolete `composer` field from `Score` AST and commands to focus `Score` strictly on title metadata and part definitions.
- **State Management Consolidation**: Deleted obsolete separate `ScoreCubit` and `ConfigCubit` implementations, unifying all state under `DocumentCubit`.
- **Custom Staff Preset Defaults**: Custom staves now initialize with clean, empty labels instead of defaulting to `"Custom Staff"`.

### Fixed
- **Staff Deletion Safety Guards**: Implemented minimum staff count guards in `RemoveStaffByUidCommand` and `StaffConfigDialog` to prevent accidental deletion of the last remaining staff in a manuscript layout.
- **Continuous Input Undo History**: Resolved undo history bloat during live slider drag operations by executing coalesced transactional commands on drag completion.
- **History Counter Status Badge**: Clarified history counter representation (`History (#)`) in the Edit menu to accurately display current undo stack depth.

---

## [0.6.2] - 2026-08-25

### Added
- **GitHub Repository Launcher**: Added `url_launcher` integration and an interactive GitHub action button to `AboutSarvDialog` with in-app browser launch mode and automated copy-to-clipboard fallback.
- **Advanced Builder Panel Localization Keys**: Added ARB localization keys for staff counts (`staffNumber`, `linesCount`), clef badges (`noClef`, `clefWithLine`), connector pickers, tooltips, and badges across English (`app_en.arb`) and Persian (`app_fa.arb`).
- **Release Versioning Procedure Ruleset**: Established and documented a formal 5-step release versioning procedure and architectural invariants in `.agents/AGENTS.md`.

### Changed
- **Single-Source Version Consolidation**: Refactored `SarvSplashScreen`, `LaunchCoordinator`, `AboutSarvDialog`, and `ChangelogService` to eliminate hardcoded version strings (`'0.6.0'`) and redundant alias constants (`fallbackVersion`). Standardized static baseline version resolution on `AppVersion.version` and dynamic resolution on `ChangelogService.getLatestVersion()`.
- **Profile Cards RTL & Localization**: Added dynamic `Directionality` and localized category badges to `ProfilePicker` and `_ProfileCard`, ensuring inner titles, descriptions, category pills, and card layouts dynamically adapt to RTL directionality and right alignment in Persian mode.
- **Advanced Builder Panel L10n Standardization**: Standardized `SystemHierarchyPanel`, `_StaffGroupWidget`, `_StaffItem`, and `_ConnectorPicker` by removing manual `isRtl` branching, replacing all hardcoded English strings with `AppLocalizations`, and streamlining bidirectional layout rows.

### Fixed
- **System Hierarchy Header RTL Reactivity & Pixel Overflows**: Resolved static LTR positioning of the system settings title and `"Add Staff"` button row, and eliminated narrow-sidebar `RenderFlex` pixel overflows in `_StaffGroupWidget` by adjusting compact threshold bounds.

---

## [0.6.1] - 2026-08-24

### Added
- **Calligraphic Splash Screen & Launch Coordinator**: Dynamic startup boot coordinator (`LaunchCoordinator`) executing a shared-element Hero transition into `EditorScreen`, official calligraphic handwriting logo animation (`SarvSplashScreen`), automated version parsing from `CHANGELOG.md`, and progress indicator.
- **Glassmorphic Language Transition Overlay**: `LanguageTransitionOverlay` component wrapping `MaterialApp` with a real-time backdrop blur filter (`ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0)`) and animated rotation emblem (`_AnimatedLanguageBadge`) during language switches.
- **URL Parameterization & Web Deep Linking**: `parseLocaleFromUri()` in `LocaleCubit` supporting query parameters (`?lang=en` / `?lang=fa`, `?locale=...`) and hash fragments, enabling direct web navigation into English or Persian UI modes with persistent `SharedPreferences` caching.

### Changed
- **Default Locale to English**: Updated default application fallback locale to English (`en`) while preserving persistent user language selection across launches.
- **Persian Documentation & Readme Refinement**: Refined tone, readability, and technical terminology in Persian documentation (`README.fa.md`) and updated live web app badge links with `?lang=en` and `?lang=fa` parameters across English and Persian READMEs.

---

## [0.6.0] - 2026-08-24

### Added
- **Vazirmatn Persian Typography Engine**: Integrated Vazirmatn variable font family across `fa` locale sidebars, dialogs, and panels.
- **Complete Persian Localization (`app_fa.arb`)**: Comprehensive Persian translations for all UI sidebars (`DocumentSettingsGroup`, `MarginsSettingsGroup`, `StaffSpacingGroup`), preset cards, export modals, and calibration dialogs.
- **Dynamic Language Switcher**: `LanguageSwitchControl` component and `LocaleCubit` integration for instant runtime language switching with persistent `shared_preferences` storage.
- **Declarative `PropertyRow` Primitive**: Standardized settings row primitive enforcing consistent label alignment and interactive control placement (Pillar 1).
- **Semantic `TextTheme` Infrastructure**: Material 3 typography token system replacing legacy inline font styling (Pillar 2).
- **Centralized `UnitFormatter` Engine & Test Suite**: `unit_formatter.dart` utility standardizing physical measurements (`mm`, `pt`, `%`, `px`, `PPI`, dimensions) across all sidebars, dialogs, and canvas HUD overlays with a strict ASCII-digit invariant (`0-9`) and full unit test coverage (`unit_formatter_test.dart`) (Pillar 4).

### Changed
- **`LayoutPolicy` Contracts & Window Frame Locking**: Introduced `LayoutPolicyMode` (`bilingualFluid`, `canvasStrict`, `documentRtl`), `CanvasStrictScope`, and `BilingualFluidScope`. Top-level `Scaffold` body `Row` is locked to LTR so Left Sidebar, Canvas Center, and Right View Panel never swap physical screen positions (Pillar 3).
- **CAD Navigation & Physical Control Layouts**: Enforced LTR CAD physical layout rules for document orientation switchers, margin 2x2 quad fields, slider tracks, and zoom scale navigation controls (`IntegratedScaleControl`).
- **BiDi Paragraph Text Formatting**: Enhanced Persian profile card titles and descriptions with RTL text directionality, resolving sentence dots (`.`), parentheses `(SATB)`, and dashes to the visual end (left side) of Persian phrases.

---

## [0.5.2] - 2026-08-12

### Added
- **Pure-Dart Direct Vector PDF Emitter**: Integrated native pure-Dart PDF rendering engine (`pdf_emitter.dart`) in `sarvmd_core` (`emitPdf`, `emitCompiledPdfPages`) allowing direct, zero-dependency PDF generation in memory without requiring host `pdflatex` installations.
- **Web Browser PDF Export**: Enabled 100% offline web PDF downloads via browser blob URL triggers (`web_download_web.dart`).

### Changed
- **Default PDF Export Pipeline**: Updated `ExportService.exportPdf` to use direct vector PDF emission as the default export strategy across Web, Desktop, and Mobile while preserving raw `.tex` source export functionality (`exportTex`).

### Fixed
- **Instrument Labels & System Indentation**: Enabled instrument name and abbreviation rendering (`def.instrumentName`, `def.instrumentAbbreviation`) across PDF, SVG, and LaTeX emitters with automatic space-aware system left indentation (`leftIndentMm`).
- **Scale-Accurate SVG Typography**: Resolved SVG label font double-scaling by serializing unitless font sizes matching the SVG `viewBox` millimeter coordinate space.
- **Responsive Branding Header**: Wrapped `SarvHeader` in a responsive `FittedBox` scale-down container to eliminate horizontal `RenderFlex` overflow warnings on narrow sidebar viewports.

---

## [0.5.1] - 2026-08-07

### Added
- **System-Wide Engraving Configuration (`EngravingConfig`)**: Introduced a centralized configuration object for layout spacing and rendering constants (`initialClefClearanceSp`, `keySignatureAccidentalSpacingSp`, `singleLineStaffBarlineOverhangSp`, `heavyBarlineWidthSp`, `smuflGlyphScale`) embedded within `PageConfig`.

### Changed
- **Unified Emitter & UI Pipeline**: Refactored LaTeX PDF emitters, SVG vector emitters, and interactive Flutter canvas painters (`preview_canvas.dart`, `live_staff_preview.dart`, `clef_config_widget.dart`) to consume `EngravingConfig` tokens instead of hardcoded magic numbers.

### Fixed
- **Standardized Clef Clearance**: Standardized clef positioning at `0.5` staff spaces from the start of the staff line across PDF compilation, SVG exports, and live UI preview widgets.
- **System Layout Panel Overflow**: Resolved label clipping and overflow in left panel on narrow viewports with dedicated sub-card layout for continuous barlines toggle and tooltip-enabled text truncation.

---

## [0.5.0] - 2026-08-06

### Added
- **Export Studio Redesign**: Multi-page PDF/SVG export modal with live preview, multiplatform directory picker integration (`file_picker`), page range selection, and custom save destinations.
- **SVG Layering Controls**: Configurable SVG vector emitter output modes (Flat, Hierarchical, and Minimal) in export dialogs.
- **GitHub Pages & PWA Support**: Automated deployment pipeline (`.github/workflows/deploy_pages.yml`) with version-tag and manual triggers, PWA manifest (`manifest.json`), high-DPI favicons, and maskable application icons.
- **Live Demo Branding**: Integrated live web app badges across English (`README.md`) and Persian (`README.fa.md`) documentation.

### Changed
- **View Panel Sidebar Refactoring**: Streamlined ViewPanel sidebar by removing redundant notation preview sections to expand canvas workspace.

### Fixed
- **Profile Picker Layout**: Fixed category tag wrapping in profile selection sidebar on narrow viewports.

---

## [0.4.0] - 2026-07-28

### Added
- **SMuFL Bravura Migration**: Complete SMuFL font integration (`Bravura.otf`) replacing legacy fonts for authentic piano brace rendering, cursive treble curls, spiral bass vectors, and accurate clef anchor alignment.
- **Inkscape SVG Layer Groups**: SVG export pipeline enhanced with Inkscape-compatible layer groups (`layer:flat`, `layer:hierarchical`, `layer:minimal`).
- **Profile Presets UI**: Interactive horizontal category bar (Piano, Vocal, Solo, Ensemble) with glassmorphic presets.
- **Structured Logging**: Integrated `logd` logging framework across UI state management and core layout services.
- **Windows Desktop Support**: Native Windows build setup (`setup_windows_build.ps1`), build automation, and application icon resources (`app_icon.ico`).

### Changed
- **BLoC State Management**: Migrated state management architecture from legacy `ChangeNotifier` to `flutter_bloc` with decoupled cubits (`ConfigCubit`, `ViewCubit`).
- **System Indentation & Labels**: Space-aware multi-line instrument labels and high-precision margins property panel with live canvas HUD.

---

## [0.3.0] - 2026-07-15

### Added
- **Domain AST & Engraving Compiler**: Core domain AST models (`sarvmd_core`), Gouldian spacing spindle, and SMuFL glyph registry.
- **MOLA Compliance**: MOLA-compliant layout standards, range-based staff spacing controls, and ensemble configurations.
- **Calligraphic Splash Screen**: Premium calligraphic splash screen on desktop application launch.
- **Developer Workflows**: Git Flow documentation, terminology glossary, DCO policies, and local git hook installer scripts.

---

## [0.2.0] - 2026-07-02

### Added
- **Clef Symbol Engine**: SMuFL-compliant Clef Symbol rendering engine with vertical alignment stability.
- **Mouse Wings Crosshairs**: Performance-optimized mouse wings ruler guides for real-time canvas crosshair alignment.
- **Display Calibration**: Persistent display scaling engine with automatic PPI detection.
- **Page Orientation Controls**: Orientation settings (Portrait/Landscape) and dynamic layout switcher.

---

## [0.1.0] - 2026-06-15

### Added
- **Initial Prototype**: Core manuscript engine supporting PDF compilation via LaTeX literals and Flutter `CustomPainter` vector paths.
- **Workspace Canvas**: Photoshop-style adaptive rulers with zoom range controls (50% - 400%).
- **Standard Page Sizes**: Supported A4, A3, A5, B5, and US Letter page sizes with symmetric margin configurations.
