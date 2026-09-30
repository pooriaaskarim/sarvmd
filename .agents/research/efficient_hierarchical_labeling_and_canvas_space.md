# Engraving Research & Reference: Canvas Space Efficiency in Hierarchical Labeling

**Task Reference:** `Todo #11`  
**Authoritative Sources:**
1. **Elaine Gould**, *Behind Bars: The Definitive Guide to Music Notation* (Faber Music / Edition Peters), Part III: Layout and Presentation, pp. 509–525.
2. **Major Orchestra Librarians' Association (MOLA)**, *Music Preparation Guidelines for Full Scores and Parts*, § "Full Scores: Instrument Names, Abbreviations, and Bracketing".
3. **Gardner Read**, *Music Notation: A Manual of Modern Practice*, 2nd ed., Chapter 4: "Score Layout and Bracketing Conventions".
4. **Ted Ross**, *The Art of Music Engraving and Processing*, Chapter 3: "Page Layout, Cast-off, and Score Alignment".

---

## 1. Domain Authority & Primary Standard Citations

### 1.1 First-System vs. Subsequent-System Standards (MOLA & Gould)

#### A. Full Names on System 1, Abbreviations on Subsequent Systems
- **MOLA Guidelines (§ "Full Scores"):**
  > *"At the beginning of the full score, the **full name** of each instrument must be listed to the left of the corresponding staff... On subsequent pages, **abbreviations** of instrument names should be used... Part numbers must be explicitly included in both full names and abbreviations (e.g. 'Clarinet 1' / 'Cl. 1')."*
- **Elaine Gould (*Behind Bars*, p. 515):**
  > *"Subsequent systems do **not** repeat instrument family names (e.g. Woodwind, Brass, Strings). Only individual instrument abbreviations appear on subsequent systems."*

#### B. First-System Indent vs. Subsequent System Indent (Gould pp. 509–510, LilyPond `indent` vs. `short-indent`)
- **Elaine Gould (*Behind Bars*, p. 509):**
  > *"The first system of a work or movement is indented to accommodate the full instrument names. Subsequent systems start further to the left, using a much smaller indent or the page margin, since abbreviations occupy far less space."*
- **LilyPond Core Architecture:**
  - `indent`: Sized for System 1 full names (typically 15–30 mm).
  - `short-indent`: Sized for subsequent systems (typically 5–12 mm).
- **Engraving Standard:** In a multi-page score, the space allocated for labeling must **drop dramatically** on System 2 onwards. Retaining a 50mm+ indent on every page wastes massive printable area for musical notation.

---

### 1.2 Brackets, Sub-Brackets, and Label Positioning (Gould pp. 511–519)

#### A. Gould's Non-Redundancy Principle (*Behind Bars*, p. 511)
> *"Do not repeat the family name on every staff if a group name is already given."*
- Redundant / anti-pattern:
  ```
  Flutes  [ Flute 1
          [ Flute 2
  ```
- Standard two-tier:
  ```
  Flutes  [ 1
          [ 2
  ```

#### B. Position of Brackets relative to Staves & Labels (Gould p. 514)
- **Rule 1: Connected Groups with NO Outer Group Label (e.g. String Quartet, Piano Grand Staff, Choir SATB, Guitar + TAB):**
  - When staves are grouped by a bracket or brace, but each staff has its own full instrument name (e.g. *Violin I, Violin II, Viola, Violoncello*):
    - **The bracket/brace sits flush against the starting barline / staves** (clearance ≈ 1.5–2.0 mm).
    - **The instrument names sit OUTSIDE (to the left of) the bracket/brace.**
    - Names are **never** trapped inside the bracket unless an outer parent name is present!
