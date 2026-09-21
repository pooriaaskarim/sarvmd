# SarvMD Knowledge Base: Hierarchical Labeling & System Connector Nesting Standards

## 1. Domain Authority & Standards Reference
This document establishes the official engraving knowledge base for **SarvMD** regarding hierarchical instrument labeling and system connector nesting. The rules are drawn directly from the definitive music engraving authorities:
- **Elaine Gould**, *Behind Bars: The Definitive Guide to Music Notation* (Faber Music), pp. 510–523.
- **Major Orchestra Librarians' Association (MOLA)**, *Music Preparation Guidelines*.
- **Ted Ross**, *The Art of Music Engraving and Processing*.
- **Gardner Read**, *Music Notation: A Manual of Modern Practice*.

---

## 2. System Connector Nesting Limits

### 2.1 The Standard Nesting Hierarchy
System connectors (brackets, sub-brackets, curly braces, and barlines) provide conductors, score readers, and librarians with an instantaneous visual map of the ensemble structure.

| Nesting Level | Glyph / Type | Target Scope | Standard Usage Example |
| :--- | :--- | :--- | :--- |
| **0 (Root)** | Continuous or Section Barline (`\|`) | Entire System | Drawn flush at the starting barline of all staves. |
| **1 (Primary)** | Heavy Square Bracket (`[`) | Instrument Family | Woodwinds, Brass, Percussion, Strings, Chorus. |
| **2 (Secondary)** | Lighter Sub-bracket (`[`) or Curly Brace (`{`) | Homogeneous sub-units or grand staff | Flutes 1 & 2, Horns 1–4, Violins I & II, Piano / Harp grand staff. |
| **3 (Tertiary)** | Thin sub-sub-bracket | Sub-desk divisions | Extreme ceiling for divided multi-choirs (Choir I → SSAA → Desks 1 & 2) or opera stage bands. |

### 2.2 The 2-Level Rule (Max 3 in Extreme Works)
*Behind Bars*, p. 518:
> *"A score should not have more than **two levels of brackets** (a main family bracket and a sub-bracket). If further subdivision is needed, use a brace for the inner pair, or rely on labels and broken barlines rather than adding a third bracket. More than two concentric brackets creates visual clutter and confuses the eye."*

#### Why Deep Nesting (>2 or 3) is Forbidden:
1. **Podium Readability at 1.5 Meters:** In orchestral practice, conductors read the score from a podium music stand 1.0 to 1.5 meters away. Triple or quadruple concentric brackets merge into an illegible thick vertical block under rehearsal lighting.
2. **Horizontal Margin Budget:** Each bracket level consumes 4.0mm to 6.0mm of horizontal indent. 4+ nesting levels would deplete 25mm–35mm of usable score width, leaving insufficient horizontal room for musical measures.
3. **Barline Navigation Supremacy:** Orchestral conductors orient across families via unbroken/broken barlines rather than tracking deeply nested tree branches.

---

## 3. Hierarchical Two-Tier Labeling Architecture

When an ensemble has both a parent group (section/family) label and individual staff labels, a two-tier spatial layout is mandatory.

```
|<-- Page Left Margin -->|
+------------------------+-------------------------------------------------------
|                        |
|   OUTER COLUMN         |      INNER COLUMN
|   (Section/Family)     |   (Numbers / Descriptors)
|          |             |             |
|          v             v             v
|                      BRACKET
|                         |
|                       +---+
|                       |   |    1   |===========================================
|        Flutes         |   |        |
|                       |   |    2   |===========================================
|                       +---+
|
|        Oboes          [        1   |===========================================
|                       [        2   |===========================================
|
|     Cor Anglais                    |===========================================
|
```

### 3.1 Elaine Gould's Non-Redundancy Principle (*Behind Bars*, p. 511)
> *"Do not repeat the family name on every staff if a group name is already given."*

- **Redundant / Anti-pattern:**
  ```
  Flutes  [ Flute 1  |======
          [ Flute 2  |======
  ```
- **Authoritative Standard:**
  ```
  Flutes  [ 1  |======
          [ 2  |======
  ```
- **Mixed Auxiliary Sections:**
  When like instruments share a section with an auxiliary member (e.g. Piccolo or English Horn), primary members receive numerals while the auxiliary receives its specific name:
  ```
  Flutes  [ 1       |======
          [ 2       |======
          [ Piccolo |======
  ```

### 3.2 The Odd-Staff Midpoint Problem
In groups with an **odd number of staves** (e.g., 3 Flutes, 3 Trombones, 5 Woodwinds):
- The vertical midpoint of the group lands **directly on the center staff** (Staff 2 of 3).
- If the group label and staff labels share the same horizontal coordinate range, the group name (*Flutes*) collides directly with the middle staff descriptor (*2*).
- **The Solution:** Two distinct horizontal columns separated by the connector. The group label sits in the outer column (to the left of the bracket), while the staff descriptor sits in the inner column (between the bracket and the starting barline).

