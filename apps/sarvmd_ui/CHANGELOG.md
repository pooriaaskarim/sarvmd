# Changelog - SarvMD UI

All notable changes to the `sarvmd_ui` application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.7.0] - 2026-09-07

### Added
- **Unified Document State & Transactional Undo/Redo Engine**: Introduced `SarvDocument` domain model (combining `Score` AST and `PageConfig` physical layout) and `DocumentCubit` to manage unified document state and transactional undo/redo across both score notation and page layout mutations (`Ctrl+Z`, `Ctrl+Y`, top bar cluster, and Edit menu).
- **Command Coalescing Engine**: Automatic time-window command merging (`coalesceThreshold: 600ms`) in `CommandHistory` and drag-end commit callbacks (`onChangeStart`, `onChangeEnd`) in `PrecisionSlider`, ensuring continuous slider/stepper adjustments do not pollute the undo stack.
- **Sealed Domain Class Hierarchies**: Refactored `StaffNode` (`StaffNodeGroup`, `StaffDefinition`) and `Clef` (`TrebleClef`, `BassClef`, `AltoClef`, `TenorClef`, `PercussionClef`, `TabClef`) to sealed class hierarchies with pattern matching, type safety, and direct JSON serialization.
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
