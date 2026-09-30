# SarvMD: Labeling System Maturation — Research, Gaps, and Refactoring Plan

> **Scope:** A complete audit of what professional music engraving standards demand for a labeling system, compared to what SarvMD currently implements, with a prioritized engineering plan.

---

## Part 1: What a Standard Labeling System Must Look Like

### 1.1 The Three Labeling Contexts

Professional engraving recognizes **three distinct labeling contexts**, each with its own spatial contract:

| Context | Object | Typography | Alignment | Placement |
|:---|:---|:---|:---|:---|
| **A. Group Label** | Family/section (Woodwinds, Strings) | Bold, Roman (upright), 11–12pt | Right-aligned, centered on group span | Left margin, outside all brackets |
| **B. Staff Descriptor** | Individual instrument voice (Fl. 1, Vla., Pno.) | Italic (System 1 full name), abbrev. (System 2+) | Right-aligned, centered on staff midline | Between bracket and barline (inner) OR outside bracket (outer) |
| **C. Section Header** | Section title above staves (WOODWINDS, BRASS) | Bold, ALL CAPS, tracked | Left-aligned, flush at barline X | Above topmost staff of the group |

SarvMD models A and C. **Context B's spatial geometry is partially modeled** — the `StaffDefinition` style fields are scattered, and descriptor placement (inside vs. outside the connector) is not modeled at all.

---

### 1.2 What Every Published Score Does: The Five Engraving Laws

Based on Gould (*Behind Bars*, pp. 509–525), MOLA Guidelines, Bärenreiter practice, and Sibelius/Dorico defaults:

#### Law 1: Two-Name / Two-System Rule
- **System 1:** Full instrument name, italicized (e.g., *Flauto piccolo*, *Violoncello*).
- **System 2+:** Standard abbreviation, italicized (e.g., *Fl. picc.*, *Vc.*).
- Abbreviation is **authoritative and mandatory** — if omitted, repeating the full name is an engraving defect.
- **SarvMD gap:** `instrumentAbbreviation` is `String?` (nullable). The UI never signals it is expected or missing.

#### Law 2: Non-Redundancy (Gould p. 511)
- When a group label is present, individual staves must not repeat the instrument stem.
- Correct: `Flutes [ 1 / 2 / Piccolo`. Error: `Flutes [ Flute 1 / Flute 2`.
- **SarvMD status:** ✓ Implemented via `resolveStaffLabel` + `isGenericStaffLabel`.

#### Law 3: Descriptor Placement — Inside vs. Outside the Connector *(not implemented)*
- **Inside (Enclosed) — Anglo-American:** Connector displaced outward; descriptors live **between connector and barline** (Gould/Boosey & Hawkes).
- **Outside (Flush) — Continental European:** Connector flush at barline; descriptors sit **to the left of the connector** (Bärenreiter, Breitkopf, Durand, Henle).
- **Brace rule (Universal):** `{` is always flush. Labels always outside.
- **SarvMD gap:** All connectors behave as *enclosed* (Anglo-American only). No `descriptorPlacement` property exists.

#### Law 4: Vertical Headroom for Above-Staff Headers *(not implemented)*
- When a group header prints above the staff (Model C), inter-system gap must include vertical headroom.
- On System 2+, the above-staff text collides with the bottom of the prior system.
- **SarvMD gap:** `computeLayout` does not add headroom for `GroupLabelPlacement.aboveStaff` groups. **Active visual bug.**

#### Law 5: Subsequent-System Header Suppression *(partially broken)*
- Model C headers appear only on System 1 (MOLA) or first system per page (Bärenreiter).
- **SarvMD gap:** `resolveGroupLabel` returns `group.abbreviation` for subsequent systems, printing it as an above-staff header on every system.

---

### 1.3 Feature Matrix vs. Professional Software

| Dimension | Sibelius | Dorico | SarvMD |
|:---|:---|:---|:---|
| Full name (System 1) | ✓ | ✓ | ✓ |
| Short name (System 2+) | ✓ required | ✓ required | ✓ optional |
| Group label | ✓ | ✓ | ✓ |
| Group abbreviation | ✓ | ✓ | ✓ |
| Descriptor placement (flush vs. enclosed) | ✓ per group | ✓ per group | ❌ |
| Above-staff section headers | ✓ | ✓ | ✓ Model C |
| Above-staff headroom reservation | ✓ | ✓ | ❌ active bug |
| Header suppression on System 2+ | ✓ | ✓ | ❌ partial bug |
| Per-staff label font | ✓ | ✓ | ✓ (5 scattered fields) |
| Auto-numbering | ✓ | ✓ | ✓ Model B |

