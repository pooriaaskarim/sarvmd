import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/inputs/document_settings_group.dart';
import 'theme/app_metrics.dart';
import 'components/inputs/section_header.dart';
import 'components/inputs/precision_slider.dart';
import 'components/inputs/staff_spacing_group.dart';
import 'components/animations/fade_in_slide.dart';
import 'components/layout/sarv_header.dart';
import 'components/specialized/profile_picker.dart';
import 'components/specialized/zoom_feedback_overlay.dart';
import 'config_notifier.dart';
import 'preview_canvas.dart';
import 'view_panel.dart';
import 'ruler_box.dart';
import 'view_notifier.dart';
import 'components/inputs/integrated_scale_control.dart';
import 'components/advanced_builder_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.viewNotifier});

  final ViewNotifier viewNotifier;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ConfigNotifier _notifier = ConfigNotifier();
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
  double? _lastEffectiveWidth;
  double? _lastEffectiveHeight;

  @override
  void initState() {
    super.initState();
    _loadLayoutPrefs();
    _lastEffectiveWidth = _notifier.config.effectiveWidth;
    _lastEffectiveHeight = _notifier.config.effectiveHeight;
    _notifier.addListener(_onConfigChanged);
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

    const double lpmm = 96 / 25.4; // canvas internal scale
    final paperWidth = _notifier.layout.config.effectiveWidth * lpmm;
    final paperHeight = _notifier.layout.config.effectiveHeight * lpmm;

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
        // The calibrationFactor is set by the user via the on-screen ruler
        // in the Display section of the View panel.
        fitScale = widget.viewNotifier.calibrationFactor
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



  void _onConfigChanged() {
    final config = _notifier.config;
    final newW = config.effectiveWidth;
    final newH = config.effectiveHeight;

    if (newW != _lastEffectiveWidth || newH != _lastEffectiveHeight) {
      _lastEffectiveWidth = newW;
      _lastEffectiveHeight = newH;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _applyZoomPreset(ZoomPreset.fitScreen);
      });
    }
  }

  @override
  void dispose() {
    _notifier.removeListener(_onConfigChanged);
    _notifier.dispose();
    _transformationController.dispose();
    _cursorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        final layout = _notifier.layout;
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
                              const SizedBox(height: AppSpacing.sectionGap),
                              FadeInSlide(
                                delay: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SectionHeader(title: 'Profiles'),
                                    const SizedBox(
                                        height: AppSpacing.itemGapSmall),
                                    ProfilePicker(
                                      currentConfig: _notifier.config,
                                      onProfileSelected: (p) =>
                                          _notifier.applyProfile(p),
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
                                    const SectionHeader(title: 'Document'),
                                    const SizedBox(
                                        height: AppSpacing.itemGapSmall),
                                    DocumentSettingsGroup(
                                      pageSize: _notifier.config.pageSize,
                                      onPageSizeChanged:
                                          _notifier.updatePageSize,
                                      orientation: _notifier.config.orientation,
                                      onOrientationChanged:
                                          _notifier.updateOrientation,
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 32),
                              FadeInSlide(
                                delay: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: 'Margins (mm)',
                                      onReset: _notifier.resetMargins,
                                    ),
                                    PrecisionSlider(
                                      label: 'Vertical',
                                      value: _notifier.config.margins.top,
                                      min: 5.0,
                                      max: 40.0,
                                      onChanged: (v) =>
                                          _notifier.updateVerticalMargins(v),
                                    ),
                                    PrecisionSlider(
                                      label: 'Horizontal',
                                      value: _notifier.config.margins.left,
                                      min: 5.0,
                                      max: 40.0,
                                      onChanged: (v) =>
                                          _notifier.updateHorizontalMargins(v),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 32),
                              FadeInSlide(
                                delay: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SectionHeader(
                                      title: 'Staff Spacing',
                                      onReset: _notifier.resetSpacing,
                                    ),
                                    StaffSpacingGroup(
                                      staffConfig: _notifier.config.staffConfig,
                                      isDoubleLine:
                                          _notifier.config.staffCount > 1,
                                      lines: _notifier.primaryLines,
                                      onLineGapChanged: _notifier.updateLineGap,
                                      onSystemGapChanged:
                                          _notifier.updateSystemGap,
                                      onInterStaffGapChanged:
                                          _notifier.updateInterStaffGap,
                                      hints: _notifier.uiHints,
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 32),
                              FadeInSlide(
                                delay: 5,
                                child: SystemHierarchyPanel(
                                  key: const ValueKey('advanced'),
                                  notifier: _notifier,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.paddingLarge),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${layout.systemCount} Systems',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                              Tooltip(
                                message: 'Reset ALL settings to defaults',
                                child: TextButton.icon(
                                  onPressed: _notifier.resetToDefaults,
                                  icon: const Icon(Icons.restore, size: 14),
                                  label: const Text('Reset',
                                      style: TextStyle(fontSize: 12)),
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
                    ),
                  ),
                ),
              ),
              // Resize Handle (Left)
              if (!_sidebarCollapsed)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (_) => setState(() => _isDraggingSidebar = true),
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
                                : Theme.of(context).colorScheme.outlineVariant,
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
                        transformationController: _transformationController,
                        viewNotifier: widget.viewNotifier,
                        cursorNotifier: _cursorNotifier,
                        paperSizeMm: Size(
                          layout.config.effectiveWidth,
                          layout.config.effectiveHeight,
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
                                  boundaryMargin: const EdgeInsets.all(100000),
                                  minScale: ScaleMetrics.minZoom,
                                  maxScale: ScaleMetrics.maxZoom,
                                  constrained: false,
                                  alignment: Alignment.topLeft,
                                  child: PreviewCanvas(
                                    layout: layout,
                                    viewNotifier: widget.viewNotifier,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 24,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: ZoomFeedbackOverlay(
                                      controller: _transformationController),
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
                                      _sidebarCollapsed = !_sidebarCollapsed;
                                    });
                                  },
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
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
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
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
                      _viewPanelWidth = (_viewPanelWidth - details.delta.dx)
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
                                : Theme.of(context).colorScheme.outlineVariant,
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
                      viewNotifier: widget.viewNotifier,
                      transformationController: _transformationController,
                      onZoomPreset: _applyZoomPreset,
                      configNotifier: _notifier,
                      layoutGetter: () => _notifier.layout,
                    ),
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
