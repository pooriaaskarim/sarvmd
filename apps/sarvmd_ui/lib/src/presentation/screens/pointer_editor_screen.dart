// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/staff/document_settings_group.dart';
import '../widgets/staff/margins_settings_group.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/layout_policy.dart';
import '../widgets/staff/staff_spacing_group.dart';
import '../widgets/layout/pointer_top_bar.dart';
import '../widgets/workspace/pointer_tab_bar.dart';

import '../widgets/common/shortcut_gateway.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/staff/profile_picker.dart';
import '../widgets/canvas/canvas_zoom_calculator.dart';
import '../widgets/canvas/preview_canvas.dart';
import '../widgets/panels/view_panel.dart';
import '../widgets/canvas/ruler_box.dart';
import '../widgets/common/integrated_scale_control.dart';
import '../widgets/panels/advanced_builder_panel.dart';
import '../widgets/panels/collapsible_section_card.dart';
import '../widgets/panels/section_spine.dart';
import '../../logic/document/document_cubit.dart';
import '../../logic/document/document_state.dart';
import '../../logic/view/view_cubit.dart';
import '../../logic/view/view_state.dart';


class PointerEditorScreen extends StatefulWidget {
  const PointerEditorScreen({super.key});

  @override
  State<PointerEditorScreen> createState() => _PointerEditorScreenState();
}

