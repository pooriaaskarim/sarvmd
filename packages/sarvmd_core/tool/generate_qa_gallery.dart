// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart';

void main() async {
  final outputDir = Directory('/home/ono/.gemini/antigravity-ide/brain/655f79d8-2fb0-4459-9e62-a468252bedc9/qa_gallery');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  print('Generating QA Manuscript SVG Gallery in ${outputDir.path}...');

  final galleryItems = <Map<String, String>>[];

  // 1. Generate SVGs for all built-in profiles (blank manuscript layout)
  for (final profile in StaffProfiles.all) {
    final baseConfig = PageConfig();
    final config = profile.applyTo(baseConfig);
    final layout = computeLayout(config);
    final svgContent = ScoreCompiler.compileToSvg(config, layout);

    final fileName = 'blank_${profile.id}.svg';
    final filePath = p.join(outputDir.path, fileName);
    File(filePath).writeAsStringSync(svgContent);

    galleryItems.add({
      'id': profile.id,
      'title': profile.label,
      'category': profile.category.name,
      'description': profile.description ?? '',
      'type': 'Blank Layout',
      'fileName': fileName,
    });
  }

  // 2. Generate SVGs for select profiles with engraved sample scores (notes, rests, barlines, key/time sigs)
  final engravedProfiles = [
    StaffProfiles.piano,
    StaffProfiles.treble,
    StaffProfiles.bass,
    StaffProfiles.guitarGrand,
    StaffProfiles.stringQuartet,
    StaffProfiles.drumSet,
    StaffProfiles.guitarTab,
  ];

  for (final profile in engravedProfiles) {
    final baseConfig = PageConfig();
    final config = profile.applyTo(baseConfig);
    // Create engraved sample score
    final score = _createSampleScoreForProfile(profile, config);
    final engravedLayout = Engraver.compile(score, config);

    if (engravedLayout.pages.isNotEmpty) {
      final svgContent = emitCompiledSvg(config, engravedLayout.pages.first);
      final fileName = 'engraved_${profile.id}.svg';
      final filePath = p.join(outputDir.path, fileName);
      File(filePath).writeAsStringSync(svgContent);

      galleryItems.add({
        'id': 'engraved_${profile.id}',
        'title': '${profile.label} (Engraved Notation)',
        'category': profile.category.name,
        'description': 'Engraved score with notes, rests, barlines, clefs, time & key signatures.',
        'type': 'Engraved Notation',
        'fileName': fileName,
      });
    }
  }

  // 3. Generate SVGs for different Page Sizes & Orientations (A3 Landscape, A5 Portrait, Letter)
  final variationConfigs = [
    (
      'A3_Landscape',
      const PageConfig(pageSize: PageSize.a3, orientation: PageOrientation.landscape),
      'A3 Landscape'
    ),
    (
      'A5_Portrait',
      const PageConfig(pageSize: PageSize.a5, orientation: PageOrientation.portrait),
      'A5 Portrait'
    ),
    (
      'Letter_Landscape',
      const PageConfig(pageSize: PageSize.letter, orientation: PageOrientation.landscape),
      'Letter Landscape'
    ),
  ];

  for (final (id, config, label) in variationConfigs) {
    final layout = computeLayout(config);
    final svgContent = ScoreCompiler.compileToSvg(config, layout);

    final fileName = 'variation_$id.svg';
    final filePath = p.join(outputDir.path, fileName);
    File(filePath).writeAsStringSync(svgContent);

    galleryItems.add({
      'id': id,
      'title': 'Page Format: $label',
      'category': 'format_variation',
      'description': 'Page dimensions and margin layout verification.',
      'type': 'Format Variation',
      'fileName': fileName,
    });
  }

  // 4. Generate HTML Gallery Page
  final htmlBuf = StringBuffer();
  htmlBuf.writeln('<!DOCTYPE html>');
  htmlBuf.writeln('<html lang="en">');
  htmlBuf.writeln('<head>');
  htmlBuf.writeln('  <meta charset="UTF-8">');
  htmlBuf.writeln('  <title>SarvMD Manuscript QA Gallery</title>');
  htmlBuf.writeln('  <style>');
  htmlBuf.writeln('    body { font-family: system-ui, -apple-system, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 24px; }');
  htmlBuf.writeln('    h1 { text-align: center; color: #38bdf8; margin-bottom: 8px; }');
  htmlBuf.writeln('    p.sub { text-align: center; color: #94a3b8; margin-bottom: 32px; }');
  htmlBuf.writeln('    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(480px, 1fr)); gap: 24px; }');
  htmlBuf.writeln('    .card { background: #1e293b; border-radius: 12px; border: 1px solid #334155; padding: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }');
  htmlBuf.writeln('    .card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }');
  htmlBuf.writeln('    .card-title { font-size: 16px; font-weight: 700; color: #f1f5f9; margin: 0; }');
  htmlBuf.writeln('    .badge { font-size: 11px; font-weight: 600; padding: 3px 8px; border-radius: 6px; background: #0284c7; color: #ffffff; }');
  htmlBuf.writeln('    .badge.engraved { background: #059669; }');
  htmlBuf.writeln('    .badge.format { background: #d97706; }');
  htmlBuf.writeln('    .card-desc { font-size: 12px; color: #94a3b8; margin-bottom: 12px; }');
  htmlBuf.writeln('    .svg-container { background: #ffffff; border-radius: 8px; padding: 12px; text-align: center; max-height: 400px; overflow: auto; border: 1px solid #475569; }');
  htmlBuf.writeln('    .svg-container img { max-width: 100%; height: auto; display: block; margin: 0 auto; }');
  htmlBuf.writeln('  </style>');
  htmlBuf.writeln('</head>');
  htmlBuf.writeln('<body>');
  htmlBuf.writeln('  <h1>SarvMD Manuscript QA Visual Gallery</h1>');
  htmlBuf.writeln('  <p class="sub">Comprehensive rendering validation across all built-in profiles, engraved notations, clefs, and page configurations (${galleryItems.length} test items)</p>');
  htmlBuf.writeln('  <div class="grid">');

  for (final item in galleryItems) {
    final badgeClass = item['type'] == 'Engraved Notation'
        ? 'engraved'
        : (item['type'] == 'Format Variation' ? 'format' : '');

    htmlBuf.writeln('    <div class="card" id="card-${item['id']}">');
    htmlBuf.writeln('      <div class="card-header">');
    htmlBuf.writeln('        <h3 class="card-title">${item['title']}</h3>');
    htmlBuf.writeln('        <span class="badge $badgeClass">${item['type']}</span>');
    htmlBuf.writeln('      </div>');
    htmlBuf.writeln('      <div class="card-desc">${item['description']}</div>');
    htmlBuf.writeln('      <div class="svg-container">');
    htmlBuf.writeln('        <img src="${item['fileName']}" alt="${item['title']}">');
    htmlBuf.writeln('      </div>');
    htmlBuf.writeln('    </div>');
  }

  htmlBuf.writeln('  </div>');
  htmlBuf.writeln('</body>');
  htmlBuf.writeln('</html>');

  final htmlPath = p.join(outputDir.path, 'export_gallery.html');
  File(htmlPath).writeAsStringSync(htmlBuf.toString());

  print('Successfully generated QA Gallery at ${htmlPath} with ${galleryItems.length} items.');
}

