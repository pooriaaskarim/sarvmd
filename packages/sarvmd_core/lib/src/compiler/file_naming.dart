// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

/// Cross-platform file naming and extension management utilities for SarvMD.
class FileNaming {
  /// Known file extensions handled by SarvMD.
  static const List<String> knownExtensions = [
    '.sarv',
    '.pdf',
    '.svg',
    '.tex',
    '.png',
    '.mid',
    '.midi',
  ];

  /// Appends [suffix] immediately before the file extension.
  ///
  /// Examples:
  /// - `appendSuffix('Piano_A4_Portrait.pdf', '_1')` -> `'Piano_A4_Portrait_1.pdf'`
  /// - `appendSuffix('score.sarv', '_2')` -> `'score_2.sarv'`
  /// - `appendSuffix('score', '_1')` -> `'score_1'`
  /// - `appendSuffix('my.score.v1.svg', '_1')` -> `'my.score.v1_1.svg'`
  static int _findExtensionDot(String path) {
    if (path.isEmpty) return -1;
    final lastSlash = path.lastIndexOf('/');
    final lastBackslash = path.lastIndexOf('\\');
    final lastSeparator = lastSlash > lastBackslash ? lastSlash : lastBackslash;
    final lastDot = path.lastIndexOf('.');

    // Ensure the dot occurs after the last directory separator (not inside directory names),
    // is not a leading dot of the file name (hidden files like .gitignore),
    // and is not trailing.
    if (lastDot > lastSeparator + 1 && lastDot < path.length - 1) {
      return lastDot;
    }
    return -1;
  }

  /// Appends [suffix] immediately before the file extension.
  ///
  /// Examples:
  /// - `appendSuffix('Piano_A4_Portrait.pdf', '_1')` -> `'Piano_A4_Portrait_1.pdf'`
  /// - `appendSuffix('score.sarv', '_2')` -> `'score_2.sarv'`
  /// - `appendSuffix('score', '_1')` -> `'score_1'`
  /// - `appendSuffix('/dir/my.score.v1.svg', '_1')` -> `'/dir/my.score.v1_1.svg'`
  /// - `appendSuffix('C:\\dir.with.dot\\score.pdf', '_1')` -> `'C:\\dir.with.dot\\score_1.pdf'`
  static String appendSuffix(String fileName, String suffix) {
    if (fileName.isEmpty) return suffix;
    final dot = _findExtensionDot(fileName);
    if (dot != -1) {
      final base = fileName.substring(0, dot);
      final ext = fileName.substring(dot);
      return '$base$suffix$ext';
    }
    return '$fileName$suffix';
  }

  /// Appends an integer numeric [index] immediately before the file extension.
  ///
  /// Examples:
  /// - `appendIndex('Piano_A4_Portrait.pdf', 1)` -> `'Piano_A4_Portrait_1.pdf'`
  /// - `appendIndex('Score.sarv', 2)` -> `'Score_2.sarv'`
  /// - `appendIndex('Score', 1)` -> `'Score_1'`
  static String appendIndex(String fileName, int index, {String separator = '_'}) {
    return appendSuffix(fileName, '$separator$index');
  }

  /// Extracts the base file name or path without its extension.
  ///
  /// Examples:
  /// - `stripExtension('Piano_A4_Portrait.pdf')` -> `'Piano_A4_Portrait'`
  /// - `stripExtension('score.sarv')` -> `'score'`
  /// - `stripExtension('/home/user/score.pdf')` -> `'/home/user/score'`
  /// - `stripExtension('/home/user.dir/score')` -> `'/home/user.dir/score'`
  static String stripExtension(String fileName) {
    final dot = _findExtensionDot(fileName);
    if (dot != -1) {
      return fileName.substring(0, dot);
    }
    return fileName;
  }

  /// Returns the file extension including the leading dot, or empty string if none.
  ///
  /// Examples:
  /// - `getExtension('Piano_A4_Portrait.pdf')` -> `'.pdf'`
  /// - `getExtension('score.sarv')` -> `'.sarv'`
  /// - `getExtension('/home/user.name/score')` -> `''`
  static String getExtension(String fileName) {
    final dot = _findExtensionDot(fileName);
    if (dot != -1) {
      return fileName.substring(dot);
    }
    return '';
  }

  /// Generates a unique file name given a base [candidate] and a collection of [existingNames].
  ///
  /// If [candidate] is already in [existingNames], increments an integer suffix placed
  /// **immediately before the file extension**:
  /// - candidate: `Piano_A4_Portrait.pdf`, existing: `['Piano_A4_Portrait.pdf']` -> `Piano_A4_Portrait_1.pdf`
  /// - candidate: `score.sarv`, existing: `['score.sarv', 'score_1.sarv']` -> `score_2.sarv`
  static String disambiguateFileName(
    String candidate,
    Iterable<String> existingNames, {
    String separator = '_',
  }) {
    final existingSet = existingNames.toSet();
    if (!existingSet.contains(candidate)) return candidate;

    var counter = 1;
    while (true) {
      final newCandidate = appendIndex(candidate, counter, separator: separator);
      if (!existingSet.contains(newCandidate)) {
        return newCandidate;
      }
      counter++;
    }
  }

  /// Generates a unique file path or name using a presence tester [exists].
  ///
  /// Places the auto-incremented index **immediately before the file extension**:
  /// ```dart
  /// final unique = FileNaming.ensureUniquePath(
  ///   '/path/to/Piano_A4_Portrait.pdf',
  ///   exists: (p) => File(p).existsSync(),
  /// );
  /// ```
  static String ensureUniquePath(
    String path, {
    required bool Function(String path) exists,
    String separator = '_',
  }) {
    if (!exists(path)) return path;

    var counter = 1;
    while (true) {
      final candidate = appendIndex(path, counter, separator: separator);
      if (!exists(candidate)) {
        return candidate;
      }
      counter++;
    }
  }
}
