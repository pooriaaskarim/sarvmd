# SarvMD Workspace Instructions & Rules

## Release Versioning Procedure

### 1. Source-of-Truth Hierarchy
- **Dynamic Authority:** Top version section in `apps/sarvmd_ui/CHANGELOG.md` (`## [X.Y.Z] - YYYY-MM-DD`).
- **Static Baseline Constant:** `AppVersion.version` in `apps/sarvmd_ui/lib/src/core/constants/app_version.dart`.
- **Package Manifest:** `version:` field in `apps/sarvmd_ui/pubspec.yaml`.

### 2. Release Procedure Checklist
When cutting a new application release:
1. **Promote Changelog Entries:** In `apps/sarvmd_ui/CHANGELOG.md`, convert items under `## [Unreleased]` into a version header `## [X.Y.Z] - YYYY-MM-DD` and reset a fresh `## [Unreleased]` section above it.
2. **Update AppVersion Constant:** Update `static const String version = 'X.Y.Z';` in `apps/sarvmd_ui/lib/src/core/constants/app_version.dart`.
3. **Update Package Manifest:** Update `version: X.Y.Z` in `apps/sarvmd_ui/pubspec.yaml`.
4. **Run Verification Tests:** Execute `flutter test` in `apps/sarvmd_ui` to ensure `ChangelogService` parses `X.Y.Z` and all UI tests pass.
5. **Git Tagging:** Commit changes (`git commit -m "release: bump version to vX.Y.Z"`) and tag (`git tag -a vX.Y.Z -m "Release vX.Y.Z"`).

### 3. Architectural Versioning Rules
- **No Hardcoded Versions in UI:** Widgets (`SarvSplashScreen`, `LaunchCoordinator`, `AboutSarvDialog`, etc.) must never introduce inline version string literals. They must consume `ChangelogService.getLatestVersion()` or fall back to `AppVersion.version`.
- **No Alias Constants:** Do not create duplicate version alias fields (e.g. `fallbackVersion`). Reference `AppVersion.version` directly.
