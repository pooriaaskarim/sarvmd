// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart' as core;

/// Generates a mathematically aligned, multi-voice sample score matching the active staff layout.
///
/// This bridges the page geometry setup with real notation data. It crawls the layout's staves
/// tree and constructs parallel timelines populated with melodies, bass counters, or rests,
/// avoiding out-of-bounds rendering crashes when users modify staff counts.
core.Score createSampleScore(core.PageConfig config) {
  final staves = _getStaffDefinitions(config.systemLayout.rootGroup);
  final parts = <core.Part>[];

  for (var i = 0; i < staves.length; i++) {
    final staff = staves[i];
    final clef = staff.clef != null
        ? _mapClefConfigToDomain(staff.clef!)
        : (i == 1 ? core.Clef.bass : core.Clef.treble);

    final String partName = staff.instrumentName ?? 'Staff ${i + 1}';
    final measures = <core.Measure>[];

    // Build 4 measures of beautiful C-major dynamic harmony
    for (var m = 1; m <= 4; m++) {
      final events = <core.MusicalEvent>[];

      if (i == 0) {
        // Melodic Top Part (Treble scale rise/fall)
        if (m == 1) {
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.c, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.d, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.e, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.f, octave: 4), core.RhythmicDuration(1, 4)));
        } else if (m == 2) {
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.g, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.a, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.b, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.c, octave: 5), core.RhythmicDuration(1, 4)));
        } else if (m == 3) {
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.c, octave: 5), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.b, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.a, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.g, octave: 4), core.RhythmicDuration(1, 4)));
        } else {
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.f, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.e, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.d, octave: 4), core.RhythmicDuration(1, 4)));
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.c, octave: 4), core.RhythmicDuration(1, 4)));
        }
      } else if (i == 1) {
        // Grand-staff / Duo Counterpoint Part (Bass line half-notes)
        events.add(const core.NoteEvent(core.Pitch(core.NoteName.c, octave: 3), core.RhythmicDuration(1, 2)));
        events.add(const core.NoteEvent(core.Pitch(core.NoteName.g, octave: 3), core.RhythmicDuration(1, 2)));
      } else {
        // Ensembles / Pads Part (Whole notes/rests for other background tracks)
        if (m % 2 == 0) {
          events.add(const core.RestEvent(core.RhythmicDuration(1, 1)));
        } else {
          events.add(const core.NoteEvent(core.Pitch(core.NoteName.c, octave: 4), core.RhythmicDuration(1, 1)));
        }
      }

      // Explicitly declare signatures and clefs on bar 1 (standard engraving)
      measures.add(core.Measure(
        number: m,
        voices: {
          'v1': core.Voice(id: 'v1', events: events),
        },
        clef: m == 1 ? clef : null,
        timeSignature: m == 1 ? const core.TimeSignature(4, 4) : null,
        keySignature: m == 1 ? const core.KeySignature(0) : null,
      ));
    }

    parts.add(core.Part(
      id: staff.uid,
      name: partName,
      measures: measures,
    ));
  }

  return core.Score(
    title: config.systemLayout.rootGroup.children.length > 1
        ? 'Duo Ensemble'
        : 'Solo Manuscript',
    composer: 'SarvMD Core Engraver',
    parts: parts,
  );
}

/// Recursively flattens the nested StaffGroup layout to find all leaf staves definitions.
List<core.StaffDefinition> _getStaffDefinitions(core.StaffGroup group) {
  final list = <core.StaffDefinition>[];
  for (final child in group.children) {
    if (child is core.StaffDefinition) {
      list.add(child);
    } else if (child is core.StaffGroup) {
      list.addAll(_getStaffDefinitions(child));
    }
  }
  return list;
}

/// Helper mapping configuration clef symbols to domain object instances.
core.Clef _mapClefConfigToDomain(core.ClefConfig config) {
  return switch (config.symbol) {
    core.ClefSymbol.g => core.Clef.treble,
    core.ClefSymbol.f => core.Clef.bass,
    core.ClefSymbol.c => core.Clef.alto,
    core.ClefSymbol.percussion => core.Clef.percussion,
    core.ClefSymbol.tab => core.Clef.tab,
  };
}
