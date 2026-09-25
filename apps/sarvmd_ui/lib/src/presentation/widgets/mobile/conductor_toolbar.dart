// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/document/document_state.dart';
import '../../../logic/view/view_cubit.dart';
import '../../../logic/view/view_state.dart';
import '../common/integrated_scale_control.dart';
import '../dialogs/adaptive_dialog_helper.dart';
import '../dialogs/calibration_dialog.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/utils/unit_formatter.dart';

/// Dual-Island Floating Mobile HUD ("Conductor Baton") for SarvMD (Proposal A + Hybrid).
/// Combines drawer triggers, undo/redo, scrubbable zoom, real-time telemetry morphing, and overlay guides.
/// Auto-collapses to compact frosted pods after 4 seconds of inactivity, and hides during canvas gestures.
class ConductorToolbar extends StatefulWidget {
  const ConductorToolbar({
    super.key,
    required this.transformationController,
    required this.onZoomPreset,
    this.isVisible = true,
    this.onOpenMenu,
    this.cursorPosition,
  });

  final TransformationController transformationController;
  final ValueChanged<ZoomPreset> onZoomPreset;
  final bool isVisible;
  final VoidCallback? onOpenMenu;
  final Offset? cursorPosition;

  @override
  State<ConductorToolbar> createState() => _ConductorToolbarState();
}

class _ConductorToolbarState extends State<ConductorToolbar> {
  Timer? _leftIdleTimer;
  Timer? _rightIdleTimer;
  bool _isLeftCollapsed = false;
  bool _isRightCollapsed = false;
  double _leftDragDelta = 0.0;
  bool _leftDragTriggered = false;

  @override
  void initState() {
    super.initState();
    _resetLeftIdleTimer();
    _resetRightIdleTimer();
    widget.transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    if (mounted) {
      _resetRightIdleTimer();
    }
  }

