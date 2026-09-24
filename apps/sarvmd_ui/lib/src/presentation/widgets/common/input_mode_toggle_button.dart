// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/view/view_cubit.dart';
import '../../../logic/view/view_state.dart';
import '../specialized/launch_coordinator.dart';

/// A top-bar action button that toggles between [InputMode.pointer] and [InputMode.touch].
///
/// Prompts the user with a confirmation dialog before toggling the cubit state and
/// executing a clean reload through [LaunchCoordinator].
class InputModeToggleButton extends StatelessWidget {
  const InputModeToggleButton({super.key});

  static ViewCubit? _getViewCubit(BuildContext context, {bool listen = true}) {
    try {
      return BlocProvider.of<ViewCubit>(context, listen: listen);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleToggle(BuildContext context, InputMode currentMode) async {
    final isPointer = currentMode == InputMode.pointer;
    final targetModeName = isPointer ? 'Touch' : 'Pointer';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Switch to $targetModeName Mode?'),
          content: Text(
            isPointer
                ? 'The interface will reload into the touch-optimized layout with larger hit targets and gesture controls. Your active score document will be preserved.'
                : 'The interface will reload into the pointer-optimized desktop layout. Your active score document will be preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Switch & Reload'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final cubit = _getViewCubit(context, listen: false);
      cubit?.toggleInputMode();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LaunchCoordinator(
            minSplashDuration: Duration(milliseconds: 300),
          ),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewCubit = _getViewCubit(context, listen: true);
    if (viewCubit == null) {
      return const SizedBox.shrink();
    }

    final inputMode = viewCubit.state.inputMode;
    final isPointer = inputMode == InputMode.pointer;

    return IconButton(
      key: const ValueKey('input_mode_toggle_button'),
      icon: Icon(
        isPointer ? Icons.touch_app_outlined : Icons.mouse_outlined,
        size: 18.0,
      ),
      tooltip: isPointer ? 'Switch to Touch Mode' : 'Switch to Pointer Mode',
      onPressed: () => _handleToggle(context, inputMode),
    );
  }
}
