// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../l10n/app_localizations.dart';
import '../../../logic/services/recent_documents_service.dart';
import '../../../logic/services/sarv_file_service.dart';
import '../../../logic/view/view_cubit.dart';
import '../../../logic/view/view_state.dart';
import '../../../logic/workspace/workspace_cubit.dart';
import '../common/input_mode_toggle_button.dart';
import '../common/language_switch_control.dart';
import '../common/shortcut_gateway.dart';
import '../dialogs/adaptive_dialog_helper.dart';
import '../dialogs/keyboard_shortcuts_dialog.dart';
import '../layout/sarv_brand_header.dart';
import '../staff/mini_staff_preview.dart';
import '../staff/profile_picker.dart';

/// The sleek, state-of-the-art "No Document / Welcome Hub" displayed when all editor tabs are closed.
///
/// Features the canonical brand header, quick-pick starter manuscript presets with vector
/// mini-stave previews, recent documents history, full template browser, and drag-and-drop prompt.
class EmptyWorkspaceView extends StatelessWidget {
  const EmptyWorkspaceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final workspaceCubit = context.read<WorkspaceCubit>();
    final viewCubit = context.watch<ViewCubit>();
    final isDark = theme.brightness == Brightness.dark;
    final isTouch = viewCubit.state.inputMode == InputMode.touch;

    final primaryCards = [
      _PresetStarter(
        profile: core.StaffProfiles.treble,
        title: l10n?.presetSoloTrebleTitle ?? 'Solo Treble',
        subtitle: l10n?.presetSoloTrebleSubtitle ?? 'Standard 5-line classical staff',
      ),
      _PresetStarter(
        profile: core.StaffProfiles.piano,
        title: l10n?.presetGrandStaffTitle ?? 'Grand Staff',
        subtitle: l10n?.presetGrandStaffSubtitle ?? 'Piano system with brace & treble/bass',
      ),
      _PresetStarter(
        profile: core.StaffProfiles.guitarTab,
        title: l10n?.presetGuitarTabTitle ?? 'Guitar + TAB',
        subtitle: l10n?.presetGuitarTabSubtitle ?? 'Standard notation with 6-string TAB',
      ),
      _PresetStarter(
        profile: core.StaffProfiles.chamberOrchestra,
        title: l10n?.presetChamberOrchestraTitle ?? 'Chamber Orchestra',
        subtitle: l10n?.presetChamberOrchestraSubtitle ?? 'String quartet & winds hierarchy',
      ),
    ];

