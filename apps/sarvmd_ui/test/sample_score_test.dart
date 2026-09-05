// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter_test/flutter_test.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:sarvmd_ui/src/logic/sample/sample_score.dart';

void main() {
  group('createSampleScore Engine Tests', () {
    test('Generates Solo Manuscript score for 1-staff treble config', () {
      final config = core.StaffProfiles.treble.applyTo(const core.PageConfig());
      final score = createSampleScore(config);

      expect(score.title, equals('Solo Manuscript'));
      expect(score.composer, equals('SarvMD Core Engraver'));
      expect(score.parts.length, equals(1));

      final part = score.parts.first;
      expect(part.measures.length, equals(4));

      // Bar 1 has clef, time signature, and key signature
      final measure1 = part.measures.first;
      expect(measure1.clef, equals(core.Clef.treble));
      expect(measure1.timeSignature, equals(const core.TimeSignature(4, 4)));
      expect(measure1.keySignature, equals(const core.KeySignature(0)));

      // Bar 2 does not repeat initial clef/signatures
      final measure2 = part.measures[1];
      expect(measure2.clef, isNull);
      expect(measure2.timeSignature, isNull);
      expect(measure2.keySignature, isNull);
    });

    test('Generates Duo Ensemble score for Piano Grand Staff', () {
      final config = core.StaffProfiles.piano.applyTo(const core.PageConfig());
      final score = createSampleScore(config);

      expect(score.title, equals('Duo Ensemble'));
      expect(score.parts.length, equals(2));

      final treblePart = score.parts[0];
      final bassPart = score.parts[1];

      expect(treblePart.measures.first.clef, equals(core.Clef.treble));
      expect(bassPart.measures.first.clef, equals(core.Clef.bass));
    });

    test('Generates 4 parts matching String Quartet profile', () {
      final config = core.StaffProfiles.stringQuartet.applyTo(const core.PageConfig());
      final score = createSampleScore(config);

      expect(score.parts.length, equals(4));
      expect(score.parts[0].measures.first.clef, equals(core.Clef.treble));
      expect(score.parts[1].measures.first.clef, equals(core.Clef.treble));
      expect(score.parts[2].measures.first.clef, equals(core.Clef.alto));
      expect(score.parts[3].measures.first.clef, equals(core.Clef.bass));
    });
  });
}
