// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/unit_formatter.dart';
import '../../logic/document/document_cubit.dart';
import '../../logic/document/document_state.dart';
import '../widgets/common/integrated_scale_control.dart';
import '../widgets/mobile/conductor_drawer.dart';
import '../widgets/mobile/conductor_toolbar.dart';
import '../widgets/mobile/mobile_canvas_area.dart';
import '../widgets/mobile/mobile_top_bar.dart';

/// Mobile Editor Screen implementing Proposal B ("Conductor's Baton").
/// Features a full-bleed light canvas, 40px ultra-minimal header, floating frosted glass baton toolbar,
/// full-height side drawer, and top-anchored real-time glassmorphic coordinate HUD bar on long-press & drag.
class MobileEditorScreen extends StatefulWidget {
  const MobileEditorScreen({super.key});

  @override
  State<MobileEditorScreen> createState() => _MobileEditorScreenState();
}

class _MobileEditorScreenState extends State<MobileEditorScreen> {
  final TransformationController _transformationController =
      TransformationController();
  final ValueNotifier<Offset?> _cursorNotifier = ValueNotifier(null);
  final GlobalKey<MobileCanvasAreaState> _canvasKey = GlobalKey();

  Offset? _longPressPos;
  Timer? _longPressDismissTimer;
  bool _batonVisible = true;
  Timer? _canvasGestureDebounce;

  void _triggerFitZoom() {
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    _canvasKey.currentState?.applyZoomPreset(isPortrait ? ZoomPreset.fitWidth : ZoomPreset.fitScreen);
  }

  void _onZoomPresetSelected(ZoomPreset preset) {
    _canvasKey.currentState?.applyZoomPreset(preset);
  }

  void _handleLongPressStart(Offset localPosition) {
    _longPressDismissTimer?.cancel();
    HapticFeedback.selectionClick();
    final matrix = _transformationController.value;
    _cursorNotifier.value = MatrixUtils.transformPoint(matrix, localPosition);
    setState(() {
      _longPressPos = localPosition;
    });
  }

  void _handleLongPressMove(Offset localPosition) {
    _longPressDismissTimer?.cancel();
    final matrix = _transformationController.value;
    _cursorNotifier.value = MatrixUtils.transformPoint(matrix, localPosition);
    setState(() {
      _longPressPos = localPosition;
    });
  }

  void _handleLongPressEnd() {
    _longPressDismissTimer?.cancel();
    _longPressDismissTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _cursorNotifier.value = null;
        setState(() {
          _longPressPos = null;
        });
      }
    });
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _canvasGestureDebounce?.cancel();
    if (_batonVisible) {
      setState(() {
        _batonVisible = false;
      });
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    _canvasGestureDebounce?.cancel();
    _canvasGestureDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _batonVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _longPressDismissTimer?.cancel();
    _canvasGestureDebounce?.cancel();
    _transformationController.dispose();
    _cursorNotifier.dispose();
    super.dispose();
  }

  Widget _buildTopCoordinateHUD(BuildContext context, Offset pos) {
    final cs = Theme.of(context).colorScheme;
    final config = context.watch<DocumentCubit>().state.config;

    const double lpmm = 96 / 25.4; // Pixels per millimeter
    final double xMm = pos.dx / lpmm;
    final double yMm = pos.dy / lpmm;

    final bool onPaper = xMm >= 0 &&
        xMm <= config.effectiveWidth &&
        yMm >= 0 &&
        yMm <= config.effectiveHeight;

    return Center(
      child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.center_focus_strong_rounded,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'X: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    UnitFormatter.formatMm(xMm),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: cs.onSurface,
                    ),
                  ),
                  Container(
                    height: 14,
                    width: 1.0,
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                  Text(
                    'Y: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    UnitFormatter.formatMm(yMm),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  // Status badge (Paper vs Margin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: onPaper
                          ? cs.primaryContainer.withValues(alpha: 0.85)
                          : cs.tertiaryContainer.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: onPaper ? cs.primary : cs.tertiary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          onPaper ? 'PAPER' : 'MARGIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: onPaper
                                ? cs.onPrimaryContainer
                                : cs.onTertiaryContainer,
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
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentCubit, DocumentState>(
      listenWhen: (previous, current) =>
          previous.config.effectiveWidth != current.config.effectiveWidth ||
          previous.config.effectiveHeight != current.config.effectiveHeight,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _triggerFitZoom();
        });
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          drawerEdgeDragWidth: 24.0,
          appBar: const MobileTopBar(),
          drawer: ConductorDrawer(
            transformationController: _transformationController,
            onZoomPreset: _onZoomPresetSelected,
          ),
          body: Stack(
            children: [
              // Layer 1: Manuscript Canvas Area
              Positioned.fill(
                child: MobileCanvasArea(
                  key: _canvasKey,
                  transformationController: _transformationController,
                  cursorNotifier: _cursorNotifier,
                  bottomPadding: 0.0,
                  onLongPressStartCanvas: _handleLongPressStart,
                  onLongPressMoveCanvas: _handleLongPressMove,
                  onLongPressEndCanvas: _handleLongPressEnd,
                  onInteractionStart: _onInteractionStart,
                  onInteractionEnd: _onInteractionEnd,
                ),
              ),

              // Layer 2: Aesthetic Top Glassmorphic Coordinate HUD
              Positioned(
                top: 12.0,
                left: 16.0,
                right: 16.0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, -0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: _longPressPos != null
                      ? KeyedSubtree(
                          key: const ValueKey('top_coord_hud_active'),
                          child: _buildTopCoordinateHUD(context, _longPressPos!),
                        )
                      : const SizedBox.shrink(key: ValueKey('top_coord_hud_idle')),
                ),
              ),

              // Layer 3: Floating Conductor Baton Toolbar (Bottom Center)
              Positioned(
                bottom: 20.0 + MediaQuery.paddingOf(context).bottom,
                left: 0.0,
                right: 0.0,
                child: Center(
                  child: ConductorToolbar(
                    transformationController: _transformationController,
                    onZoomPreset: _onZoomPresetSelected,
                    isVisible: _batonVisible,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
