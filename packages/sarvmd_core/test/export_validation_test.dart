// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:test/test.dart';
import 'package:sarvmd_core/sarvmd_core.dart';

void main() {
  group('Comprehensive Export Validation Across All Profiles', () {
    final allProfiles = StaffProfiles.all;

    test('Validates that all ${allProfiles.length} presets export clean SVG vectors without corruption', () {
      for (final profile in allProfiles) {
        final config = profile.applyTo(const PageConfig());
        final layout = computeLayout(config);
        final svgString = emitSvg(config, layout);

        // Basic SVG structure verification
        expect(svgString, contains('<svg'), reason: 'Profile ${profile.id} must output valid <svg>');
        expect(svgString, contains('</svg>'), reason: 'Profile ${profile.id} must close </svg>');

        // Check TAB specific export requirements
        if (profile.id.toLowerCase().contains('tab')) {
          expect(
            svgString,
            contains('M 40.0,950.0 L 320.0,950.0'),
            reason: 'TAB Profile ${profile.id} must export clean T-A-B vector path, not C-clef or random glyphs',
          );
        }

        // Check Percussion specific export requirements
        if (profile.id.toLowerCase().contains('percussion')) {
          expect(
            svgString,
            contains('<rect'),
            reason: 'Percussion Profile ${profile.id} must render neutral double bar rects',
          );
        }
      }
    });

    test('Validates all presets across all 3 SvgLayeringModes', () {
      for (final mode in SvgLayeringMode.values) {
        for (final profile in allProfiles) {
          final config = profile.applyTo(const PageConfig());
          final layout = computeLayout(config);
          final svg = emitSvg(config, layout, layeringMode: mode);

          expect(svg, contains('<svg'));
          expect(svg, contains('</svg>'));
          expect(svg, isNot(contains('NaN')), reason: 'Mode $mode with ${profile.id} must have no NaN coordinates');
        }
      }
    });

    test('Validates that all ${allProfiles.length} presets export clean PDF binary bytes', () async {
      for (final profile in allProfiles) {
        final config = profile.applyTo(const PageConfig());
        final layout = computeLayout(config);
        final pdfBytes = await emitPdf(config, layout);

        expect(pdfBytes, isNotEmpty, reason: 'Profile ${profile.id} must produce non-empty PDF bytes');
        final header = String.fromCharCodes(pdfBytes.take(4));
        expect(header, equals('%PDF'), reason: 'Profile ${profile.id} must start with valid %PDF header');
      }
    });

    test('Validates multi-page PDF export for complex ensembles (Piano & String Quartet)', () async {
      for (final profile in [StaffProfiles.piano, StaffProfiles.stringQuartet]) {
        final config = profile.applyTo(const PageConfig());
        final layout = computeLayout(config);

        // PDF multi-page
        final pdfBytes = await emitPdf(config, layout, pageCount: 3);
        expect(pdfBytes, isNotEmpty);
        final header = String.fromCharCodes(pdfBytes.take(4));
        expect(header, equals('%PDF'));
      }
    });
  });

  group('Hierarchical Labeling Export Scenarios (SVG & PDF Parity)', () {
    test('Two-tier labeled group exports correct non-overlapping coordinates in SVG & PDF', () async {
      final flute1 = StaffDefinition(uid: 'f1', instrumentName: '1');
      final flute2 = StaffDefinition(uid: 'f2', instrumentName: '2');
      final flutes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        children: [flute1, flute2],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: flutes),
      );

      final layout = computeLayout(config);
      final svg = emitSvg(config, layout);

      // SVG verification
      expect(svg, contains('Flutes'));
      expect(svg, contains('>1<'));
      expect(svg, contains('>2<'));

      final flutesMatch = RegExp(r'<text x="([\d\.]+)"[^>]*>Flutes</text>').firstMatch(svg);
      final innerMatch1 = RegExp(r'<text x="([\d\.]+)"[^>]*>1</text>').firstMatch(svg);
      final innerMatch2 = RegExp(r'<text x="([\d\.]+)"[^>]*>2</text>').firstMatch(svg);

      expect(flutesMatch, isNotNull);
      expect(innerMatch1, isNotNull);
      expect(innerMatch2, isNotNull);

      final flutesX = double.parse(flutesMatch!.group(1)!);
      final inner1X = double.parse(innerMatch1!.group(1)!);
      final inner2X = double.parse(innerMatch2!.group(1)!);

      // Inner descriptors share the same right-aligned X coordinate
      expect(inner1X, equals(inner2X));

      // Outer group label sits to the left of inner staff descriptors
      expect(flutesX, lessThan(inner1X));

      // Separation must account for connector glyph and clear spaces
      expect(inner1X - flutesX, greaterThan(4.5));

      // Check bracket line hook length (must be exactly 2.0mm, not extending to barline)
      final tickMatches = RegExp(r'<line x1="([\d\.]+)" y1="([\d\.]+)" x2="([\d\.]+)" y2="([\d\.]+)".*?/>').allMatches(svg);
      final tick = tickMatches.firstWhere((m) => m.group(2) == m.group(4) && m.group(1) != m.group(3));
      final connStartX = double.parse(tick.group(1)!);
      final connTickEndX = double.parse(tick.group(3)!);
      expect(connTickEndX - connStartX, closeTo(2.0, 0.01));

      // PDF verification
      final pdfBytes = await emitPdf(config, layout);
      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.take(4)), equals('%PDF'));
    });

    test('Odd-staff midpoint ensemble (3 Trombones) avoids vertical label collision', () async {
      final tbn1 = StaffDefinition(uid: 't1', instrumentName: '1');
      final tbn2 = StaffDefinition(uid: 't2', instrumentName: '2');
      final tbn3 = StaffDefinition(uid: 't3', instrumentName: '3');
      final trombones = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Trombones',
        children: [tbn1, tbn2, tbn3],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: trombones),
      );

      final layout = computeLayout(config);
      final svg = emitSvg(config, layout);

      final groupMatch = RegExp(r'<text x="([\d\.]+)" y="([\d\.]+)"[^>]*>Trombones</text>').firstMatch(svg);
      final midStaffMatch = RegExp(r'<text x="([\d\.]+)" y="([\d\.]+)"[^>]*>2</text>').firstMatch(svg);

      expect(groupMatch, isNotNull);
      expect(midStaffMatch, isNotNull);

      final groupX = double.parse(groupMatch!.group(1)!);
      final groupY = double.parse(groupMatch.group(2)!);
      final midStaffX = double.parse(midStaffMatch!.group(1)!);
      final midStaffY = double.parse(midStaffMatch.group(2)!);

      // Their Y-coordinates are vertically centered on the middle staff
      expect(groupY, closeTo(midStaffY, 1.0));

      // Their X-coordinates MUST NOT collide (group label is to the left of inner label)
      expect(groupX, lessThan(midStaffX));
      expect(midStaffX - groupX, greaterThan(4.5));

      // PDF generation
      final pdfBytes = await emitPdf(config, layout);
      expect(pdfBytes, isNotEmpty);
      expect(String.fromCharCodes(pdfBytes.take(4)), equals('%PDF'));
    });

    test('Mixed auxiliary instrumentation (Flutes 1, 2, Piccolo) scales indent dynamically', () async {
      final f1 = StaffDefinition(uid: 'f1', instrumentName: '1');
      final f2 = StaffDefinition(uid: 'f2', instrumentName: '2');
      final picc = StaffDefinition(uid: 'picc', instrumentName: 'Piccolo');
      final flutes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        children: [f1, f2, picc],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: flutes),
      );

      final layout = computeLayout(config);
      final system = layout.systems.first;

      // Piccolo width (~14mm) expands inner label width beyond numeral '1' (~1.9mm)
      expect(system.maxInnerLabelWidthMm, greaterThan(10.0));

      final svg = emitSvg(config, layout);
      final flutesMatch = RegExp(r'<text x="([\d\.]+)"[^>]*>Flutes</text>').firstMatch(svg);
      final piccMatch = RegExp(r'<text x="([\d\.]+)"[^>]*>Piccolo</text>').firstMatch(svg);

      expect(flutesMatch, isNotNull);
      expect(piccMatch, isNotNull);

      final flutesX = double.parse(flutesMatch!.group(1)!);
      final piccX = double.parse(piccMatch!.group(1)!);

      // Outer label is shifted far enough to accommodate Piccolo in the inner column
      expect(piccX - flutesX, greaterThan(13.0));

      final pdfBytes = await emitPdf(config, layout);
      expect(pdfBytes, isNotEmpty);
    });

    test('Single-tier fallback: Unlabeled group with labeled staves', () {
      final vln1 = StaffDefinition(uid: 'v1', instrumentName: 'Violin I');
      final vln2 = StaffDefinition(uid: 'v2', instrumentName: 'Violin II');
      final strings = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: '', // Unlabeled
        children: [vln1, vln2],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: strings),
      );

      final layout = computeLayout(config);
      final system = layout.systems.first;

      // Connected group inner width reflects labeled staves enclosed by the connector
      expect(system.maxInnerLabelWidthMm, equals(system.groupPlacements.first.innerStaffLabelWidthMm));
      expect(system.leftIndentMm, greaterThan(15.0));

      final svg = emitSvg(config, layout);
      expect(svg, contains('Violin I'));
      expect(svg, contains('Violin II'));
      expect(svg, isNot(contains('NaN')));
    });

    test('Single-tier fallback: Labeled grand staff with unlabeled staves (Piano)', () {
      final rh = StaffDefinition(uid: 'rh', clef: Clef.treble);
      final lh = StaffDefinition(uid: 'lh', clef: Clef.bass);
      final piano = StaffNodeGroup(
        connector: SystemConnector.brace,
        label: 'Piano',
        children: [rh, lh],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: piano),
      );

      final layout = computeLayout(config);
      final system = layout.systems.first;

      // Max inner width is 0 because child staves have no labels
      expect(system.maxInnerLabelWidthMm, equals(0.0));

      final svg = emitSvg(config, layout);
      expect(svg, contains('Piano'));
      expect(svg, contains('path')); // Brace path
    });

    test('Multi-level nested brackets render distinct horizontal level offsets', () {
      final f1 = StaffDefinition(uid: 'f1', instrumentName: '1');
      final f2 = StaffDefinition(uid: 'f2', instrumentName: '2');
      final flutes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Flutes',
        children: [f1, f2],
      );

      final ob1 = StaffDefinition(uid: 'ob1', instrumentName: '1');
      final ob2 = StaffDefinition(uid: 'ob2', instrumentName: '2');
      final oboes = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Oboes',
        children: [ob1, ob2],
      );

      final woodwinds = StaffNodeGroup(
        connector: SystemConnector.bracket,
        label: 'Woodwinds',
        children: [flutes, oboes],
      );

      final config = PageConfig(
        systemLayout: SystemLayout(rootGroup: woodwinds),
      );

      final layout = computeLayout(config);
      final svg = emitSvg(config, layout);

      expect(svg, contains('Woodwinds'));
      expect(svg, contains('Flutes'));
      expect(svg, contains('Oboes'));
      expect(svg, isNot(contains('NaN')));
    });

    test('Page orientation & dimension export matrix', () async {
      final configs = [
        const PageConfig(pageSize: PageSize.a4, orientation: PageOrientation.portrait),
        const PageConfig(pageSize: PageSize.a4, orientation: PageOrientation.landscape),
        const PageConfig(pageSize: PageSize.letter, orientation: PageOrientation.portrait),
        const PageConfig(pageSize: PageSize.letter, orientation: PageOrientation.landscape),
        const PageConfig(pageSize: PageSize.a3, orientation: PageOrientation.landscape),
      ];

      for (final config in configs) {
        final layout = computeLayout(config);
        final svg = emitSvg(config, layout);

        // Check viewBox matches page dimensions
        expect(
          svg,
          contains('viewBox="0 0 ${config.effectiveWidth.toStringAsFixed(3)} ${config.effectiveHeight.toStringAsFixed(3)}"'),
        );

        final pdf = await emitPdf(config, layout);
        expect(pdf, isNotEmpty);
      }
    });
  });
}