    return SarvShortcutGateway(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Minimalist Top Navigation Header (Enforced LTR Layout) ──
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.75),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      const SarvBrandHeader(
                        mode: SarvBrandHeaderMode.reactive,
                        scaleFactor: 0.9,
                        enableInteractiveAbout: true,
                      ),
                      const Spacer(),
                      if (!isTouch) ...[
                        IconButton(
                          tooltip: l10n?.keyboardShortcutsTitle ?? 'Keyboard Shortcuts',
                          icon: const Icon(Icons.keyboard_outlined, size: 18),
                          onPressed: () => showKeyboardShortcutsDialog(context),
                        ),
                        const SizedBox(width: 4),
                      ],
                      const InputModeToggleButton(),
                      const SizedBox(width: 8),
                      const LanguageToggleButton(),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: isDark ? 'Light Theme' : 'Dark Theme',
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          size: 18,
                        ),
                        onPressed: () {
                          final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                          viewCubit.updateThemeMode(newMode);
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // ── Scrollable Welcome Hub ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 840;
                  final bottomInset = MediaQuery.paddingOf(context).bottom;

                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 28,
                      bottom: 40 + bottomInset,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ── Hero Branding Section ──
                            const SarvBrandHeader(
                              mode: SarvBrandHeaderMode.full,
                              scaleFactor: 1.25,
                              enableInteractiveAbout: true,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n?.welcomeSubtitle ??
                                  'Zero-compromise Gouldian music manuscript creation',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // ── Two Columns (or Stacked) ──
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildNewManuscriptCard(
                                      context,
                                      theme,
                                      l10n,
                                      workspaceCubit,
                                      primaryCards,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 5,
                                    child: _buildRecentFilesCard(
                                      context,
                                      theme,
                                      l10n,
                                      workspaceCubit,
                                      isWide: true,
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildNewManuscriptCard(
                                context,
                                theme,
                                l10n,
                                workspaceCubit,
                                primaryCards,
                              ),
                              const SizedBox(height: 24),
                              _buildRecentFilesCard(
                                context,
                                theme,
                                l10n,
                                workspaceCubit,
                                isWide: false,
                              ),
                            ],

                            const SizedBox(height: 28),

                            // ── Drop / Open Prompt & Shortcut Footers ──
                            _buildDropTargetPrompt(
                              context,
                              theme,
                              l10n,
                              workspaceCubit,
                              isTouch: isTouch,
                            ),
                            if (!isTouch) ...[
                              const SizedBox(height: 16),
                              _buildShortcutLegend(context, theme, l10n),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ── "Start New Manuscript" Card ──
  Widget _buildNewManuscriptCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    WorkspaceCubit workspaceCubit,
    List<_PresetStarter> starters,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n?.startNewManuscript ?? 'Start New Manuscript',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Presets List
          ...starters.map((starter) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StarterPresetTile(
                starter: starter,
                onTap: () {
                  workspaceCubit.openNewTab(profile: starter.profile);
                },
              ),
            );
          }),

          const SizedBox(height: 6),

          // Browse all templates button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.grid_view_rounded, size: 16),
              label: Text(l10n?.browseAllTemplates ?? 'Browse all templates…'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                _showAllTemplatesPicker(context, workspaceCubit);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── "Recent Manuscripts" Card ──
  Widget _buildRecentFilesCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    WorkspaceCubit workspaceCubit, {
    required bool isWide,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n?.recentManuscripts ?? 'Recent Manuscripts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ValueListenableBuilder<List<String>>(
                valueListenable: RecentDocumentsService.recentDocumentsNotifier,
                builder: (context, recents, _) {
                  if (recents.isEmpty) return const SizedBox.shrink();
                  return TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => RecentDocumentsService.clearRecentDocuments(),
                    child: Text(
                      l10n?.menuClearRecent ?? 'Clear',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Recents list or empty placeholder
          ValueListenableBuilder<List<String>>(
            valueListenable: RecentDocumentsService.recentDocumentsNotifier,
            builder: (context, recents, _) {
              if (recents.isEmpty) {
                return Container(
                  height: isWide ? 200 : 120,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_toggle_off_outlined,
                        size: 36,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n?.noRecentManuscripts ?? 'No recent manuscripts yet',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final displayRecents = recents.take(4).toList();

              return Column(
                children: displayRecents.map((filePath) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RecentDocumentTile(
                      filePath: filePath,
                      onTap: () async {
                        await workspaceCubit.openFileTab(filePath);
                        await RecentDocumentsService.addRecentDocument(filePath);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 8),

          // Open other file button
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.file_open_outlined, size: 16),
              label: Text(l10n?.openOtherFile ?? 'Open other file…'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final result = await SarvFileService().openSarvFile();
                if (result != null) {
                  await workspaceCubit.openDocumentTab(
                    result.document,
                    filePath: result.filePath,
                    title: result.fileName,
                  );
                  if (result.filePath != null) {
                    await RecentDocumentsService.addRecentDocument(result.filePath!);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Drag & Drop / Tap Landing Target ──
  Widget _buildDropTargetPrompt(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
    WorkspaceCubit workspaceCubit, {
    required bool isTouch,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final result = await SarvFileService().openSarvFile();
        if (result != null) {
          await workspaceCubit.openDocumentTab(
            result.document,
            filePath: result.filePath,
            title: result.fileName,
          );
          if (result.filePath != null) {
            await RecentDocumentsService.addRecentDocument(result.filePath!);
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTouch ? Icons.folder_open_outlined : Icons.file_download_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isTouch
                    ? (l10n?.touchOpenExistingPrompt ?? 'Tap to open an existing .sarv manuscript')
                    : (l10n?.dropToOpenHint ?? 'Drag and drop a .sarv manuscript anywhere to start editing'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shortcut Legend Footer ──
  Widget _buildShortcutLegend(
    BuildContext context,
    ThemeData theme,
    AppLocalizations? l10n,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ShortcutChip(
          keyLabel: 'Ctrl+N',
          desc: l10n?.newScore ?? 'New',
        ),
        const SizedBox(width: 12),
        _ShortcutChip(
          keyLabel: 'Ctrl+O',
          desc: l10n?.menuOpen ?? 'Open…',
        ),
      ],
    );
  }

  void _showAllTemplatesPicker(BuildContext context, WorkspaceCubit workspaceCubit) {
    showSarvAdaptiveModal<void>(
      context: context,
      maxWidth: 720,
      builder: (modalContext, isMobile) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(modalContext).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    color: Theme.of(modalContext).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(modalContext)?.browseAllTemplates ?? 'All Manuscript Templates',
                    style: Theme.of(modalContext).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: ProfilePicker(
                    currentConfig: const core.PageConfig(),
                    onProfileSelected: (profile) {
                      Navigator.of(modalContext).pop();
                      workspaceCubit.openNewTab(profile: profile);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresetStarter {
  final core.StaffProfile profile;
  final String title;
  final String subtitle;

  const _PresetStarter({
    required this.profile,
    required this.title,
    required this.subtitle,
  });
}

class _StarterPresetTile extends StatefulWidget {
  final _PresetStarter starter;
  final VoidCallback onTap;

  const _StarterPresetTile({
    required this.starter,
    required this.onTap,
  });

  @override
  State<_StarterPresetTile> createState() => _StarterPresetTileState();
}

class _StarterPresetTileState extends State<_StarterPresetTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.06)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.6)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: _isHovered ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Vector Mini Preview
                Container(
                  width: 64,
                  height: 44,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: MiniStaffPreview(
                    systemLayout: widget.starter.profile.systemLayout,
                    active: _isHovered,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.starter.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isHovered
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.starter.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scaleX: isRtl ? -1.0 : 1.0,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _isHovered
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentDocumentTile extends StatefulWidget {
  final String filePath;
  final VoidCallback onTap;

  const _RecentDocumentTile({
    required this.filePath,
    required this.onTap,
  });

  @override
  State<_RecentDocumentTile> createState() => _RecentDocumentTileState();
}

class _RecentDocumentTileState extends State<_RecentDocumentTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = p.basename(widget.filePath);
    final dirName = p.dirname(widget.filePath);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.filePath,
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isHovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.05)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isHovered
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: _isHovered ? theme.colorScheme.primary : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isHovered ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dirName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                            fontSize: 10.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: _isHovered ? theme.colorScheme.primary : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final String keyLabel;
  final String desc;

  const _ShortcutChip({
    required this.keyLabel,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              keyLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            desc,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
