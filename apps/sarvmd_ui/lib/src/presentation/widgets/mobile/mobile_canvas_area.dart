// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/layout_policy.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/view/view_cubit.dart';
import '../canvas/preview_canvas.dart';
import '../canvas/ruler_box.dart';
import '../common/integrated_scale_control.dart';

/// Touch & gesture optimized interactive mobile canvas area for SarvMD manuscript rendering.
class MobileCanvasArea extends StatefulWidget {
  const MobileCanvasArea({
    super.key,
    required this.transformationController,
    required this.cursorNotifier,
    this.bottomPadding = 0,
    this.onLongPressCanvas,
    this.onLongPressStartCanvas,
    this.onLongPressMoveCanvas,
    this.onLongPressEndCanvas,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  final TransformationController transformationController;
  final ValueNotifier<Offset?> cursorNotifier;
  final double bottomPadding;
  final void Function(Offset localPosition)? onLongPressCanvas;
  final void Function(Offset localPosition)? onLongPressStartCanvas;
  final void Function(Offset localPosition)? onLongPressMoveCanvas;
  final VoidCallback? onLongPressEndCanvas;
  final void Function(ScaleStartDetails details)? onInteractionStart;
  final void Function(ScaleEndDetails details)? onInteractionEnd;

  @override
  State<MobileCanvasArea> createState() => MobileCanvasAreaState();
}

class MobileCanvasAreaState extends State<MobileCanvasArea> {
  BoxConstraints? _lastConstraints;
  bool _hasCentered = false;
  ZoomPreset _currentPreset = ZoomPreset.fitWidth;

  // Track pointers for 2-finger tap detection (Undo)
  int _activePointers = 0;
  DateTime? _twoPointerDownTime;

  void toggleFitZoom() {
    final next = _currentPreset == ZoomPreset.fitWidth
        ? ZoomPreset.fitScreen
        : ZoomPreset.fitWidth;
    applyZoomPreset(next);
  }

  void applyZoomPreset(ZoomPreset preset) {
    _currentPreset = preset;
    final constraints = _lastConstraints;
    if (constraints == null) return;

    final config = context.read<DocumentCubit>().state.config;
    final viewState = context.read<ViewCubit>().state;

    const double lpmm = 96 / 25.4; // canvas internal scale (px per mm)
    final paperWidth = config.effectiveWidth * lpmm;
    final paperHeight = config.effectiveHeight * lpmm;

    const double rulerSize = 25.0;
    const double padding = 24.0;
    final canvasWidth = constraints.maxWidth - rulerSize;
    final canvasHeight = constraints.maxHeight - rulerSize - widget.bottomPadding;
    final availableWidth = (canvasWidth - padding * 2).clamp(1.0, double.infinity);
    final availableHeight = (canvasHeight - padding * 2).clamp(1.0, double.infinity);

    double fitScale;

    switch (preset) {
      case ZoomPreset.actualSize:
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

    widget.transformationController.value = Matrix4.translationValues(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(fitScale, fitScale, 1.0));
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers++;
    if (_activePointers == 2) {
      _twoPointerDownTime = DateTime.now();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_activePointers == 2 && _twoPointerDownTime != null) {
      final elapsed = DateTime.now().difference(_twoPointerDownTime!);
      if (elapsed.inMilliseconds < 300) {
        // Quick 2-finger tap detected -> Trigger Undo
        final cubit = context.read<DocumentCubit>();
        if (cubit.state.canUndo) {
          cubit.undo();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Undo (2-finger tap)'),
              duration: Duration(milliseconds: 1000),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    _activePointers = (_activePointers - 1).clamp(0, 10);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final documentCubit = context.watch<DocumentCubit>();
    final docState = documentCubit.state;
    final configState = docState.config;
    final viewState = context.watch<ViewCubit>().state;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _lastConstraints = constraints;
          if (!_hasCentered) {
            _hasCentered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
                applyZoomPreset(isPortrait ? ZoomPreset.fitWidth : ZoomPreset.fitScreen);
              }
            });
          }

          return CanvasStrictScope(
            child: RulerBox(
              transformationController: widget.transformationController,
              viewState: viewState,
              cursorNotifier: widget.cursorNotifier,
              paperSizeMm: Size(
                configState.effectiveWidth,
                configState.effectiveHeight,
              ),
              child: Listener(
                onPointerDown: _handlePointerDown,
                onPointerUp: _handlePointerUp,
                onPointerCancel: _handlePointerCancel,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: widget.transformationController,
                        boundaryMargin: const EdgeInsets.all(100000),
                        minScale: ScaleMetrics.minZoom,
                        maxScale: ScaleMetrics.maxZoom,
                        constrained: false,
                        alignment: Alignment.topLeft,
                        onInteractionStart: widget.onInteractionStart,
                        onInteractionEnd: widget.onInteractionEnd,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: toggleFitZoom,
                          onLongPressStart: (details) {
                            if (widget.onLongPressStartCanvas != null) {
                              widget.onLongPressStartCanvas!(details.localPosition);
                            } else if (widget.onLongPressCanvas != null) {
                              widget.onLongPressCanvas!(details.localPosition);
                            }
                          },
                          onLongPressMoveUpdate: widget.onLongPressMoveCanvas != null
                              ? (details) => widget.onLongPressMoveCanvas!(details.localPosition)
                              : null,
                          onLongPressEnd: widget.onLongPressEndCanvas != null
                              ? (_) => widget.onLongPressEndCanvas!()
                              : null,
                          onLongPressCancel: widget.onLongPressEndCanvas != null
                              ? () => widget.onLongPressEndCanvas!()
                              : null,
                          child: PreviewCanvas(
                            layout: documentCubit.layout,
                            viewState: viewState,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
