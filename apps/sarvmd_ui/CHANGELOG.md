# Changelog - SarvMD UI

All notable changes to the `sarvmd_ui` application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.1.0] - 2026-08-06

### Added
- **Export Studio Redesign**: Multi-page PDF/SVG export modal with live preview, multiplatform directory picker integration (`file_picker`), page range selection, and custom save destinations.
- **SVG Layering Controls**: Configurable SVG vector emitter output modes (Flat, Hierarchical, and Minimal) in export dialogs.
- **SMuFL Bravura Integration**: Complete SMuFL font integration (`Bravura.otf`) for authentic piano brace rendering, cursive treble curls, spiral bass vectors, and accurate clef anchor alignment.
- **GitHub Pages & PWA Support**: Automated deployment pipeline (`.github/workflows/deploy_pages.yml`), PWA manifest (`manifest.json`), high-DPI favicons, and maskable application icons.
- **Profile Presets UI**: Interactive category selection bar with responsive tag wrapping and preset manuscript templates (Piano, Vocal, Solo, Ensemble).
- **Structured Logging**: Integrated `logd` logging framework across UI state management and core layout services.
- **Windows Desktop Support**: Windows build configuration, automated setup script (`setup_windows_build.ps1`), and native application resources (`app_icon.ico`).

### Changed
- **View Panel Sidebar Refactoring**: Streamlined ViewPanel sidebar by removing redundant notation preview sections to expand canvas workspace.
- **BLoC State Management**: Migrated state management architecture to `flutter_bloc` with decoupled cubits (`ConfigCubit`, `ViewCubit`).

### Fixed
- **Profile Picker Layout**: Fixed category tag wrapping in profile selection sidebar on narrow viewports.
- **ReorderableListView Deprecation**: Migrated legacy `onReorder` callback to `onReorderItem`.
- **Material Ink Splash**: Wrapped `CheckboxListTile` components in `Material` widgets to resolve UI rendering warnings.
