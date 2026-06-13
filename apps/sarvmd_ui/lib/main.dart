// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a Business Source License 1.1
// license that can be found in the LICENSE file in the root of this project.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'src/logic/config/config_cubit.dart';
import 'src/logic/view/view_state.dart';
import 'src/logic/view/view_cubit.dart';
import 'src/logic/score/score_cubit.dart';
import 'src/core/theme/app_theme.dart';
import 'src/presentation/screens/editor_screen.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ConfigCubit()),
        BlocProvider(create: (_) => ViewCubit()),
        BlocProvider(create: (_) => ScoreCubit()),
      ],
      child: const SarvApp(),
    ),
  );
}

class SarvApp extends StatelessWidget {
  const SarvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewCubit, ViewState>(
      builder: (context, viewState) {
        final accent = viewState.accent;
        return MaterialApp(
          title: 'SarvMD',
          debugShowCheckedModeBanner: false,
          themeMode: viewState.themeMode,
          theme: AppTheme.build(accent, Brightness.light),
          darkTheme: AppTheme.build(accent, Brightness.dark),
          home: const EditorScreen(),
        );
      },
    );
  }
}
