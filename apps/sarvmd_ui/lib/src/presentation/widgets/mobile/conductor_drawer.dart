// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_version.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../../../logic/view/view_cubit.dart';
import '../common/integrated_scale_control.dart';
import '../common/section_header.dart';
import '../layout/sarv_reactive_brand_logo.dart';
import '../panels/advanced_builder_panel.dart';
import '../panels/export_panel.dart';
import '../staff/document_settings_group.dart';
import '../staff/margins_settings_group.dart';
import '../staff/profile_picker.dart';
import '../staff/staff_spacing_group.dart';
import 'mobile_language_button.dart';
import 'mobile_theme_button.dart';

/// Full-height side drawer for Proposal B ("Conductor's Baton").
class ConductorDrawer extends StatelessWidget {
  const ConductorDrawer({
    super.key,
    required this.transformationController,
    required this.onZoomPreset,
  });

  final TransformationController transformationController;
  final void Function(ZoomPreset preset) onZoomPreset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isFa = Localizations.localeOf(context).languageCode == 'fa';
    final sectionTextDir = isFa ? TextDirection.rtl : TextDirection.ltr;
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.82;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: drawerWidth.clamp(280.0, 420.0),
        child: Drawer(
          backgroundColor: cs.surfaceContainerLow,
          child: SafeArea(
            child: Column(
            children: [
              // Drawer Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
                          logoHeight: 22.0,
                          enableExpandAnimation: false,
                        ),
                        const SizedBox(height: 2.0),
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
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
                        SizedBox(width: 8.0),
                        MobileThemeButton(),
                      ],
                    ),
                  ],
                ),
              ),

              // Drawer Body Content
              Expanded(
                child: BlocBuilder<DocumentCubit, DocumentState>(
                  builder: (context, docState) {
                    final cubit = context.read<DocumentCubit>();
                    final config = docState.config;

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      children: [
                        // Section 1: Presets
                        Directionality(
                          textDirection: sectionTextDir,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(title: l10n.headerEnsembleProfiles),
                              const SizedBox(height: 8),
                              ProfilePicker(
                                currentConfig: config,
                                onProfileSelected: (p) => cubit.applyProfile(p),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 28),

                        // Section 2: Page Setup & Margins
                        Directionality(
                          textDirection: sectionTextDir,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(title: l10n.pageSettings),
                              const SizedBox(height: 8),
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
                          ),
                        ),
                        const Divider(height: 28),

                        // Section 3: Staff Spacing
                        Directionality(
                          textDirection: sectionTextDir,
                          child: Column(
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
                          ),
                        ),
                        const Divider(height: 28),

                        // Section 4: System Layout & Hierarchy
                        SystemHierarchyPanel(notifier: cubit),
                        const Divider(height: 28),

                        // Section 5: Export Panel
                        const ExportPanel(),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
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
