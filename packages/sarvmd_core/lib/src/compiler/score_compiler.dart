// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:typed_data';

import '../compiler.dart' as pdflatex;
import '../config.dart';
import '../domain/svg_layering_mode.dart';
import '../emitter.dart' as tex_emitter;
import '../layout.dart';
import '../pdf_emitter.dart' as pdf_emitter;
import '../profiles.dart';
import '../svg_emitter.dart' as svg_emitter;

/// High-level compilation & code generation engine for SarvMD manuscript scores.
abstract final class ScoreCompiler {
  /// Generates a default clean filename based on page configuration.
  ///
  /// Examples: `Piano_A4_Portrait`, `Treble_A4_Portrait`, `Ensemble_4Staff_A4_Portrait`, `Manuscript_A4_Portrait`.
  static String getDefaultFileName(PageConfig config) {
    final size = config.pageSize.name.toUpperCase();
    final orient = config.orientation.name[0].toUpperCase() +
        config.orientation.name.substring(1);

    // Match against predefined staff profiles
    for (final profile in StaffProfiles.all) {
      if (config.systemLayout == profile.systemLayout) {
        final cleanLabel = profile.label
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .trim();
        return '${cleanLabel}_${size}_$orient';
      }
    }

    // Infer layout description from staves
    final count = config.staffCount;
    if (count == 0) {
      return 'Manuscript_${size}_$orient';
    }

    if (count == 1) {
      final group = config.systemLayout.rootGroup;
      if (group.children.isNotEmpty && group.children.first is StaffDefinition) {
        final staff = group.children.first as StaffDefinition;
        final clef = staff.clef;
        if (clef != null) {
          final clefName = clef.displayName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          return '${clefName}_${size}_$orient';
        }
      }
      return 'Staff_${size}_$orient';
    }

    return 'Ensemble_${count}Staff_${size}_$orient';
  }

  /// Sanitizes a file name query, stripping extensions and illegal characters.
  static String sanitizeFileName(String name, PageConfig config) {
    var trimmed = name.trim();
    if (trimmed.isEmpty) {
      trimmed = getDefaultFileName(config);
    }
    if (trimmed.endsWith('.tex') || trimmed.endsWith('.pdf') || trimmed.endsWith('.svg')) {
      final lastDot = trimmed.lastIndexOf('.');
      if (lastDot != -1) {
        trimmed = trimmed.substring(0, lastDot);
      }
    }
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  /// Compiles the score layout configuration to LaTeX source code (`.tex`).
  static String compileToTex(
    PageConfig config,
    PageLayout layout, {
    int pageCount = 1,
  }) {
    return tex_emitter.emit(config, layout, pageCount: pageCount);
  }

  /// Compiles the score layout configuration directly to vector PDF bytes (`.pdf`).
  static Future<Uint8List> compileToPdf(
    PageConfig config,
    PageLayout layout, {
    int pageCount = 1,
  }) async {
    final bytes = await pdf_emitter.emitPdf(config, layout, pageCount: pageCount);
    return Uint8List.fromList(bytes);
  }

  /// Compiles the score layout configuration to scalable vector graphics (`.svg`).
  static String compileToSvg(
    PageConfig config,
    PageLayout layout, {
    SvgLayeringMode layeringMode = SvgLayeringMode.flatByCategory,
  }) {
    return svg_emitter.emitSvg(config, layout, layeringMode: layeringMode);
  }


  /// Shells out to `pdflatex` to compile an existing `.tex` file on disk to a `.pdf` file.
  static Future<String> compileTexFileToPdf(
    String texPath, {
    String? outputDir,
  }) {
    return pdflatex.compile(texPath, outputDir: outputDir);
  }
}
