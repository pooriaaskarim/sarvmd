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
      previewBuilder: (context, option) {
        if (option is ModeOption) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 16.0, color: cs.primary),
              const SizedBox(width: 6.0),
              Text(
                option.label,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          );
        } else if (option is AccentOption) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14.0,
                height: 14.0,
                decoration: BoxDecoration(
                  color: option.accent.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: option.accent.primary.withValues(alpha: 0.6),
                      blurRadius: 6.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                option.accent.label,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
      buttonBuilder: (context, onTap) {
        return Container(
          height: 38.0,
          constraints: const BoxConstraints(minWidth: 44.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(19.0),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22.0,
                height: 22.0,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  modeIcon,
                  size: 13.0,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 6.0),
              Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: viewState.accent.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      menuBuilder: (context, hoveredValue, itemKeys, onSelect) {
        return Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.15),
                blurRadius: 16.0,
                spreadRadius: 1.0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20.0,
                offset: const Offset(0, 8),
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
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? cs.primaryContainer
                            : (isCurrent
                                ? cs.primary.withValues(alpha: 0.18)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isHovered
                              ? cs.primary
                              : (isCurrent
                                  ? cs.primary.withValues(alpha: 0.5)
                                  : cs.outlineVariant.withValues(alpha: 0.3)),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opt.icon,
                            size: 14.0,
                            color: isHovered
                                ? cs.onPrimaryContainer
                                : (isCurrent ? cs.primary : cs.onSurfaceVariant),
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: (isCurrent || isHovered)
                                  ? FontWeight.bold
                                  : FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(
                  height: 1.0,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              // Row 2 Header: Accent Color
              Padding(
                padding: const EdgeInsets.only(left: 6.0, bottom: 6.0),
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

                  return Tooltip(
                    message: opt.accent.label,
                    child: GestureDetector(
                      onTap: () => onSelect(opt),
                      child: AnimatedContainer(
                        key: itemKeys[opt],
                        duration: const Duration(milliseconds: 140),
                        width: 36.0,
                        height: 36.0,
                        margin: const EdgeInsets.symmetric(horizontal: 3.0),
                        decoration: BoxDecoration(
                          color: opt.accent.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isCurrent || isHovered)
                                ? cs.onSurface
                                : Colors.transparent,
                            width: isHovered ? 2.5 : (isCurrent ? 2.0 : 0),
                          ),
                          boxShadow: [
                            if (isCurrent || isHovered)
                              BoxShadow(
                                color: opt.accent.primary.withValues(alpha: 0.6),
                                blurRadius: isHovered ? 12.0 : 6.0,
                                spreadRadius: isHovered ? 2.0 : 1.0,
                              ),
                          ],
                        ),
                        child: Center(
                          child: (isCurrent || isHovered)
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 18.0,
                                  color: opt.accent.primary.computeLuminance() > 0.5
                                      ? Colors.black87
                                      : Colors.white,
                                )
                              : null,
                        ),
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
