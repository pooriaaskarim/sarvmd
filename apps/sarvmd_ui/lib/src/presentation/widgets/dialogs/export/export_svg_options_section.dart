// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../../l10n/app_localizations.dart';

/// SVG Layering Mode configuration options section.
class ExportSvgOptionsSection extends StatelessWidget {
  final core.SvgLayeringMode svgMode;
  final ValueChanged<core.SvgLayeringMode> onModeChanged;

  const ExportSvgOptionsSection({
    super.key,
    required this.svgMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                l10n.svgLayerOrganizationLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SvgLayerCard(
            title: l10n.svgCategoryTitle,
            subtitle: l10n.svgCategoryDesc,
            icon: Icons.category_outlined,
            isSelected: svgMode == core.SvgLayeringMode.flatByCategory,
            onTap: () => onModeChanged(core.SvgLayeringMode.flatByCategory),
          ),
          const SizedBox(height: 8),
          _SvgLayerCard(
            title: l10n.svgSystemTitle,
            subtitle: l10n.svgSystemDesc,
            icon: Icons.account_tree_outlined,
            isSelected: svgMode == core.SvgLayeringMode.hierarchicalBySystem,
            onTap: () => onModeChanged(core.SvgLayeringMode.hierarchicalBySystem),
          ),
          const SizedBox(height: 8),
          _SvgLayerCard(
            title: l10n.svgMinimalTitle,
            subtitle: l10n.svgMinimalDesc,
            icon: Icons.layers_clear_outlined,
            isSelected: svgMode == core.SvgLayeringMode.none,
            onTap: () => onModeChanged(core.SvgLayeringMode.none),
          ),
        ],
      ),
    );
  }
}

class _SvgLayerCard extends StatelessWidget {
  const _SvgLayerCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.1)
              : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon,
                          size: 13,
                          color: isSelected ? cs.primary : cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.3,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
