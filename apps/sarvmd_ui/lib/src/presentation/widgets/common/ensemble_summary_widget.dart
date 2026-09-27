// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../core/utils/unit_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';

/// Reusable Document & Ensemble Summary component for SarvMD.
/// Displays total staves, system height, systems count (density), and page info.
class EnsembleSummaryWidget extends StatelessWidget {
  const EnsembleSummaryWidget({
    super.key,
    this.padding = const EdgeInsets.all(12.0),
    this.showPageBadge = false,
  });

  final EdgeInsetsGeometry padding;
  final bool showPageBadge;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, docState) {
        final cs = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;
        final isFa = Localizations.localeOf(context).languageCode == 'fa';
        final textDir = isFa ? TextDirection.rtl : TextDirection.ltr;
        final cubit = context.read<DocumentCubit>();
        final config = docState.config;
        final staffCount = config.staffCount;
        final totalHeight = config.systemHeight;
        final systemCount = cubit.layout.systemCount;

        final orientationLabel = config.orientation == core.PageOrientation.portrait
            ? l10n.portrait
            : l10n.landscape;

        return Directionality(
          textDirection: textDir,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.ensembleSummary,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          letterSpacing: 0.5,
                        ),
                        textAlign: isFa ? TextAlign.right : TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showPageBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          '${config.pageSize.name.toUpperCase()} $orientationLabel',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: l10n.totalStaves,
                  value: '$staffCount',
                ),
                _SummaryRow(
                  label: l10n.systemHeight,
                  value: UnitFormatter.formatMm(totalHeight),
                ),
                _SummaryRow(
                  label: l10n.density,
                  value: l10n.systemsCount(systemCount),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
