// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

abstract class AppVersion {
  static const String name = 'SarvMD';
  static const String tagline = 'Manuscript Designer';
  static const String fallbackVersion = '0.5.1';
  static const String description =
      'A zero-dependency music manuscript notebook generator powered by Gouldian spacing and high-fidelity LaTeX vector compilation.';
  static const String author = 'Pooria Askari Moqaddam';
  static const String copyright = 'Copyright © 2026 Pooria Askari Moqaddam';
  static const String license = 'Business Source License 1.1 (BUSL-1.1)';
  static const String githubUrl = 'https://github.com/pooriaaskarim/sarvmd';

  static String getFormattedBuildInfo(String version, String date) =>
      '$name v${version.isNotEmpty ? version : fallbackVersion}${date.isNotEmpty ? " ($date)" : ""}\n'
      '$copyright\n'
      'License: $license\n'
      'Repository: $githubUrl';
}
