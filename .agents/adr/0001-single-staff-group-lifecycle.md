# ADR-0001: Single-Staff Group Lifecycle and Preservation Policy

- **Status:** Accepted (Preserve Group Container; Defer Auto-Dissolution)
- **Date:** 2026-09-24
- **Author:** Pooria Askari Moqaddam & Antigravity Agent
- **Context:** `sarvmd_core` (`SystemLayout`, `RemoveStaffByUidCommand`, `UngroupSubGroupCommand`) and `sarvmd_ui` (`AdvancedBuilderPanel`, `EditMenu`, `CompactMenu`)

---

## 1. Context & Problem Statement

In SarvMD, manuscripts are modeled as a hierarchical layout tree (`SystemLayout`) rooted in a `StaffNodeGroup`. Children can be individual `StaffDefinition` leaves or nested `StaffNodeGroup` nodes representing instrument families, grand staves, or sub-sections (e.g. *Woodwinds*, *Piano*, *Violins I & II*).

When a staff is deleted from the score (via the desktop top bar **Edit** menu, compact mobile menu, the **Staff Config Dialog**, or the **Advanced Builder Panel** card delete icon), all surfaces route through a single source of truth: [`RemoveStaffByUidCommand`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/command/config_command.dart).

When a staff is removed from an inner `StaffNodeGroup`:
1. If the group has **0 remaining staves**, it is unconditionally pruned to eliminate orphan empty containers and avoid division-by-zero or indexing bugs in emitters.
2. If the group has **$\ge 2$ remaining staves**, it remains a standard multi-staff section.
3. If the group has **exactly 1 remaining staff** (e.g. deleting *Violin II* from a 2-violin sub-bracket, leaving only *Violin I*), what should happen to the parent `StaffNodeGroup`?

### The Architectural Dilemma
- **Option A (Preserve Container):** Keep the `StaffNodeGroup` wrapper around the single remaining staff.
- **Option B (Auto-Dissolve / Promote):** Automatically dissolve the `StaffNodeGroup` and promote its single remaining child to the parent (or root) group.

---

## 2. Decision Drivers

1. **Music Engraving Standards (Elaine Gould *Behind Bars*, MOLA Guidelines):**
   - Brackets (`[`), sub-brackets, and curly braces (`{`) by definition connect **two or more** staves.
   - An engraving engine must **never** draw a bracket or brace around a single 5-line staff (*Behind Bars*, pp. 510–518).
   - Emitters (`pdf_emitter.dart`, `svg_emitter.dart`, and `preview_canvas.dart`) enforce this via:
     ```dart
     case SystemConnector.bracket when groupStaves.length >= 2:
     case SystemConnector.brace when groupStaves.length >= 2:
     case SystemConnector.subBracket when groupStaves.length >= 2:
     ```
   - Therefore, rendered output (PDF, SVG, Flutter Canvas) is visually identical and compliant under both options.

2. **Data Loss Prevention & User Metadata:**
   - A `StaffNodeGroup` contains user-defined metadata:
     - `label` (e.g., `"Violins"`, `"Horns in F"`, `"Percussion"`, `"Choir I"`)
     - `abbreviation` (e.g., `"Vln."`, `"Hn."`)
     - `connector` (`SystemConnector.bracket`, `subBracket`, `brace`)
     - `continuousBarlines` (boolean)
     - `initialBarline` (boolean)
   - Auto-dissolving the group instantly deletes all of this metadata without user consent.

3. **Gould’s Non-Redundancy Labeling Principle (*Behind Bars*, p. 511):**
   - In standard scores, individual staves inside labeled sections omit the family name and use numerals (e.g. group `"Violins"` contains staves `"1"` and `"2"`).
   - If deleting *Violin 2* dissolves the group and promotes *Violin 1*, the score is left with a solitary staff named `"1"` floating at the root level, losing all semantic context of `"Violins"`.

4. **Arranging / Drafting Workflow Velocity:**
   - Copyists and composers frequently delete a staff temporarily to swap clefs, change transposition, or adjust instrument lines.
   - Auto-dissolving destroys their section structure mid-edit, forcing them to re-create the group, re-select connectors, and re-type section labels.