Score _createSampleScoreForProfile(StaffProfile profile, PageConfig config) {
  final partsList = <Part>[];

  if (profile.id == 'guitarGrand') {
    // Guitar Treble part + Guitar TAB part
    partsList.add(Part(
      id: 'p1',
      name: 'Guitar',
      measures: [
        Measure(
          number: 1,
          clef: Clef.treble,
          timeSignature: const TimeSignature(4, 4),
          keySignature: const KeySignature(1), // G major
          voices: {
            'v1': Voice(
              id: 'v1',
              events: [
                const NoteEvent(Pitch(NoteName.g, octave: 4), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.b, octave: 4), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.d, octave: 5), RhythmicDuration.half),
              ],
            ),
          },
        ),
      ],
    ));
    partsList.add(Part(
      id: 'p2',
      name: 'TAB',
      measures: [
        Measure(
          number: 1,
          clef: Clef.tab,
          timeSignature: const TimeSignature(4, 4),
          voices: {
            'v1': Voice(
              id: 'v1',
              events: [
                const NoteEvent(Pitch(NoteName.g, octave: 4), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.b, octave: 4), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.d, octave: 5), RhythmicDuration.half),
              ],
            ),
          },
        ),
      ],
    ));
  } else if (profile.id == 'piano') {
    // Treble + Bass parts
    partsList.add(Part(
      id: 'p1',
      name: 'Right Hand',
      measures: [
        Measure(
          number: 1,
          clef: Clef.treble,
          timeSignature: const TimeSignature(4, 4),
          voices: {
            'v1': Voice(
              id: 'v1',
              events: [
                const NoteEvent(Pitch(NoteName.c, octave: 5), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.e, octave: 5), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.g, octave: 5), RhythmicDuration.half),
              ],
            ),
          },
        ),
      ],
    ));
    partsList.add(Part(
      id: 'p2',
      name: 'Left Hand',
      measures: [
        Measure(
          number: 1,
          clef: Clef.bass,
          timeSignature: const TimeSignature(4, 4),
          voices: {
            'v1': Voice(
              id: 'v1',
              events: [
                const NoteEvent(Pitch(NoteName.c, octave: 3), RhythmicDuration.half),
                const NoteEvent(Pitch(NoteName.g, octave: 3), RhythmicDuration.half),
              ],
            ),
          },
        ),
      ],
    ));
  } else {
    // Single staff default part
    final clef = config.systemLayout.rootGroup.children.isNotEmpty &&
            config.systemLayout.rootGroup.children.first is StaffDefinition
        ? (config.systemLayout.rootGroup.children.first as StaffDefinition).clef ?? Clef.treble
        : Clef.treble;

    partsList.add(Part(
      id: 'p1',
      name: profile.label,
      measures: [
        Measure(
          number: 1,
          clef: clef,
          timeSignature: const TimeSignature(4, 4),
          voices: {
            'v1': Voice(
              id: 'v1',
              events: [
                const NoteEvent(Pitch(NoteName.c, octave: 4), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.e, octave: 4), RhythmicDuration.quarter),
                const NoteEvent(Pitch(NoteName.g, octave: 4), RhythmicDuration.half),
              ],
            ),
          },
        ),
      ],
    ));
  }

  return Score(title: profile.label, parts: partsList);
}
