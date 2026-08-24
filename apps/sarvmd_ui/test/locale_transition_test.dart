// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sarvmd_ui/src/l10n/app_localizations.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_cubit.dart';
import 'package:sarvmd_ui/src/logic/locale/locale_state.dart';
import 'package:sarvmd_ui/src/presentation/widgets/common/language_transition_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleCubit & LanguageTransitionOverlay Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('LocaleState defaults to English (en)', () {
      const state = LocaleState();
      expect(state.locale, const Locale('en'));
      expect(state.isPersian, isFalse);
    });

    test('parseLocaleFromUri correctly parses query parameters and fragments', () {
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/?lang=fa')), const Locale('fa'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/?lang=en')), const Locale('en'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/?locale=fa')), const Locale('fa'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/?l=fa')), const Locale('fa'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/#/?lang=fa')), const Locale('fa'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/#/editor?lang=en')), const Locale('en'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/?lang=persian')), const Locale('fa'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/?lang=english')), const Locale('en'));
      expect(parseLocaleFromUri(Uri.parse('http://sarvmd.app/')), isNull);
    });

    test('LocaleCubit initializes from URL parameter when present', () async {
      final uri = Uri.parse('http://sarvmd.app/?lang=fa');
      final cubit = LocaleCubit(null, uri);

      // Wait brief moment for async _initLocale
      await Future.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.locale, const Locale('fa'));

      // Verify that URL parameter choice was cached in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sarvmd_locale'), 'fa');
    });

    test('LocaleCubit handles setLocale transition states and persistence correctly', () async {
      final cubit = LocaleCubit(const LocaleState(locale: Locale('fa')));

      expect(cubit.state.locale, const Locale('fa'));
      expect(cubit.state.isTransitioning, isFalse);

      final transitionFuture = cubit.setLocale(
        const Locale('en'),
        fadeInDuration: const Duration(milliseconds: 50),
        blurSettleDuration: const Duration(milliseconds: 50),
      );

      // Check immediate transition state
      expect(cubit.state.isTransitioning, isTrue);

      await transitionFuture;

      // Verify final updated state & persistent storage
      expect(cubit.state.locale, const Locale('en'));
      expect(cubit.state.isTransitioning, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sarvmd_locale'), 'en');
    });

    test('LocaleCubit ignores duplicate or redundant locale switches', () async {
      final cubit = LocaleCubit(const LocaleState(locale: Locale('fa')));

      // Attempting to set same locale
      await cubit.setLocale(
        const Locale('fa'),
        fadeInDuration: Duration.zero,
        blurSettleDuration: Duration.zero,
      );

      expect(cubit.state.isTransitioning, isFalse);
    });

    testWidgets('LanguageTransitionOverlay renders blur overlay when transitioning', (tester) async {
      final cubit = LocaleCubit(const LocaleState(locale: Locale('fa')));

      await tester.pumpWidget(
        BlocProvider<LocaleCubit>.value(
          value: cubit,
          child: MaterialApp(
            locale: const Locale('fa'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return LanguageTransitionOverlay(child: child!);
            },
            home: const Scaffold(
              body: Center(child: Text('Workspace Home')),
            ),
          ),
        ),
      );

      // Initially, no blur overlay is visible
      expect(find.byKey(const ValueKey('language_transition_blur_overlay')), findsNothing);
      expect(find.text('Workspace Home'), findsOneWidget);

      // Trigger language switch transition
      final future = cubit.setLocale(
        const Locale('en'),
        fadeInDuration: const Duration(milliseconds: 100),
        blurSettleDuration: const Duration(milliseconds: 100),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      // Blur overlay should be visible
      expect(find.byKey(const ValueKey('language_transition_blur_overlay')), findsOneWidget);

      // Complete async setLocale steps (fadeIn + blurSettle)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await future;

      // Trigger and complete AnimatedSwitcher reverse fade-out duration (300ms)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Blur overlay should fade out and hide
      expect(find.byKey(const ValueKey('language_transition_blur_overlay')), findsNothing);
    });
  });
}
