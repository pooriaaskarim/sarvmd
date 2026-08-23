// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import 'locale_state.dart';

final _log = AppLogger.get('sarvmd.l10n');

/// Cubit managing application language state and persistence.
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit([LocaleState? initial]) : super(initial ?? const LocaleState()) {
    _loadFromPrefs();
  }

  static const String _keyLocale = 'sarvmd_locale';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_keyLocale);
      if (savedLang != null) {
        final newLocale = Locale(savedLang);
        emit(state.copyWith(locale: newLocale));
        _log.info('Loaded saved locale from preferences', context: {
          'languageCode': savedLang,
        });
      }
    } catch (e, st) {
      _log.error('Failed to load locale preferences', error: e, stackTrace: st);
    }
  }

  /// Sets language to Persian (fa) or English (en).
  Future<void> setLocale(Locale locale) async {
    if (state.locale == locale) return;
    emit(state.copyWith(locale: locale));

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocale, locale.languageCode);
      _log.info('Updated application locale', context: {
        'languageCode': locale.languageCode,
      });
    } catch (e, st) {
      _log.error('Failed to save locale preference', error: e, stackTrace: st);
    }
  }

  /// Toggles between Persian and English locales.
  Future<void> toggleLocale() async {
    final nextLocale = state.isPersian ? const Locale('en') : const Locale('fa');
    await setLocale(nextLocale);
  }
}
