// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Supported export formats in SarvMD export studio.
enum ExportFormat {
  pdf(
    label: 'PDF Document',
    shortLabel: 'PDF',
    icon: Icons.picture_as_pdf,
    ext: '.pdf',
    description: 'Printable sheet music PDF.',
  ),
  svg(
    label: 'Vector Graphic (SVG)',
    shortLabel: 'SVG',
    icon: Icons.image_outlined,
    ext: '.svg',
    description: 'Editable vector paths.',
  ),
  tex(
    label: 'LaTeX Source (.tex)',
    shortLabel: 'TeX',
    icon: Icons.code,
    ext: '.tex',
    description: 'Raw LaTeX manuscript code.',
  );

  final String label;
  final String shortLabel;
  final IconData icon;
  final String ext;
  final String description;

  const ExportFormat({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.ext,
    required this.description,
  });

  String getLocalizedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      ExportFormat.pdf => l10n.formatPdfDesc,
      ExportFormat.svg => l10n.formatSvgDesc,
      ExportFormat.tex => l10n.formatTexDesc,
    };
  }
}
