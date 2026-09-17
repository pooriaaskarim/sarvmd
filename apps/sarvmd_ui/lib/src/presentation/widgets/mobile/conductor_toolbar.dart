// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:ui';
import 'package:flutter/material.dart';
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

/// Single Unified Mobile HUD ("Conductor Baton") for SarvMD.
/// Combines drawer triggers, undo/redo, real-time zoom stepper/presets, and overlay guides into a single floating dock.
class ConductorToolbar extends StatelessWidget {
  const ConductorToolbar({
    super.key,
    required this.transformationController,
    required this.onZoomPreset,
  });

  final TransformationController transformationController;
  final ValueChanged<ZoomPreset> onZoomPreset;

  void _stepZoom(double factor) {
    final matrix = transformationController.value.clone();
    final currentScale = matrix.row0[0];
    final targetScale = (currentScale * factor)
        .clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom);
    final translation = matrix.getTranslation();

    transformationController.value =
        Matrix4.translationValues(translation.x, translation.y, 0.0)
          ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1.0));
  }

  void _setScale(double targetScale) {
    final matrix = transformationController.value.clone();
    final translation = matrix.getTranslation();

    transformationController.value =
        Matrix4.translationValues(translation.x, translation.y, 0.0)
          ..multiply(Matrix4.diagonal3Values(
            targetScale.clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom),
            targetScale.clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom),
            1.0,
          ));
  }

  void _showGuidesSheet(BuildContext context) {
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

    return BlocBuilder<DocumentCubit, DocumentState>(
      builder: (context, docState) {
        final cubit = context.read<DocumentCubit>();
        final canUndo = docState.canUndo;
        final canRedo = docState.canRedo;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30.0),
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
              child: ListenableBuilder(
                listenable: transformationController,
                builder: (context, _) {
                  final currentScale = transformationController.value.row0[0];

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Drawer / Controls Trigger
                      IconButton(
                        icon: const Icon(Icons.tune, size: 18),
                        tooltip: l10n.appMenuTooltip,
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        color: cs.primary,
                        visualDensity: VisualDensity.compact,
                      ),

                      // Divider
                      SizedBox(
                        height: 16,
                        child: VerticalDivider(
                          width: 8,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),

                      // 2. Undo Quick Action
                      IconButton(
                        icon: const Icon(Icons.undo, size: 18),
                        tooltip: l10n.undo,
                        onPressed: canUndo ? () => cubit.undo() : null,
                        color: canUndo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.30),
                        visualDensity: VisualDensity.compact,
                      ),

                      // 3. Redo Quick Action
                      IconButton(
                        icon: const Icon(Icons.redo, size: 18),
                        tooltip: l10n.redo,
                        onPressed: canRedo ? () => cubit.redo() : null,
                        color: canRedo ? cs.onSurface : cs.onSurface.withValues(alpha: 0.30),
                        visualDensity: VisualDensity.compact,
                      ),

                      // Divider
                      SizedBox(
                        height: 16,
                        child: VerticalDivider(
                          width: 8,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),

                      // 4. Zoom Stepper (-) Button
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        tooltip: l10n.zoomOut,
                        onPressed: () => _stepZoom(0.85),
                        color: cs.onSurface,
                        visualDensity: VisualDensity.compact,
                      ),

                      // 5. Real-time Scale Readout & Presets Dropdown
                      PopupMenuButton<void>(
                        tooltip: 'Zoom Presets',
                        offset: const Offset(0, -220),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            UnitFormatter.formatPercent(currentScale),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: () => _setScale(0.25),
                            child: const Text('25%'),
                          ),
                          PopupMenuItem(
                            onTap: () => _setScale(0.50),
                            child: const Text('50%'),
                          ),
                          PopupMenuItem(
                            onTap: () => _setScale(0.75),
                            child: const Text('75%'),
                          ),
                          PopupMenuItem(
                            onTap: () => _setScale(1.00),
                            child: const Text('100% (Actual)'),
                          ),
                          PopupMenuItem(
                            onTap: () => _setScale(1.50),
                            child: const Text('150%'),
                          ),
                          PopupMenuItem(
                            onTap: () => _setScale(2.00),
                            child: const Text('200%'),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            onTap: () => onZoomPreset(ZoomPreset.fitScreen),
                            child: Row(
                              children: [
                                Icon(Icons.fit_screen_outlined, size: 16, color: cs.primary),
                                const SizedBox(width: 8),
                                const Text('Fit to Page'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: () => onZoomPreset(ZoomPreset.fitWidth),
                            child: Row(
                              children: [
                                Icon(Icons.width_wide_outlined, size: 16, color: cs.primary),
                                const SizedBox(width: 8),
                                const Text('Fit to Width'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 6. Zoom Stepper (+) Button
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        tooltip: l10n.zoomIn,
                        onPressed: () => _stepZoom(1.18),
                        color: cs.onSurface,
                        visualDensity: VisualDensity.compact,
                      ),

                      // Divider
                      SizedBox(
                        height: 16,
                        child: VerticalDivider(
                          width: 8,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),

                      // 7. Overlay Guides Action Button
                      IconButton(
                        icon: Icon(
                          activeGuidesCount > 0
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        tooltip: l10n.guides,
                        onPressed: () => _showGuidesSheet(context),
                        color: activeGuidesCount > 0 ? cs.primary : cs.onSurfaceVariant,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
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
          const Divider(height: 16),
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
