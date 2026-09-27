// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

/// Represents descriptive score metadata for a SarvMD manuscript document.
class DocumentMetadata {
  /// The main title of the musical work.
  final String title;

  /// Subtitle or movement title (e.g., 'Op. 14', 'I. Allegro').
  final String subtitle;

  /// The composer of the piece.
  final String composer;

  /// The arranger or orchestrator of the piece.
  final String arranger;

  /// The lyricist or librettist.
  final String lyricist;

  /// Copyright notice or license terms printed on the score.
  final String copyright;

  /// The ID of the built-in staff profile from which this document originated (if any).
  final String? profileId;

  /// When this document was first created.
  final DateTime? createdAt;

  /// When this document was last modified.
  final DateTime? modifiedAt;

  /// Arbitrary forward-compatible key-value pairs for future plugins or user properties.
  final Map<String, dynamic> customProperties;

  const DocumentMetadata({
    this.title = '',
    this.subtitle = '',
    this.composer = '',
    this.arranger = '',
    this.lyricist = '',
    this.copyright = '',
    this.profileId,
    this.createdAt,
    this.modifiedAt,
    this.customProperties = const {},
  });

  /// The effective creation timestamp, defaulting to unix epoch if not set.
  DateTime get effectiveCreatedAt =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// The effective modification timestamp, defaulting to [effectiveCreatedAt] if not set.
  DateTime get effectiveModifiedAt => modifiedAt ?? effectiveCreatedAt;

  /// Creates a copy of this metadata with optional field overrides.
  DocumentMetadata copyWith({
    String? title,
    String? subtitle,
    String? composer,
    String? arranger,
    String? lyricist,
    String? copyright,
    String? Function()? profileId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Map<String, dynamic>? customProperties,
  }) {
    return DocumentMetadata(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      composer: composer ?? this.composer,
      arranger: arranger ?? this.arranger,
      lyricist: lyricist ?? this.lyricist,
      copyright: copyright ?? this.copyright,
      profileId: profileId != null ? profileId() : this.profileId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      customProperties: customProperties ?? this.customProperties,
    );
  }

  /// Serializes this metadata instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'composer': composer,
        'arranger': arranger,
        'lyricist': lyricist,
        'copyright': copyright,
        if (profileId != null) 'profileId': profileId,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (modifiedAt != null) 'modifiedAt': modifiedAt!.toIso8601String(),
        if (customProperties.isNotEmpty) 'customProperties': customProperties,
      };

  /// Deserializes a [DocumentMetadata] from a JSON map.
  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return DocumentMetadata(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      composer: json['composer'] as String? ?? '',
      arranger: json['arranger'] as String? ?? '',
      lyricist: json['lyricist'] as String? ?? '',
      copyright: json['copyright'] as String? ?? '',
      profileId: json['profileId'] as String?,
      createdAt: parseDate(json['createdAt']),
      modifiedAt: parseDate(json['modifiedAt']),
      customProperties: json['customProperties'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['customProperties'] as Map)
          : const {},
    );
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final valA = a[key];
      final valB = b[key];
      if (valA is List && valB is List) {
        if (valA.length != valB.length) return false;
        for (int i = 0; i < valA.length; i++) {
          if (valA[i] != valB[i]) return false;
        }
      } else if (valA != valB) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          subtitle == other.subtitle &&
          composer == other.composer &&
          arranger == other.arranger &&
          lyricist == other.lyricist &&
          copyright == other.copyright &&
          profileId == other.profileId &&
          createdAt == other.createdAt &&
          modifiedAt == other.modifiedAt &&
          _mapEquals(customProperties, other.customProperties);

  @override
  int get hashCode => Object.hash(
        title,
        subtitle,
        composer,
        arranger,
        lyricist,
        copyright,
        profileId,
        createdAt,
        modifiedAt,
      );
}
