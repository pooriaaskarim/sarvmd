// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/locale/locale_cubit.dart';
import 'hold_drag_context_menu.dart';

enum LangOption {
  en('English', 'EN'),
  fa('فارسی', 'FA');

  const LangOption(this.label, this.code);
  final String label;
  final String code;
}

/// Language selection button with dual interaction modes (click popup & hold-drag selection).
class MobileLanguageButton extends StatelessWidget {
  const MobileLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final localeState = context.watch<LocaleCubit>().state;
    final isPersian = localeState.isPersian;
    final currentCode = isPersian ? 'FA' : 'EN';

    return HoldDragContextMenu<LangOption>(
      items: LangOption.values,
      onSelect: (option) {
        final targetLocale = option == LangOption.fa ? const Locale('fa') : const Locale('en');
        context.read<LocaleCubit>().setLocale(targetLocale);
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
                Icons.language_rounded,
                size: 16.0,
                color: cs.primary,
              ),
              const SizedBox(width: 5.0),
              Text(
                currentCode,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
      menuBuilder: (context, hoveredValue, itemKeys, onSelect) {
        return Container(
          padding: const EdgeInsets.all(6.0),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: LangOption.values.map((opt) {
              final isCurrent = (opt == LangOption.fa && isPersian) ||
                  (opt == LangOption.en && !isPersian);
              final isHovered = hoveredValue == opt;

              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  key: itemKeys[opt],
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? cs.primaryContainer
                        : (isCurrent
                            ? cs.primary.withValues(alpha: 0.15)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isHovered
                          ? cs.primary
                          : (isCurrent
                              ? cs.primary.withValues(alpha: 0.4)
                              : Colors.transparent),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: (isCurrent || isHovered) ? FontWeight.bold : FontWeight.normal,
                      color: isHovered
                          ? cs.onPrimaryContainer
                          : (isCurrent ? cs.primary : cs.onSurface),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