---

## Part 2: SarvMD Gap Analysis

### 2.1 Domain Model (`config.dart`)

| ID | Issue | Severity |
|:---|:---|:---|
| G1 | `StaffDefinition` carries label aesthetics inline (5 loose fields) — no `StaffLabelStyle` object | Medium |
| G2 | `instrumentAbbreviation` is `String?` with no UI signal when missing | Medium |
| G3 | `StaffNodeGroup` has no `descriptorPlacement` field | **High** |
| G4 | `StaffNodeGroup` has no `headerVisibility` (Model C lifecycle control) | **High** |
| G5 | No `allGroups` flattened getter on `StaffNodeGroup` (needed for headroom scan) | Low |

### 2.2 Layout Engine (`layout.dart`)

| ID | Issue | Severity |
|:---|:---|:---|
| L1 | No headroom reservation for `aboveStaff` groups — visual bug on multi-system pages | **Critical** |
| L2 | `resolveGroupLabel` prints `group.abbreviation` as above-staff header on every system | **High** |
| L3 | `innerStaffIndices` recomputed independently in both layout and every emitter | Medium |
| L4 | Above-staff clearance `2.5mm` hardcoded in all 4 emitters — not a shared constant | Low |
| L5 | `StaffPosition.resolvedLabel` carries no style info — emitters hardcode italic | Medium |

### 2.3 Emitters (SVG, PDF, LaTeX, Canvas)

| ID | Issue | Severity |
|:---|:---|:---|
| E1 | Staff label italic hardcoded in all 4 emitters (ignores `labelItalic` field) | Medium |
| E2 | `innerStaffIndices` recomputed independently in each emitter | Medium |
| E3 | LaTeX, PDF, Canvas: no system-index guard on above-staff header — prints on every system | **High** |

### 2.4 UI (`advanced_builder_panel.dart`)

| ID | Issue | Severity |
|:---|:---|:---|
| U1 | No `descriptorPlacement` control exposed | High |
| U2 | No visual signal for missing `instrumentAbbreviation` | Medium |
| U3 | No `headerVisibility` (Model C lifecycle) control | High |
| U4 | `resolvedLabel` not previewed in the group card tree | Medium |

---

## Part 3: Target Architecture — Three New Domain Types

### 3.1 `StaffLabelStyle` Value Object

Consolidates 5 scattered `StaffDefinition` fields into one reusable type:

```dart
class StaffLabelStyle {
  const StaffLabelStyle({
    this.fontFamily = 'serif',
    this.fontSizePt = 11.0,
    this.isItalic = true,
    this.isBold = false,
    this.horizontalOffsetMm = 0.0,
    this.verticalOffsetMm = 0.0,
  });
  static const StaffLabelStyle defaultStaff = StaffLabelStyle();
  static const StaffLabelStyle boldUpright = StaffLabelStyle(isItalic: false, isBold: true);
}
```

`StaffDefinition` gains `final StaffLabelStyle labelStyle`.
`StaffPosition` gains `final StaffLabelStyle? resolvedLabelStyle` — emitters consume both text and style from layout.

### 3.2 `DescriptorPlacement` Enum on `StaffNodeGroup`

```dart
enum DescriptorPlacement {
  /// Anglo-American style (Gould/Boosey & Hawkes):
  /// Connector displaced outward; descriptors between connector and barline.
  enclosedByConnector,

  /// Continental European style (Bärenreiter/Breitkopf/Henle):
  /// Connector flush at barline; descriptors left of connector (outer zone).
  outsideConnector,
}
```

- Brace (`SystemConnector.brace`) → always `outsideConnector`, regardless of field value.
- Default: `enclosedByConnector` — **zero change** to existing `.sarv` files.
- Layout impact when `outsideConnector`: `connectorOffsetMm = 0.0`, descriptors computed in the outer zone, new `GroupPlacement.outerDescriptorWidthMm` field drives system indent.

### 3.3 `GroupHeaderVisibility` Enum on `StaffNodeGroup`

```dart
enum GroupHeaderVisibility {
  /// Shown only on the first system of the score (MOLA default).
  firstSystemOnly,

  /// Shown on the first system of each page (Bärenreiter house style).
  firstSystemOfPage,

  /// Shown on every system.
  always,
}
```

Default: `firstSystemOnly` — **fixes the existing bug** of above-staff headers printing on every system.

---

## Part 4: Prioritized Refactoring Plan

