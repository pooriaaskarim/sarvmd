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
import '../widgets/common/section_header.dart';
import '../widgets/staff/staff_spacing_group.dart';
import '../widgets/animations/fade_in_slide.dart';
import '../widgets/layout/sarv_top_bar.dart';

import '../widgets/common/shortcut_gateway.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/staff/profile_picker.dart';
import '../widgets/canvas/preview_canvas.dart';
import '../widgets/panels/view_panel.dart';
import '../widgets/canvas/ruler_box.dart';
import '../widgets/common/integrated_scale_control.dart';
import '../widgets/panels/advanced_builder_panel.dart';
import '../../logic/document/document_cubit.dart';
import '../../logic/document/document_state.dart';
import '../../logic/view/view_cubit.dart';
import '../../logic/view/view_state.dart';


class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final ValueNotifier<Offset?> _cursorNotifier = ValueNotifier(null);
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
      if (currentWidth < SarvBreakpoints.desktopWideThreshold) {
        _viewPanelCollapsed = true;
      }
      if (currentWidth < SarvBreakpoints.desktopMediumThreshold) {
        _sidebarCollapsed = true;
      }
    } else {
      if (_lastScreenWidth! >= SarvBreakpoints.desktopWideThreshold &&
          currentWidth < SarvBreakpoints.desktopWideThreshold) {
        _viewPanelCollapsed = true;
      }
      if (_lastScreenWidth! >= SarvBreakpoints.desktopMediumThreshold &&
          currentWidth < SarvBreakpoints.desktopMediumThreshold) {
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
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingLarge),
              children: [
                const SizedBox(height: AppSpacing.paddingMedium),
                FadeInSlide(
                  delay: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                          title: AppLocalizations.of(context)!
                              .headerEnsembleProfiles),
                      const SizedBox(height: AppSpacing.itemGapSmall),
                      ProfilePicker(
                        currentConfig: configState,
                        onProfileSelected: (p) =>
                            documentCubit.applyProfile(p),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                FadeInSlide(
                  delay: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                          title: AppLocalizations.of(context)!.pageSettings),
                      const SizedBox(height: AppSpacing.itemGapSmall),
                      DocumentSettingsGroup(
                        pageSize: configState.pageSize,
                        onPageSizeChanged: documentCubit.updatePageSize,
                        orientation: configState.orientation,
                        onOrientationChanged:
                            documentCubit.updateOrientation,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                FadeInSlide(
                  delay: 3,
                  child: MarginsSettingsGroup(
                    margins: configState.margins,
                    onLeftChanged: documentCubit.updateLeftMargin,
                    onRightChanged: documentCubit.updateRightMargin,
                    onTopChanged: documentCubit.updateTopMargin,
                    onBottomChanged: documentCubit.updateBottomMargin,
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
                const Divider(height: 32),
                FadeInSlide(
                  delay: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: AppLocalizations.of(context)!.staffSpacing,
                        onReset: documentCubit.resetSpacing,
                      ),
                      StaffSpacingGroup(
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
                    ],
                  ),
                ),
                const Divider(height: 32),
                SystemHierarchyPanel(
                  key: const ValueKey('advanced_panel'),
                  notifier: documentCubit,
                ),
                const SizedBox(height: AppSpacing.paddingLarge),
              ],
            ),
          ),
        ),
        Divider(
            color: Theme.of(context).colorScheme.outline,
            height: 1),
        Padding(
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
              Tooltip(
                message:
                    AppLocalizations.of(context)!.resetAllSettings,
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

    const double lpmm = 96 / 25.4; // canvas internal scale
    final paperWidth = config.effectiveWidth * lpmm;
    final paperHeight = config.effectiveHeight * lpmm;

    // constraints wraps the full RulerBox (ruler strips + canvas area).
    // Subtract rulerSize so scale is computed against the canvas-only area.
    const double rulerSize = 25.0;
    const double padding = 40.0;
    final canvasWidth = constraints.maxWidth - rulerSize;
    final canvasHeight = constraints.maxHeight - rulerSize;
    final availableWidth = canvasWidth - padding * 2;
    final availableHeight = canvasHeight - padding * 2;

    double fitScale;

    switch (preset) {
      case ZoomPreset.actualSize:
        // Zoom so that 1 mm of paper = 1 mm on the physical screen.
        // The calibrationFactor is set by the user via the on-screen ruler.
        fitScale = viewState.calibrationFactor
            .clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
      case ZoomPreset.fitWidth:
        fitScale = (availableWidth / paperWidth)
            .clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
      case ZoomPreset.fitScreen:
        final scaleX = availableWidth / paperWidth;
        final scaleY = availableHeight / paperHeight;
        fitScale = (scaleX < scaleY ? scaleX : scaleY)
            .clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
        break;
    }

    // dx/dy go into the TransformationController which is in canvas-local
    // coordinates (InteractiveViewer's own space, after the ruler strips).
    // Center within the canvas area — no rulerSize offset needed.
    final double dx = (canvasWidth - paperWidth * fitScale) / 2;
    double dy;

    if (preset == ZoomPreset.fitScreen) {
      dy = (canvasHeight - paperHeight * fitScale) / 2;
    } else {
      final scaledHeight = paperHeight * fitScale;
      if (scaledHeight < availableHeight) {
        dy = (canvasHeight - scaledHeight) / 2;
      } else {
        dy = padding;
      }
    }

    _transformationController.value = Matrix4.translationValues(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(fitScale, fitScale, 1.0));
  }

  @override
  void dispose() {
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
                      const SarvTopBar(),
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



