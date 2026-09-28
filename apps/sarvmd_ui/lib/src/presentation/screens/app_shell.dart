// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/sarv_display_context.dart';
import '../../logic/document/document_cubit.dart';
import '../../logic/document/document_state.dart';
import '../../logic/services/web_download/web_download.dart';
import '../../logic/view/view_cubit.dart';
import '../../logic/view/view_state.dart';
import '../../logic/workspace/workspace_cubit.dart';
import '../../logic/workspace/workspace_state.dart';
import 'pointer_editor_screen.dart';
import 'touch_editor_screen.dart';

/// The root adaptive application shell.
///
/// Listens to [ViewCubit] and transitions seamlessly between the touch-optimized layout
/// and pointer-optimized desktop layout without destroying application state or replaying splash.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final workspace = context.read<WorkspaceCubit?>();
      if (workspace != null) {
        setWebUnsavedChangesGuard(workspace.state.hasDirtyTabs);
      } else {
        final doc = context.read<DocumentCubit?>();
        if (doc != null) {
          setWebUnsavedChangesGuard(doc.state.isDirty);
        }
      }
    });
  }

  @override
  void dispose() {
    setWebUnsavedChangesGuard(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceCubit = context.watch<WorkspaceCubit?>();

    Widget content = BlocBuilder<ViewCubit, ViewState>(
      buildWhen: (prev, curr) => prev.inputMode != curr.inputMode,
      builder: (context, viewState) {
        final isTouch = viewState.inputMode == InputMode.touch;

        return SarvDisplayScope(
          inputModeOverride: viewState.inputMode,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: isTouch
                ? const TouchEditorScreen(key: ValueKey('mobile_editor_screen'))
                : const PointerEditorScreen(key: ValueKey('editor_screen')),
          ),
        );
      },
    );

    if (workspaceCubit != null) {
      content = BlocListener<WorkspaceCubit, WorkspaceState>(
        listenWhen: (prev, curr) => prev.hasDirtyTabs != curr.hasDirtyTabs,
        listener: (context, state) {
          setWebUnsavedChangesGuard(state.hasDirtyTabs);
        },
        child: BlocProvider<DocumentCubit>.value(
          key: ValueKey('active_doc_cubit_${workspaceCubit.state.activeSession.id}'),
          value: workspaceCubit.state.activeCubit,
          child: content,
        ),
      );
    } else {
      content = BlocListener<DocumentCubit, DocumentState>(
        listenWhen: (prev, curr) => prev.isDirty != curr.isDirty,
        listener: (context, state) {
          setWebUnsavedChangesGuard(state.isDirty);
        },
        child: content,
      );
    }

    return PageStorage(
      bucket: _pageStorageBucket,
      child: content,
    );
  }
}
