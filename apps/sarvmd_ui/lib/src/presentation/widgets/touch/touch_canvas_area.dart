// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/layout_policy.dart';
import '../../../logic/document/document_cubit.dart';
import '../../../logic/view/view_cubit.dart';
import '../canvas/canvas_zoom_calculator.dart';
import '../canvas/preview_canvas.dart';
import '../canvas/ruler_box.dart';
import '../common/integrated_scale_control.dart';

/// Touch & gesture optimized interactive mobile canvas area for SarvMD manuscript rendering.
class TouchCanvasArea extends StatefulWidget {
  const TouchCanvasArea({
    super.key,
    required this.transformationController,
    required this.cursorNotifier,
    this.bottomPadding = 0,
    this.topSafeArea = 0.0,
    this.leftSafeArea = 0.0,
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
  final double topSafeArea;
  final double leftSafeArea;
  final void Function(Offset localPosition)? onLongPressCanvas;
  final void Function(Offset localPosition)? onLongPressStartCanvas;
  final void Function(Offset localPosition)? onLongPressMoveCanvas;
  final VoidCallback? onLongPressEndCanvas;
  final void Function(ScaleStartDetails details)? onInteractionStart;
  final void Function(ScaleEndDetails details)? onInteractionEnd;

  @override
  State<TouchCanvasArea> createState() => TouchCanvasAreaState();
}

class TouchCanvasAreaState extends State<TouchCanvasArea> {
  BoxConstraints? _lastConstraints;
  bool _hasCentered = false;
  ZoomPreset _currentPreset = ZoomPreset.fitWidth;

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

    final transform = CanvasZoomCalculator.compute(
      preset: preset,
      constraints: constraints,
      config: config,
      calibrationFactor: viewState.calibrationFactor,
      padding: 24.0,
      topSafeArea: widget.topSafeArea,
      leftSafeArea: widget.leftSafeArea,
      bottomPadding: widget.bottomPadding,
    );

    widget.transformationController.value = transform.matrix;
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
              showCoordinateHud: false,
              topSafeArea: widget.topSafeArea,
              leftSafeArea: widget.leftSafeArea,
              paperSizeMm: Size(
                configState.effectiveWidth,
                configState.effectiveHeight,
              ),
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
          );
        },
      ),
    );
  }
}
