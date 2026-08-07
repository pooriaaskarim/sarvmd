// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../widgets/staff/document_settings_group.dart';
import '../widgets/staff/margins_settings_group.dart';
import '../../core/theme/app_metrics.dart';
import '../widgets/common/section_header.dart';
import '../widgets/staff/staff_spacing_group.dart';
import '../widgets/animations/fade_in_slide.dart';
import '../widgets/layout/sarv_header.dart';
import '../widgets/staff/profile_picker.dart';
import '../widgets/staff/zoom_feedback_overlay.dart';
import '../widgets/canvas/preview_canvas.dart';
import '../widgets/panels/view_panel.dart';
import '../widgets/canvas/ruler_box.dart';
import '../widgets/common/integrated_scale_control.dart';
import '../widgets/panels/advanced_builder_panel.dart';
import '../../logic/config/config_cubit.dart';
import '../../logic/view/view_cubit.dart';
import '../../logic/view/view_state.dart';
import '../../core/constants/app_version.dart';
import '../widgets/dialogs/about_dialog.dart';

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
  double _sidebarWidth = 320;
  double _viewPanelWidth = 280;
  bool _sidebarCollapsed = false;
  bool _viewPanelCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadLayoutPrefs();
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

  void _applyZoomPreset(ZoomPreset preset) {
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final config = context.read<ConfigCubit>().state;
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
    final configCubit = context.read<ConfigCubit>();
    return BlocListener<ConfigCubit, core.PageConfig>(
      listenWhen: (previous, current) =>
          previous.effectiveWidth != current.effectiveWidth ||
          previous.effectiveHeight != current.effectiveHeight,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyZoomPreset(ZoomPreset.fitScreen);
        });
      },
      child: BlocBuilder<ConfigCubit, core.PageConfig>(
        builder: (context, configState) {
          return BlocBuilder<ViewCubit, ViewState>(
            builder: (context, viewState) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Row(
                  children: [
                    // Sidebar (Left)
                    AnimatedContainer(
                      duration: _isDraggingSidebar
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: _sidebarCollapsed ? 0 : _sidebarWidth,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: ClipRect(
                        child: OverflowBox(
                          minWidth: 0,
                          maxWidth: _sidebarWidth,
                          alignment: Alignment.topLeft,
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.paddingLarge),
                                  children: [
                                    const SizedBox(height: 48),
                                    const SarvHeader(),
                                    const SizedBox(
                                        height: AppSpacing.sectionGap),
                                    FadeInSlide(
                                      delay: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(
                                              title: 'Profiles'),
                                          const SizedBox(
                                              height: AppSpacing.itemGapSmall),
                                          ProfilePicker(
                                            currentConfig: configState,
                                            onProfileSelected: (p) =>
                                                configCubit.applyProfile(p),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 32),
                                    FadeInSlide(
                                      delay: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SectionHeader(
                                              title: 'Document'),
                                          const SizedBox(
                                              height: AppSpacing.itemGapSmall),
                                          DocumentSettingsGroup(
                                            pageSize: configState.pageSize,
                                            onPageSizeChanged:
                                                configCubit.updatePageSize,
                                            orientation:
                                                configState.orientation,
                                            onOrientationChanged:
                                                configCubit.updateOrientation,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 32),
                                    FadeInSlide(
                                      delay: 3,
                                      child: MarginsSettingsGroup(
                                        margins: configState.margins,
                                        onLeftChanged:
                                            configCubit.updateLeftMargin,
                                        onRightChanged:
                                            configCubit.updateRightMargin,
                                        onTopChanged:
                                            configCubit.updateTopMargin,
                                        onBottomChanged:
                                            configCubit.updateBottomMargin,
                                        onHorizontalChanged:
                                            configCubit.updateHorizontalMargins,
                                        onVerticalChanged:
                                            configCubit.updateVerticalMargins,
                                        onReset: configCubit.resetMargins,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SectionHeader(
                                            title: 'Staff Spacing',
                                            onReset: configCubit.resetSpacing,
                                          ),
                                          StaffSpacingGroup(
                                            staffConfig:
                                                configState.staffConfig,
                                            isDoubleLine:
                                                configState.staffCount > 1,
                                            lines: configCubit.primaryLines,
                                            onLineGapChanged:
                                                configCubit.updateLineGap,
                                            onSystemGapChanged:
                                                configCubit.updateSystemGap,
                                            onInterStaffGapChanged:
                                                configCubit.updateInterStaffGap,
                                            hints: configCubit.uiHints,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 32),
                                    SystemHierarchyPanel(
                                      key: const ValueKey('advanced_panel'),
                                      notifier: configCubit,
                                    ),
                                    const SizedBox(
                                        height: AppSpacing.paddingLarge),
                                  ],
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Tooltip(
                                      message: 'About SarvMD v${AppVersion.version}',
                                      child: InkWell(
                                        onTap: () => showSarvAboutDialog(context),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'v${AppVersion.version}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.info_outline,
                                                size: 13,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${configCubit.layout.systemCount} Systems',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                    ),
                                    Tooltip(
                                      message: 'Reset ALL settings to defaults',
                                      child: TextButton.icon(
                                        onPressed: configCubit.resetToDefaults,
                                        icon:
                                            const Icon(Icons.restore, size: 14),
                                        label: const Text('Reset',
                                            style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4)),
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
                          ),
                        ),
                      ),
                    ),
                    // Resize Handle (Left)
                    if (!_sidebarCollapsed)
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (_) =>
                            setState(() => _isDraggingSidebar = true),
                        onPanEnd: (_) {
                          setState(() => _isDraggingSidebar = false);
                          _saveLayoutPrefs();
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _sidebarWidth = (_sidebarWidth + details.delta.dx)
                                .clamp(minSidebarWidth, maxSidebarWidth);
                          });
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Container(
                            width: 8,
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isDraggingSidebar ? 2 : 1,
                                height: _isDraggingSidebar ? 60 : 40,
                                decoration: BoxDecoration(
                                  color: _isDraggingSidebar
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Preview Area
                    Expanded(
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            _lastConstraints = constraints;
                            if (!_hasCentered) {
                              _hasCentered = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _applyZoomPreset(ZoomPreset.fitScreen);
                              });
                            }

                            return RulerBox(
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
                                  _cursorNotifier.value = event.localPosition;
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
                                            const EdgeInsets.all(100000),
                                        minScale: ScaleMetrics.minZoom,
                                        maxScale: ScaleMetrics.maxZoom,
                                        constrained: false,
                                        alignment: Alignment.topLeft,
                                        child: PreviewCanvas(
                                          layout: configCubit.layout,
                                          viewState: viewState,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 24,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: ZoomFeedbackOverlay(
                                            controller:
                                                _transformationController),
                                      ),
                                    ),

                                    // Sidebar Toggle (Left)
                                    Positioned(
                                      top: 16,
                                      left: 16,
                                      child: FloatingActionButton.small(
                                        heroTag: 'left_toggle',
                                        onPressed: () {
                                          setState(() {
                                            _sidebarCollapsed =
                                                !_sidebarCollapsed;
                                          });
                                        },
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        elevation: 2,
                                        tooltip: _sidebarCollapsed
                                            ? 'Expand Left Sidebar'
                                            : 'Collapse Left Sidebar',
                                        child: Icon(
                                          _sidebarCollapsed
                                              ? Icons.menu
                                              : Icons.arrow_back_ios_new,
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
                                        onPressed: () {
                                          setState(() {
                                            _viewPanelCollapsed =
                                                !_viewPanelCollapsed;
                                          });
                                        },
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        elevation: 2,
                                        tooltip: _viewPanelCollapsed
                                            ? 'Expand Settings'
                                            : 'Collapse Settings',
                                        child: Icon(
                                          _viewPanelCollapsed
                                              ? Icons.tune
                                              : Icons.arrow_forward_ios,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Resize Handle (Right)
                    if (!_viewPanelCollapsed)
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: (_) =>
                            setState(() => _isDraggingViewPanel = true),
                        onPanEnd: (_) {
                          setState(() => _isDraggingViewPanel = false);
                          _saveLayoutPrefs();
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _viewPanelWidth = (_viewPanelWidth -
                                    details.delta.dx)
                                .clamp(minViewPanelWidth, maxViewPanelWidth);
                          });
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          child: Container(
                            width: 8,
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isDraggingViewPanel ? 2 : 1,
                                height: _isDraggingViewPanel ? 60 : 40,
                                decoration: BoxDecoration(
                                  color: _isDraggingViewPanel
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // View Panel (Right)
                    AnimatedContainer(
                      duration: _isDraggingViewPanel
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: _viewPanelCollapsed ? 0 : _viewPanelWidth,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: ClipRect(
                        child: OverflowBox(
                          minWidth: 0,
                          maxWidth: _viewPanelWidth,
                          alignment: Alignment.topRight,
                          child: ViewPanel(
                            transformationController: _transformationController,
                            onZoomPreset: _applyZoomPreset,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
