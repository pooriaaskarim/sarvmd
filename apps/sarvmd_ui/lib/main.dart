// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'src/l10n/app_localizations.dart';
import 'src/core/utils/app_logger.dart';
import 'src/logic/config/config_cubit.dart';
import 'src/logic/view/view_state.dart';
import 'src/logic/view/view_cubit.dart';
import 'src/logic/score/score_cubit.dart';
import 'src/logic/locale/locale_cubit.dart';
import 'src/logic/locale/locale_state.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/layout_policy.dart';
import 'src/presentation/widgets/specialized/launch_coordinator.dart';
import 'src/presentation/widgets/common/language_transition_overlay.dart';

void main() {
  // 1. Initialize logging before anything else.
  AppLogger.init(isDev: kDebugMode);

  // 2. Record session start — the anchor point for every log file.
  AppLogger.get('sarvmd').info('SarvMD starting', context: {
    'mode': kDebugMode ? 'debug' : 'release',
    'platform': defaultTargetPlatform.name,
    'isWeb': kIsWeb,
  });

  // 3. Capture Flutter framework errors (layout overflows, widget errors, etc.).
  FlutterError.onError = (final details) {
    AppLogger.crash.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // 4. Capture errors on the platform message channel (Dart ↔ native layer).
  //    These are NOT caught by FlutterError.onError or runZonedGuarded.
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.crash.error(
      'Platform dispatcher error',
      error: error,
      stackTrace: stack,
    );
    return true; // Returning true marks the error as handled.
  };

  // 5. Capture all remaining async errors that escape the widget tree.
  runZonedGuarded(
    () => runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocaleCubit()),
          BlocProvider(create: (_) => ConfigCubit()),
          BlocProvider(create: (_) => ViewCubit()),
          BlocProvider(create: (_) => ScoreCubit()),
        ],
        child: const SarvApp(),
      ),
    ),
    (error, stack) {
      AppLogger.crash.error(
        'Uncaught async error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

class SarvApp extends StatelessWidget {
  const SarvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        return BlocBuilder<ViewCubit, ViewState>(
          builder: (context, viewState) {
            final accent = viewState.accent;
            return MaterialApp(
              title: 'SarvMD',
              debugShowCheckedModeBanner: false,
              locale: localeState.locale,
              supportedLocales: const [
                Locale('en'),
                Locale('fa'),
              ],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: viewState.themeMode,
              theme: AppTheme.build(accent, Brightness.light, isPersian: localeState.isPersian),
              darkTheme: AppTheme.build(accent, Brightness.dark, isPersian: localeState.isPersian),
              builder: (context, child) {
                return BilingualFluidScope(
                  child: LanguageTransitionOverlay(
                    child: child!,
                  ),
                );
              },
              home: const LaunchCoordinator(),
            );
          },
        );
      },
    );
  }
}
