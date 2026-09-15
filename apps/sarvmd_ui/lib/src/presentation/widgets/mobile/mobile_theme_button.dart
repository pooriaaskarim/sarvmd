// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../logic/view/view_cubit.dart';
import 'hold_drag_context_menu.dart';

sealed class ThemeMenuOption {
  const ThemeMenuOption();
}

class ModeOption extends ThemeMenuOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;
  const ModeOption(this.mode, this.label, this.icon);
}

class AccentOption extends ThemeMenuOption {
  final SarvAccent accent;
  const AccentOption(this.accent);
}

/// Double-rowed theme selection button (Mode + Accent) with dual interaction modes
/// (click popup & hold-drag selection across rows).
class MobileThemeButton extends StatelessWidget {
  const MobileThemeButton({super.key});

  static const List<ModeOption> _modeOptions = [
    ModeOption(ThemeMode.system, 'Auto', Icons.brightness_auto_rounded),
    ModeOption(ThemeMode.light, 'Light', Icons.light_mode_rounded),
    ModeOption(ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
  ];

  static final List<AccentOption> _accentOptions = SarvAccent.values
      .map((accent) => AccentOption(accent))
      .toList();

  static final List<ThemeMenuOption> _allOptions = [
    ..._modeOptions,
    ..._accentOptions,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewState = context.watch<ViewCubit>().state;

    final IconData modeIcon = switch (viewState.themeMode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };

    return HoldDragContextMenu<ThemeMenuOption>(
      items: _allOptions,
      onSelect: (option) {
        final viewCubit = context.read<ViewCubit>();
        if (option is ModeOption) {
          viewCubit.updateThemeMode(option.mode);
        } else if (option is AccentOption) {
          viewCubit.updateAccent(option.accent);
        }
      },
      buttonBuilder: (context, onTap) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                modeIcon,
                size: 16.0,
                color: cs.primary,
              ),
              const SizedBox(width: 6.0),
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: viewState.accent.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
      menuBuilder: (context, hoveredValue, itemKeys, onSelect) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 16.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1 Header: Theme Mode
              Padding(
                padding: const EdgeInsets.only(left: 6.0, bottom: 4.0, top: 2.0),
                child: Text(
                  'MODE',
                  style: TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _modeOptions.map((opt) {
                  final isCurrent = viewState.themeMode == opt.mode;
                  final isHovered = hoveredValue == opt;

                  return GestureDetector(
                    onTap: () => onSelect(opt),
                    child: AnimatedContainer(
                      key: itemKeys[opt],
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? cs.primaryContainer
                            : (isCurrent
                                ? cs.primary.withValues(alpha: 0.15)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isHovered
                              ? cs.primary
                              : (isCurrent
                                  ? cs.primary.withValues(alpha: 0.4)
                                  : Colors.transparent),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opt.icon,
                            size: 13.0,
                            color: isHovered
                                ? cs.onPrimaryContainer
                                : (isCurrent ? cs.primary : cs.onSurfaceVariant),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: (isCurrent || isHovered)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isHovered
                                  ? cs.onPrimaryContainer
                                  : (isCurrent ? cs.primary : cs.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Divider(
                  height: 1.0,
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              // Row 2 Header: Accent Color
              Padding(
                padding: const EdgeInsets.only(left: 6.0, bottom: 4.0),
                child: Text(
                  'ACCENT',
                  style: TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _accentOptions.map((opt) {
                  final isCurrent = viewState.accent == opt.accent;
                  final isHovered = hoveredValue == opt;

                  return GestureDetector(
                    onTap: () => onSelect(opt),
                    child: AnimatedContainer(
                      key: itemKeys[opt],
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? cs.primaryContainer
                            : (isCurrent
                                ? cs.primary.withValues(alpha: 0.15)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isHovered
                              ? cs.primary
                              : (isCurrent
                                  ? cs.primary.withValues(alpha: 0.4)
                                  : Colors.transparent),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              color: opt.accent.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            opt.accent.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: (isCurrent || isHovered)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isHovered
                                  ? cs.onPrimaryContainer
                                  : (isCurrent ? cs.primary : cs.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
