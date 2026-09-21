# Music Engraving Standards: Group & Staff Hierarchical Labeling and Nesting Limits

This reference codifies the authoritative music engraving standards (**Elaine Gould's *Behind Bars***, **Major Orchestra Librarians' Association [MOLA] Guidelines**, **Ted Ross**, and **Gardner Read**) regarding **system connector nesting depth limits**, **hierarchical group/staff labeling**, and their mathematical integration into the **SarvMD** layout and vector emission pipeline.

---

## 1. System Connector Nesting Limits

In classical and modern orchestral music publishing, system connectors (brackets, sub-brackets, curly braces, and barlines) provide immediate structural orientation to conductors, librarians, and performers.

### 1.1 The Classical Hierarchy of Connectors

| Tier | Standard Name | Glyph / Style | Standard Usage |
| :--- | :--- | :--- | :--- |
| **Root (0)** | **System Barline** | Continuous vertical rule (`|`) | Spans the full height of the entire system across all staves. |
| **Level 1** | **Primary Bracket** | Thick square-ended bracket (`[`) | Encloses an entire **instrument family** (*Woodwinds, Brass, Percussion, Strings, Chorus*). |
| **Level 2** | **Sub-bracket** or **Brace** | Lighter square bracket (`[`) or calligraphic curly brace (`{`) | Encloses **identical or paired instruments** within that family (*Flutes 1 & 2*, *4 Horns*, *Violins I & II*, *Harp grand staff*). |
| **Level 3** | **Sub-sub-bracket** | Thin line bracket or broken sub-bracket | **The absolute maximum practical ceiling.** Used exclusively in massive 20th-century scores, opera with stage bands, or divided multi-choirs (*Choir I → Women's Voices SSAA → Desks 1 & 2*). |

---

### 1.2 The Absolute Nesting Ceiling: 2 Levels (Maximum 3 in Extreme Works)

According to **Elaine Gould (*Behind Bars*, Faber Music, p. 518)**:

> *"A score should not have more than **two levels of brackets** (a main family bracket and a sub-bracket). If further subdivision is needed, use a brace for the inner pair, or rely on labels and broken barlines rather than adding a third bracket. More than two concentric brackets creates visual clutter and confuses the eye."*

#### Why Gould and MOLA Restrict Nesting to 2–3 Levels:
1. **Podium Readability (1.0 to 1.5 meters distance):** Concentric brackets (`[ [ [ `) merge visually into unintelligible vertical clutter under stage lighting and rapid page turns.
2. **Horizontal Margin Conservation:** Each concentric bracket consumes between `4mm` and `6mm` of horizontal indent. Nesting 4 or 5 levels would consume `25mm` to `35mm` of usable horizontal width solely for delimiters, starving notation measures.
3. **Barline Navigation:** Orchestral conductors navigate scores by **family barlines** (barlines unbroken within a family, broken between families) rather than tracking deeply nested tree branches.

#### Software Precedents:
* **Sibelius & Finale:** Enforce a strict 2-tier model: *Bracket* (Primary) and *Sub-bracket* (Secondary), plus *Brace*.
* **Dorico:** Caps nested brackets at 3 levels (*Bracket, Sub-bracket, Sub-sub-bracket*).
* **LilyPond:** Supports programmatic nesting but explicitly warns in documentation that exceeding 2 bracket levels violates standard Gouldian engraving.

---

## 2. Hierarchical Labeling: Group vs. Staff Labels

When both a group (section/family) label and individual staff labels are present, a two-tier spatial layout is mandatory.

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

### 2.1 Gould's Non-Redundancy Principle (*Behind Bars*, p. 511)
> *"Do not repeat the family name on every staff if a group name is already given."*

* **Flawed / Redundant Layout:**
  ```
  Flutes  [ Flute 1  |======
          [ Flute 2  |======
  ```
* **Gould / MOLA Standard Layout:**
  ```
  Flutes  [ 1  |======
          [ 2  |======
  ```
* **Mixed Auxiliary Layout:**
  Where like instruments share a section with an auxiliary member, the primary members receive numerals while the auxiliary receives its specific name:
  ```
  Oboes  [ 1             |======
         [ 2             |======
         [ Corno Inglese |======
  ```

---

### 2.2 The Odd-Staff Midpoint Problem

In groups with an **odd number of staves** (e.g., 3 Trombones, 3 Flutes, 5 Strings):
* The vertical midpoint of the group lands **directly on the center staff** (e.g. Staff 2).
* **The Danger:** If the group label and staff labels share the same horizontal coordinate range (as SarvMD previously did), the group name (*Tromboni*) directly collides with the middle staff's number (*2*).
* **The Gould Solution:** Enforce **two distinct horizontal columns separated by the connector**. The group label sits in the outer column, while staff descriptors sit in the inner column.

---

### 2.3 Typographic Alignment Rules
* **Right-Alignment:** Both outer group labels and inner staff labels must be **right-aligned** (*Behind Bars*, p. 513). Right alignment provides a uniform whitespace buffer leading into the bracket and the staves.
* **Vertical Alignment:**
  - Group labels are centered on the **vertical bounding span** of the group staves.
  - Staff labels are centered on the **centerline of each 5-line staff** (Line 3).
* **Typographic Hierarchy:**
  - Group labels: Upright / Bold or Small Caps (e.g., *Noto Serif*, 11pt, `w700`).
  - Staff labels: Italic or Roman numerals (e.g., *Noto Serif Italic*, 10pt–11pt).

---

## 3. Mathematical Coordinate Engine for SarvMD

To guarantee zero collisions across interactive preview (`preview_canvas.dart`), PDF export (`pdf_emitter.dart`), and SVG export (`svg_emitter.dart`), SarvMD adopts the following mathematical coordinate formulation:

### 3.1 Two-Tier Horizontal Spacing Formulation

Let:
* $X_{\text{sys}}$ be the starting X coordinate of the staves on the system ($X_{\text{sys}} = \text{leftMargin} + \text{leftIndentMm}$).
* $W_{\text{inner}}$ be the maximum width among all active staff labels in that group/system.
* $W_{\text{outer}}$ be the maximum width among all active group labels.
* $G_{\text{staff}}$ be the padding between inner staff labels and the barline ($3.0\text{ mm}$).
* $G_{\text{connector}}$ be the clearance between connectors and text ($3.0\text{ mm}$).
* $W_{\text{bracket}}$ be the bracket offset for nesting level ($4.0\text{ mm} \times \text{level}$).

#### Spatial Positioning:
1. **Inner Staff Label Right-Anchor ($X_{\text{staffRight}}$):**
   $$X_{\text{staffRight}} = X_{\text{sys}} - G_{\text{staff}}$$
   The staff label is painted right-aligned ending at $X_{\text{staffRight}}$.
2. **Connector Position ($X_{\text{connector}}$):**
   $$X_{\text{connector}} = X_{\text{sys}} - W_{\text{inner}} - G_{\text{connector}} - W_{\text{bracket}}$$
3. **Outer Group Label Right-Anchor ($X_{\text{groupRight}}$):**
   $$X_{\text{groupRight}} = X_{\text{connector}} - G_{\text{connector}}$$
   The group label is painted right-aligned ending at $X_{\text{groupRight}}$ and vertically centered at:
   $$Y_{\text{groupMid}} = \frac{Y_{\text{topStaff}} + Y_{\text{bottomStaff}}}{2}$$

### 3.2 Total System Indent Formula (`layout.dart`)

$$\text{leftIndentMm} = W_{\text{outer}} + G_{\text{connector}} + W_{\text{bracket}} + W_{\text{inner}} + G_{\text{staff}}$$

- When a group has no visible label, $W_{\text{outer}} = 0$ and $G_{\text{connector}} = 0$, causing the calculation to collapse gracefully to the single-tier staff label indent.
- When staves have no visible labels, $W_{\text{inner}} = 0$, causing the connector to sit flush against the starting barline.
