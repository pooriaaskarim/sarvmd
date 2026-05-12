import 'package:flutter/material.dart';
import '../../view_notifier.dart';
import '../dialogs/calibration_dialog.dart';
import '../../theme/app_metrics.dart';

enum ZoomPreset {
  actualSize,
  fitScreen,
  fitWidth,
}

class IntegratedScaleControl extends StatelessWidget {
  const IntegratedScaleControl({
    super.key,
    required this.viewNotifier,
    required this.transformationController,
    required this.onZoomPreset,
  });

  final ViewNotifier viewNotifier;
  final TransformationController transformationController;
  final ValueChanged<ZoomPreset> onZoomPreset;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewNotifier, transformationController]),
      builder: (context, _) {
        final currentZoom = transformationController.value.row0[0];
        final calibrationFactor = viewNotifier.calibrationFactor;
        final isDefault = (calibrationFactor - 1.0).abs() < 0.001;
        final effectivePpi = (calibrationFactor * 96).round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Row 1: Status & Calibration ─────────────────────────────
            _StatusHeader(
              currentZoom: currentZoom,
              effectivePpi: effectivePpi,
              isDefault: isDefault,
              onCalibrate: () => showCalibrationDialog(context, viewNotifier),
            ),
            const SizedBox(height: AppSpacing.itemGap),

            // ── Row 2: Preset Switcher ──────────────────────────────────
            _PresetSwitcher(
              currentZoom: currentZoom,
              calibrationFactor: calibrationFactor,
              onPreset: onZoomPreset,
            ),
            const SizedBox(height: AppSpacing.itemGap),

            // ── Row 3: Granular Slider ──────────────────────────────────
            _ZoomSlider(
              value: currentZoom,
              onChanged: (v) {
                final t = transformationController.value.getTranslation();
                transformationController.value =
                    Matrix4.translationValues(t.x, t.y, 0.0)
                      ..multiply(Matrix4.diagonal3Values(v, v, 1.0));
              },
            ),
          ],
        );
      },
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.currentZoom,
    required this.effectivePpi,
    required this.isDefault,
    required this.onCalibrate,
  });

  final double currentZoom;
  final int effectivePpi;
  final bool isDefault;
  final VoidCallback onCalibrate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large Zoom Percentage
        Text(
          '${(currentZoom * 100).round()}%',
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: cs.onSurface,
          ),
        ),

        // Calibration Status Chip
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCalibrate,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDefault
                    ? cs.onSurface.withValues(alpha: 0.05)
                    : cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDefault
                      ? cs.outlineVariant.withValues(alpha: 0.3)
                      : cs.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDefault ? Icons.straighten_rounded : Icons.verified_rounded,
                    size: 14,
                    color: isDefault ? cs.onSurfaceVariant : cs.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDefault ? 'Standard' : '$effectivePpi PPI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDefault ? cs.onSurfaceVariant : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetSwitcher extends StatelessWidget {
  const _PresetSwitcher({
    required this.currentZoom,
    required this.calibrationFactor,
    required this.onPreset,
  });

  final double currentZoom;
  final double calibrationFactor;
  final ValueChanged<ZoomPreset> onPreset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Determine which preset is "active" based on zoom level
    // Actual Size is active if zoom matches calibrationFactor
    final bool isActual = (currentZoom - calibrationFactor).abs() < 0.01;
    
    // For Page/Width we'd need more context to know if it's currently active,
    // so we'll just treat them as buttons for now, or keep "Actual" highlighted.
    
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PresetButton(
            label: 'Page',
            icon: Icons.fit_screen_rounded,
            isSelected: false, // Page/Width are transient targets
            onTap: () => onPreset(ZoomPreset.fitScreen),
          ),
          _PresetButton(
            label: 'Width',
            icon: Icons.width_full_rounded,
            isSelected: false,
            onTap: () => onPreset(ZoomPreset.fitWidth),
          ),
          _PresetButton(
            label: 'Actual',
            icon: Icons.zoom_in_map_rounded,
            isSelected: isActual,
            highlightColor: cs.primary,
            onTap: () => onPreset(ZoomPreset.actualSize),
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.highlightColor,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isSelected 
        ? (highlightColor ?? cs.primary) 
        : cs.onSurfaceVariant.withValues(alpha: 0.7);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  const _ZoomSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.onSurface.withValues(alpha: 0.1),
        thumbColor: cs.primary,
      ),
      child: Slider(
        value: value.clamp(ScaleMetrics.minZoom, ScaleMetrics.maxZoom),
        min: ScaleMetrics.minZoom,
        max: ScaleMetrics.maxZoom,
        onChanged: onChanged,
      ),
    );
  }
}
