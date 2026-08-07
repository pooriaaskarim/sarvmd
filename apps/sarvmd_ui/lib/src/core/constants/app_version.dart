// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

abstract class AppVersion {
  static const String name = 'SarvMD';
  static const String tagline = 'Manuscript Designer';
  static const String fallbackVersion = '0.5.1';
  static const String author = 'Pooria Askari Moqaddam';
  static const String license = 'Business Source License 1.1 (BUSL-1.1)';
  static const String smuflSpec = 'SMuFL 1.4 / Bravura 1.39';
  static const String engravingRules = 'Gouldian Logarithmic Spacing & MOLA';
  static const String latexBackend = 'pdflatex Direct Operator Stream';
  static const String githubUrl = 'https://github.com/pooriaaskarim/sarvmd';

  static String getFormattedBuildInfo(String version, String date) =>
      '$name v${version.isNotEmpty ? version : fallbackVersion} ${date.isNotEmpty ? "($date)" : ""}\n'
      'Author: $author\n'
      'License: $license\n'
      'Notation: $smuflSpec\n'
      'Engraving: $engravingRules\n'
      'LaTeX Backend: $latexBackend';
}
