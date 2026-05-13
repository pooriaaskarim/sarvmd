import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../theme/app_metrics.dart';
import 'dropdown_setting.dart';

class DocumentSettingsGroup extends StatelessWidget {
  const DocumentSettingsGroup({
    super.key,
    required this.pageSize,
    required this.onPageSizeChanged,
    required this.orientation,
    required this.onOrientationChanged,
  });

  final core.PageSize pageSize;
  final ValueChanged<core.PageSize> onPageSizeChanged;
  final core.PageOrientation orientation;
  final ValueChanged<core.PageOrientation> onOrientationChanged;

  @override
  Widget build(BuildContext context) => Column(
        spacing: 12.0,
        children: [
          DropdownSetting<core.PageSize>(
            value: pageSize,
            options: core.PageSize.values,
            onChanged: onPageSizeChanged,
          ),
          OrientationSwitcher(
            current: orientation,
            onChanged: onOrientationChanged,
          ),
        ],
      );
}

class OrientationSwitcher extends StatelessWidget {
  const OrientationSwitcher({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final core.PageOrientation current;
  final ValueChanged<core.PageOrientation> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int selectedIndex = current == core.PageOrientation.portrait ? 0 : 1;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: AppOpacities.border),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = (constraints.maxWidth) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
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
                  _OrientationOption(
                    icon: Icons.portrait_outlined,
                    activeIcon: Icons.portrait,
                    label: 'Portrait',
                    isSelected: current == core.PageOrientation.portrait,
                    onTap: () => onChanged(core.PageOrientation.portrait),
                  ),
                  _OrientationOption(
                    icon: Icons.landscape_outlined,
                    activeIcon: Icons.landscape,
                    label: 'Landscape',
                    isSelected: current == core.PageOrientation.landscape,
                    onTap: () => onChanged(core.PageOrientation.landscape),
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

class _OrientationOption extends StatelessWidget {
  const _OrientationOption({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  size: 16,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
