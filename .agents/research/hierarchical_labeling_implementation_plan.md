# Implementation Plan: Hierarchical Labeling Canvas Space Optimization

**Task Reference:** `Todo #11`  
**Authoritative Standards:** Elaine Gould (*Behind Bars*, pp. 509–525), Major Orchestra Librarians' Association (MOLA) *Music Preparation Guidelines*.

---

## 1. Objectives

1. **Eliminate False Cascading Indent:** Prevent horizontally independent, vertically disjoint groups (e.g. Woodwinds vs. Strings) from additively inflating system left indents.
2. **Correct Single-Tier vs. Two-Tier Bracketing:** When a group has no group label (e.g., String Quartet, Piano Grand Staff, Guitar + TAB), connectors sit flush against the starting barline, with instrument names placed outside (to the left of) the connector.
3. **Locally Scoped Inner Widths:** Scope inner staff descriptor widths strictly to the group spanned by that connector, preventing long names on other staves from blowing out unrelated brackets.
4. **Subsequent Systems Compaction:** Omit instrument family names on subsequent systems per Gould (*Behind Bars*, p. 515), reducing indentation on subsequent systems to compact abbreviation widths (~10–14 mm) and reclaiming up to 50 mm of notation width.
5. **Calibrate Engraving Clearances:** Align clearance constants in `GroupPlacementMetrics` with authentic Gould/SMuFL specifications (1.5–2.0 mm).
6. **Cross-Platform Rendering Parity:** Maintain exact parity across:
   - Interactive Flutter Preview Canvas (`preview_canvas.dart`)
   - Vector PDF Emitter (`pdf_emitter.dart`)
   - Vector SVG Emitter (`svg_emitter.dart`)
   - LaTeX Emitter (`emitter.dart`)

---

## 2. Proposed Changes & File Modifications

### A. Core Constants (`packages/sarvmd_core/lib/src/config.dart`)
- Update `GroupPlacementMetrics`:
  - `connectorLevelSpacingMm = 3.0` (from 4.0)
  - `bracketTickLengthMm = 1.8` (from 2.0)
  - `staffLabelClearanceMm = 2.0` (from 3.0)
  - `staffLabelConnectorClearanceMm = 1.5` (from 2.0)
  - `groupLabelClearanceMm = 2.0` (from 3.0)

### B. Core Layout Engine (`packages/sarvmd_core/lib/src/layout.dart`)
- Refactor `computeLayout(PageConfig config)`:
  1. Determine effective group labels per system:
     - On System 1: full `group.label`.
     - On System 2+: `group.abbreviation` (if empty and top-level family, omit per Gould).
  2. Identify Two-Tier groups (`hasGroupLabel && hasConnector`) vs. Single-Tier groups (`!hasGroupLabel`).
  3. Mark staves as `innerStaffIndices` **only** if they belong to a Two-Tier group.
  4. Compute `connectorOffsetMm` per group locally:
     - Leaf Two-Tier groups: offset = local inner width + clearances.
     - Leaf Single-Tier groups: offset = 0.0 (flush against staves).
     - Nested parent groups: offset = $\max_{child} (\text{childOffset} + \text{childLabelExtent} + G_{\text{level}})$.
  5. Compute `leftIndentMm` by taking the row-aware maximum over all groups and standalone staves:
     $$\text{leftIndentMm} = \max(\text{reqIndent}(g), \text{reqIndent}(s)) + 0.5$$

### C. UI Canvas Preview (`apps/sarvmd_ui/lib/src/presentation/widgets/canvas/preview_canvas.dart`)
- Update `innerStaffIndices` calculation:
  - Only groups with `hasGroupLabel && hasConnector` produce inner staves.
- Update group label rendering on subsequent systems:
  - Omit group labels when effective label is empty.
- Ensure non-inner staff labels sit to the left of the outermost enclosing connector offset.

### D. PDF Emitter (`packages/sarvmd_core/lib/src/pdf_emitter.dart`)
- Update `innerStaffIndices` calculation to match the new layout paradigm.
- Update group label drawing on subsequent systems.

### E. SVG Emitter (`packages/sarvmd_core/lib/src/svg_emitter.dart`)
- Update `innerStaffIndices` calculation to match the new layout paradigm.
- Update group label drawing on subsequent systems.

### F. LaTeX Emitter (`packages/sarvmd_core/lib/src/emitter.dart`)
- Verify that `staffLeftBp` correctly applies `system.leftIndentMm` and bracket ticks align flush at the new offsets.

### G. Test Suites & QA Gallery
- Update `packages/sarvmd_core/test/hierarchical_labeling_test.dart` to validate the new space-efficient calculations and standards.
- Update `packages/sarvmd_core/test/export_validation_test.dart`.
- Re-run `packages/sarvmd_core/tool/generate_qa_gallery.dart` to verify all 32 QA visual scenarios.
- Run UI test suites in `apps/sarvmd_ui/test/`.

---

## 3. Verification Plan

1. **Unit Tests:** Run `dart test` in `packages/sarvmd_core` to verify all layout calculations, indent metrics, and SVG/PDF emissions.
2. **UI Tests:** Run `flutter test` in `apps/sarvmd_ui`.
3. **QA Gallery Generation:** Run `dart run packages/sarvmd_core/tool/generate_qa_gallery.dart` and verify generated SVG/PDF artifacts.
4. **Visual Inspection:** Verify that presets (Chamber Orchestra, Flutes, Piano, Guitar+TAB) display cleanly with reclaimed canvas space.
