# Changelog - SarvMD UI

All notable changes to the `sarvmd_ui` application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Adaptive Dynamic Header ("Zen Top Bar") in Touch Mode**:
  - Implemented smart viewport-aware top bar pinning: defaults to pinned in portrait (`height >= 500dp`) and unpinned in landscape/compact screens (`height < 500dp`), reclaiming 15–20% of vertical canvas space.
  - Added an interactive pin/unpin toggle button (`Icons.push_pin` / `Icons.push_pin_outlined`) in the top bar with persistent user overrides.
  - Added full canvas gesture immersion: when unpinned, the top bar smoothly slides up off-screen (`Offset(0, -1.3)`) in sync with the bottom Conductor HUD on pan/zoom, restoring borderless score visibility.
  - Added a collapsible floating micro-pill mode with centered title capsule and one-tap expansion.
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
- **Mobile Landscape Side Navigation**:
  - Transformed the landscape menu into an on-demand, thumb-friendly side drawer with backdrop dismissal, keeping over 60% of the manuscript score in view.
  - Redesigned menu categories into a compact, single-screen layout with an integrated score summary below.
  - Automatically recalculates score fitting when rotating between portrait and landscape orientations.

### Fixed
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