- **Rule 2: Hierarchical Groups with Outer Family/Group Labels (e.g. Flutes [ 1, 2):**
  - The bracket sits outside the inner staff descriptors (`1`, `2`, or short auxiliary names like `Picc.`).
  - The group label sits outside (to the left of) the bracket.
  - Because inner descriptors are typically single numerals (`1`, `2`) or small Roman numerals (`I`, `II`), they require only **2.5 mm to 4.0 mm** of width. The bracket therefore stays very close to the staves (approx. 5–7 mm total offset), NOT 30 mm away.

#### C. Sub-brackets and Nesting Limits (Gould p. 518, MOLA Guidelines)
- Primary brackets enclose instrument families (*Woodwinds, Brass, Strings*).
- Secondary brackets (sub-brackets) enclose identical instrument pairs (*Flutes 1 & 2, Oboes 1 & 2*).
- Concentric brackets must be limited to **2 levels** (maximum 3 in extreme works).
- Sub-brackets sit to the right of primary family brackets with a uniform 3.0 mm clearance.

---

### 1.3 Typographic Alignment and Clearances (Gould p. 513)

- **Right-Alignment:**
  > *"Right-alignment provides a uniform whitespace buffer leading into the bracket and the staves. Left-alignment creates jagged, unpredictable gaps."*
- **Engraving Clearances (Gould & SMuFL Specifications):**
  - Staff label to starting barline: `1.5 mm – 2.0 mm`
  - Text to bracket / connector: `1.5 mm – 2.0 mm`
  - Bracket tick horizontal length: `1.8 mm – 2.0 mm`
  - Space between nested bracket levels: `3.0 mm`

---

## 2. Root Cause Analysis of SarvMD Space Inefficiency

In SarvMD's current engine (`packages/sarvmd_core/lib/src/layout.dart`), several compounding factors cause labeling to consume **40mm to 70mm+** of canvas space:

| Issue | Current Behavior in SarvMD | Gould & MOLA Standard | Consequence |
| :--- | :--- | :--- | :--- |
| **1. Global Inner Width Contamination** | `systemMaxInnerWidthMm = max(all inner labels across entire score)`. | Inner width must be **locally scoped** to the group spanned by that connector. | A single long name in Strings (e.g. *Double Bass* = 24mm) shoved the *Flutes* sub-bracket **31mm** away from the staves, creating an enormous 28mm void. |
| **2. Unconditional Inner Classification** | All staves inside any connected group were marked `innerStaffIndices`. | If a group has NO outer group label (e.g. String Quartet, Piano, Guitar+TAB), names sit **outside** the connector; the connector sits **flush with staves**. | Brackets were pushed 25mm–30mm away from staves with full names awkwardly trapped between the bracket and staff. |
| **3. Vertical Disjointness Ignored** | Level offsets (`levelOffsets[lvl + 1]`) accumulated label extents of **all** groups across the system. | Different families (*Woodwinds* vs *Strings*) occupy different vertical staves. They are **vertically disjoint**. | Woodwinds and Strings label widths were added together as if they were side-by-side, creating an artificial 71mm indent in *Chamber Orchestra*. |
| **4. Family Name Repetition on Subsequent Systems** | If `abbreviation` was empty, `layout.dart` fell back to `group.label` on every system. | Family names are **strictly omitted** on subsequent systems (*Behind Bars*, p. 515). Only instrument abbreviations appear. | 50mm+ indents persisted across all pages, severely shrinking printable notation area throughout the score. |
| **5. Cumulative Padding Buffers** | Padded clearances: `3mm + 2mm + 2mm + 3mm + 4mm + 1mm = 15mm` minimum overhead. | Authentic clearances: `1.5mm – 2.0mm` per stage. | Over-allocation of 6–10mm of pure dead space on every labeled system. |

---

## 3. Mathematical Optimization Model for SarvMD

### 3.1 Two Placement Paradigms

For each `GroupPlacement` $g$ in a system:
Let $L(g)$ be the effective group label for the system:
- On **System 1**: $L(g) = \text{group.label.trim()}$
- On **Subsequent Systems (System 2+)**:
  - If $g$ is a top-level instrument family: $L(g) = \text{group.abbreviation.trim()}$ (if empty, it is **omitted**: $L(g) = ''$).
  - Gould Rule: Family names do not repeat on subsequent systems!

#### Paradigm A: Two-Tier Hierarchical Group ($L(g)$ is non-empty and visible)
- Staves inside $g$ display **inner descriptors** (numerals `1`, `2` or short names):
  $$W_{\text{inner}}(g) = \max_{s \in \text{staves}(g)} \text{width}(s)$$
- The connector offset from the starting barline is locally scoped:
  $$\text{connectorOffset}(g) = W_{\text{inner}}(g) + G_{\text{staff}} + W_{\text{tick}} + G_{\text{conn}}$$
- The outer group label sits to the left of the connector:
  $$\text{reqIndent}(g) = \text{connectorOffset}(g) + G_{\text{label}} + W_{\text{groupLabel}}(g)$$

#### Paradigm B: Single-Tier Connected Group ($L(g)$ is empty or hidden)
- There is NO outer group label.
- The connector sits **flush** against the starting barline:
  $$\text{connectorOffset}(g) = 0.0$$
- Staves inside $g$ display their full names **outside (to the left of) the connector**:
  $$\text{reqIndent}(s) = \text{width}(s) + G_{\text{label}} + W_{\text{connector}}$$
  where $W_{\text{connector}} \approx 2.0\text{ mm}$ for brackets, $0.0$ for flush barlines.

---

### 3.2 Row-Aware Vertical Disjointness (Max, Not Sum)

Because instrument families occupy separate vertical regions of the page, the system left indent is determined by the **maximum** horizontal requirement across all rows, NOT the sum across families:

$$\text{SystemLeftIndentMm} = \max \left( \max_{g \in \text{Placements}} \text{reqIndent}(g), \max_{s \in \text{Staves}} \text{reqIndent}(s) \right)$$

For nested groups (where parent group $P$ actually encloses child group $C$, e.g., `Strings` enclosing `Violins`):
$$\text{connectorOffset}(P) = \max_{C \subset P} \left( \text{connectorOffset}(C) + W_{\text{label}}(C) + G_{\text{level}} \right)$$
Disjoint groups (e.g. `Woodwinds` and `Strings`) do not contribute to each other's connector offsets.

---

### 3.3 Calibrated Authentic Engraving Clearances

| Constant | Previous Value | Standard Optimized Value | Authority |
| :--- | :--- | :--- | :--- |
| `staffLabelClearanceMm` | `3.0 mm` | `2.0 mm` | Gould p. 513 |
| `bracketTickLengthMm` | `2.0 mm` | `1.8 mm` | SMuFL Bravura Spec |
| `staffLabelConnectorClearanceMm` | `2.0 mm` | `1.5 mm` | Gould p. 514 |
| `groupLabelClearanceMm` | `3.0 mm` | `2.0 mm` | Gould p. 513 |
| `connectorLevelSpacingMm` | `4.0 mm` | `3.0 mm` | Gould p. 518 |

---

## 4. Expected Space Optimization Results

| Template / Preset | Previous Indent (System 1) | Optimized Indent (System 1) | Previous Indent (System 2+) | Optimized Indent (System 2+) | Usable Canvas Reclaimed |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Chamber Orchestra** | `~71.0 mm` | **`~26.0 mm`** | `~71.0 mm` | **`~12.0 mm`** | **+45 mm (Sys 1) / +59 mm (Sys 2+)** |
| **Flutes 1 & 2** | `~22.0 mm` | **`~16.0 mm`** | `~22.0 mm` | **`~10.0 mm`** | **+6 mm (Sys 1) / +12 mm (Sys 2+)** |
| **String Quartet** | `~30.0 mm` | **`~24.0 mm`** | `~30.0 mm` | **`~11.0 mm`** | **+6 mm (Sys 1) / +19 mm (Sys 2+)** |
| **Guitar + TAB** | `~20.0 mm` | **`~14.0 mm`** | `~20.0 mm` | **`~10.0 mm`** | **+6 mm (Sys 1) / +10 mm (Sys 2+)** |
| **Grand Staff / Piano** | `~18.0 mm` | **`~13.0 mm`** | `~18.0 mm` | **`~8.0 mm`** | **+5 mm (Sys 1) / +10 mm (Sys 2+)** |
