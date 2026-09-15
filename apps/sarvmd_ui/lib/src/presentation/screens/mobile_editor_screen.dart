// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/document/document_cubit.dart';
import '../../logic/document/document_state.dart';
import '../widgets/common/integrated_scale_control.dart';
import '../widgets/mobile/conductor_drawer.dart';
import '../widgets/mobile/conductor_toolbar.dart';
import '../widgets/mobile/mobile_canvas_area.dart';
import '../widgets/mobile/mobile_top_bar.dart';

/// Mobile Editor Screen implementing Proposal B ("Conductor's Baton").
/// Features a full-bleed light canvas, 40px ultra-minimal header, floating frosted glass baton toolbar,
/// and full-height side drawer.
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

  void _triggerFitZoom() {
    _canvasKey.currentState?.applyZoomPreset(ZoomPreset.fitScreen);
  }

  void _onZoomPresetSelected(ZoomPreset preset) {
    _canvasKey.currentState?.applyZoomPreset(preset);
  }

  void _handleLongPressCanvas(Offset localPosition) {
    setState(() {
      _longPressPos = localPosition;
    });

    // Auto-dismiss ruler tooltip after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _longPressPos == localPosition) {
        setState(() {
          _longPressPos = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _cursorNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                bottomPadding: 64.0,
                onLongPressCanvas: _handleLongPressCanvas,
              ),
            ),

            // Layer 2: Long-press Measurement Tooltip
            if (_longPressPos != null)
              Positioned(
                left: (_longPressPos!.dx - 60).clamp(16.0, MediaQuery.sizeOf(context).width - 140),
                top: (_longPressPos!.dy - 50).clamp(16.0, MediaQuery.sizeOf(context).height - 100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${(_longPressPos!.dx / (96 / 25.4)).toStringAsFixed(1)} mm, ${(_longPressPos!.dy / (96 / 25.4)).toStringAsFixed(1)} mm',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),

            // Layer 3: Floating Conductor Baton Toolbar (Bottom Center)
            Positioned(
              bottom: 20.0 + MediaQuery.paddingOf(context).bottom,
              left: 0.0,
              right: 0.0,
              child: Center(
                child: ConductorToolbar(
                  onFitZoom: _triggerFitZoom,
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
