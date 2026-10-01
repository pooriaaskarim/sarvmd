# Standard Score Examples & Sub-Group Labeling Analysis
## Comparative Study: Published Engraving Standards vs. SarvMD Implementation

---

## 1. Executive Summary

When comparing SarvMD's current rendering with authoritative published scores (**Bärenreiter Urtext**, **Breitkopf & Härtel**, **Boosey & Hawkes**, **Henle**, and **Elaine Gould's *Behind Bars***), there is a fundamental architectural discrepancy in how sub-groups are handled:

> [!WARNING]
> **The Root Cause of Space Waste in SarvMD:**
> SarvMD currently treats nested groups as **nested horizontal Russian dolls**:
> `Woodwinds Label` → `Outer Bracket` → `Flutes Label` → `Sub-Bracket` → `Staff Numbers (1, 2)` → `Barline`.
> This creates **5 consecutive horizontal columns**, eating up **50mm–66mm** (over 30% of the entire page width) before music even begins!
>
> **In Real Published Scores:**
> Real publishers **never** place an instrument name *between* two brackets. All brackets sit tightly packed against the starting barline (**only 2.5mm–3.0mm apart**), and instrument names sit in **one unified vertical column** to the left of all brackets, or are formatted with section headers above the staff.

---

## 2. Standard Published Models (How the Masters Engrave)

### Model A: Flat Inline Nomenclature (Breitkopf, Peters, Dover, Kalmus, Schirmer)
*Used in >85% of classical, romantic, and modern orchestral scores (e.g. Beethoven, Brahms, Tchaikovsky, Mahler).*

In standard practice, publishers **do not print section names ("Woodwinds", "Brass", "Strings") in the left margin**. The primary bracket already unambiguously communicates the family to the conductor.

#### Visual Plate:
```text
           Primary     Sub-
           Bracket    Bracket   Barline
              │          │        │
Flute 1 ──────┤          ┌────────┼════════════════════════ (Staff 1)
              │          │        │
Flute 2 ──────┤          └────────┼════════════════════════ (Staff 2)
              │                   │
Oboe 1 ───────┤          ┌────────┼════════════════════════ (Staff 3)
              │          │        │
Oboe 2 ───────┤          └────────┼════════════════════════ (Staff 4)
              │          │        │
Clarinet 1 ───┤          ┌────────┼════════════════════════ (Staff 5)
              │          │        │
Clarinet 2 ───┤          └────────┼════════════════════════ (Staff 6)
              │                   │
Bassoon 1 ────┤          ┌────────┼════════════════════════ (Staff 7)
              │          │        │
Bassoon 2 ────┤          └────────┼════════════════════════ (Staff 8)
              │          │        │
```

