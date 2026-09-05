// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/config/config_cubit.dart';
import '../../../logic/locale/locale_cubit.dart';
import '../../../logic/score/score_cubit.dart';
import '../dialogs/about_dialog.dart';
import '../dialogs/export_dialog.dart';

import 'sarv_reactive_brand_logo.dart';

/// Photoshop / Figma-style top control header bar for SarvMD.
///
/// Responsive: In wide screens, renders full horizontal control bar with hover-expanding logo.
/// In narrow screens (<720px), secondary tools collapse into a smart logo dropdown menu,
/// while keeping Undo/Redo instant accessible at the top beside the logo.
class SarvTopBar extends StatelessWidget implements PreferredSizeWidget {
  const SarvTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final themeExt = Theme.of(context).extension<SarvThemeExtension>();

    return BlocBuilder<ScoreCubit, ScoreState>(
      builder: (context, scoreState) {
        return BlocBuilder<ConfigCubit, core.PageConfig>(
          builder: (context, configState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                height: 52.0,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 720;

                    // Common Undo / Redo Cluster (always beside the logo)
                    final undoRedoCluster = [
                      Tooltip(
                        message: scoreState.canUndo
                            ? 'Undo (Ctrl+Z)'
                            : 'Undo (${l10n.hidden})',
                        child: IconButton(
                          icon: const Icon(
                            Icons.undo_rounded,
                            size: 20.0,
                          ),
                          color: cs.onSurface,
                          disabledColor: cs.onSurface.withValues(alpha: 0.38),
                          onPressed: scoreState.canUndo
                              ? () => context.read<ScoreCubit>().undo()
                              : null,
                        ),
                      ),
                      Tooltip(
                        message: scoreState.canRedo
                            ? 'Redo (Ctrl+Y)'
                            : 'Redo (${l10n.hidden})',
                        child: IconButton(
                          icon: const Icon(
                            Icons.redo_rounded,
                            size: 20.0,
                          ),
                          color: cs.onSurface,
                          disabledColor: cs.onSurface.withValues(alpha: 0.38),
                          onPressed: scoreState.canRedo
                              ? () => context.read<ScoreCubit>().redo()
                              : null,
                        ),
                      ),
                    ];

                    if (isCompact) {
                      // Narrow mode: Logo opens smart app menu dropdown; Undo/Redo beside logo
                      return SizedBox(
                        height: 51.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'App Menu',
                              offset: const Offset(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              color: cs.surfaceContainerHigh,
                              onSelected: (value) {
                                switch (value) {
                                  case 'export':
                                    showExportDialog(context);
                                    break;
                                  case 'language':
                                    context.read<LocaleCubit>().toggleLocale();
                                    break;
                                  case 'about':
                                    showSarvAboutDialog(context);
                                    break;
                                }
                              },
                              itemBuilder: (context) {
                                return [
                                  // Header: Full Sarv logo (top) + Manuscript Designer (underneath)
                                  PopupMenuItem<String>(
                                    enabled: false,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 8.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SvgPicture.asset(
                                            'assets/handwriting/Sarv Handwriting.svg',
                                            height: 28.0,
                                            colorFilter: ColorFilter.mode(
                                              cs.onSurface,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Text(
                                            l10n.appSubtitle,
                                            style: themeExt?.brandSubtitleStyle ??
                                                TextStyle(
                                                  fontSize: 13.5,
                                                  fontFamily: 'IranNastaliq',
                                                  fontWeight: FontWeight.bold,
                                                  color: cs.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  // History info item
                                  PopupMenuItem<String>(
                                    value: 'history',
                                    enabled: false,
                                    child: Row(
                                      children: [
                                        Icon(Icons.history, size: 18, color: cs.onSurfaceVariant),
                                        const SizedBox(width: 12),
                                        Text(
                                          'History (${scoreState.undoStack.length})',
                                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Document status item
                                  PopupMenuItem<String>(
                                    enabled: false,
                                    child: Row(
                                      children: [
                                        Icon(Icons.description_outlined, size: 18, color: cs.primary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${scoreState.score.title} • ${configState.pageSize.name.toUpperCase()} ${configState.orientation.name}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  // Export item
                                  PopupMenuItem<String>(
                                    value: 'export',
                                    child: Row(
                                      children: [
                                        Icon(Icons.file_upload_outlined, size: 18, color: cs.onSurface),
                                        const SizedBox(width: 12),
                                        Text(l10n.export),
                                      ],
                                    ),
                                  ),
                                  // Language switcher item
                                  PopupMenuItem<String>(
                                    value: 'language',
                                    child: Row(
                                      children: [
                                        Icon(Icons.language, size: 18, color: cs.onSurface),
                                        const SizedBox(width: 12),
                                        Text(l10n.toggleLanguage),
                                      ],
                                    ),
                                  ),
                                  // About item
                                  PopupMenuItem<String>(
                                    value: 'about',
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 18, color: cs.onSurface),
                                        const SizedBox(width: 12),
                                        Text(l10n.aboutSarvMD),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                              child: const SarvReactiveBrandLogo(isMenuMode: true),
                            ),

                            const SizedBox(width: 8.0),
                            const VerticalDivider(indent: 12, endIndent: 12, width: 16),

                            ...undoRedoCluster,
                          ],
                        ),
                      );
                    }

                    // Wide mode: Full toolbar with horizontal scroll fallback
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          height: 51.0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SarvReactiveBrandLogo(isMenuMode: false),

                              const SizedBox(width: 12.0),
                              const VerticalDivider(indent: 12, endIndent: 12, width: 16),

                              ...undoRedoCluster,
                              const SizedBox(width: 4.0),

                              // History Popover / Badge
                              PopupMenuButton<int>(
                                enabled: scoreState.undoStack.isNotEmpty || scoreState.redoStack.isNotEmpty,
                                tooltip: 'Action History Stack',
                                offset: const Offset(0, 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                itemBuilder: (context) {
                                  final items = <PopupMenuEntry<int>>[];

                                  items.add(const PopupMenuItem<int>(
                                    enabled: false,
                                    child: Text(
                                      'Transaction History',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ));
                                  items.add(const PopupMenuDivider());

                                  if (scoreState.undoStack.isEmpty && scoreState.redoStack.isEmpty) {
                                    items.add(const PopupMenuItem<int>(
                                      enabled: false,
                                      child: Text('No actions performed yet', style: TextStyle(fontSize: 12)),
                                    ));
                                  } else {
                                    for (int i = scoreState.undoStack.length - 1; i >= 0; i--) {
                                      final cmd = scoreState.undoStack[i];
                                      items.add(PopupMenuItem<int>(
                                        value: i,
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle_outline, size: 14, color: cs.primary),
                                            const SizedBox(width: 8),
                                            Text(
                                              cmd.runtimeType.toString(),
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ));
                                    }
                                  }
                                  return items;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6.0),
                                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.history, size: 14.0, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        'History (${scoreState.undoStack.length})',
                                        style: TextStyle(fontSize: 11.0, color: cs.onSurfaceVariant),
                                      ),
                                      const SizedBox(width: 2.0),
                                      Icon(Icons.arrow_drop_down, size: 14.0, color: cs.onSurfaceVariant),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 24.0),

                              // Document Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.description_outlined, size: 14.0, color: cs.onPrimaryContainer),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      '${scoreState.score.title} • ${configState.pageSize.name.toUpperCase()} ${configState.orientation.name}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 24.0),

                              // Master Export Trigger Button
                              OutlinedButton.icon(
                                onPressed: () => showExportDialog(context),
                                icon: const Icon(Icons.file_upload_outlined, size: 16.0),
                                label: Text(l10n.export),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                ),
                              ),

                              const SizedBox(width: 8.0),

                              // Language Switcher
                              IconButton(
                                icon: const Icon(Icons.language, size: 20.0),
                                tooltip: l10n.toggleLanguage,
                                onPressed: () => context.read<LocaleCubit>().toggleLocale(),
                              ),

                              const SizedBox(width: 4.0),

                              // About Dialog Info Trigger
                              IconButton(
                                icon: const Icon(Icons.info_outline, size: 20.0),
                                tooltip: l10n.aboutSarvMD,
                                onPressed: () => showSarvAboutDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
