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
      previewBuilder: (context, option) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option == LangOption.fa ? '🇮🇷' : '🇬🇧',
              style: const TextStyle(fontSize: 15.0),
            ),
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
                  Icons.language_rounded,
                  size: 13.0,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                currentCode,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: 0.6,
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
            color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(22.0),
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
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
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
                      Text(
                        opt == LangOption.fa ? '🇮🇷' : '🇬🇧',
                        style: const TextStyle(fontSize: 14.0),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: (isCurrent || isHovered) ? FontWeight.bold : FontWeight.w500,
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
        );
      },
    );
  }
}
