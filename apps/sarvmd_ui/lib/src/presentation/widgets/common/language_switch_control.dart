// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../logic/locale/locale_cubit.dart';
import '../../../logic/locale/locale_state.dart';

/// A sleek, compact single-button toggle for switching between English and Persian.
///
/// Features a pill design with globe icon, native font rendering, and micro-animations.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        final isPersian = localeState.isPersian;
        final cs = Theme.of(context).colorScheme;

        // Target language to switch to
        final targetCode = isPersian ? 'en' : 'fa';
        final targetLabel = isPersian ? 'English' : 'فارسی';

        return Tooltip(
          message: AppLocalizations.of(context)!.toggleLanguage,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<LocaleCubit>().setLocale(Locale(targetCode));
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 15,
                      color: cs.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      targetLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
