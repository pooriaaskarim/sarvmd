// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import 'locale_state.dart';

final _log = AppLogger.get('sarvmd.l10n');

/// Parses and normalizes locale from URI query parameters or hash fragments.
///
/// Supports keys `lang`, `locale`, or `l` (e.g. `?lang=en`, `?lang=fa`, `/#/?lang=fa`).
Locale? parseLocaleFromUri(Uri uri) {
  String? normalize(String? raw) {
    if (raw == null) return null;
    final val = raw.toLowerCase().trim();
    if (val == 'fa' || val == 'farsi' || val == 'persian') return 'fa';
    if (val == 'en' || val == 'english') return 'en';
    return null;
  }

  // 1. Check primary query parameters
  final direct = normalize(
    uri.queryParameters['lang'] ??
        uri.queryParameters['locale'] ??
        uri.queryParameters['l'],
  );
  if (direct != null) return Locale(direct);

  // 2. Check hash fragment query parameters (e.g. #/?lang=fa)
  if (uri.hasFragment) {
    final fragment = uri.fragment;
    final queryIdx = fragment.indexOf('?');
    if (queryIdx != -1 && queryIdx < fragment.length - 1) {
      final queryStr = fragment.substring(queryIdx + 1);
      final fragUri = Uri.parse('http://dummy/?$queryStr');
      final fragLang = normalize(
        fragUri.queryParameters['lang'] ??
            fragUri.queryParameters['locale'] ??
            fragUri.queryParameters['l'],
      );
      if (fragLang != null) return Locale(fragLang);
    }
  }

  return null;
}

/// Cubit managing application language state, persistence, and URL parameterization.
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit([LocaleState? initial, Uri? currentUri])
      : super(initial ?? const LocaleState()) {
    _initLocale(currentUri);
  }

  static const String _keyLocale = 'sarvmd_locale';

  Future<void> _initLocale([Uri? overrideUri]) async {
    try {
      final uri = overrideUri ?? Uri.base;
      final urlLocale = parseLocaleFromUri(uri);

      if (urlLocale != null) {
        emit(state.copyWith(locale: urlLocale));
        _log.info('Application locale initialized from URL parameter', context: {
          'languageCode': urlLocale.languageCode,
        });

        // Persist URL-specified locale so subsequent launches without params preserve it
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLocale, urlLocale.languageCode);
        return;
      }

      // Load saved preference from SharedPreferences
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
      _log.error('Failed to initialize locale settings', error: e, stackTrace: st);
    }
  }

  /// Sets language to Persian (fa) or English (en) with a smooth blur transition overlay.
  Future<void> setLocale(
    Locale locale, {
    Duration fadeInDuration = const Duration(milliseconds: 180),
    Duration blurSettleDuration = const Duration(milliseconds: 250),
  }) async {
    if (state.locale == locale || state.isTransitioning) return;

    // 1. Indicate language change in progress (overlay blurs screen)
    emit(state.copyWith(isTransitioning: true));

    if (fadeInDuration > Duration.zero) {
      await Future.delayed(fadeInDuration);
    }

    // 2. Update locale underneath the blur overlay
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

    if (blurSettleDuration > Duration.zero) {
      await Future.delayed(blurSettleDuration);
    }

    // 3. Complete transition (overlay fades out)
    emit(state.copyWith(isTransitioning: false));
  }

  /// Toggles between Persian and English locales.
  Future<void> toggleLocale() async {
    final nextLocale = state.isPersian ? const Locale('en') : const Locale('fa');
    await setLocale(nextLocale);
  }
}
