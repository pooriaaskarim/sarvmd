// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_version.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/view/view_cubit.dart';
import '../common/ensemble_summary_widget.dart';
import '../common/integrated_scale_control.dart';
import '../common/section_header.dart';
import '../dialogs/about_dialog.dart';
import '../layout/sarv_reactive_brand_logo.dart';
import '../panels/advanced_builder_panel.dart';
import '../panels/export_panel.dart';
import '../staff/document_settings_group.dart';
import '../staff/margins_settings_group.dart';
import '../staff/profile_picker.dart';
import '../staff/staff_spacing_group.dart';
import 'mobile_language_button.dart';
import 'mobile_theme_button.dart';

enum DrawerSection {
  mainMenu,
  profiles,
  pageSetup,
  staffSpacing,
  systemHierarchy,
  export,
}

/// Full-height side drawer for Proposal B ("Conductor's Baton").
/// Implements Progressive Disclosure category navigation with sticky primary actions.
class ConductorDrawer extends StatefulWidget {
  const ConductorDrawer({
    super.key,
    required this.transformationController,
    required this.onZoomPreset,
    this.isSideSheet = false,
    this.onClose,
  });

  final TransformationController transformationController;
  final void Function(ZoomPreset preset) onZoomPreset;
  final bool isSideSheet;
  final VoidCallback? onClose;

  @override
  State<ConductorDrawer> createState() => _ConductorDrawerState();
}

class _ConductorDrawerState extends State<ConductorDrawer> {
  DrawerSection _currentSection = DrawerSection.mainMenu;

  void _navigateTo(DrawerSection section) {
    setState(() {
      _currentSection = section;
    });
  }