#### Millimeter Budget (Model A):
- Longest label (`Clarinet 1` / `Bassoon 1`): ~19.0 mm
- Clearance to primary bracket: 2.0 mm
- Primary bracket + tick: 1.8 mm
- Inter-bracket spacing: 2.5 mm
- Sub-bracket: 1.0 mm
- Clearance to barline: 1.5 mm
- **TOTAL LEFT INDENT: ~27.8 mm** (compared to SarvMD's 65.6 mm → **saves ~38 mm!**)

---

### Model B: Centered Group Label with Inner Numbers (Bärenreiter Urtext, Boosey & Hawkes, Durand, Dorico "Group between staves")
*Used in French/German repertoire (e.g. Ravel, Debussy, Stravinsky, Bartók) and contemporary master editions.*

When a group label like "Flutes" or "Flauti" is shared across staves, notice where the brackets sit:
**Both the primary bracket AND the secondary bracket sit adjacent at the staff line.** The group label sits to the LEFT of the primary bracket. The numbers sit inside.

#### Visual Plate:
```text
          Primary    Sub-
          Bracket   Bracket   Barline
             │         │        │
             │         ┌── 1 ───┼════════════════════════ (Staff 1)
Flutes ──────┤         │        │
             │         └── 2 ───┼════════════════════════ (Staff 2)
             │                  │
             │         ┌── 1 ───┼════════════════════════ (Staff 3)
Oboes ───────┤         │        │
             │         └── 2 ───┼════════════════════════ (Staff 4)
```

#### Millimeter Budget (Model B):
- Group label (`Flutes` / `Oboes`): ~13.0 mm
- Clearance to primary bracket: 2.0 mm
- Primary bracket: 1.8 mm
- Inter-bracket spacing: 2.5 mm
- Sub-bracket: 1.0 mm
- Inner number (`1`, `2`) + clearances: ~4.5 mm
- **TOTAL LEFT INDENT: ~24.8 mm** (saves **~41 mm**!)

---

### Model C: Section Header Above Staff (MOLA Guidelines & Modern Film/Commercial Scoring)
*Standardized by MOLA (Major Orchestra Librarians' Association) and widely used in film scoring (John Williams, Hans Zimmer, Hollywood studio scores).*

In this model:
- Family names (`WOODWINDS`, `BRASS`, `PERCUSSION`, `STRINGS`) appear **above the first staff of each section in bold capital letters**, completely removing them from the left margin!
- Margin space is 100% dedicated to instrument names.

#### Visual Plate:
```text
WOODWINDS
              [ ┌── 1 ───┼════════════════════════ (Flute 1)
Flutes ───────[ │        │
              [ └── 2 ───┼════════════════════════ (Flute 2)
              [          │
              [ ┌── 1 ───┼════════════════════════ (Oboe 1)
Oboes ────────[ │        │
              [ └── 2 ───┼════════════════════════ (Oboe 2)
```

---

## 3. Direct Side-by-Side Comparison: SarvMD vs. Standard Practice

| Dimension | SarvMD (Current Architecture) | Standard Published Engraving (Bärenreiter / Gould / Boosey) |
| :--- | :--- | :--- |
| **Number of Horizontal Tiers** | **4 to 5 tiers** (Family Name → Family Bracket → Sub-group Name → Sub-bracket → Numbers → Staves) | **2 tiers maximum** (Names → Adjacent Brackets → Staves) |
| **Bracket Positions** | Displaced across multiple horizontal stages (outer bracket is pushed 25mm–35mm away from the staff) | **All brackets sit together** at the left barline, separated only by 2.5mm–3.0mm |
| **Section Labels ("Woodwinds", "Brass")** | Placed in the left margin to the left of the outer bracket, pushing all instruments inwards | Either **omitted** (bracket shows the choir), placed **above the top staff**, or only used if there are no sub-group labels |
| **Sub-bracket Position** | Trapped between two text columns | Directly adjacent to the primary bracket |
| **System 1 Left Indent** | **55 mm – 66 mm** | **22 mm – 28 mm** |
| **Notation Area Lost** | **31% of page width** | **11% of page width** |

---

## 4. Specific Repertoire Examples to Inspect

### Example 1: Beethoven Symphony No. 5 (Breitkopf & Härtel Urtext)
- **Woodwind Section:**
  - 1 Primary bracket enclosing 2 Flauti, 2 Oboi, 2 Clarinetti, 2 Fagotti.
  - Thin secondary brackets grouping pairs of staves.
  - Labels on the left:
    `Flauto I`
    `Flauto II`
    `Oboe I`
    `Oboe II`
    `Clarinetto I in B`
    `Clarinetto II in B`
    `Fagotto I`
    `Fagotto II`
  - **No "Woodwinds" word anywhere in the margin.**
  - Left indent: **~24 mm**.

### Example 2: Stravinsky *The Rite of Spring* (Boosey & Hawkes Master Score)
- Stravinsky uses huge woodwinds (Piccolo, 3 Flutes, Alto Flute, 4 Oboes, English Horn, etc.).
- Boosey & Hawkes uses Model B:
  - Outer bracket connects entire Woodwind section.
  - Sub-brackets connect `Flauti I. II. III.` and `Oboi I. II. III.`.
  - The name `Flauti` is centered outside the brackets; Roman numerals `I. II. III.` are placed next to the staves.
  - Both brackets are flush together (**3mm apart**).
  - Left indent: **~28 mm**.

### Example 3: Ravel *Daphnis et Chloé* (Durand / Dover)
- Durand groups `2 Flûtes` with a brace or bracket.
- Centered label: `Flûtes`, with small `1` and `2` immediately before the clef.
- Left indent: **~25 mm**.

---

## 5. Architectural Path for SarvMD

To make SarvMD look like a Bärenreiter or Boosey & Hawkes score and reclaim the remaining 25mm–35mm of canvas space:

1. **Pack Brackets Cohesively at the Barline:**
   - Level 0 (sub-bracket): sits at barline (or clearance for numbers).
   - Level 1 (family bracket): sits **immediately to the left of Level 0** (offset by only `GroupPlacementMetrics.connectorLevelSpacingMm = 3.0mm`), NOT pushed out by intermediate text!
2. **Unified Label Column to the Left of All Connectors:**
   - Instead of placing sub-group labels *inside* the outer bracket, place group labels in the outer label column to the left of the outermost bracket, OR
3. **Automatic Section Header Mode (Alternative):**
   - Render section titles ("WOODWINDS", "BRASS", "STRINGS") above the first staff of the group rather than forcing a 25mm horizontal column.
