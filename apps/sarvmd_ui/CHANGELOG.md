# Changelog - SarvMD UI

All notable changes to the `sarvmd_ui` application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

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
