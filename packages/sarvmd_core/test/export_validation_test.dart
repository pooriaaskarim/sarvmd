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
}
