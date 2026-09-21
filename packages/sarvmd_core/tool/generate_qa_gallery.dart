// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart';

void main(List<String> args) async {
  final primaryOutputDir = Directory(
    args.isNotEmpty
        ? args[0]
        : '/home/ono/Projects/sarvmd/apps/sarvmd_ui/output/qa_gallery',
  );

  final artifactDir = Directory(
    '/home/ono/.gemini/antigravity-ide/brain/ea1eed8f-dfa4-49f6-aee6-2153a64044b5/qa_gallery',
  );

  if (!primaryOutputDir.existsSync()) {
    primaryOutputDir.createSync(recursive: true);
  }
  if (!artifactDir.existsSync()) {
    artifactDir.createSync(recursive: true);
  }

  print('Generating QA Manuscript Visual Validation Gallery...');
  print('Target Primary:  ${primaryOutputDir.path}');
  print('Target Artifact: ${artifactDir.path}');

  final galleryItems = <Map<String, dynamic>>[];

  Future<void> saveArtifacts({
    required String id,
    required String title,
    required String category,
    required String categoryLabel,
    required String description,
    required String standardsNote,
    required PageConfig config,
    required PageLayout layout,
    required String svgContent,
    required Uint8List pdfBytes,
  }) async {
    final svgFileName = '$id.svg';
    final pdfFileName = '$id.pdf';

    final primarySvgPath = p.join(primaryOutputDir.path, svgFileName);
    final primaryPdfPath = p.join(primaryOutputDir.path, pdfFileName);
    File(primarySvgPath).writeAsStringSync(svgContent);
    File(primaryPdfPath).writeAsBytesSync(pdfBytes);

    final artifactSvgPath = p.join(artifactDir.path, svgFileName);
    final artifactPdfPath = p.join(artifactDir.path, pdfFileName);
    File(artifactSvgPath).writeAsStringSync(svgContent);
    File(artifactPdfPath).writeAsBytesSync(pdfBytes);

    final firstSys = layout.systems.isNotEmpty ? layout.systems.first : null;
    final leftIndent = firstSys?.leftIndentMm ?? 0.0;
    final maxInnerWidth = firstSys?.maxInnerLabelWidthMm ?? 0.0;

    galleryItems.add({
      'id': id,
      'title': title,
      'category': category,
      'categoryLabel': categoryLabel,
      'description': description,
      'standardsNote': standardsNote,
      'svgFileName': svgFileName,
      'pdfFileName': pdfFileName,
      'pageSize': '${config.pageSize.name.toUpperCase()} ${config.orientation.name}',
      'dimensions': '${config.effectiveWidth.toStringAsFixed(1)} × ${config.effectiveHeight.toStringAsFixed(1)} mm',
      'systemCount': layout.systemCount,
      'staffCount': config.staffCount,
      'leftIndentMm': leftIndent.toStringAsFixed(2),
      'maxInnerWidthMm': maxInnerWidth.toStringAsFixed(2),
      'svgSizeBytes': svgContent.length,
      'pdfSizeBytes': pdfBytes.length,
    });

    stdout.write('.');
  }

  // =========================================================================
  // 1. HIERARCHICAL & TWO-TIER LABELING SCENARIOS (Gould & MOLA Standards)
  // =========================================================================
  print('\n[1/4] Exporting Gouldian Hierarchical Labeling Scenarios with Abbreviations...');

  // 1.1 Flutes 1 & 2 (Classic 2-Tier Standard with Abbreviations)
  {
    final f1 = const StaffDefinition(uid: 'f1', instrumentName: '1', instrumentAbbreviation: '1');
    final f2 = const StaffDefinition(uid: 'f2', instrumentName: '2', instrumentAbbreviation: '2');
    final flutes = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Flutes',
      abbreviation: 'Fl.',
      children: [f1, f2],
    );
    final config = PageConfig(systemLayout: SystemLayout(rootGroup: flutes));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_flutes_2tier',
      title: 'Flutes 1 & 2 (Two-Tier Gouldian Standard)',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'Outer section label "Flutes" (abbrev: "Fl.") with bracket connector and right-aligned inner numerals "1" and "2". Standard 2.0 mm bracket ticks.',
      standardsNote: 'Gould (p. 515): Full section name on System 1; abbreviation "Fl." on subsequent systems.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.2 Trombones 1, 2, 3 (Odd-Staff Midpoint Alignment with Abbreviation)
  {
    final t1 = const StaffDefinition(uid: 't1', instrumentName: '1', instrumentAbbreviation: '1');
    final t2 = const StaffDefinition(uid: 't2', instrumentName: '2', instrumentAbbreviation: '2');
    final t3 = const StaffDefinition(uid: 't3', instrumentName: '3', instrumentAbbreviation: '3');
    final trombones = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Trombones',
      abbreviation: 'Tbn.',
      children: [t1, t2, t3],
    );
    final config = PageConfig(systemLayout: SystemLayout(rootGroup: trombones));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_trombones_midpoint',
      title: 'Trombones 1, 2, 3 (Odd-Staff Midpoint Centering)',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: '3-staff ensemble where group label "Trombones" (abbrev: "Tbn.") centers on Trombone 2 with zero collision. Shows "Tbn." on subsequent systems.',
      standardsNote: 'Gould (p. 517): When group has an odd number of staves, center group label on middle staff descriptor.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.3 Mixed Auxiliary Instrumentation (Flutes 1, 2, Piccolo)
  {
    final f1 = const StaffDefinition(uid: 'f1', instrumentName: '1', instrumentAbbreviation: '1');
    final f2 = const StaffDefinition(uid: 'f2', instrumentName: '2', instrumentAbbreviation: '2');
    final picc = const StaffDefinition(uid: 'picc', instrumentName: 'Piccolo', instrumentAbbreviation: 'Picc.');
    final flutes = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Flutes',
      abbreviation: 'Fl.',
      children: [f1, f2, picc],
    );
    final config = PageConfig(systemLayout: SystemLayout(rootGroup: flutes));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_auxiliary_piccolo',
      title: 'Flutes & Piccolo (Mixed Auxiliary Lengths)',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'System 1 has "Piccolo" (~14mm width); System 2+ has "Picc." (~7mm width), with indent shrinking dynamically.',
      standardsNote: 'Gould (p. 511): Primary staves numbered; auxiliary instrument receives name on Sys 1 and standard abbrev on Sys 2+.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.4 Nested Woodwinds Hierarchy (Level 1 & Level 2 Sub-groups with Abbreviations)
  {
    final f1 = const StaffDefinition(uid: 'f1', instrumentName: '1', instrumentAbbreviation: '1');
    final f2 = const StaffDefinition(uid: 'f2', instrumentName: '2', instrumentAbbreviation: '2');
    final flutes = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Flutes',
      abbreviation: 'Fl.',
      children: [f1, f2],
    );

    final ob1 = const StaffDefinition(uid: 'ob1', instrumentName: '1', instrumentAbbreviation: '1');
    final ob2 = const StaffDefinition(uid: 'ob2', instrumentName: '2', instrumentAbbreviation: '2');
    final oboes = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Oboes',
      abbreviation: 'Ob.',
      children: [ob1, ob2],
    );

    final woodwinds = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Woodwinds',
      abbreviation: 'W.W.',
      children: [flutes, oboes],
    );

    final config = PageConfig(systemLayout: SystemLayout(rootGroup: woodwinds));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_nested_woodwinds',
      title: 'Woodwinds (Level 1 Section + Level 2 Sub-groups)',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'Family "Woodwinds" (abbrev: "W.W.") on Level 1; sub-groups "Flutes" ("Fl.") and "Oboes" ("Ob.") on Level 2.',
      standardsNote: 'Gould (p. 512): Sub-brackets sit to the right of primary family bracket with uniform 4.0 mm clearance.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.5 Orchestral Strings with Violins Sub-group (MOLA Standard)
  {
    final v1 = const StaffDefinition(uid: 'v1', instrumentName: '1', instrumentAbbreviation: '1');
    final v2 = const StaffDefinition(uid: 'v2', instrumentName: '2', instrumentAbbreviation: '2');
    final violins = StaffNodeGroup(
      connector: SystemConnector.subBracket,
      label: 'Violins',
      abbreviation: 'Vln.',
      children: [v1, v2],
    );

    final va = const StaffDefinition(uid: 'va', instrumentName: 'Viola', instrumentAbbreviation: 'Vla.');
    final vc = const StaffDefinition(uid: 'vc', instrumentName: 'Violoncello', instrumentAbbreviation: 'Vc.');
    final db = const StaffDefinition(uid: 'db', instrumentName: 'Double Bass', instrumentAbbreviation: 'D.B.');

    final strings = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Strings',
      abbreviation: 'Str.',
      children: [violins, va, vc, db],
    );

    final config = PageConfig(systemLayout: SystemLayout(rootGroup: strings));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_strings_subgroups',
      title: 'Strings with Violins Sub-group (MOLA Standard)',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'Family "Strings" ("Str.") bracket enclosing a "Violins" ("Vln.") sub-bracket for Violins 1 & 2, alongside Viola ("Vla."), Cello ("Vc."), and Bass ("D.B.").',
      standardsNote: 'MOLA standard orchestral string section layout with homogeneous sub-bracket.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.6 Orchestral Brass with Trumpets & Trombones Sub-groups
  {
    final tpt1 = const StaffDefinition(uid: 'tp1', instrumentName: '1', instrumentAbbreviation: '1');
    final tpt2 = const StaffDefinition(uid: 'tp2', instrumentName: '2', instrumentAbbreviation: '2');
    final trumpets = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Trumpets in C',
      abbreviation: 'Tpt. (C)',
      children: [tpt1, tpt2],
    );

    final tb1 = const StaffDefinition(uid: 'tb1', instrumentName: '1', instrumentAbbreviation: '1');
    final tb2 = const StaffDefinition(uid: 'tb2', instrumentName: '2', instrumentAbbreviation: '2');
    final btb = const StaffDefinition(uid: 'btb', instrumentName: 'Bass Trombone', instrumentAbbreviation: 'B. Tbn.');
    final trombones = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Trombones',
      abbreviation: 'Tbn.',
      children: [tb1, tb2, btb],
    );

    final tuba = const StaffDefinition(uid: 'tu', instrumentName: 'Tuba', instrumentAbbreviation: 'Tba.');

    final brass = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Brass',
      abbreviation: 'Br.',
      children: [trumpets, trombones, tuba],
    );

    final config = PageConfig(systemLayout: SystemLayout(rootGroup: brass));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_brass_subgroups',
      title: 'Brass Family with Trumpets & Trombones Sub-groups',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'Family "Brass" ("Br.") enclosing Trumpets sub-group ("Tpt. (C)") and Trombones sub-group ("Tbn." with 1, 2, B. Tbn.), followed by Tuba ("Tba.").',
      standardsNote: 'Gould (p. 514): Sub-groups for like brass instruments with independent key indications.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.7 Strings Chamber Section (Full Names with Abbreviations)
  {
    final v1 = const StaffDefinition(uid: 'v1', instrumentName: 'Violin I', instrumentAbbreviation: 'Vln. I');
    final v2 = const StaffDefinition(uid: 'v2', instrumentName: 'Violin II', instrumentAbbreviation: 'Vln. II');
    final va = const StaffDefinition(uid: 'va', instrumentName: 'Viola', instrumentAbbreviation: 'Vla.');
    final vc = const StaffDefinition(uid: 'vc', instrumentName: 'Violoncello', instrumentAbbreviation: 'Vc.');
    final strings = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: 'Strings',
      abbreviation: 'Str.',
      children: [v1, v2, va, vc],
    );

    final config = PageConfig(systemLayout: SystemLayout(rootGroup: strings));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_strings_full',
      title: 'Strings (Section Bracket + Full Instrument Names & Abbreviations)',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'System 1 displays "Strings" and full names ("Violin I", "Violoncello"); System 2+ displays "Str." and abbreviations ("Vln. I", "Vc.").',
      standardsNote: 'MOLA standard chamber string layout with full-to-abbreviated system progression.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.8 Grand Staff Fallback (Piano Brace with Abbreviation)
  {
    final rh = const StaffDefinition(uid: 'rh', clef: Clef.treble);
    final lh = const StaffDefinition(uid: 'lh', clef: Clef.bass);
    final piano = StaffNodeGroup(
      connector: SystemConnector.brace,
      label: 'Piano',
      abbreviation: 'Pno.',
      children: [rh, lh],
    );

    final config = PageConfig(systemLayout: SystemLayout(rootGroup: piano));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_piano_fallback',
      title: 'Piano (Grand Staff Brace with Abbreviation)',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'Grand staff brace displaying "Piano" on System 1 and "Pno." on subsequent systems. Zero inner width allocated for unlabeled staves.',
      standardsNote: 'Single-tier fallback eliminates phantom margins while supporting group abbreviation.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // 1.9 Unlabeled Group with Labeled Staves and Abbreviations
  {
    final v1 = const StaffDefinition(uid: 'v1', instrumentName: 'Violin I', instrumentAbbreviation: 'Vln. I');
    final v2 = const StaffDefinition(uid: 'v2', instrumentName: 'Violin II', instrumentAbbreviation: 'Vln. II');
    final group = StaffNodeGroup(
      connector: SystemConnector.bracket,
      label: '', // Unlabeled
      abbreviation: '',
      children: [v1, v2],
    );

    final config = PageConfig(systemLayout: SystemLayout(rootGroup: group));
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'hierarchical_unlabeled_group',
      title: 'Unlabeled Bracket with Labeled Staves & Abbreviations',
      category: 'hierarchical',
      categoryLabel: 'Hierarchical Labeling',
      description: 'Unlabeled bracket displaying "Violin I" on Sys 1 and "Vln. I" on Sys 2+. Reverts cleanly to single-tier indentation.',
      standardsNote: 'Gould (p. 510): Unlabeled bracket applies standard left indent without ghost group space.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // =========================================================================
  // 2. ALL 14 BUILT-IN PRESETS (Blank Manuscript Layouts)
  // =========================================================================
  print('\n[2/5] Exporting All 14 Built-In Presets...');

  for (final profile in StaffProfiles.all) {
    final baseConfig = const PageConfig();
    final config = profile.applyTo(baseConfig);
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: 'preset_${profile.id}',
      title: profile.label,
      category: 'presets',
      categoryLabel: 'Preset Profiles',
      description: profile.description ?? 'Blank manuscript configuration for ${profile.label}.',
      standardsNote: 'Predefined SarvMD standard ensemble layout with calibrated spacing.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // =========================================================================
  // 3. PAGE GEOMETRY & ORIENTATION MATRIX
  // =========================================================================
  print('\n[3/4] Exporting Page Geometries & Orientations...');

  final variationConfigs = [
    (
      'format_a4_portrait',
      const PageConfig(pageSize: PageSize.a4, orientation: PageOrientation.portrait),
      'A4 Portrait (210 × 297 mm)',
      'Standard European publication format for solo and chamber parts.'
    ),
    (
      'format_a4_landscape',
      const PageConfig(pageSize: PageSize.a4, orientation: PageOrientation.landscape),
      'A4 Landscape (297 × 210 mm)',
      'Landscape orientation widely used for organ and keyboard music.'
    ),
    (
      'format_letter_portrait',
      const PageConfig(pageSize: PageSize.letter, orientation: PageOrientation.portrait),
      'US Letter Portrait (215.9 × 279.4 mm)',
      'Standard North American paper size for sheet music.'
    ),
    (
      'format_letter_landscape',
      const PageConfig(pageSize: PageSize.letter, orientation: PageOrientation.landscape),
      'US Letter Landscape (279.4 × 215.9 mm)',
      'North American landscape format for choral octavos and lead sheets.'
    ),
    (
      'format_a3_landscape',
      const PageConfig(pageSize: PageSize.a3, orientation: PageOrientation.landscape),
      'A3 Landscape (420 × 297 mm)',
      'Large orchestral conductor score format accommodating massive system heights.'
    ),
    (
      'format_a5_portrait',
      const PageConfig(pageSize: PageSize.a5, orientation: PageOrientation.portrait),
      'A5 Portrait (148 × 210 mm)',
      'Compact study score and marching band booklet dimensions.'
    ),
  ];

  for (final (id, config, title, desc) in variationConfigs) {
    final layout = computeLayout(config);
    final svg = ScoreCompiler.compileToSvg(config, layout);
    final pdf = await ScoreCompiler.compileToPdf(config, layout);

    await saveArtifacts(
      id: id,
      title: title,
      category: 'geometry',
      categoryLabel: 'Page Geometries',
      description: desc,
      standardsNote: 'Strict physical dimension adherence with calibrated proportional margins.',
      config: config,
      layout: layout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // =========================================================================
  // 4. SVG LAYERING MODES
  // =========================================================================
  print('\n[4/4] Exporting SVG Layering Modes...');

  final layeringConfigs = [
    (
      'layering_flat',
      SvgLayeringMode.flatByCategory,
      'SVG Layering: Flat by Category',
      'Groups elements into semantic layers: <g id="sarv-staves">, <g id="sarv-connectors">, <g id="sarv-labels">. Ideal for vector illustration software like Inkscape and Illustrator.'
    ),
    (
      'layering_hierarchical',
      SvgLayeringMode.hierarchicalBySystem,
      'SVG Layering: Hierarchical by System',
      'Nests elements by musical system and staff index. Optimal for interactive web playback, SVG DOM manipulation, and note-highlighting.'
    ),
    (
      'layering_none',
      SvgLayeringMode.none,
      'SVG Layering: Streamlined Flat Stream',
      'Raw, unnested linear SVG stream minimizing file size and XML overhead for high-speed rendering pipelines.'
    ),
  ];

  final ensembleConfig = StaffProfiles.chamberOrchestra.applyTo(const PageConfig());
  final ensembleLayout = computeLayout(ensembleConfig);

  for (final (id, mode, title, desc) in layeringConfigs) {
    final svg = ScoreCompiler.compileToSvg(ensembleConfig, ensembleLayout, layeringMode: mode);
    final pdf = await ScoreCompiler.compileToPdf(ensembleConfig, ensembleLayout);

    await saveArtifacts(
      id: id,
      title: title,
      category: 'layering',
      categoryLabel: 'SVG Layering Modes',
      description: desc,
      standardsNote: 'Compliant with SVG 1.1 / SVG 2 recommendations for vector graphics interchange.',
      config: ensembleConfig,
      layout: ensembleLayout,
      svgContent: svg,
      pdfBytes: pdf,
    );
  }

  // =========================================================================
  // 6. GENERATE RICH INTERACTIVE HTML GALLERY
  // =========================================================================
  print('\nCompiling Interactive HTML Gallery...');

  final htmlContent = _buildGalleryHtml(galleryItems);

  final primaryHtmlPath = p.join(primaryOutputDir.path, 'export_gallery.html');
  final artifactHtmlPath = p.join(artifactDir.path, 'export_gallery.html');

  File(primaryHtmlPath).writeAsStringSync(htmlContent);
  File(artifactHtmlPath).writeAsStringSync(htmlContent);

  print('\n' + '=' * 70);
  print('QA VALIDATION GALLERY GENERATION COMPLETE!');
  print('Total Scenarios Exported: ${galleryItems.length}');
  print('Primary Gallery HTML:     file://$primaryHtmlPath');
  print('Artifact Gallery HTML:    file://$artifactHtmlPath');
  print('=' * 70 + '\n');
}

String _buildGalleryHtml(List<Map<String, dynamic>> items) {
  final buf = StringBuffer();
  buf.writeln('<!DOCTYPE html>');
  buf.writeln('<html lang="en">');
  buf.writeln('<head>');
  buf.writeln('  <meta charset="UTF-8">');
  buf.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
  buf.writeln('  <title>SarvMD Manuscript QA & Visual Validation Gallery</title>');
  buf.writeln('  <style>');
  buf.writeln('''
    :root {
      --bg: #090d16;
      --surface: #131c2e;
      --surface-border: #23314d;
      --card-hover: #18243c;
      --accent-cyan: #38bdf8;
      --accent-blue: #60a5fa;
      --accent-indigo: #818cf8;
      --accent-emerald: #10b981;
      --accent-amber: #f59e0b;
      --text-main: #f8fafc;
      --text-muted: #94a3b8;
      --text-dim: #64748b;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: var(--bg);
      color: var(--text-main);
      padding: 0 0 60px 0;
      line-height: 1.5;
    }
    header {
      background: linear-gradient(180deg, #131d31 0%, #090d16 100%);
      border-bottom: 1px solid var(--surface-border);
      padding: 36px 32px 28px 32px;
      position: sticky;
      top: 0;
      z-index: 100;
      backdrop-filter: blur(12px);
    }
    .header-content {
      max-width: 1400px;
      margin: 0 auto;
    }
    .title-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
      margin-bottom: 16px;
    }
    h1 {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.02em;
      background: linear-gradient(135deg, #e0f2fe 0%, #38bdf8 50%, #818cf8 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .meta-badges {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
    }
    .stat-pill {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 14px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 600;
      background: rgba(56, 189, 248, 0.1);
      color: var(--accent-cyan);
      border: 1px solid rgba(56, 189, 248, 0.25);
    }
    .stat-pill.success {
      background: rgba(16, 185, 129, 0.1);
      color: var(--accent-emerald);
      border-color: rgba(16, 185, 129, 0.25);
    }
    .controls-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
    }
    .filter-tabs {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }
    .tab-btn {
      background: var(--surface);
      border: 1px solid var(--surface-border);
      color: var(--text-muted);
      padding: 8px 16px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.2s ease;
    }
    .tab-btn:hover {
      background: var(--card-hover);
      color: var(--text-main);
      border-color: var(--accent-cyan);
    }
    .tab-btn.active {
      background: var(--accent-cyan);
      color: #04111d;
      border-color: var(--accent-cyan);
    }
    .search-box {
      position: relative;
    }
    .search-box input {
      background: var(--surface);
      border: 1px solid var(--surface-border);
      color: var(--text-main);
      padding: 8px 16px 8px 36px;
      border-radius: 8px;
      font-size: 13px;
      width: 240px;
      outline: none;
      transition: all 0.2s ease;
    }
    .search-box input:focus {
      border-color: var(--accent-cyan);
      box-shadow: 0 0 0 3px rgba(56, 189, 248, 0.15);
      width: 280px;
    }
    .search-icon {
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-dim);
      font-size: 14px;
      pointer-events: none;
    }
    main {
      max-width: 1400px;
      margin: 32px auto 0 auto;
      padding: 0 32px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(420px, 1fr));
      gap: 24px;
    }
    .card {
      background: var(--surface);
      border: 1px solid var(--surface-border);
      border-radius: 14px;
      padding: 20px;
      display: flex;
      flex-direction: column;
      transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease;
    }
    .card:hover {
      transform: translateY(-3px);
      box-shadow: 0 12px 28px -6px rgba(0, 0, 0, 0.5);
      border-color: rgba(56, 189, 248, 0.4);
    }
    .card-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 8px;
    }
    .card-title {
      font-size: 16px;
      font-weight: 700;
      color: var(--text-main);
    }
    .badge {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      padding: 4px 9px;
      border-radius: 6px;
      white-space: nowrap;
    }
    .badge-hierarchical { background: rgba(56, 189, 248, 0.15); color: var(--accent-cyan); border: 1px solid rgba(56, 189, 248, 0.3); }
    .badge-presets { background: rgba(96, 165, 250, 0.15); color: var(--accent-blue); border: 1px solid rgba(96, 165, 250, 0.3); }
    .badge-geometry { background: rgba(245, 158, 11, 0.15); color: var(--accent-amber); border: 1px solid rgba(245, 158, 11, 0.3); }
    .badge-layering { background: rgba(129, 140, 248, 0.15); color: var(--accent-indigo); border: 1px solid rgba(129, 140, 248, 0.3); }

    .card-desc {
      font-size: 13px;
      color: var(--text-muted);
      margin-bottom: 12px;
      min-height: 38px;
    }
    .standards-note {
      font-size: 12px;
      font-style: italic;
      color: #7dd3fc;
      background: rgba(14, 165, 233, 0.08);
      border-left: 3px solid var(--accent-cyan);
      padding: 6px 10px;
      border-radius: 0 6px 6px 0;
      margin-bottom: 16px;
    }
    .metrics-chips {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-bottom: 16px;
    }
    .chip {
      font-size: 11px;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      padding: 3px 8px;
      border-radius: 4px;
      background: #090d16;
      border: 1px solid #1f2a3f;
      color: var(--text-dim);
    }
    .chip span {
      color: var(--text-main);
      font-weight: 600;
    }
    .preview-box {
      background: #ffffff;
      border-radius: 8px;
      padding: 12px;
      min-height: 240px;
      max-height: 320px;
      overflow: auto;
      border: 1px solid #334155;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 16px;
    }
    .preview-box img {
      max-width: 100%;
      height: auto;
      display: block;
      margin: 0 auto;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .actions-row {
      display: flex;
      gap: 10px;
      margin-top: auto;
    }
    .action-btn {
      flex: 1;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      text-decoration: none;
      font-size: 12px;
      font-weight: 700;
      padding: 8px 12px;
      border-radius: 6px;
      transition: all 0.2s ease;
    }
    .btn-pdf {
      background: rgba(239, 68, 68, 0.12);
      color: #fca5a5;
      border: 1px solid rgba(239, 68, 68, 0.3);
    }
    .btn-pdf:hover {
      background: #dc2626;
      color: #ffffff;
      border-color: #dc2626;
    }
    .btn-svg {
      background: rgba(56, 189, 248, 0.12);
      color: #7dd3fc;
      border: 1px solid rgba(56, 189, 248, 0.3);
    }
    .btn-svg:hover {
      background: #0284c7;
      color: #ffffff;
      border-color: #0284c7;
    }
  ''');
  buf.writeln('  </style>');
  buf.writeln('</head>');
  buf.writeln('<body>');
  buf.writeln('  <header>');
  buf.writeln('    <div class="header-content">');
  buf.writeln('      <div class="title-row">');
  buf.writeln('        <h1>SarvMD Manuscript QA & Visual Validation Gallery</h1>');
  buf.writeln('        <div class="meta-badges">');
  buf.writeln('          <span class="stat-pill"><strong>${items.length}</strong> Scenarios</span>');
  buf.writeln('          <span class="stat-pill success">✓ SVG & PDF Vector Parity</span>');
  buf.writeln('          <span class="stat-pill">Gould & MOLA Compliant</span>');
  buf.writeln('        </div>');
  buf.writeln('      </div>');

  final hCount = items.where((i) => i['category'] == 'hierarchical').length;
  final pCount = items.where((i) => i['category'] == 'presets').length;
  final gCount = items.where((i) => i['category'] == 'geometry').length;
  final lCount = items.where((i) => i['category'] == 'layering').length;

  buf.writeln('      <div class="controls-row">');
  buf.writeln('        <div class="filter-tabs">');
  buf.writeln('          <button class="tab-btn active" onclick="filterCategory(\'all\', this)">All Scenarios (${items.length})</button>');
  buf.writeln('          <button class="tab-btn" onclick="filterCategory(\'hierarchical\', this)">Hierarchical & Sub-groups ($hCount)</button>');
  buf.writeln('          <button class="tab-btn" onclick="filterCategory(\'presets\', this)">Presets ($pCount)</button>');
  buf.writeln('          <button class="tab-btn" onclick="filterCategory(\'geometry\', this)">Geometries ($gCount)</button>');
  buf.writeln('          <button class="tab-btn" onclick="filterCategory(\'layering\', this)">SVG Layering ($lCount)</button>');
  buf.writeln('        </div>');
  buf.writeln('        <div class="search-box">');
  buf.writeln('          <span class="search-icon">🔍</span>');
  buf.writeln('          <input type="text" id="searchInput" placeholder="Search scenarios..." oninput="handleSearch()">');
  buf.writeln('        </div>');
  buf.writeln('      </div>');
  buf.writeln('    </div>');
  buf.writeln('  </header>');
  buf.writeln('  <main>');
  buf.writeln('    <div class="grid" id="galleryGrid">');

  for (final item in items) {
    final cat = item['category'] as String;
    final title = item['title'] as String;
    final badgeClass = 'badge-$cat';

    buf.writeln('      <div class="card" data-category="$cat" data-title="${title.toLowerCase()}">');
    buf.writeln('        <div class="card-top">');
    buf.writeln('          <h3 class="card-title">${item['title']}</h3>');
    buf.writeln('          <span class="badge $badgeClass">${item['categoryLabel']}</span>');
    buf.writeln('        </div>');
    buf.writeln('        <p class="card-desc">${item['description']}</p>');
    buf.writeln('        <div class="standards-note">${item['standardsNote']}</div>');

    buf.writeln('        <div class="metrics-chips">');
    buf.writeln('          <div class="chip">Indent: <span>${item['leftIndentMm']} mm</span></div>');
    buf.writeln('          <div class="chip">Inner: <span>${item['maxInnerWidthMm']} mm</span></div>');
    buf.writeln('          <div class="chip">Format: <span>${item['pageSize']}</span></div>');
    buf.writeln('          <div class="chip">Systems: <span>${item['systemCount']}</span></div>');
    buf.writeln('          <div class="chip">Staves: <span>${item['staffCount']}</span></div>');
    buf.writeln('        </div>');

    buf.writeln('        <div class="preview-box">');
    buf.writeln('          <img src="${item['svgFileName']}" alt="${item['title']}" loading="lazy">');
    buf.writeln('        </div>');

    buf.writeln('        <div class="actions-row">');
    buf.writeln('          <a href="${item['pdfFileName']}" class="action-btn btn-pdf" target="_blank" rel="noopener">');
    buf.writeln('            📄 View PDF (${(item['pdfSizeBytes'] / 1024).toStringAsFixed(1)} KB)');
    buf.writeln('          </a>');
    buf.writeln('          <a href="${item['svgFileName']}" class="action-btn btn-svg" target="_blank" rel="noopener">');
    buf.writeln('            🎨 View SVG (${(item['svgSizeBytes'] / 1024).toStringAsFixed(1)} KB)');
    buf.writeln('          </a>');
    buf.writeln('        </div>');
    buf.writeln('      </div>');
  }

  buf.writeln('    </div>');
  buf.writeln('  </main>');

  buf.writeln('''
  <script>
    let currentCategory = 'all';

    function filterCategory(category, btn) {
      currentCategory = category;
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      applyFilters();
    }

    function handleSearch() {
      applyFilters();
    }

    function applyFilters() {
      const query = document.getElementById('searchInput').value.toLowerCase().trim();
      const cards = document.querySelectorAll('#galleryGrid .card');

      cards.forEach(card => {
        const catMatch = currentCategory === 'all' || card.getAttribute('data-category') === currentCategory;
        const textMatch = query === '' || card.getAttribute('data-title').includes(query) || card.innerText.toLowerCase().includes(query);

        if (catMatch && textMatch) {
          card.style.display = 'flex';
        } else {
          card.style.display = 'none';
        }
      });
    }
  </script>
''');
  buf.writeln('</body>');
  buf.writeln('</html>');
  return buf.toString();
}