### 3.3 Typographic Alignment & Hierarchy
1. **Right-Alignment:** Both outer group labels and inner staff labels must be **right-aligned**. This creates a clean, predictable whitespace buffer leading into the brackets and staves.
2. **Vertical Anchoring:**
   - Group labels are centered on the vertical bounding span of the group staves:
     $$Y_{\text{groupMid}} = \frac{Y_{\text{topStaff}} + Y_{\text{bottomStaff}}}{2}$$
   - Staff labels are centered on the centerline (Line 3) of each individual 5-line staff:
     $$Y_{\text{staffMid}} = Y_{\text{staffTop}} + \frac{\text{height}}{2}$$
3. **Typography:**
   - Group Labels: Upright Bold / Roman, e.g. *Noto Serif*, 11pt, `w700`.
   - Staff Labels: Italic or Roman numerals, e.g. *Noto Serif Italic*, 10pt–11pt.

---

## 4. Mathematical Coordinate Formulation for SarvMD

To ensure absolute visual parity and zero collision across `preview_canvas.dart`, `pdf_emitter.dart`, and `svg_emitter.dart`:

### 4.1 Character-Weighted Font Advance Measurement (`estimateLabelWidthMm`)
Standard typography metrics (Noto Serif / Helvetica):
- Uppercase letters (`[A-Z]`): $0.68\text{ em}$
- Digits (`[0-9]`): $0.55\text{ em}$
- Spaces (` `): $0.28\text{ em}$
- Wide lowercase (`m, w`): $0.78\text{ em}$
- Narrow characters (`i, j, l, t, ., ,, :, ;, ', !, -`): $0.30\text{ em}$
- Other lowercase / symbols: $0.52\text{ em}$
- Group titles (Bold): $1.08 \times$ advance factor
- Safety cushion: $+ 0.5\text{ mm}$
- Explicit newlines (`\n`): String splits on `\n` and budgets the maximum advance among lines. Multi-word strings without `\n` are budgeted as their full length on a single line.

### 4.2 Dynamic Cumulative Level Offset Formulation (`layout.dart`)
Fixed level spacing ($L \times 4.0\text{ mm}$) fails whenever an inner sub-group has a label, causing parent brackets to slice through child labels. SarvMD solves this via cumulative additive offsets per nesting level:

1. **Level 0 (Innermost Connectors):**
   $$\text{Offset}(0) = \begin{cases} W_{\text{systemMaxInner}} + G_{\text{staff}} & \text{if } W_{\text{systemMaxInner}} > 0 \\ 0.0 & \text{otherwise} \end{cases}$$
   where $G_{\text{staff}} = 3.0\text{ mm}$.

2. **Level $L+1$ Spacing (Outer Ancestor Connectors):**
   $$\text{Step}(L) = \begin{cases} \max_{g \in \text{Level } L} (W_{\text{groupLabel}}(g) + G_{\text{group}}) + S_{\text{connector}} & \text{if any } g \in \text{Level } L \text{ has label} \\ S_{\text{connector}} & \text{otherwise} \end{cases}$$
   $$\text{Offset}(L + 1) = \text{Offset}(L) + \text{Step}(L)$$
   where $G_{\text{group}} = 3.0\text{ mm}$ and $S_{\text{connector}} = 4.0\text{ mm}$.

3. **Single Source of Truth (`GroupPlacement.connectorOffsetMm`):**
   `layout.dart` assigns `connectorOffsetMm: Offset(group.level)` directly to each `GroupPlacement`. Emitters never calculate ad-hoc level multiplications; they consume `group.connectorOffsetMm` directly:
   - Starting Barline: $X_{\text{barline}} = \text{margins.left} + \text{leftIndentMm}$
   - Connector: $X_{\text{connector}} = X_{\text{barline}} - \text{group.connectorOffsetMm}$
   - Outer Group Label: $X_{\text{groupRight}} = X_{\text{connector}} - G_{\text{group}}$
   - Inner Staff Descriptor: $X_{\text{staffRight}} = X_{\text{barline}} - G_{\text{staff}}$
   - Standalone Staff Label: $X_{\text{staffRight}} = X_{\text{barline}} - \max(\text{group.connectorOffsetMm}) - G_{\text{staff}}$

4. **Dynamic System Indent Formulation:**
   $$\text{maxRequiredIndent} = \max \left( \max_g (g.\text{connectorOffsetMm} + G_{\text{group}} + g.\text{groupLabelWidthMm}), \max_s (W_s + G_{\text{staff}} + \max(g.\text{connectorOffsetMm})) \right)$$
   $$\text{leftIndentMm} = \text{maxRequiredIndent} > 0.0 \text{ ? } \text{maxRequiredIndent} + 1.0\text{ mm} : 0.0$$

---

## 5. Architectural Invariants for SarvMD Codebase
1. **Zero Connector Collisions:** No bracket or connector line may ever intersect a label bounding box.
2. **Three-Target Parity:** `preview_canvas.dart`, `pdf_emitter.dart`, and `svg_emitter.dart` must produce millimeter-for-millimeter and pixel-for-pixel identical layout anchors.
3. **Multi-line Parity:** Explicit `\n` in instrument or group names is rendered with vertically centered and right-aligned blocks across all three targets.
4. **Nesting Enforcement:** The UI hierarchy editor enforces a maximum nesting depth of 2 (hard ceiling 3) and prevents unbounded recursion.
5. **Smart Auto-Numbering Assistant:** Assist users with Gould's non-redundancy principle (e.g. converting "Flute 1", "Flute 2" to "1", "2" when grouped under "Flutes").