class _PointerEditorScreenState extends State<PointerEditorScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final ValueNotifier<Offset?> _cursorNotifier = ValueNotifier(null);
  final ScrollController _sidebarScrollController = ScrollController();
  final GlobalKey _profilesAnchorKey = GlobalKey();
  final GlobalKey _pageSetupAnchorKey = GlobalKey();
  final GlobalKey _marginsAnchorKey = GlobalKey();
  final GlobalKey _staffSpacingAnchorKey = GlobalKey();
  final GlobalKey _hierarchyAnchorKey = GlobalKey();
  BoxConstraints? _lastConstraints;
  bool _hasCentered = false;
  bool _isDraggingSidebar = false;
  bool _isDraggingViewPanel = false;
  bool _isHoveringSidebarHandle = false;
  bool _isHoveringViewPanelHandle = false;
  double _sidebarWidth = 320;
  double _viewPanelWidth = 280;
  bool _sidebarCollapsed = false;
  bool _viewPanelCollapsed = false;
  double? _lastScreenWidth;

  @override
  void initState() {
    super.initState();
    _loadLayoutPrefs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentWidth = MediaQuery.sizeOf(context).width;
    if (_lastScreenWidth == null) {
      if (currentWidth < SarvBreakpoints.bothSidebarsDockedMinWidth) {
        _viewPanelCollapsed = true;
      }
      if (currentWidth < SarvBreakpoints.primarySidebarDockedMinWidth) {
        _sidebarCollapsed = true;
      }
    } else {
      if (_lastScreenWidth! >= SarvBreakpoints.bothSidebarsDockedMinWidth &&
          currentWidth < SarvBreakpoints.bothSidebarsDockedMinWidth) {
        _viewPanelCollapsed = true;
      }
      if (_lastScreenWidth! >= SarvBreakpoints.primarySidebarDockedMinWidth &&
          currentWidth < SarvBreakpoints.primarySidebarDockedMinWidth) {
        _sidebarCollapsed = true;
      }
    }
    _lastScreenWidth = currentWidth;
  }

  void _toggleLeftSidebar(bool canDockLeft, bool canDockRight) {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
      if (!_sidebarCollapsed && !canDockLeft && !canDockRight) {
        _viewPanelCollapsed = true;
      }
    });
  }

  void _toggleViewPanel(bool canDockLeft, bool canDockRight) {
    setState(() {
      _viewPanelCollapsed = !_viewPanelCollapsed;
      if (!_viewPanelCollapsed && !canDockLeft && !canDockRight) {
        _sidebarCollapsed = true;
      }
    });
  }

  Future<void> _loadLayoutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sidebarWidth = prefs.getDouble('sidebar_width') ?? 320;
      _viewPanelWidth = prefs.getDouble('view_panel_width') ?? 280;
    });
  }

  Future<void> _saveLayoutPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sidebar_width', _sidebarWidth);
    await prefs.setDouble('view_panel_width', _viewPanelWidth);
  }

  static const double minSidebarWidth = 280;
  static const double maxSidebarWidth = 500;
  static const double minViewPanelWidth = 240;
  static const double maxViewPanelWidth = 400;

  Widget _buildLeftResizeHandle(BuildContext context, {double? maxWidth}) {
    final isActive = _isDraggingSidebar || _isHoveringSidebarHandle;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHoveringSidebarHandle = true),
      onExit: (_) => setState(() => _isHoveringSidebarHandle = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => setState(() => _isDraggingSidebar = true),
        onPanEnd: (_) {
          setState(() => _isDraggingSidebar = false);
          _saveLayoutPrefs();
        },
        onPanUpdate: (details) {
          setState(() {
            final maxAllowed = maxWidth ?? maxSidebarWidth;
            final minAllowed = math.min(minSidebarWidth, maxAllowed);
            _sidebarWidth = (_sidebarWidth + details.delta.dx)
                .clamp(minAllowed, maxAllowed);
          });
        },
        child: Container(
          width: 12,
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full-height subtle divider track line
              Container(
                width: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: isActive ? 0.8 : 0.4),
              ),
              // Centered grip indicator pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: isActive ? 4 : 2.5,
                height: isActive ? 64 : 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightResizeHandle(BuildContext context, {double? maxWidth}) {
    final isActive = _isDraggingViewPanel || _isHoveringViewPanelHandle;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _isHoveringViewPanelHandle = true),
      onExit: (_) => setState(() => _isHoveringViewPanelHandle = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => setState(() => _isDraggingViewPanel = true),
        onPanEnd: (_) {
          setState(() => _isDraggingViewPanel = false);
          _saveLayoutPrefs();
        },
        onPanUpdate: (details) {
          setState(() {
            final maxAllowed = maxWidth ?? maxViewPanelWidth;
            final minAllowed = math.min(minViewPanelWidth, maxAllowed);
            _viewPanelWidth = (_viewPanelWidth - details.delta.dx)
                .clamp(minAllowed, maxAllowed);
          });
        },
        child: Container(
          width: 12,
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Full-height subtle divider track line
              Container(
                width: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: isActive ? 0.8 : 0.4),
              ),
              // Centered grip indicator pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: isActive ? 4 : 2.5,
                height: isActive ? 64 : 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftOverlay({
    required BuildContext context,
    required DocumentCubit documentCubit,
    required core.PageConfig configState,
    required TextDirection sidebarTextDir,
    required double screenWidth,
  }) {
    final maxAllowed = screenWidth * 0.85;
    final minAllowed = math.min(minSidebarWidth, maxAllowed);
    final overlayWidth = _sidebarWidth.clamp(minAllowed, maxAllowed);

    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      width: overlayWidth + 12,
      child: Material(
        elevation: 16,
        shadowColor: Colors.black54,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSidebarContent(
                  context: context,
                  documentCubit: documentCubit,
                  configState: configState,
                  sidebarTextDir: sidebarTextDir,
                  isOverlay: true,
                ),
              ),
              _buildLeftResizeHandle(context, maxWidth: maxAllowed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightOverlay({
    required BuildContext context,
    required TextDirection textDir,
    required double screenWidth,
  }) {
    final maxAllowed = screenWidth * 0.85;
    final minAllowed = math.min(minViewPanelWidth, maxAllowed);
    final overlayWidth = _viewPanelWidth.clamp(minAllowed, maxAllowed);

    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: overlayWidth + 12,
      child: Material(
        elevation: 16,
        shadowColor: Colors.black54,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildRightResizeHandle(context, maxWidth: maxAllowed),
              Expanded(
                child: _buildViewPanelContent(
                  context: context,
                  textDir: textDir,
                  isOverlay: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SectionSpineEntry> _buildSpineEntries(
    ViewState viewState,
    AppLocalizations l10n,
  ) {
    return [
      SectionSpineEntry(
        section: SettingsSection.profiles,
        label: l10n.headerEnsembleProfiles,
        icon: Icons.queue_music_rounded,
        key: _profilesAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.profiles),
      ),
      SectionSpineEntry(
        section: SettingsSection.pageSetup,
        label: l10n.pageSettings,
        icon: Icons.description_outlined,
        key: _pageSetupAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.pageSetup),
      ),
      SectionSpineEntry(
        section: SettingsSection.margins,
        label: l10n.marginsLabel,
        icon: Icons.space_dashboard_outlined,
        key: _marginsAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.margins),
      ),
      SectionSpineEntry(
        section: SettingsSection.staffSpacing,
        label: l10n.staffSpacing,
        icon: Icons.format_line_spacing_rounded,
        key: _staffSpacingAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.staffSpacing),
      ),
      SectionSpineEntry(
        section: SettingsSection.systemHierarchy,
        label: l10n.systemHierarchy,
        icon: Icons.account_tree_outlined,
        key: _hierarchyAnchorKey,
        isExpanded: viewState.isPointerSectionExpanded(SettingsSection.systemHierarchy),
      ),
    ];
  }

  Widget _buildSidebarContent({
    required BuildContext context,
    required DocumentCubit documentCubit,
    required core.PageConfig configState,
    required TextDirection sidebarTextDir,
    bool isOverlay = false,
  }) {
    return Column(
      children: [
        if (isOverlay)
          Directionality(
            textDirection: sidebarTextDir,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingLarge,
                vertical: AppSpacing.paddingSmall,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.itemGapSmall),
                      Text(
                        AppLocalizations.of(context)!.pageSettings,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: AppLocalizations.of(context)!.close,
                    onPressed: () => setState(() => _sidebarCollapsed = true),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Directionality(
            textDirection: sidebarTextDir,
            child: Builder(
              builder: (context) {
                final viewCubit = context.read<ViewCubit>();
                final viewState = context.watch<ViewCubit>().state;
                final l10n = AppLocalizations.of(context)!;

                final spineEntries = _buildSpineEntries(viewState, l10n);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          scrollbars: false,
                        ),
                        child: ListView(
                          key: const PageStorageKey('pointer_primary_sidebar'),
                          controller: _sidebarScrollController,
                          padding: const EdgeInsets.fromLTRB(
                            28.0,
                            AppSpacing.paddingMedium,
                            8.0,
                            AppSpacing.paddingLarge,
                          ),
                          children: [
                            CollapsibleSectionCard(
                              section: SettingsSection.profiles,
                              title: l10n.headerEnsembleProfiles,
                              icon: Icons.queue_music_rounded,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.profiles),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.profiles),
                              anchorKey: _profilesAnchorKey,
                              child: ProfilePicker(
                                currentConfig: configState,
                                onProfileSelected: (p) =>
                                    documentCubit.applyProfile(p),
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.pageSetup,
                              title: l10n.pageSettings,
                              icon: Icons.description_outlined,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.pageSetup),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.pageSetup),
                              anchorKey: _pageSetupAnchorKey,
                              child: DocumentSettingsGroup(
                                pageSize: configState.pageSize,
                                onPageSizeChanged: documentCubit.updatePageSize,
                                orientation: configState.orientation,
                                onOrientationChanged:
                                    documentCubit.updateOrientation,
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.margins,
                              title: l10n.marginsLabel,
                              icon: Icons.space_dashboard_outlined,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.margins),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.margins),
                              anchorKey: _marginsAnchorKey,
                              action: Tooltip(
                                message: l10n.reset,
                                child: InkWell(
                                  onTap: documentCubit.resetMargins,
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.restore,
                                      size: 14.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              child: MarginsSettingsGroup(
                                margins: configState.margins,
                                onLeftChanged: documentCubit.updateLeftMargin,
                                onRightChanged: documentCubit.updateRightMargin,
                                onTopChanged: documentCubit.updateTopMargin,
                                onBottomChanged:
                                    documentCubit.updateBottomMargin,
                                onHorizontalChanged:
                                    documentCubit.updateHorizontalMargins,
                                onVerticalChanged:
                                    documentCubit.updateVerticalMargins,
                                onReset: documentCubit.resetMargins,
                                onScrubStart: (side) => context
                                    .read<ViewCubit>()
                                    .setActiveScrubbingMargin(side),
                                onScrubEnd: () => context
                                    .read<ViewCubit>()
                                    .setActiveScrubbingMargin(null),
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.staffSpacing,
                              title: l10n.staffSpacing,
                              icon: Icons.format_line_spacing_rounded,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.staffSpacing),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.staffSpacing),
                              anchorKey: _staffSpacingAnchorKey,
                              action: Tooltip(
                                message: l10n.reset,
                                child: InkWell(
                                  onTap: documentCubit.resetSpacing,
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.restore,
                                      size: 14.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              child: StaffSpacingGroup(
                                staffConfig: configState.staffConfig,
                                isDoubleLine: configState.staffCount > 1,
                                lines: documentCubit.primaryLines,
                                onLineGapChanged: documentCubit.updateLineGap,
                                onSystemGapChanged:
                                    documentCubit.updateSystemGap,
                                onInterStaffGapChanged:
                                    documentCubit.updateInterStaffGap,
                                hints: documentCubit.uiHints,
                              ),
                            ),
                            CollapsibleSectionCard(
                              section: SettingsSection.systemHierarchy,
                              title: l10n.systemHierarchy,
                              icon: Icons.account_tree_outlined,
                              isExpanded: viewState.isPointerSectionExpanded(
                                  SettingsSection.systemHierarchy),
                              onToggle: () => viewCubit.togglePointerSection(
                                  SettingsSection.systemHierarchy),
                              anchorKey: _hierarchyAnchorKey,
                              child: SystemHierarchyPanel(
                                key: const ValueKey('advanced_panel'),
                                notifier: documentCubit,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.paddingLarge),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 2.0,
                      child: SectionSpine(
                        entries: spineEntries,
                        scrollController: _sidebarScrollController,
                        onJumpToSection: (section) =>
                            viewCubit.jumpToSection(section),
                        activeSection: viewState.jumpTargetSection,
                        onActiveSectionChanged: (section) =>
                            viewCubit.setActiveSection(section),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Divider(
            color: Theme.of(context).colorScheme.outline,
            height: 1),
        BlocBuilder<ViewCubit, ViewState>(
          builder: (context, viewState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingLarge,
                  vertical: AppSpacing.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .systemsCount(documentCubit.layout.systemCount),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          viewState.expandedPointerSections.isEmpty
                              ? Icons.unfold_more_rounded
                              : Icons.unfold_less_rounded,
                          size: 16,
                        ),
                        tooltip: viewState.expandedPointerSections.isEmpty
                            ? 'Expand All Sections'
                            : 'Collapse All Sections',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (viewState.expandedPointerSections.isEmpty) {
                            context
                                .read<ViewCubit>()
                                .expandAllPointerSections();
                          } else {
                            context
                                .read<ViewCubit>()
                                .collapseAllPointerSections();
                          }
                        },
                      ),
                      const SizedBox(width: 4.0),
                      Tooltip(
                        message: AppLocalizations.of(context)!.resetAllSettings,
                        child: TextButton.icon(
                          onPressed: documentCubit.resetToDefaults,
                          icon: const Icon(Icons.restore, size: 14),
                          label: Text(AppLocalizations.of(context)!.reset,
                              style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildViewPanelContent({
    required BuildContext context,
    required TextDirection textDir,
    bool isOverlay = false,
  }) {
    return Column(
      children: [
        if (isOverlay)
          Directionality(
            textDirection: textDir,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.paddingLarge,
                vertical: AppSpacing.paddingSmall,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.itemGapSmall),
                      Text(
                        AppLocalizations.of(context)!.view,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: AppLocalizations.of(context)!.close,
                    onPressed: () => setState(() => _viewPanelCollapsed = true),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ViewPanel(
            transformationController: _transformationController,
            onZoomPreset: _applyZoomPreset,
          ),
        ),
      ],
    );
  }

  void _applyZoomPreset(ZoomPreset preset) {
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final config = context.read<DocumentCubit>().state.config;
    final viewState = context.read<ViewCubit>().state;

    final transform = CanvasZoomCalculator.compute(
      preset: preset,
      constraints: constraints,
      config: config,
      calibrationFactor: viewState.calibrationFactor,
      padding: 40.0,
    );

    _transformationController.value = transform.matrix;
  }

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    _transformationController.dispose();
    _cursorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentCubit = context.read<DocumentCubit>();
    return BlocListener<DocumentCubit, DocumentState>(
      listenWhen: (previous, current) =>
          previous.config.effectiveWidth != current.config.effectiveWidth ||
          previous.config.effectiveHeight != current.config.effectiveHeight,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyZoomPreset(ZoomPreset.fitScreen);
        });
      },
      child: BlocBuilder<DocumentCubit, DocumentState>(
        builder: (context, docState) {
          final configState = docState.config;
          final isFa = Localizations.localeOf(context).languageCode == 'fa';
          final sidebarTextDir = isFa ? TextDirection.rtl : TextDirection.ltr;          final screenWidth = MediaQuery.sizeOf(context).width;
          final canDockLeft = SarvBreakpoints.canDockPrimarySidebar(context);
          final canDockRight = SarvBreakpoints.canDockBothSidebars(context);

          return BlocBuilder<ViewCubit, ViewState>(
            builder: (context, viewState) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: SarvShortcutGateway(
                  child: Column(
                    children: [
                      const PointerTopBar(),
                      const PointerTabBar(),
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              // Sidebar (Left) - docked when viewport allows
                              if (canDockLeft) ...[
                                AnimatedContainer(
                                  duration: _isDraggingSidebar
                                      ? Duration.zero
                                      : const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  width: _sidebarCollapsed ? 0 : _sidebarWidth,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      minWidth: 0,
                                      maxWidth: _sidebarWidth,
                                      alignment: Alignment.topLeft,
                                      child: _buildSidebarContent(
                                        context: context,
                                        documentCubit: documentCubit,
                                        configState: configState,
                                        sidebarTextDir: sidebarTextDir,
                                        isOverlay: false,
                                      ),
                                    ),
                                  ),
                                ),
                                // Resize Handle (Left)
                                if (!_sidebarCollapsed)
                                  _buildLeftResizeHandle(context),
                              ],
                              // Preview Area
                              Expanded(
                                child: Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      _lastConstraints = constraints;
                                      if (!_hasCentered) {
                                        _hasCentered = true;
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          _applyZoomPreset(ZoomPreset.fitScreen);
                                        });
                                      }

                                      return Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CanvasStrictScope(
                                              child: RulerBox(
                                                transformationController:
                                                    _transformationController,
                                                viewState: viewState,
                                                cursorNotifier: _cursorNotifier,
                                                paperSizeMm: Size(
                                                  configState.effectiveWidth,
                                                  configState.effectiveHeight,
                                                ),
                                                child: MouseRegion(
                                                  onHover: (event) {
                                                    _cursorNotifier.value =
                                                        event.localPosition;
                                                  },
                                                  onExit: (_) {
                                                    _cursorNotifier.value = null;
                                                  },
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: InteractiveViewer(
                                                          transformationController:
                                                              _transformationController,
                                                          boundaryMargin:
                                                              const EdgeInsets.all(
                                                                  100000),
                                                          minScale:
                                                              ScaleMetrics.minZoom,
                                                          maxScale:
                                                              ScaleMetrics.maxZoom,
                                                          constrained: false,
                                                          alignment:
                                                              Alignment.topLeft,
                                                          child: PreviewCanvas(
                                                            layout:
                                                                documentCubit.layout,
                                                            viewState: viewState,
                                                          ),
                                                        ),
                                                      ),
                                                      // Sidebar Toggle (Left)
                                                      Positioned(
                                                        top: 16,
                                                        left: 16,
                                                        child: FloatingActionButton.small(
                                                          heroTag: 'left_toggle',
                                                          onPressed: () =>
                                                              _toggleLeftSidebar(
                                                                  canDockLeft,
                                                                  canDockRight),
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .surface,
                                                          foregroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                          elevation: 2,
                                                          tooltip: _sidebarCollapsed
                                                              ? (canDockLeft
                                                                  ? 'Expand Left Sidebar'
                                                                  : 'Open Sidebar')
                                                              : 'Collapse Left Sidebar',
                                                          child: Icon(
                                                            _sidebarCollapsed
                                                                ? Icons.menu
                                                                : Icons
                                                                    .arrow_back_ios_new,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                      // View Panel Toggle (Right)
                                                      Positioned(
                                                        top: 16,
                                                        right: 16,
                                                        child: FloatingActionButton.small(
                                                          heroTag: 'right_toggle',
                                                          onPressed: () =>
                                                              _toggleViewPanel(
                                                                  canDockLeft,
                                                                  canDockRight),
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .surface,
                                                          foregroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                          elevation: 2,
                                                          tooltip: _viewPanelCollapsed
                                                              ? (canDockRight
                                                                  ? 'Expand Settings'
                                                                  : 'Open Settings')
                                                              : 'Collapse Settings',
                                                          child: Icon(
                                                            _viewPanelCollapsed
                                                                ? Icons.tune
                                                                : Icons
                                                                    .arrow_forward_ios,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Scrim for overlay drawer(s)
                                          if ((!canDockLeft &&
                                                  !_sidebarCollapsed) ||
                                              (!canDockRight &&
                                                  !_viewPanelCollapsed))
                                            Positioned.fill(
                                              child: GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: () {
                                                  setState(() {
                                                    if (!canDockLeft) {
                                                      _sidebarCollapsed =
                                                          true;
                                                    }
                                                    if (!canDockRight) {
                                                      _viewPanelCollapsed =
                                                          true;
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  color: Colors.black
                                                      .withValues(
                                                          alpha: 0.35),
                                                ),
                                              ),
                                            ),
                                          // Left Sidebar Overlay (flush with top bar and screen edges)
                                          if (!canDockLeft &&
                                              !_sidebarCollapsed)
                                            _buildLeftOverlay(
                                              context: context,
                                              documentCubit:
                                                  documentCubit,
                                              configState: configState,
                                              sidebarTextDir:
                                                  sidebarTextDir,
                                              screenWidth: screenWidth,
                                            ),
                                          // Right View Panel Overlay (flush with top bar and screen edges)
                                          if (!canDockRight &&
                                              !_viewPanelCollapsed)
                                            _buildRightOverlay(
                                              context: context,
                                              textDir: sidebarTextDir,
                                              screenWidth: screenWidth,
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Docked Right View Panel
                              if (canDockRight) ...[
                                if (!_viewPanelCollapsed)
                                  _buildRightResizeHandle(context),
                                AnimatedContainer(
                                  duration: _isDraggingViewPanel
                                      ? Duration.zero
                                      : const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                  width: _viewPanelCollapsed
                                      ? 0
                                      : _viewPanelWidth,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      minWidth: 0,
                                      maxWidth: _viewPanelWidth,
                                      alignment: Alignment.topRight,
                                      child: _buildViewPanelContent(
                                        context: context,
                                        textDir: sidebarTextDir,
                                        isOverlay: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