  void _goBack() {
    setState(() {
      _currentSection = DrawerSection.mainMenu;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    final sectionTextDir = isFa ? TextDirection.rtl : TextDirection.ltr;
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.85;

    final content = SafeArea(
      top: !widget.isSideSheet,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: widget.isSideSheet ? 8.0 : 12.0,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand Logo + Version
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SarvReactiveBrandLogo(
                      logoHeight: 20.0,
                      enableExpandAnimation: false,
                    ),
                    const SizedBox(height: 2.0),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'v${AppVersion.version}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // Controls (Language & Theme)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MobileLanguageButton(),
                    SizedBox(width: 4.0),
                    MobileThemeButton(),
                  ],
                ),
              ],
            ),
          ),

          // Drawer Body Content (AnimatedSwitcher for smooth navigation)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _currentSection == DrawerSection.mainMenu
                  ? _buildMainMenu(context, cs, l10n)
                  : _buildSectionContent(context, cs, l10n, sectionTextDir),
            ),
          ),
        ],
      ),
    );

    if (widget.isSideSheet) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: cs.surfaceContainerLow,
          elevation: 6.0,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16.0),
              bottomRight: Radius.circular(16.0),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: drawerWidth.clamp(280.0, 420.0),
        child: Drawer(
          backgroundColor: cs.surfaceContainerLow,
          child: content,
        ),
      ),
    );
  }

  Widget _buildFooterContent(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EnsembleSummaryWidget(showPageBadge: true),
        const SizedBox(height: 6.0),
        TextButton.icon(
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else {
              Navigator.of(context).maybePop();
            }
            showSarvAboutDialog(context);
          },
          icon: const Icon(Icons.info_outline, size: 16),
          label: Text(l10n.aboutSarvMD),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenu(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final isDense = widget.isSideSheet;

    return Column(
      key: const ValueKey('main_menu'),
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDense ? 12.0 : 14.0,
              vertical: isDense ? 8.0 : 14.0,
            ),
            children: [
              _DrawerCategoryTile(
                icon: Icons.queue_music,
                title: l10n.headerEnsembleProfiles,
                subtitle: isDense ? null : 'Standard, Solo, Choir & Orchestra',
                isDense: isDense,
                onTap: () => _navigateTo(DrawerSection.profiles),
              ),
              _DrawerCategoryTile(
                icon: Icons.description_outlined,
                title: l10n.pageSettings,
                subtitle: isDense ? null : 'Paper size, orientation & margins',
                isDense: isDense,
                onTap: () => _navigateTo(DrawerSection.pageSetup),
              ),
              _DrawerCategoryTile(
                icon: Icons.format_line_spacing,
                title: l10n.staffSpacing,
                subtitle: isDense ? null : 'Line gap, system gap, inter-staff gap',
                isDense: isDense,
                onTap: () => _navigateTo(DrawerSection.staffSpacing),
              ),
              _DrawerCategoryTile(
                icon: Icons.account_tree_outlined,
                title: l10n.systemHierarchy,
                subtitle: isDense ? null : 'Staves, parts & system hierarchy',
                isDense: isDense,
                onTap: () => _navigateTo(DrawerSection.systemHierarchy),
              ),
              _DrawerCategoryTile(
                icon: Icons.ios_share,
                title: l10n.exportManuscriptTitle,
                subtitle: isDense ? null : 'Vector SVG, high-res PNG, PDF & print',
                isDense: isDense,
                onTap: () => _navigateTo(DrawerSection.export),
              ),
              // In landscape side sheet mode, unpin footer so it scrolls below the 5 categories
              if (isDense) ...[
                const SizedBox(height: 6.0),
                Divider(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                  height: 12.0,
                ),
                const SizedBox(height: 6.0),
                _buildFooterContent(context, cs, l10n),
                const SizedBox(height: 8.0),
              ],
            ],
          ),
        ),

        // Sticky Drawer Footer Actions (Portrait Mode only)
        if (!isDense)
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: _buildFooterContent(context, cs, l10n),
          ),
      ],
    );
  }

  Widget _buildSectionContent(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    TextDirection sectionTextDir,
  ) {
    String title = '';
    Widget body = const SizedBox.shrink();

    final docState = context.watch<DocumentCubit>().state;
    final cubit = context.read<DocumentCubit>();
    final config = docState.config;

    switch (_currentSection) {
      case DrawerSection.profiles:
        title = l10n.headerEnsembleProfiles;
        body = ProfilePicker(
          currentConfig: config,
          onProfileSelected: (p) => cubit.applyProfile(p),
        );
        break;

      case DrawerSection.pageSetup:
        title = l10n.pageSettings;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DocumentSettingsGroup(
              pageSize: config.pageSize,
              onPageSizeChanged: cubit.updatePageSize,
              orientation: config.orientation,
              onOrientationChanged: cubit.updateOrientation,
            ),
            const SizedBox(height: 16),
            MarginsSettingsGroup(
              margins: config.margins,
              onLeftChanged: cubit.updateLeftMargin,
              onRightChanged: cubit.updateRightMargin,
              onTopChanged: cubit.updateTopMargin,
              onBottomChanged: cubit.updateBottomMargin,
              onHorizontalChanged: cubit.updateHorizontalMargins,
              onVerticalChanged: cubit.updateVerticalMargins,
              onReset: cubit.resetMargins,
              onScrubStart: (side) => context
                  .read<ViewCubit>()
                  .setActiveScrubbingMargin(side),
              onScrubEnd: () => context
                  .read<ViewCubit>()
                  .setActiveScrubbingMargin(null),
            ),
          ],
        );
        break;

      case DrawerSection.staffSpacing:
        title = l10n.staffSpacing;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.staffSpacing,
              onReset: cubit.resetSpacing,
            ),
            const SizedBox(height: 8),
            StaffSpacingGroup(
              staffConfig: config.staffConfig,
              isDoubleLine: config.staffCount > 1,
              lines: cubit.primaryLines,
              onLineGapChanged: cubit.updateLineGap,
              onSystemGapChanged: cubit.updateSystemGap,
              onInterStaffGapChanged: cubit.updateInterStaffGap,
            ),
          ],
        );
        break;

      case DrawerSection.systemHierarchy:
        title = l10n.systemHierarchy;
        body = SystemHierarchyPanel(notifier: cubit);
        break;

      case DrawerSection.export:
        title = l10n.exportManuscriptTitle;
        body = const ExportPanel();
        break;

      case DrawerSection.mainMenu:
        break;
    }

    return Column(
      key: ValueKey(_currentSection.name),
      children: [
        // Sub-page Back Header
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: widget.isSideSheet ? 4.0 : 8.0,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: _goBack,
                tooltip: 'Back to Menu',
              ),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Sub-page Content Body
        Expanded(
          child: Directionality(
            textDirection: sectionTextDir,
            child: ListView(
              padding: const EdgeInsets.all(14.0),
              children: [body],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawerCategoryTile extends StatelessWidget {
  const _DrawerCategoryTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDense = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isDense ? 5.0 : 8.0),
      child: Material(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isDense ? 10.0 : 14.0),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          dense: isDense,
          visualDensity: isDense ? VisualDensity.compact : VisualDensity.standard,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDense ? 10.0 : 14.0,
            vertical: 0.0,
          ),
          leading: Container(
            padding: EdgeInsets.all(isDense ? 5.0 : 8.0),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(isDense ? 8.0 : 10.0),
            ),
            child: Icon(icon, color: cs.primary, size: isDense ? 18 : 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: isDense ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            size: isDense ? 18 : 20,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
