// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

/// Helper utilities for presenting adaptive dialogs and bottom sheets in SarvMD.
///
/// On Desktop & Tablet (viewport width >= 600px): Presents a centered, elevated modal dialog.
/// On Mobile (viewport width < 600px): Presents a thumb-accessible draggable bottom sheet.
Future<T?> showSarvAdaptiveModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, bool isMobile) builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  double maxWidth = 560.0,
}) {
  final media = MediaQuery.of(context);
  final isMobile = media.size.width < 600 || media.size.height < 600;

  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (bottomSheetContext) {
        final cs = Theme.of(bottomSheetContext).colorScheme;

        return Material(
          color: cs.surfaceContainerHigh,
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            bottom: true,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Drag Handle Indicator
                      const SizedBox(height: 10.0),
                      Container(
                        width: 36.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                      const SizedBox(height: 6.0),

                      // Bottom Sheet Content
                      Flexible(
                        child: builder(bottomSheetContext, true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  } else {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final dialogMedia = MediaQuery.of(dialogContext);

        return Dialog(
          backgroundColor: cs.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 24.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: dialogMedia.size.height * 0.90,
            ),
            child: builder(dialogContext, false),
          ),
        );
      },
    );
  }
}
