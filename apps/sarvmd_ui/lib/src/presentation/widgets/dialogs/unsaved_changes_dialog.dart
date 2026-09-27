// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import 'adaptive_dialog_helper.dart';

/// User decision when prompted about unsaved changes.
enum UnsavedChangesAction {
  save,
  discard,
  cancel,
}

/// Displays an adaptive, aesthetically refined confirmation modal asking the user
/// how to proceed with unsaved modifications before creating or opening a document.
Future<UnsavedChangesAction> showUnsavedChangesDialog(
  BuildContext context, {
  required String documentName,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;

  final result = await showSarvAdaptiveModal<UnsavedChangesAction>(
    context: context,
    maxWidth: 440.0,
    builder: (modalContext, isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    Icons.save_as_outlined,
                    color: cs.primary,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    l10n.unsavedChangesTitle,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              l10n.unsavedChangesMessage(documentName),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(modalContext).pop(UnsavedChangesAction.cancel),
                    child: Text(l10n.actionCancel),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withValues(alpha: 0.3)),
                    ),
                    onPressed: () => Navigator.of(modalContext).pop(UnsavedChangesAction.discard),
                    child: Text(l10n.actionDiscard),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                    ),
                    onPressed: () => Navigator.of(modalContext).pop(UnsavedChangesAction.save),
                    child: Text(l10n.actionSave),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  return result ?? UnsavedChangesAction.cancel;
}
