import 'package:flutter/material.dart';
import 'theme/app_metrics.dart';
import 'components/inputs/section_header.dart';
import 'components/inputs/precision_slider.dart';
import 'components/inputs/dropdown_setting.dart';
import 'components/inputs/segmented_setting.dart';
import 'components/specialized/profile_picker.dart';
import 'components/specialized/clef_config_widget.dart';
import 'components/specialized/zoom_feedback_overlay.dart';

import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'config_notifier.dart';
import 'preview_canvas.dart';

import 'ruler_box.dart';
import 'view_notifier.dart';
import 'view_panel.dart';

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

  void _fitToScreen() {
    final constraints = _lastConstraints;
    if (constraints == null) return;
    
    final double lpmm = 96 / 25.4;
    final paperWidth = _notifier.layout.config.pageSize.width * lpmm;
    final paperHeight = _notifier.layout.config.pageSize.height * lpmm;

    const padding = 40.0;
    final availableWidth = constraints.maxWidth - padding * 2;
    final availableHeight = constraints.maxHeight - padding * 2;
    
    final scaleX = availableWidth / paperWidth;
    final scaleY = availableHeight / paperHeight;
    final fitScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 4.0);

    final dx = (constraints.maxWidth - paperWidth * fitScale) / 2;
    final dy = (constraints.maxHeight - paperHeight * fitScale) / 2;

    _transformationController.value = Matrix4.translationValues(dx, dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(fitScale, fitScale, 1.0));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
              // Sidebar
              Container(
                width: 320,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.paddingLarge),
                        children: [
                          const SizedBox(height: 48),
                          const _Header(),
                          const SizedBox(height: AppSpacing.sectionGap),
                          const SectionHeader(title: 'Profiles'),
                          const SizedBox(height: AppSpacing.itemGapSmall),
                          ProfilePicker(
                            currentConfig: _notifier.config,
                            onProfileSelected: (p) => _notifier.applyProfile(p),
                          ),
                          Divider(
                              color: Theme.of(context).colorScheme.outline,
                              height: 32),
                          const SectionHeader(title: 'Document'),
                          const SizedBox(height: AppSpacing.itemGapSmall),
                          DropdownSetting<core.PageSize>(
                            value: _notifier.config.pageSize,
                            options: core.PageSize.values,
                            onChanged: (v) => _notifier.updatePageSize(v),
                          ),
                          const SizedBox(height: AppSpacing.paddingMedium),
                          SegmentedSetting<core.LayoutType>(
                            value: _notifier.config.layoutType,
                            options: core.LayoutType.values,
                            onChanged: (v) => _notifier.updateLayoutType(v),
                          ),
                          Divider(
                              color: Theme.of(context).colorScheme.outline,
                              height: 32),
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
                          Divider(
                              color: Theme.of(context).colorScheme.outline,
                              height: 32),
                          SectionHeader(
                            title: 'Spacing (mm)',
                            onReset: _notifier.resetSpacing,
                          ),
                          PrecisionSlider(
                            label: 'Line Gap',
                            value: _notifier.config.staffConfig.lineGapMm,
                            min: 1.0,
                            max: 3.0,
                            onChanged: (v) => _notifier.updateLineGap(v),
                          ),
                          PrecisionSlider(
                            label: 'System Gap',
                            value: _notifier.config.staffConfig.systemGapMm,
                            min: 5.0,
                            max: 30.0,
                            onChanged: (v) => _notifier.updateSystemGap(v),
                          ),
                          if (layout.config.layoutType ==
                              core.LayoutType.doubleLine)
                            PrecisionSlider(
                              label: 'Inter-staff Gap',
                              value:
                                  _notifier.config.staffConfig.interStaffGapMm,
                              min: 5.0,
                              max: 20.0,
                              onChanged: (v) =>
                                  _notifier.updateInterStaffGap(v),
                            ),
                          Divider(
                              color: Theme.of(context).colorScheme.outline,
                              height: 32),
                          SectionHeader(
                            title: 'Clefs & Symbols',
                            onReset: _notifier.resetClefs,
                          ),
                          ClefConfigWidget(
                            label: layout.config.layoutType ==
                                    core.LayoutType.doubleLine
                                ? 'Upper Staff'
                                : 'Staff Clef',
                            value: _notifier.config.primaryClef,
                            onChanged: (v) => _notifier.updatePrimaryClef(v),
                          ),
                          if (layout.config.layoutType ==
                              core.LayoutType.doubleLine) ...[
                            const SizedBox(height: AppSpacing.paddingMedium),
                            ClefConfigWidget(
                              label: 'Lower Staff',
                              value: _notifier.config.secondaryClef,
                              onChanged: (v) =>
                                  _notifier.updateSecondaryClef(v),
                            ),
                          ],
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
                          _fitToScreen();
                        });
                      }

                      return RulerBox(
                        transformationController: _transformationController,
                        viewNotifier: widget.viewNotifier,
                        cursorNotifier: _cursorNotifier,
                        paperSizeMm: Size(
                          layout.config.pageSize.width,
                          layout.config.pageSize.height,
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
                                  minScale: 0.1,
                                  maxScale: 4.0,
                                  constrained: false,
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // View Panel (Right)
              ViewPanel(
                viewNotifier: widget.viewNotifier,
                transformationController: _transformationController,
                onFitToScreen: () {
                  if (_lastConstraints != null) _fitToScreen();
                },
                configNotifier: _notifier,
                layoutGetter: () => _notifier.layout,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SARV',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        Text(
          'MANUSCRIPT DESIGNER',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
