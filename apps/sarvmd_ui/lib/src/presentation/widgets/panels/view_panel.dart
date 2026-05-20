import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_theme.dart';
import '../common/section_header.dart';
import '../common/integrated_scale_control.dart';
import '../common/guide_toggle.dart';
import '../animations/fade_in_slide.dart';
import 'export_panel.dart';
import '../../../logic/view/view_state.dart';
import '../../../logic/view/view_cubit.dart';

class ViewPanel extends StatelessWidget {
  const ViewPanel({
    super.key,
    required this.transformationController,
    required this.onZoomPreset,
  });

  final TransformationController transformationController;
  final ValueChanged<ZoomPreset> onZoomPreset;

  @override
  Widget build(BuildContext context) {
    final viewCubit = context.read<ViewCubit>();
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<ViewCubit, ViewState>(
              builder: (context, viewState) {
                return ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.paddingLarge),
                  children: [
                    const SizedBox(height: 48),
                    const FadeInSlide(
                      delay: 0,
                      child: Text(
                        'VIEW',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    const FadeInSlide(
                        delay: 1, child: SectionHeader(title: 'Appearance')),
                    FadeInSlide(
                      delay: 2,
                      child: _AppearanceSettings(
                        themeMode: viewState.themeMode,
                        accent: viewState.accent,
                        onThemeModeChanged: viewCubit.updateThemeMode,
                        onAccentChanged: viewCubit.updateAccent,
                      ),
                    ),
                    const FadeInSlide(
                      delay: 3,
                      child: Divider(height: 32),
                    ),
                    const FadeInSlide(
                        delay: 4, child: SectionHeader(title: 'Zoom')),
                    FadeInSlide(
                      delay: 5,
                      child: IntegratedScaleControl(
                        viewState: viewState,
                        viewCubit: viewCubit,
                        transformationController: transformationController,
                        onZoomPreset: onZoomPreset,
                      ),
                    ),
                    const FadeInSlide(
                      delay: 6,
                      child: Divider(height: 32),
                    ),
                    const FadeInSlide(
                      delay: 7,
                      child: SectionHeader(title: 'Notation Preview'),
                    ),
                    FadeInSlide(
                      delay: 8,
                      child: GuideToggle(
                        label: 'Show Music Score',
                        value: viewState.showNotation,
                        onChanged: (v) => viewCubit.toggleShowNotation(),
                      ),
                    ),
                    const FadeInSlide(
                      delay: 9,
                      child: Divider(height: 32),
                    ),
                    const FadeInSlide(
                        delay: 10, child: SectionHeader(title: 'Guides')),
                    FadeInSlide(
                      delay: 11,
                      child: Column(
                        children: [
                          GuideToggle(
                            label: 'Mouse Wings',
                            value:
                                viewState.isGuideActive(GuideType.rulerWings),
                            onChanged: (v) => viewCubit.toggleGuide(
                                GuideType.rulerWings, v ?? false),
                          ),
                          GuideToggle(
                            label: 'Paper Edges',
                            value:
                                viewState.isGuideActive(GuideType.paperEdges),
                            onChanged: (v) => viewCubit.toggleGuide(
                                GuideType.paperEdges, v ?? false),
                          ),
                          GuideToggle(
                            label: 'Paper Centers',
                            value:
                                viewState.isGuideActive(GuideType.paperCenters),
                            onChanged: (v) => viewCubit.toggleGuide(
                                GuideType.paperCenters, v ?? false),
                          ),
                          GuideToggle(
                            label: 'Document Margins',
                            value: viewState.isGuideActive(GuideType.margins),
                            onChanged: (v) => viewCubit.toggleGuide(
                                GuideType.margins, v ?? false),
                          ),
                          GuideToggle(
                            label: 'Staff Bounds',
                            value:
                                viewState.isGuideActive(GuideType.staffBounds),
                            onChanged: (v) => viewCubit.toggleGuide(
                                GuideType.staffBounds, v ?? false),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const FadeInSlide(
            delay: 12,
            child: ExportPanel(),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings({
    required this.themeMode,
    required this.accent,
    required this.onThemeModeChanged,
    required this.onAccentChanged,
  });

  final ThemeMode themeMode;
  final SarvAccent accent;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<SarvAccent> onAccentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThemeModeSwitcher(
          current: themeMode,
          onChanged: onThemeModeChanged,
        ),
        const SizedBox(height: AppSpacing.itemGap),
        _AccentPillPicker(
          selected: accent,
          onChanged: onAccentChanged,
        ),
      ],
    );
  }
}

class _ThemeModeSwitcher extends StatelessWidget {
  const _ThemeModeSwitcher({
    required this.current,
    required this.onChanged,
  });

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int selectedIndex = switch (current) {
      ThemeMode.light => 0,
      ThemeMode.dark => 1,
      ThemeMode.system => 2,
    };

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = (constraints.maxWidth) / 3;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: selectedIndex * segmentWidth,
                width: segmentWidth,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_outlined,
                    activeIcon: Icons.light_mode,
                    isSelected: current == ThemeMode.light,
                    onTap: () => onChanged(ThemeMode.light),
                  ),
                  _ThemeOption(
                    icon: Icons.dark_mode_outlined,
                    activeIcon: Icons.dark_mode,
                    isSelected: current == ThemeMode.dark,
                    onTap: () => onChanged(ThemeMode.dark),
                  ),
                  _ThemeOption(
                    icon: Icons.brightness_auto_outlined,
                    activeIcon: Icons.brightness_auto,
                    isSelected: current == ThemeMode.system,
                    onTap: () => onChanged(ThemeMode.system),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey(isSelected),
              size: 18,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccentPillPicker extends StatefulWidget {
  const _AccentPillPicker({
    required this.selected,
    required this.onChanged,
  });

  final SarvAccent selected;
  final ValueChanged<SarvAccent> onChanged;

  @override
  State<_AccentPillPicker> createState() => _AccentPillPickerState();
}

class _AccentPillPickerState extends State<_AccentPillPicker>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: SarvAccent.values.map((a) {
        final isSelected = a == widget.selected;
        return GestureDetector(
          onTap: () => widget.onChanged(a),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? a.pastelContainer
                  : a.seed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? a.primary : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: a.primary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? a.onPastelContainer
                        : a.primary.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                ),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: SizedBox(
                      width: isSelected ? null : 0,
                      child: isSelected
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                a.label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: a.onPastelContainer,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
