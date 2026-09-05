// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:sarvmd_core/sarvmd_core.dart';

/// MusicXML Transcription service for parsing and generating MusicXML score files.
abstract final class MusicXmlTranscriber {
  /// Transcribes a [Score] AST object into a standardized MusicXML string document.
  static String scoreToMusicXml(Score score) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">');
    buffer.writeln('<score-partwise version="4.0">');
    buffer.writeln('  <work>');
    buffer.writeln('    <work-title>${score.title}</work-title>');
    buffer.writeln('  </work>');
    buffer.writeln('  <identification>');
    buffer.writeln('    <creator type="composer">${score.composer}</creator>');
    buffer.writeln('  </identification>');
    buffer.writeln('  <part-list>');
    if (score.parts.isEmpty) {
      buffer.writeln('    <score-part id="P1">');
      buffer.writeln('      <part-name>Music</part-name>');
      buffer.writeln('    </score-part>');
    } else {
      for (var i = 0; i < score.parts.length; i++) {
        final part = score.parts[i];
        buffer.writeln('    <score-part id="P${i + 1}">');
        buffer.writeln('      <part-name>${part.name}</part-name>');
        buffer.writeln('    </score-part>');
      }
    }
    buffer.writeln('  </part-list>');

    if (score.parts.isEmpty) {
      buffer.writeln('  <part id="P1">');
      buffer.writeln('  </part>');
    } else {
      for (var i = 0; i < score.parts.length; i++) {
        final part = score.parts[i];
        buffer.writeln('  <part id="P${i + 1}">');
        for (var mIdx = 0; mIdx < part.measures.length; mIdx++) {
          final measure = part.measures[mIdx];
          buffer.writeln('    <measure number="${mIdx + 1}">');
          final timeSig = measure.timeSignature;
          if (mIdx == 0 && timeSig != null) {
            buffer.writeln('      <attributes>');
            buffer.writeln('        <divisions>4</divisions>');
            buffer.writeln('        <time>');
            buffer.writeln('          <beats>${timeSig.beats}</beats>');
            buffer.writeln('          <beat-type>${timeSig.beatValue}</beat-type>');
            buffer.writeln('        </time>');
            buffer.writeln('      </attributes>');
          }
          for (final voice in measure.voices.values) {
            for (final event in voice.events) {
              buffer.writeln('      <note>');
              switch (event) {
                case NoteEvent(:final pitch):
                  buffer.writeln('        <pitch>');
                  buffer.writeln('          <step>${pitch.noteName.name.toUpperCase()}</step>');
                  buffer.writeln('          <alter>${pitch.accidental.semitoneOffset}</alter>');
                  buffer.writeln('          <octave>${pitch.octave}</octave>');
                  buffer.writeln('        </pitch>');
                case RestEvent():
                  buffer.writeln('        <rest/>');
                case ChordEvent(:final pitches):
                  if (pitches.isNotEmpty) {
                    final p = pitches.first;
                    buffer.writeln('        <pitch>');
                    buffer.writeln('          <step>${p.noteName.name.toUpperCase()}</step>');
                    buffer.writeln('          <alter>${p.accidental.semitoneOffset}</alter>');
                    buffer.writeln('          <octave>${p.octave}</octave>');
                    buffer.writeln('        </pitch>');
                  }
              }
              buffer.writeln('        <duration>${(event.duration.numerator / event.duration.denominator * 4).round()}</duration>');
              buffer.writeln('      </note>');
            }
          }
          buffer.writeln('    </measure>');
        }
        buffer.writeln('  </part>');
      }
    }

    buffer.writeln('</score-partwise>');
    return buffer.toString();
  }

  /// Parses a MusicXML string document into a [Score] AST object.
  static Score musicXmlToScore(String xmlContent) {
    final titleMatch = RegExp(r'<work-title>(.*?)</work-title>').firstMatch(xmlContent);
    final composerMatch = RegExp(r'<creator type="composer">(.*?)</creator>').firstMatch(xmlContent);

    final title = titleMatch?.group(1)?.trim() ?? 'Untitled Score';
    final composer = composerMatch?.group(1)?.trim() ?? 'Anonymous';

    return Score(
      title: title,
      composer: composer,
      parts: const [],
    );
  }
}
