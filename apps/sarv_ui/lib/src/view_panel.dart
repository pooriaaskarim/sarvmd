import 'package:flutter/material.dart';
import 'theme/app_metrics.dart';
import 'components/inputs/section_header.dart';
import 'components/inputs/precision_slider.dart';
import 'components/inputs/guide_toggle.dart';

import 'view_notifier.dart';

class ViewPanel extends StatelessWidget {
  const ViewPanel({
    super.key,
    required this.viewNotifier,
    required this.transformationController,
  });

  final ViewNotifier viewNotifier;
  final TransformationController transformationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.paddingLarge),
              children: [
                const SizedBox(height: 48),
                Text(
                  'VIEW',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const SectionHeader(title: 'Theme'),
                ListenableBuilder(
                  listenable: viewNotifier,
                  builder: (context, _) {
                    IconData iconData;
                    String tooltip;
                    if (viewNotifier.themeMode == ThemeMode.system) {
                      iconData = Icons.brightness_auto;
                      tooltip = 'System Theme';
                    } else if (viewNotifier.themeMode == ThemeMode.dark) {
                      iconData = Icons.dark_mode;
                      tooltip = 'Dark Theme';
                    } else {
                      iconData = Icons.light_mode;
                      tooltip = 'Light Theme';
                    }

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: tooltip,
                        child: IconButton(
                          icon: Icon(iconData,
                              color: Theme.of(context).colorScheme.primary),
                          onPressed: viewNotifier.toggleThemeMode,
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Divider(
                    color: Theme.of(context).colorScheme.outline, height: 32),
                const SectionHeader(title: 'Zoom'),
                ListenableBuilder(
                  listenable: transformationController,
                  builder: (context, _) {
                    final currentZoom =
                        transformationController.value.getMaxScaleOnAxis();
                    return ZoomSliderControls(
                      value: currentZoom.clamp(0.1, 4.0),
                      min: 0.1,
                      max: 4.0,
                      onChanged: (v) {
                        final t =
                            transformationController.value.getTranslation();
                        transformationController.value =
                            Matrix4.translationValues(t.x, t.y, 0.0)
                              ..multiply(Matrix4.diagonal3Values(v, v, 1.0));
                      },
                    );
                  },
                ),
                Divider(
                    color: Theme.of(context).colorScheme.outline, height: 32),
                const SectionHeader(title: 'Guides'),
                ListenableBuilder(
                  listenable: viewNotifier,
                  builder: (context, _) {
                    return Column(
                      children: [
                        GuideToggle(
                          label: 'Mouse Wings',
                          value:
                              viewNotifier.isGuideActive(GuideType.rulerWings),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.rulerWings, v ?? false),
                        ),
                        GuideToggle(
                          label: 'Paper Edges',
                          value:
                              viewNotifier.isGuideActive(GuideType.paperEdges),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.paperEdges, v ?? false),
                        ),
                        GuideToggle(
                          label: 'Paper Centers',
                          value: viewNotifier
                              .isGuideActive(GuideType.paperCenters),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.paperCenters, v ?? false),
                        ),
                        GuideToggle(
                          label: 'Document Margins',
                          value: viewNotifier.isGuideActive(GuideType.margins),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.margins, v ?? false),
                        ),
                        GuideToggle(
                          label: 'Staff Bounds',
                          value:
                              viewNotifier.isGuideActive(GuideType.staffBounds),
                          onChanged: (v) => viewNotifier.toggleGuide(
                              GuideType.staffBounds, v ?? false),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