### Phase 1 — Critical Bug Fixes *(~3 hrs)*

| Task | File | What |
|:---|:---|:---|
| P1.1 | `layout.dart` | Add `allGroups` getter to `StaffNodeGroup`. Add `aboveStaffHeaderHeightMm = 5.5` to `adjustedGap` when any group has `aboveStaff` placement. |
| P1.2 | `layout.dart` | `resolveGroupLabel`: for `aboveStaff` groups, return `''` on non-first systems. |
| P1.3 | SVG, PDF, LaTeX, Canvas | Add system-index guard: skip above-staff header rendering when `sysIdx != 0`. |
| P1.4 | `config.dart` | Add `aboveStaffHeaderClearanceMm` constant to `GroupPlacementMetrics`. |

### Phase 2 — `StaffLabelStyle` Extraction *(~5 hrs)*

| Task | File | What |
|:---|:---|:---|
| P2.1 | `config.dart` | Define `StaffLabelStyle` with full JSON round-trip. |
| P2.2 | `config.dart` | Refactor `StaffDefinition`: 5 fields → `labelStyle`. JSON migration: old 5-field → `StaffLabelStyle`. |
| P2.3 | `layout.dart` | Add `resolvedLabelStyle` to `StaffPosition`. Thread through `resolveStaffLabel`. |
| P2.4 | All 4 emitters | Consume `staff.resolvedLabelStyle` instead of hardcoding italic. |
| P2.5 | Tests | Update `StaffDefinition` unit tests. |

### Phase 3 — `DescriptorPlacement` *(~7 hrs)*

| Task | File | What |
|:---|:---|:---|
| P3.1 | `config.dart` | Add `DescriptorPlacement` enum. Add `descriptorPlacement` to `StaffNodeGroup`. |
| P3.2 | `layout.dart` | Propagate to `GroupPlacement`. When `outsideConnector`: `connectorOffsetMm = 0.0`, compute `outerDescriptorWidthMm`, include in system indent. Brace always → `outsideConnector`. |
| P3.3 | All 4 emitters | Render descriptors in outer zone when `outsideConnector`. |
| P3.4 | `advanced_builder_panel.dart` | Expose descriptor placement toggle in group card. |
| P3.5 | Tests | Unit tests for both placement modes. |

### Phase 4 — `GroupHeaderVisibility` *(~3 hrs)*

| Task | File | What |
|:---|:---|:---|
| P4.1 | `config.dart` | Add `GroupHeaderVisibility` enum. Add `headerVisibility` to `StaffNodeGroup`. |
| P4.2 | `layout.dart` | Propagate to `GroupPlacement`. Resolve `isAboveStaffVisible` per system. Replace P1.2 hardcoded fix. |
| P4.3 | All 4 emitters | Consume `GroupPlacement.isAboveStaffVisible`. |
| P4.4 | `advanced_builder_panel.dart` | Expose `GroupHeaderVisibility` for `aboveStaff` groups. |

### Phase 5 — UI Maturation *(~3 hrs)*

| Task | File | What |
|:---|:---|:---|
| P5.1 | `advanced_builder_panel.dart` | Amber dot indicator when `instrumentAbbreviation` is empty. |
| P5.2 | `advanced_builder_panel.dart` | Show `resolvedLabel` preview chip in staff card. |
| P5.3 | `advanced_builder_panel.dart` | `StaffLabelStyle` quick controls (italic toggle, font size). |

---

## Part 5: Backwards Compatibility

| Change | Default | Impact |
|:---|:---|:---|
| `DescriptorPlacement` | `.enclosedByConnector` | **Zero** — existing files unchanged |
| `GroupHeaderVisibility` | `.firstSystemOnly` | **Bug fix** — above-staff headers were printing on every system |
| `StaffLabelStyle` | Same defaults as current 5 fields | **Zero** — JSON migration preserves all values |
| Headroom addition (P1.1) | Only added when `aboveStaff` groups exist | Margin-only files: **zero change** |

---

## Summary

```
Phase 1  [CRITICAL]  — Fix above-staff headroom + suppression bugs     ~3 hrs
Phase 2  [HIGH]      — StaffLabelStyle extraction (model cleanup)       ~5 hrs
Phase 3  [HIGH]      — DescriptorPlacement (flush vs. enclosed)        ~7 hrs
Phase 4  [MEDIUM]    — GroupHeaderVisibility (Model C lifecycle)        ~3 hrs
Phase 5  [LOW]       — UI polish                                        ~3 hrs
                                                              Total:   ~21 hrs
```