  @override
  void didUpdateWidget(ConductorToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _resetLeftIdleTimer();
        _resetRightIdleTimer();
      }
    }
    if (widget.transformationController != oldWidget.transformationController) {
      oldWidget.transformationController.removeListener(_onTransformationChanged);
      widget.transformationController.addListener(_onTransformationChanged);
    }
    if (widget.cursorPosition != null && oldWidget.cursorPosition == null) {
      _expandRightWing();
    }
  }

  void _resetLeftIdleTimer() {
    _leftIdleTimer?.cancel();
    if (!_isLeftCollapsed) {
      _leftIdleTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isLeftCollapsed = true;
          });
        }
      });
    }
  }

  void _resetRightIdleTimer() {
    _rightIdleTimer?.cancel();
    if (!_isRightCollapsed) {
      _rightIdleTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isRightCollapsed = true;
          });
        }
      });
    }
  }

  void _expandLeftWing() {
    setState(() {
      _isLeftCollapsed = false;
    });
    _resetLeftIdleTimer();
  }

  void _expandRightWing() {
    setState(() {
      _isRightCollapsed = false;
    });
    _resetRightIdleTimer();
  }

  void _openDrawerOrMenu() {
    _resetLeftIdleTimer();
    if (widget.onOpenMenu != null) {
      widget.onOpenMenu!();
    } else {
      Scaffold.of(context).openDrawer();
    }
  }

  void _onLeftWingHorizontalDragStart(DragStartDetails details) {
    _leftDragDelta = 0.0;
    _leftDragTriggered = false;
    _resetLeftIdleTimer();
  }

  void _onLeftWingHorizontalDragUpdate(DragUpdateDetails details) {
    _resetLeftIdleTimer();
    if (_leftDragTriggered) return;

    _leftDragDelta = math.max(0.0, _leftDragDelta + details.delta.dx);
    if (_leftDragDelta > 24.0) {
      _leftDragTriggered = true;
      HapticFeedback.lightImpact();
      _openDrawerOrMenu();
    }
  }

  void _onLeftWingHorizontalDragEnd(DragEndDetails details) {
    if (!_leftDragTriggered && (details.primaryVelocity ?? 0) > 150.0) {
      _leftDragTriggered = true;
      HapticFeedback.lightImpact();
      _openDrawerOrMenu();
    }
    _leftDragDelta = 0.0;
    _leftDragTriggered = false;
  }

  void _onLeftWingHorizontalDragCancel() {
    _leftDragDelta = 0.0;
    _leftDragTriggered = false;
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onTransformationChanged);
    _leftIdleTimer?.cancel();
    _rightIdleTimer?.cancel();
    super.dispose();
  }

  void _stepZoom(double factor) {
    _resetRightIdleTimer();
    final matrix = widget.transformationController.value.clone();
    final currentScale = matrix.row0[0];
    final targetScale = (currentScale * factor)
        .clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
    final translation = matrix.getTranslation();

    widget.transformationController.value =
        Matrix4.translationValues(translation.x, translation.y, 0.0)
          ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1.0));
  }

  void _setScale(double targetScale) {
    _resetRightIdleTimer();
    final matrix = widget.transformationController.value.clone();
    final translation = matrix.getTranslation();

    widget.transformationController.value =
        Matrix4.translationValues(translation.x, translation.y, 0.0)
          ..multiply(Matrix4.diagonal3Values(
            targetScale.clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom),
            targetScale.clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom),
            1.0,
          ));
  }

  void _showGuidesSheet(BuildContext context) {
    _resetRightIdleTimer();
    final viewCubit = context.read<ViewCubit>();
    showSarvAdaptiveModal<void>(
      context: context,
      builder: (ctx, _) => BlocBuilder<ViewCubit, ViewState>(
        builder: (context, viewState) {
          return _MobileGuidesSheet(
            viewState: viewState,
            viewCubit: viewCubit,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final viewState = context.watch<ViewCubit>().state;
    final activeGuidesCount = viewState.activeGuides.length;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: widget.isVisible ? Offset.zero : const Offset(0, 1.8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.isVisible ? 1.0 : 0.0,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left Wing: Document & History
              _buildLeftWing(context, cs, l10n),

              // Right Wing: Camera & Guides
              _buildRightWing(context, cs, l10n, viewState, activeGuidesCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftWing(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return GestureDetector(
      onTapDown: (_) => _resetLeftIdleTimer(),
      onHorizontalDragStart: _onLeftWingHorizontalDragStart,
      onHorizontalDragUpdate: _onLeftWingHorizontalDragUpdate,
      onHorizontalDragEnd: _onLeftWingHorizontalDragEnd,
      onHorizontalDragCancel: _onLeftWingHorizontalDragCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        child: _isLeftCollapsed
            ? _buildCollapsedLeftWing(context, cs, l10n)
            : _buildExpandedLeftWing(context, cs, l10n),
      ),
    );
  }

  Widget _buildRightWing(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    ViewState viewState,
    int activeGuidesCount,
  ) {
    return GestureDetector(
      onTapDown: (_) => _resetRightIdleTimer(),
      behavior: HitTestBehavior.translucent,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        child: _isRightCollapsed
            ? _buildCollapsedRightWing(context, cs, l10n)
            : _buildExpandedRightWing(context, cs, l10n, viewState, activeGuidesCount),
      ),
    );
  }

  Widget _buildCollapsedLeftWing(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return ClipRRect(
      key: const ValueKey('collapsed_left_wing'),
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: _expandLeftWing,
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
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
            child: Tooltip(
              message: l10n.appMenuTooltip,
              child: Icon(
                Icons.tune,
                size: 20,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedLeftWing(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return BlocBuilder<DocumentCubit, DocumentState>(
      key: const ValueKey('expanded_left_wing'),
      builder: (context, docState) {
        final cubit = context.read<DocumentCubit>();
        final canUndo = docState.canUndo;
        final canRedo = docState.canRedo;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Drawer / Controls Trigger
                  IconButton(
                    icon: const Icon(Icons.tune, size: 18),
                    tooltip: l10n.appMenuTooltip,
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _openDrawerOrMenu,
                    color: cs.primary,
                    visualDensity: VisualDensity.compact,
                  ),

                  // Micro Divider
                  SizedBox(
                    height: 16,
                    child: VerticalDivider(
                      width: 6,
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),

                  // 2. Undo Quick Action
                  IconButton(
                    icon: const Icon(Icons.undo, size: 18),
                    tooltip: l10n.undo,
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: canUndo
                        ? () {
                            _resetLeftIdleTimer();
                            cubit.undo();
                          }
                        : null,
                    color: canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.30),
                    visualDensity: VisualDensity.compact,
                  ),

                  // 3. Redo Quick Action
                  IconButton(
                    icon: const Icon(Icons.redo, size: 18),
                    tooltip: l10n.redo,
                    padding: const EdgeInsets.all(4.0),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: canRedo
                        ? () {
                            _resetLeftIdleTimer();
                            cubit.redo();
                          }
                        : null,
                    color: canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.30),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedRightWing(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    return ListenableBuilder(
      key: const ValueKey('collapsed_right_wing'),
      listenable: widget.transformationController,
      builder: (context, _) {
        final currentScale = widget.transformationController.value.row0[0];

        return ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 48.0,
              constraints: const BoxConstraints(minWidth: 48.0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
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
              child: _CollapsedScrubbableChip(
                currentScale: currentScale,
                onScrub: (scale) => _setScale(scale),
                onResetIdle: _resetRightIdleTimer,
                onTap: _expandRightWing,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandedRightWing(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    ViewState viewState,
    int activeGuidesCount,
  ) {
    final isTelemetryActive = widget.cursorPosition != null;

    return ClipRRect(
      key: const ValueKey('expanded_right_wing'),
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: isTelemetryActive
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outlineVariant.withValues(alpha: 0.35),
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isTelemetryActive
                ? _buildTelemetryContent(context, cs, widget.cursorPosition!)
                : _buildCameraContent(context, cs, l10n, activeGuidesCount),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraContent(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    int activeGuidesCount,
  ) {
    return ListenableBuilder(
      key: const ValueKey('camera_controls_cluster'),
      listenable: widget.transformationController,
      builder: (context, _) {
        final currentScale = widget.transformationController.value.row0[0];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Zoom Stepper (-) Button
            IconButton(
              icon: const Icon(Icons.remove, size: 16),
              tooltip: l10n.zoomOut,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _stepZoom(0.85),
              color: cs.onSurface,
              visualDensity: VisualDensity.compact,
            ),

            // 2. Real-time Scrubbable Scale Readout & Presets Dropdown
            _ScrubbableZoomChip(
              currentScale: currentScale,
              onScrub: (scale) => _setScale(scale),
              onResetIdle: _resetRightIdleTimer,
              onPresetSelected: (preset) {
                _resetRightIdleTimer();
                widget.onZoomPreset(preset);
              },
              onScaleSelected: (scale) {
                _resetRightIdleTimer();
                _setScale(scale);
              },
            ),

            // 3. Zoom Stepper (+) Button
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              tooltip: l10n.zoomIn,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _stepZoom(1.18),
              color: cs.onSurface,
              visualDensity: VisualDensity.compact,
            ),

            // Micro Divider
            SizedBox(
              height: 16,
              child: VerticalDivider(
                width: 6,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),

            // 4. Overlay Guides Action Button
            IconButton(
              icon: Icon(
                activeGuidesCount > 0
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              tooltip: l10n.guides,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => _showGuidesSheet(context),
              color: activeGuidesCount > 0 ? cs.primary : cs.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTelemetryContent(BuildContext context, ColorScheme cs, Offset pos) {
    final config = context.watch<DocumentCubit>().state.config;
    const double lpmm = 96 / 25.4;
    final double xMm = pos.dx / lpmm;
    final double yMm = pos.dy / lpmm;

    final bool onPaper = xMm >= 0 &&
        xMm <= config.effectiveWidth &&
        yMm >= 0 &&
        yMm <= config.effectiveHeight;

    return Padding(
      key: const ValueKey('cad_telemetry_dock'),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.center_focus_strong_rounded,
            size: 14,
            color: cs.primary,
          ),
          const SizedBox(width: 4.0),
          Text(
            'X',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 3.0),
          Text(
            UnitFormatter.formatMm(xMm, includeUnit: false),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: cs.onSurface,
            ),
          ),
          Container(
            height: 12,
            width: 1.0,
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            color: cs.outlineVariant.withValues(alpha: 0.4),
          ),
          Text(
            'Y',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 3.0),
          Text(
            UnitFormatter.formatMm(yMm, includeUnit: false),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: cs.onSurface,
            ),
          ),
          const SizedBox(width: 2.0),
          Text(
            'mm',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 5.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.5),
            decoration: BoxDecoration(
              color: onPaper
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.0),
              border: Border.all(
                color: onPaper
                    ? Colors.green.withValues(alpha: 0.5)
                    : Colors.amber.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Text(
              onPaper ? 'PAPER' : 'MARGIN',
              style: TextStyle(
                fontSize: 8.0,
                fontWeight: FontWeight.w800,
                color: onPaper ? Colors.green : Colors.amber,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive scrubbable zoom chip that supports analog horizontal scrubbing with haptics
/// and quick-tapping to reveal standard zoom presets.
class _ScrubbableZoomChip extends StatefulWidget {
  const _ScrubbableZoomChip({
    required this.currentScale,
    required this.onScrub,
    required this.onResetIdle,
    required this.onPresetSelected,
    required this.onScaleSelected,
  });

  final double currentScale;
  final ValueChanged<double> onScrub;
  final VoidCallback onResetIdle;
  final ValueChanged<ZoomPreset> onPresetSelected;
  final ValueChanged<double> onScaleSelected;

  @override
  State<_ScrubbableZoomChip> createState() => _ScrubbableZoomChipState();
}

class _ScrubbableZoomChipState extends State<_ScrubbableZoomChip> {
  bool _isScrubbing = false;
  double _dragStartScale = 1.0;
  double _dragCumulativeDelta = 0.0;
  int _lastHapticTick = 0;

  void _onPanStart(DragStartDetails details) {
    widget.onResetIdle();
    _dragStartScale = widget.currentScale;
    _dragCumulativeDelta = 0.0;
    _lastHapticTick = (widget.currentScale * 10).round();
    setState(() {
      _isScrubbing = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    widget.onResetIdle();
    // Bi-directional scrub: Up (-dy) and Right (+dx) zoom in; Down (+dy) and Left (-dx) zoom out
    _dragCumulativeDelta += (details.delta.dx - details.delta.dy);
    // Logarithmic scale sensitivity: 180px displaces zoom by 2x / 0.5x
    final newScale = (_dragStartScale * math.pow(2.0, _dragCumulativeDelta / 180.0))
        .clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);

    final currentTick = (newScale * 10).round();
    if (currentTick != _lastHapticTick) {
      _lastHapticTick = currentTick;
      HapticFeedback.selectionClick();
    }

    widget.onScrub(newScale.toDouble());
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onResetIdle();
    setState(() {
      _isScrubbing = false;
    });
  }

  void _showPresetsMenu(BuildContext context) {
    widget.onResetIdle();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final buttonPosition = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = renderBox.size;
    final cs = Theme.of(context).colorScheme;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          buttonPosition + const Offset(0, -220),
          buttonPosition + Offset(buttonSize.width, 0),
        ),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          onTap: () => widget.onScaleSelected(0.25),
          child: const Text('25%'),
        ),
        PopupMenuItem(
          onTap: () => widget.onScaleSelected(0.50),
          child: const Text('50%'),
        ),
        PopupMenuItem(
          onTap: () => widget.onScaleSelected(0.75),
          child: const Text('75%'),
        ),
        PopupMenuItem(
          onTap: () => widget.onScaleSelected(1.00),
          child: const Text('100% (Actual)'),
        ),
        PopupMenuItem(
          onTap: () => widget.onScaleSelected(1.50),
          child: const Text('150%'),
        ),
        PopupMenuItem(
          onTap: () => widget.onScaleSelected(2.00),
          child: const Text('200%'),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            widget.onResetIdle();
            widget.onPresetSelected(ZoomPreset.fitScreen);
          },
          child: Row(
            children: [
              Icon(Icons.fit_screen_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Fit to Page'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            widget.onResetIdle();
            widget.onPresetSelected(ZoomPreset.fitWidth);
          },
          child: Row(
            children: [
              Icon(Icons.width_wide_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Fit to Width'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      key: const ValueKey('scrubbable_zoom_chip'),
      onTap: () => _showPresetsMenu(context),
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () {
        setState(() {
          _isScrubbing = false;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: 'Tap for presets, drag to scrub zoom',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: _isScrubbing
                ? cs.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isScrubbing)
                Icon(Icons.chevron_left, size: 12, color: cs.primary.withValues(alpha: 0.8)),
              Text(
                UnitFormatter.formatPercent(widget.currentScale),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: -0.2,
                ),
              ),
              if (_isScrubbing)
                Icon(Icons.chevron_right, size: 12, color: cs.primary.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact scrubbable zoom chip for the collapsed right HUD.
/// Dragging horizontally scrubs the zoom with haptics; tapping expands to full controls.
class _CollapsedScrubbableChip extends StatefulWidget {
  const _CollapsedScrubbableChip({
    required this.currentScale,
    required this.onScrub,
    required this.onResetIdle,
    required this.onTap,
  });

  final double currentScale;
  final ValueChanged<double> onScrub;
  final VoidCallback onResetIdle;
  final VoidCallback onTap;

  @override
  State<_CollapsedScrubbableChip> createState() => _CollapsedScrubbableChipState();
}

class _CollapsedScrubbableChipState extends State<_CollapsedScrubbableChip> {
  bool _isScrubbing = false;
  bool _isActive = true;
  Timer? _activeTimer;
  double _dragStartScale = 1.0;
  double _dragCumulativeDelta = 0.0;
  int _lastHapticTick = 0;

  @override
  void initState() {
    super.initState();
    _startActiveCountdown();
  }

  @override
  void didUpdateWidget(_CollapsedScrubbableChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.currentScale - widget.currentScale).abs() > 0.001) {
      _markActive();
    }
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    super.dispose();
  }

  void _markActive() {
    _activeTimer?.cancel();
    if (!_isActive) {
      setState(() {
        _isActive = true;
      });
    }
    _startActiveCountdown();
  }

  void _startActiveCountdown() {
    _activeTimer?.cancel();
    _activeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isActive = false;
        });
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    widget.onResetIdle();
    _markActive();
    _dragStartScale = widget.currentScale;
    _dragCumulativeDelta = 0.0;
    _lastHapticTick = (widget.currentScale * 10).round();
    setState(() {
      _isScrubbing = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    widget.onResetIdle();
    _markActive();
    // Bi-directional scrub: Up (-dy) and Right (+dx) zoom in; Down (+dy) and Left (-dx) zoom out
    _dragCumulativeDelta += (details.delta.dx - details.delta.dy);
    final newScale = (_dragStartScale * math.pow(2.0, _dragCumulativeDelta / 180.0))
        .clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);

    final currentTick = (newScale * 10).round();
    if (currentTick != _lastHapticTick) {
      _lastHapticTick = currentTick;
      HapticFeedback.selectionClick();
    }

    widget.onScrub(newScale.toDouble());
  }

  void _onPanEnd(DragEndDetails details) {
    widget.onResetIdle();
    _startActiveCountdown();
    setState(() {
      _isScrubbing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isInteracting = _isScrubbing || _isActive;

    // Visual balance:
    // While interacting: percent is vibrant, magnifier is subtle watermark.
    // A few seconds after being left alone: percent softens, magnifier gets more visible.
    final magnifierOpacity = _isScrubbing
        ? 0.08
        : isInteracting
            ? 0.18
            : 0.46;

    final textColor = isInteracting
        ? cs.primary
        : cs.onSurfaceVariant.withValues(alpha: 0.65);

    return GestureDetector(
      key: const ValueKey('collapsed_scrubbable_chip'),
      onTap: widget.onTap,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () {
        _startActiveCountdown();
        setState(() {
          _isScrubbing = false;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: 'Tap to expand, drag to scrub zoom',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: _isScrubbing
                ? cs.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background magnifier watermark with smooth opacity transition
              AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                opacity: magnifierOpacity,
                child: Icon(
                  Icons.search,
                  size: 26,
                  color: cs.primary,
                ),
              ),

              // Foreground percentage readout & scrub indicators with smooth text style transition
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isScrubbing)
                    Icon(Icons.chevron_left, size: 10, color: cs.primary.withValues(alpha: 0.8)),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isInteracting ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                    child: Text(
                      UnitFormatter.formatPercent(widget.currentScale),
                    ),
                  ),
                  if (_isScrubbing)
                    Icon(Icons.chevron_right, size: 10, color: cs.primary.withValues(alpha: 0.8)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileGuidesSheet extends StatelessWidget {
  const _MobileGuidesSheet({
    required this.viewState,
    required this.viewCubit,
  });

  final ViewState viewState;
  final ViewCubit viewCubit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.guides,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const Divider(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MobileGuideTile(
                    label: l10n.mouseWings,
                    value: viewState.isGuideActive(GuideType.rulerWings),
                    onChanged: (v) => viewCubit.toggleGuide(GuideType.rulerWings, v),
                  ),
                  _MobileGuideTile(
                    label: l10n.paperEdges,
                    value: viewState.isGuideActive(GuideType.paperEdges),
                    onChanged: (v) => viewCubit.toggleGuide(GuideType.paperEdges, v),
                  ),
                  _MobileGuideTile(
                    label: l10n.paperCenters,
                    value: viewState.isGuideActive(GuideType.paperCenters),
                    onChanged: (v) => viewCubit.toggleGuide(GuideType.paperCenters, v),
                  ),
                  _MobileGuideTile(
                    label: l10n.documentMargins,
                    value: viewState.isGuideActive(GuideType.margins),
                    onChanged: (v) => viewCubit.toggleGuide(GuideType.margins, v),
                  ),
                  _MobileGuideTile(
                    label: l10n.staffBounds,
                    value: viewState.isGuideActive(GuideType.staffBounds),
                    onChanged: (v) => viewCubit.toggleGuide(GuideType.staffBounds, v),
                  ),
                  const Divider(height: 16),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.straighten, size: 18, color: cs.primary),
                    title: Text(
                      l10n.actualSize,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      l10n.physicalDensity,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    onTap: () {
                      Navigator.of(context).maybePop();
                      showCalibrationDialog(context, viewCubit);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileGuideTile extends StatelessWidget {
  const _MobileGuideTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
