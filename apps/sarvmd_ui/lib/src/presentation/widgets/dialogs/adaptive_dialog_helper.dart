// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../core/theme/sarv_display_context.dart';

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
  final display = SarvDisplayContext.of(context);
  final isMobile = display.preferBottomSheet;

  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (bottomSheetContext) {
        final cs = Theme.of(bottomSheetContext).colorScheme;
        final sheetMedia = MediaQuery.of(bottomSheetContext);
        final availableHeight =
            (sheetMedia.size.height - sheetMedia.viewInsets.bottom);

        return Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: sheetMedia.viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutQuad,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: availableHeight < 500
                    ? availableHeight * 0.96
                    : availableHeight * 0.90,
              ),
              child: Material(
                color: cs.surfaceContainerHigh,
                elevation: 8,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24.0)),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  bottom: sheetMedia.viewInsets.bottom == 0,
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
        final availableHeight =
            (dialogMedia.size.height - dialogMedia.viewInsets.bottom);

        return Dialog(
          backgroundColor: cs.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: availableHeight < 600 ? 8.0 : 24.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: availableHeight < 600
                  ? availableHeight * 0.96
                  : availableHeight * 0.90,
            ),
            child: builder(dialogContext, false),
          ),
        );
      },
    );
  }
}
