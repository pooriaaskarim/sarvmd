// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/document/document_state.dart';
import '../../../../../logic/services/recent_documents_service.dart';
import '../top_bar_menu_handler.dart';
import '../top_bar_menu_header.dart';

/// `File` desktop menu for the top bar.
class TopBarFileMenu extends StatelessWidget {
  final DocumentState documentState;

  const TopBarFileMenu({super.key, required this.documentState});

  /// Builds the [Widget] entries for the File menu.
  ///
  /// Shared between desktop wide-mode [TopBarFileMenu] and compact [TopBarCompactAppMenu].
  static List<Widget> buildChildren(BuildContext context, DocumentState documentState) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return [
      MenuItemButton(
        leadingIcon: Icon(Icons.note_add_outlined, size: 17, color: cs.onSurface),
        trailingIcon: Text('Ctrl+N', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        onPressed: () => handleTopBarMenuSelection(context, 'new_document', documentState),
        child: Text(l10n.menuNew),
      ),
      MenuItemButton(
        leadingIcon: Icon(Icons.file_open_outlined, size: 17, color: cs.onSurface),
        trailingIcon: Text('Ctrl+O', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        onPressed: () => handleTopBarMenuSelection(context, 'open_document', documentState),
        child: Text(l10n.menuOpen),
      ),
      ValueListenableBuilder<List<String>>(
        valueListenable: RecentDocumentsService.recentDocumentsNotifier,
        builder: (context, recentFiles, _) {
          return SubmenuButton(
            leadingIcon: Icon(Icons.history_outlined, size: 17, color: cs.onSurface),
            menuChildren: recentFiles.isEmpty
                ? [
                    MenuItemButton(
                      onPressed: null,
                      child: Text(
                        l10n.menuNoRecentFiles,
                        style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      ),
                    ),
                  ]
                : [
                    ...recentFiles.map(
                      (path) {
                        final fileName = p.basename(path);
                        return MenuItemButton(
                          leadingIcon: Icon(Icons.description_outlined, size: 15, color: cs.onSurfaceVariant),
                          onPressed: () => handleOpenRecentDocument(context, path),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: Tooltip(
                              message: path,
                              child: Text(
                                fileName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    MenuItemButton(
                      leadingIcon: Icon(Icons.clear_all_outlined, size: 15, color: cs.error),
                      onPressed: () => RecentDocumentsService.clearRecentDocuments(),
                      child: Text(
                        l10n.menuClearRecent,
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  ],
            child: Text(l10n.menuOpenRecent),
          );
        },
      ),
      const Divider(),
      MenuItemButton(
        leadingIcon: Icon(Icons.save_outlined, size: 17, color: cs.onSurface),
        trailingIcon: Text('Ctrl+S', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        onPressed: () => handleTopBarMenuSelection(context, 'save_document', documentState),
        child: Text(l10n.menuSave),
      ),
      MenuItemButton(
        leadingIcon: Icon(Icons.save_as_outlined, size: 17, color: cs.onSurface),
        trailingIcon: Text('Ctrl+Shift+S', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        onPressed: () => handleTopBarMenuSelection(context, 'save_as_document', documentState),
        child: Text(l10n.menuSaveAs),
      ),
      const Divider(),
      MenuItemButton(
        leadingIcon: Icon(Icons.file_upload_outlined, size: 17, color: cs.primary),
        trailingIcon: Text('Ctrl+E', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        onPressed: () => handleTopBarMenuSelection(context, 'export', documentState),
        child: Text(l10n.export),
      ),
      const Divider(),
      MenuItemButton(
        leadingIcon: Icon(Icons.info_outline, size: 17, color: cs.onSurface),
        trailingIcon: Text('Ctrl+I', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        onPressed: () => handleTopBarMenuSelection(context, 'document_properties', documentState),
        child: Text(l10n.menuDocumentProperties),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TopBarMenuHeader(
      label: l10n.menuFile,
      menuChildren: buildChildren(context, documentState),
    );
  }
}
