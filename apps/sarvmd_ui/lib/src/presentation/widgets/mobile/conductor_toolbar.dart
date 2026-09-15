// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../common/section_header.dart';
import '../staff/profile_picker.dart';

/// Floating frosted-glass baton toolbar for SarvMD Mobile Proposal B.
class ConductorToolbar extends StatelessWidget {
  const ConductorToolbar({
    super.key,
    required this.onFitZoom,
  });

  final VoidCallback onFitZoom;

  void _showQuickProfilesSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isFa = Localizations.localeOf(context).languageCode == 'fa';

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: isFa ? TextDirection.rtl : TextDirection.ltr,
                  child: Row(
                    children: [
                      Icon(Icons.layers_outlined, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SectionHeader(
                          title: l10n.headerEnsembleProfiles,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<DocumentCubit, DocumentState>(
                  builder: (context, docState) {
                    final cubit = context.read<DocumentCubit>();
                    return ProfilePicker(
                      currentConfig: docState.config,
                      onProfileSelected: (p) {
                        cubit.applyProfile(p);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, docState) {
        final cubit = context.read<DocumentCubit>();
        final canUndo = docState.canUndo;
        final canRedo = docState.canRedo;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Drawer Trigger
                  IconButton(
                    icon: const Icon(Icons.tune, size: 20),
                    tooltip: l10n.appMenuTooltip,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    color: cs.primary,
                  ),
                  const SizedBox(width: 4),

                  // 2. Preset Selector Quick Action
                  IconButton(
                    icon: const Icon(Icons.layers_outlined, size: 20),
                    tooltip: l10n.tooltipEnsemblePicker,
                    onPressed: () => _showQuickProfilesSheet(context),
                    color: cs.onSurface,
                  ),
                  const SizedBox(width: 4),

                  // 3. Fit Screen Zoom Action
                  IconButton(
                    icon: const Icon(Icons.aspect_ratio, size: 20),
                    tooltip: l10n.resetZoom,
                    onPressed: onFitZoom,
                    color: cs.onSurface,
                  ),
                  const SizedBox(width: 4),

                  // 4. Undo Quick Action
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: l10n.undo,
                    onPressed: canUndo ? () => cubit.undo() : null,
                    color: canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35),
                  ),

                  // 5. Redo Quick Action
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    tooltip: l10n.redo,
                    onPressed: canRedo ? () => cubit.redo() : null,
                    color: canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