5. **The Explicit Action Principle (Least Astonishment):**
   - The user initiated a **"Remove Staff"** action, not a **"Delete Section"** action.
   - SarvMD already provides a dedicated, explicit **"Ungroup"** action ([`UngroupSubGroupCommand`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/command/config_command.dart)) in the UI.

---

## 3. Options Evaluated

### Option 1: Preserve Group Container (Selected)
- **Implementation:** In `RemoveStaffByUidCommand`, when `updatedChild.children.length == 1`, keep `newChildren.add(updatedChild)`.
- **Pros:**
  - Zero data loss: preserves section label, abbreviation, connector choice, and barline style.
  - Safe for Gould non-redundant names (`"1"`, `"2"`).
  - Friendly to multi-step drafting workflows.
  - Emitters automatically suppress bracket/brace rendering ($N < 2$).
- **Cons:**
  - The hierarchy tree contains a single-staff group container until explicitly ungrouped or another staff is added.

### Option 2: Automatic Dissolution / Promotion
- **Implementation:** In `RemoveStaffByUidCommand`, when `updatedChild.children.length == 1`, promote with `newChildren.addAll(updatedChild.children)`.
- **Pros:**
  - Strict tree cleanliness: no groups exist with $N < 2$.
- **Cons:**
  - Irrevocable silent loss of group label, abbreviation, and connector preferences.
  - Leaves inner staves with orphaned numeric labels (`"1"`).
  - Frustrating for users temporarily replacing staves.

### Option 3: Smart Dissolution with Label Inheritance
- **Implementation:** If `children.length == 1`, promote the child; if the child's name is numeric (`"1"`, `"2"`) or empty, inherit the group's label.
- **Pros:** Prevents anonymous staves.
- **Cons:**
  - High heuristic complexity and unexpected side effects.
  - Still discards connector and barline preferences.
  - Complicates transactional undo/redo history.

### Option 4: Preserve Container + Smart UI Action
- **Implementation:** Keep Option 1 at the domain engine level. In [`AdvancedBuilderPanel`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/presentation/widgets/panels/advanced_builder_panel.dart), if a group has 1 child, display an intuitive badge or 1-click **"Dissolve into Parent"** action button.
- **Pros:** Best of both worlds: 100% data safety in the domain model + streamlined UX in the presentation tier.

---

## 4. Decision

We choose **Option 1 (Preserve Group Container)** as the authoritative domain model behavior:

1. **Safety First:** `RemoveStaffByUidCommand` will preserve single-child `StaffNodeGroup` containers to prevent silent loss of labels, abbreviations, and connector settings.
2. **Engraving Compliance:** Rendering emitters (`pdf_emitter.dart`, `svg_emitter.dart`, `preview_canvas.dart`) continue to suppress bracket/brace glyphs when $N < 2$, ensuring pristine visual engraving that strictly adheres to Gould and MOLA guidelines.
3. **Explicit User Control:** Group dissolution remains strictly user-initiated via [`UngroupSubGroupCommand`](file:///home/ono/Projects/sarvmd/packages/sarvmd_core/lib/src/command/config_command.dart).

### Future Roadmap / Trigger for Change
If usability testing reveals that users frequently forget to ungroup 1-staff groups after deciding to permanently keep them as solo staves, we will implement **Option 4** (presenting an inline "Dissolve Group" action badge in [`AdvancedBuilderPanel`](file:///home/ono/Projects/sarvmd/apps/sarvmd_ui/lib/src/presentation/widgets/panels/advanced_builder_panel.dart)) without altering the underlying safety of the domain command.

---

## 5. Architectural Invariants

1. **Pruning Invariant:** A `StaffNodeGroup` with `children.isEmpty` is **always pruned**.
2. **Preservation Invariant:** A `StaffNodeGroup` with `children.length == 1` is **preserved** by default.
3. **Renderer Invariant:** Connectors (`bracket`, `brace`, `subBracket`) are **never drawn** unless `groupStaves.length >= 2`.
4. **Single Source of Truth:** All staff deletions must route through `RemoveStaffByUidCommand` so this policy is uniformly applied across desktop menus, mobile menus, dialogs, panels, and batch operations.
