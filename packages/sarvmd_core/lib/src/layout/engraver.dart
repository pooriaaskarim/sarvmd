// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import '../config.dart';
import '../domain/clef.dart';
import '../domain/duration.dart';
import '../domain/musical_event.dart';
import '../domain/score.dart';
import '../domain/smufl.dart';
import '../layout.dart';
import 'positioned_element.dart';
import 'spacing_spindle.dart';

/// Represents a single visual page of the engraved score, containing the flat
/// physical layout and all positioned musical symbols.
class EngravingPage {
  /// Creates a new [EngravingPage].
  const EngravingPage({
    required this.pageLayout,
    required this.elements,
  });

  /// The physical structural layout of the page (margins, systems, staves).
  final PageLayout pageLayout;

  /// The collection of physically positioned symbols (notes, rests, barlines) on this page.
  final List<PositionedElement> elements;
}

/// Represents the completed, physical engraving layout output for an entire score.
class EngravingLayout {
  /// Creates a new [EngravingLayout] containing multiple visual pages.
  const EngravingLayout({
    required this.pages,
  });

  /// The list of compiled visual pages in the score.
  final List<EngravingPage> pages;
}

/// The Engraving Layout Compiler for SarvMD.
///
/// Translates a logical [Score] AST and a physical [PageConfig] into a completely
/// scale-accurate, multi-page [EngravingLayout] with precisely positioned musical
/// elements.
class Engraver {
  /// Compiles a [Score] into a full [EngravingLayout] using a given [PageConfig].
  static EngravingLayout compile(Score score, PageConfig config) {
    if (score.parts.isEmpty) {
      return const EngravingLayout(pages: []);
    }

    final lineGap = config.staffConfig.lineGapMm;
    final leftX = config.margins.left;
    final rightX = config.effectiveWidth - config.margins.right;
    final usableWidth = rightX - leftX;

    // Retrieve systems per page using layout engine rules
    final baseLayout = computeLayout(config);
    final systemsPerPage = baseLayout.systems.length;

    if (systemsPerPage == 0) {
      return const EngravingLayout(pages: []);
    }

    // Step 1: Pre-calculate the synchronized visual width of each measure index.
    // In multi-part engraving, measure columns must align vertically.
    final measureCount = score.parts.first.measures.length;
    final measureSpacingWidths = <double>[];
    final measureSpindles = <List<SpacingSpindle>>[];

    for (var m = 0; m < measureCount; m++) {
      final spindlesForMeasure = <SpacingSpindle>[];
      var maxMeasureSpacingWidth = 0.0;

      for (final part in score.parts) {
        final measure = part.measures[m];
        final voices = measure.voices.values.toList();
        
        final spindle = SpacingSpindle.compute(
          voices: voices,
          timeSignature: measure.timeSignature,
        );
        spindlesForMeasure.add(spindle);
        
        if (spindle.totalWidth > maxMeasureSpacingWidth) {
          maxMeasureSpacingWidth = spindle.totalWidth;
        }
      }

      measureSpacingWidths.add(maxMeasureSpacingWidth);
      measureSpindles.add(spindlesForMeasure);
    }

    // Step 2: Compute measure boundaries and total physical widths (including decoration margins)
    final decorationLeftWidths = List<double>.filled(measureCount, 0.0);
    
    // Track active clefs, signatures across parts to detect changes
    final activeClefs = score.parts.map((p) => p.measures.first.clef ?? Clef.treble).toList();
    final activeKeys = score.parts.map((p) => p.measures.first.keySignature).toList();
    final activeTimes = score.parts.map((p) => p.measures.first.timeSignature).toList();

    for (var m = 0; m < measureCount; m++) {
      var clefWidth = 0.0;
      var keyWidth = 0.0;
      var timeWidth = 0.0;

      for (var pIdx = 0; pIdx < score.parts.length; pIdx++) {
        final measure = score.parts[pIdx].measures[m];

        // Clef decoration margin
        if (measure.clef != null && measure.clef != activeClefs[pIdx]) {
          activeClefs[pIdx] = measure.clef!;
          final width = SmuflGlyph.gClef.widthSp * lineGap; // Approximation
          if (width > clefWidth) clefWidth = width;
        } else if (m == 0) {
          // Draw initial system clefs
          final width = SmuflGlyph.gClef.widthSp * lineGap;
          if (width > clefWidth) clefWidth = width;
        }

        // Key signature decoration margin
        if (measure.keySignature != null && measure.keySignature != activeKeys[pIdx]) {
          activeKeys[pIdx] = measure.keySignature!;
          final stepCount = measure.keySignature!.fifths.abs();
          final width = stepCount * SmuflGlyph.accidentalFlat.widthSp * lineGap * 0.8;
          if (width > keyWidth) keyWidth = width;
        }

        // Time signature decoration margin
        if (measure.timeSignature != null && measure.timeSignature != activeTimes[pIdx]) {
          activeTimes[pIdx] = measure.timeSignature!;
          final width = 2.0 * lineGap; // Roughly 2 spaces wide
          if (width > timeWidth) timeWidth = width;
        }
      }

      // Buffer spacing between decorations
      decorationLeftWidths[m] = clefWidth + keyWidth + timeWidth + (m == 0 ? 2.0 : 1.0);
    }

    // Step 3: Greedy measure pagination onto systems across pages
    final pagesList = <EngravingPage>[];
    var currentMeasureIdx = 0;

    // Reset tracking for layout placement
    for (var pIdx = 0; pIdx < score.parts.length; pIdx++) {
      activeClefs[pIdx] = score.parts[pIdx].measures.first.clef ?? Clef.treble;
      activeKeys[pIdx] = score.parts[pIdx].measures.first.keySignature;
      activeTimes[pIdx] = score.parts[pIdx].measures.first.timeSignature;
    }

    while (currentMeasureIdx < measureCount) {
      final pageBaseLayout = computeLayout(config);
      final pageElements = <PositionedElement>[];

      for (var sIdx = 0; sIdx < pageBaseLayout.systems.length; sIdx++) {
        if (currentMeasureIdx >= measureCount) break;

        final system = pageBaseLayout.systems[sIdx];
        
        // Find how many measures fit in this system
        final systemMeasures = <int>[];
        var accumulatedWidth = 0.0;

        while (currentMeasureIdx < measureCount) {
          final mWidth = decorationLeftWidths[currentMeasureIdx] +
              measureSpacingWidths[currentMeasureIdx] +
              1.0; // Barline buffer

          if (systemMeasures.isEmpty) {
            systemMeasures.add(currentMeasureIdx);
            accumulatedWidth += mWidth;
            currentMeasureIdx++;
          } else if (accumulatedWidth + mWidth <= usableWidth) {
            systemMeasures.add(currentMeasureIdx);
            accumulatedWidth += mWidth;
            currentMeasureIdx++;
          } else {
            break; // Wrap to next system
          }
        }

        // Justification factor (fill usable horizontal width exactly)
        var justifyFactor = 1.0;
        final decorationSum = systemMeasures.fold<double>(
          0.0,
          (sum, idx) => sum + decorationLeftWidths[idx] + 1.0,
        );
        final spacingSum = systemMeasures.fold<double>(
          0.0,
          (sum, idx) => sum + measureSpacingWidths[idx],
        );

        if (spacingSum > 0.0) {
          justifyFactor = (usableWidth - decorationSum) / spacingSum;
        }

        // Place system-level barlines at left margin
        final sysTopY = system.staves.first.topY;
        final sysBottomY = system.staves.last.topY + system.staves.last.height;
        pageElements.add(PositionedBarline(
          x: leftX,
          topY: sysTopY,
          bottomY: sysBottomY,
          thicknessMm: 0.6,
        ));

        // Place elements inside the measures allocated to this system
        var xCursor = leftX;

        for (final mIdx in systemMeasures) {
          final decorWidth = decorationLeftWidths[mIdx];
          final rawSpacingWidth = measureSpacingWidths[mIdx];
          final justifiedSpacingWidth = rawSpacingWidth * justifyFactor;

          // Draw decorations at measure start
          var localX = xCursor + 1.0;

          for (var pIdx = 0; pIdx < score.parts.length; pIdx++) {
            final part = score.parts[pIdx];
            final measure = part.measures[mIdx];
            final staff = system.staves[pIdx];

            // 1. Clef Change
            if (measure.clef != null && measure.clef != activeClefs[pIdx]) {
              activeClefs[pIdx] = measure.clef!;
              final glyph = _smuflClef(activeClefs[pIdx]);
              pageElements.add(PositionedClef(
                x: localX,
                y: staff.topY + (staff.lines - activeClefs[pIdx].anchorLine) * lineGap * staff.scale,
                scale: staff.scale,
                glyph: glyph,
              ));
            } else if (mIdx == 0) {
              // Initial staff clefs
              final glyph = _smuflClef(activeClefs[pIdx]);
              pageElements.add(PositionedClef(
                x: localX,
                y: staff.topY + (staff.lines - activeClefs[pIdx].anchorLine) * lineGap * staff.scale,
                scale: staff.scale,
                glyph: glyph,
              ));
            }
          }
          if (decorWidth > 0.0) localX += lineGap * SmuflGlyph.gClef.widthSp * 0.8;

          for (var pIdx = 0; pIdx < score.parts.length; pIdx++) {
            final part = score.parts[pIdx];
            final measure = part.measures[mIdx];
            final staff = system.staves[pIdx];

            // 2. Key Signature
            if (measure.keySignature != null && (mIdx == 0 || measure.keySignature != activeKeys[pIdx])) {
              activeKeys[pIdx] = measure.keySignature!;
              
              final keySig = activeKeys[pIdx];
              if (keySig != null && keySig.fifths != 0) {
                final accList = <KeySignatureAccidental>[];
                final isFlat = keySig.fifths < 0;
                final count = keySig.fifths.abs();
                for (var i = 0; i < count; i++) {
                  final glyph = isFlat ? SmuflGlyph.accidentalFlat : SmuflGlyph.accidentalSharp;
                  
                  accList.add(KeySignatureAccidental(
                    glyph: glyph,
                    y: staff.topY + (staff.lines - 3) * lineGap * staff.scale, // Positioned on staff center
                  ));
                }
                pageElements.add(PositionedKeySignature(
                  x: localX,
                  y: staff.topY,
                  scale: staff.scale,
                  accidentals: accList,
                ));
              }
            }
          }
          if (decorWidth > 0.0) localX += lineGap * 1.5;

          for (var pIdx = 0; pIdx < score.parts.length; pIdx++) {
            final part = score.parts[pIdx];
            final measure = part.measures[mIdx];
            final staff = system.staves[pIdx];

            // 3. Time Signature
            if (measure.timeSignature != null && (mIdx == 0 || measure.timeSignature != activeTimes[pIdx])) {
              activeTimes[pIdx] = measure.timeSignature!;
              pageElements.add(PositionedTimeSignature(
                x: localX,
                y: staff.topY + 2 * lineGap * staff.scale,
                scale: staff.scale,
                beats: activeTimes[pIdx]!.beats,
                beatValue: activeTimes[pIdx]!.beatValue,
              ));
            }
          }

          // Move cursor to event start space
          final eventStartX = xCursor + decorWidth;
          final spindleList = measureSpindles[mIdx];

          // 4. Place Notes & Rests
          for (var pIdx = 0; pIdx < score.parts.length; pIdx++) {
            final part = score.parts[pIdx];
            final measure = part.measures[mIdx];
            final staff = system.staves[pIdx];
            final spindle = spindleList[pIdx];
            final clef = activeClefs[pIdx];

            for (final voice in measure.voices.values) {
              var timeCursor = const RhythmicDuration(0, 1);

              for (final event in voice.events) {
                final onsetX = eventStartX + (spindle.coordinates[timeCursor] ?? 0.0) * justifyFactor;

                switch (event) {
                  case NoteEvent(:final pitch, :final duration):
                    // Y calculation: E4 is line 1. Ledger line placement starts below E4
                    // In Treble clef, G4 is line 2 (index 1).
                    // diatonicStepOffset gives scientific step. Let's map physically:
                    final stepFromBottom = (clef.anchorLine - 1) * 2 + pitch.diatonicStepOffset(reference: clef.referencePitch);
                    final noteY = staff.topY + (staff.lines - 1) * lineGap * staff.scale -
                        stepFromBottom * (lineGap / 2.0) * staff.scale;

                    // Generate ledger lines if note falls outside the 5 staff lines
                    final ledgers = <double>[];
                    if (stepFromBottom < 0) {
                      // Ledger lines below staff
                      for (var s = -2; s >= stepFromBottom; s -= 2) {
                        ledgers.add(staff.topY + (staff.lines - 1) * lineGap * staff.scale -
                            s * (lineGap / 2.0) * staff.scale);
                      }
                    } else if (stepFromBottom >= staff.lines * 2 - 1) {
                      // Ledger lines above staff
                      for (var s = staff.lines * 2; s <= stepFromBottom; s += 2) {
                        ledgers.add(staff.topY + (staff.lines - 1) * lineGap * staff.scale -
                            s * (lineGap / 2.0) * staff.scale);
                      }
                    }

                    // Choose visual properties
                    final hasStem = duration <= RhythmicDuration.half;
                    final stemUp = stepFromBottom < 4; // Stem up for lower notes, down for higher
                    final noteheadGlyph = duration >= RhythmicDuration.whole
                        ? SmuflGlyph.noteheadWhole
                        : (duration == RhythmicDuration.half
                            ? SmuflGlyph.noteheadHalf
                            : SmuflGlyph.noteheadBlack);

                    // Add flag if necessary
                    SmuflGlyph? flag;
                    if (duration == RhythmicDuration.eighth) {
                      flag = stemUp ? SmuflGlyph.flag8thUp : SmuflGlyph.flag8thDown;
                    } else if (duration == RhythmicDuration.sixteenth) {
                      flag = stemUp ? SmuflGlyph.flag16thUp : SmuflGlyph.flag16thDown;
                    }

                    pageElements.add(PositionedNote(
                      x: onsetX,
                      y: noteY,
                      scale: staff.scale,
                      pitch: pitch,
                      glyph: noteheadGlyph,
                      hasStem: hasStem,
                      stemUp: stemUp,
                      flagGlyph: flag,
                      ledgerLineYs: ledgers,
                    ));
                    timeCursor = (timeCursor + duration).simplified();
                    break;

                  case RestEvent(:final duration):
                    final restGlyph = _smuflRest(duration);
                    pageElements.add(PositionedRest(
                      x: onsetX,
                      y: staff.topY + 2.0 * lineGap * staff.scale, // Staff center
                      scale: staff.scale,
                      glyph: restGlyph,
                    ));
                    timeCursor = (timeCursor + duration).simplified();
                    break;

                  case ChordEvent(:final pitches, :final duration):
                    // Draw each note in the chord
                    final hasStem = duration <= RhythmicDuration.half;
                    // Sort pitches so stem logic handles bounds
                    final sortedPitches = pitches.toList()..sort();
                    if (sortedPitches.isNotEmpty) {
                      final lowestStep = (clef.anchorLine - 1) * 2 + sortedPitches.first.diatonicStepOffset(reference: clef.referencePitch);
                      final stemUp = lowestStep < 4;

                      for (final pitch in pitches) {
                        final stepFromBottom = (clef.anchorLine - 1) * 2 + pitch.diatonicStepOffset(reference: clef.referencePitch);
                        final noteY = staff.topY + (staff.lines - 1) * lineGap * staff.scale -
                            stepFromBottom * (lineGap / 2.0) * staff.scale;

                        final ledgers = <double>[];
                        if (stepFromBottom < 0) {
                          for (var s = -2; s >= stepFromBottom; s -= 2) {
                            ledgers.add(staff.topY + (staff.lines - 1) * lineGap * staff.scale -
                                s * (lineGap / 2.0) * staff.scale);
                          }
                        } else if (stepFromBottom >= staff.lines * 2 - 1) {
                          for (var s = staff.lines * 2; s <= stepFromBottom; s += 2) {
                            ledgers.add(staff.topY + (staff.lines - 1) * lineGap * staff.scale -
                                s * (lineGap / 2.0) * staff.scale);
                          }
                        }

                        final noteheadGlyph = duration >= RhythmicDuration.whole
                            ? SmuflGlyph.noteheadWhole
                            : (duration == RhythmicDuration.half
                                ? SmuflGlyph.noteheadHalf
                                : SmuflGlyph.noteheadBlack);

                        pageElements.add(PositionedNote(
                          x: onsetX,
                          y: noteY,
                          scale: staff.scale,
                          pitch: pitch,
                          glyph: noteheadGlyph,
                          hasStem: hasStem,
                          stemUp: stemUp,
                          ledgerLineYs: ledgers,
                        ));
                      }
                    }
                    timeCursor = (timeCursor + duration).simplified();
                    break;
                }
              }
            }
          }

          // Advance horizontal measure bounds and draw a final barline
          xCursor += decorWidth + justifiedSpacingWidth + 1.0;
          
          pageElements.add(PositionedBarline(
            x: xCursor,
            topY: sysTopY,
            bottomY: sysBottomY,
            thicknessMm: 0.5,
          ));
        }
      }

      pagesList.add(EngravingPage(
        pageLayout: pageBaseLayout,
        elements: pageElements,
      ));
    }

    return EngravingLayout(pages: pagesList);
  }

  // --- Helpers to resolve domain configurations to SMuFL vectors ---

  static SmuflGlyph _smuflClef(Clef clef) {
    if (clef is TrebleClef) return SmuflGlyph.gClef;
    if (clef is BassClef) return SmuflGlyph.fClef;
    if (clef is AltoClef || clef is TenorClef) return SmuflGlyph.cClef;
    if (clef is PercussionClef) return SmuflGlyph.percussionClef;
    if (clef is TabClef) return SmuflGlyph.tabClef;
    return SmuflGlyph.gClef;
  }

  static SmuflGlyph _smuflRest(RhythmicDuration duration) {
    if (duration >= RhythmicDuration.whole) return SmuflGlyph.restWhole;
    if (duration == RhythmicDuration.half) return SmuflGlyph.restHalf;
    if (duration == RhythmicDuration.quarter) return SmuflGlyph.restQuarter;
    if (duration == RhythmicDuration.eighth) return SmuflGlyph.restEighth;
    if (duration == RhythmicDuration.sixteenth) return SmuflGlyph.restSixteenth;
    return SmuflGlyph.restThirtySecond;
  }
}
