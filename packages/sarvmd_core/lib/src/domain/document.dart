// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'dart:convert';
import '../config.dart';
import 'metadata.dart';
import 'score.dart';

/// Represents the complete, versionable state of a SarvMD manuscript document,
/// combining musical score content ([Score]), physical layout configuration ([PageConfig]),
/// metadata ([DocumentMetadata]), and target page count.
class SarvDocument {
  /// Canonical format identifier for .sarv files.
  static const String formatIdentifier = 'sarv';

  /// Current schema specification version.
  static const int currentVersion = 1;

  /// Official JSON schema URL for schema validation and editor hints.
  static const String schemaUrl = 'https://sarvmd.org/schemas/v1/sarv.json';

  /// Default generator stamp.
  static const String defaultGenerator = 'SarvMD';

  /// Musical content AST and part specifications.
  final Score score;

  /// Physical page geometry, staff metrics, margins, and hierarchical system layout.
  final PageConfig config;

  /// Descriptive score metadata (composer, title, subtitle, copyright, profileId).
  final DocumentMetadata metadata;

  /// Number of intended pages for notebook/manuscript pagination.
  final int pageCount;

  const SarvDocument({
    this.score = const Score(title: ''),
    this.config = const PageConfig(),
    this.metadata = const DocumentMetadata(),
    this.pageCount = 1,
  });

  /// Creates a copy of this document with optional field overrides.
  SarvDocument copyWith({
    Score? score,
    PageConfig? config,
    DocumentMetadata? metadata,
    int? pageCount,
  }) {
    return SarvDocument(
      score: score ?? this.score,
      config: config ?? this.config,
      metadata: metadata ?? this.metadata,
      pageCount: pageCount ?? this.pageCount,
    );
  }

  /// Serializes this document into the standard .sarv schema envelope JSON map.
  Map<String, dynamic> toJson() => {
        r'$schema': schemaUrl,
        'format': formatIdentifier,
        'version': currentVersion,
        'generator': defaultGenerator,
        'metadata': metadata.toJson(),
        'pageCount': pageCount,
        'config': config.toJson(),
      };

  /// Serializes the document to a UTF-8 JSON string.
  ///
  /// If [pretty] is true, outputs indented, human-readable JSON.
  String toSarvJson({bool pretty = true}) {
    final map = toJson();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }

  /// Deserializes a [SarvDocument] from a JSON map with schema validation.
  factory SarvDocument.fromJson(Map<String, dynamic> json) {
    final format = json['format'] as String?;
    if (format != null && format != formatIdentifier) {
      throw FormatException(
        'Unsupported document format: Expected "$formatIdentifier", got "$format".',
      );
    }

    final version = (json['version'] as num?)?.toInt() ?? currentVersion;
    if (version > currentVersion) {
      throw FormatException(
        'Unsupported .sarv version $version. Maximum supported version is $currentVersion. '
        'Please upgrade SarvMD to open this document.',
      );
    }

    // Support nested document structure if present
    final docMap = json['document'] is Map
        ? (json['document'] as Map).cast<String, dynamic>()
        : json;

    final metadataMap = json['metadata'] is Map
        ? (json['metadata'] as Map).cast<String, dynamic>()
        : (docMap['metadata'] is Map ? (docMap['metadata'] as Map).cast<String, dynamic>() : null);

    final configMap = docMap['config'] is Map
        ? (docMap['config'] as Map).cast<String, dynamic>()
        : (json['config'] is Map ? (json['config'] as Map).cast<String, dynamic>() : const <String, dynamic>{});

    final scoreMap = docMap['score'] is Map
        ? (docMap['score'] as Map).cast<String, dynamic>()
        : (json['score'] is Map ? (json['score'] as Map).cast<String, dynamic>() : const <String, dynamic>{});

    final pageCount = (json['pageCount'] as num?)?.toInt() ??
        (docMap['pageCount'] as num?)?.toInt() ??
        1;

    final config = PageConfig.fromJson(configMap);
    final rawMetadata = metadataMap != null
        ? DocumentMetadata.fromJson(metadataMap)
        : null;

    final title = (rawMetadata?.title.isNotEmpty ?? false)
        ? rawMetadata!.title
        : (scoreMap['title'] as String? ?? '');

    final metadata = rawMetadata != null
        ? (rawMetadata.title.isNotEmpty ? rawMetadata : rawMetadata.copyWith(title: title))
        : DocumentMetadata(title: title);
    final score = Score(title: title);

    return SarvDocument(
      score: score,
      config: config,
      metadata: metadata,
      pageCount: pageCount,
    );
  }

  /// Parses a UTF-8 JSON string into a [SarvDocument].
  static SarvDocument parseSarvJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid .sarv document: Root element must be a valid JSON object.',
      );
    }
    return SarvDocument.fromJson(decoded);
  }

  /// Checks whether two documents have identical musical and layout content,
  /// ignoring volatile operational timestamps.
  bool hasSameContent(SarvDocument other) =>
      identical(this, other) ||
      (score == other.score &&
          config == other.config &&
          pageCount == other.pageCount &&
          metadata.hasSameContent(other.metadata));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SarvDocument &&
          runtimeType == other.runtimeType &&
          score == other.score &&
          config == other.config &&
          metadata == other.metadata &&
          pageCount == other.pageCount;

  @override
  int get hashCode =>
      score.hashCode ^
      config.hashCode ^
      metadata.hashCode ^
      pageCount.hashCode;
}
