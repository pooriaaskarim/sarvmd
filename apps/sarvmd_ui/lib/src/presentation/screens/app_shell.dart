// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../core/theme/sarv_display_context.dart';
import '../../logic/document/document_cubit.dart';
import '../../logic/document/document_state.dart';
import '../../logic/services/file_open_service.dart';
import '../../logic/services/sarv_file_service.dart';
import '../../logic/services/web_download/web_download.dart';
import '../../logic/view/view_cubit.dart';
import '../../logic/view/view_state.dart';
import '../../logic/workspace/workspace_cubit.dart';
import '../../logic/workspace/workspace_state.dart';
import '../../core/utils/app_logger.dart';
import '../../l10n/app_localizations.dart';
import 'pointer_editor_screen.dart';
import 'touch_editor_screen.dart';

final _log = AppLogger.get('sarvmd.ui.shell');

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
  StreamSubscription<String>? _fileOpenSub;
  bool _isDraggingFile = false;

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

    // Subscribe to Android file-open intents (no-op stream on other platforms).
    _fileOpenSub = FileOpenService.filePathStream.listen(_handleExternalFilePath);
  }

  /// Routes an externally-opened `.sarv` file path into the editor workspace.
  Future<void> _handleExternalFilePath(String path) async {
    if (!mounted) return;
    _log.info('Opening externally triggered .sarv file', context: {'path': path});
    final fileName = path.split(RegExp(r'[/\\]')).last;

    try {
      final workspace = context.read<WorkspaceCubit?>();
      if (workspace != null) {
        final wasAlreadyOpen = workspace.state.sessions.any((s) => s.filePath == path);
        final session = await workspace.openFileTab(path);
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          final title = session.cubit.state.document.metadata.title.trim().isNotEmpty
              ? session.cubit.state.document.metadata.title
              : fileName;

          final message = wasAlreadyOpen
              ? (l10n?.fileSwitchedTab(title) ?? 'Switched to tab "$title"')
              : (l10n?.fileOpenedSuccess(title) ?? 'Opened "$title"');

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              content: Row(
                children: [
                  Icon(
                    wasAlreadyOpen ? Icons.tab : Icons.description_outlined,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        final doc = context.read<DocumentCubit?>();
        if (doc != null) {
          final service = SarvFileService();
          await doc.loadFromPath(path, fileService: service);
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            final title = doc.state.document.metadata.title.trim().isNotEmpty
                ? doc.state.document.metadata.title
                : fileName;
            final message = l10n?.fileOpenedSuccess(title) ?? 'Opened "$title"';

            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                content: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }
    } catch (e, st) {
      _log.error('Failed to open externally triggered file', error: e, stackTrace: st);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n?.fileOpenFailed ?? 'Could not open file: ${e.toString()}'),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  /// Handles files dropped directly onto the workspace window.
  Future<void> _handleDroppedFiles(List<DropItem> files) async {
    final sarvFiles = files.where((f) {
      final effectiveName = f.name.isNotEmpty ? f.name : f.path.split(RegExp(r'[/\\]')).last;
      return effectiveName.toLowerCase().endsWith('.sarv');
    }).toList();

    if (sarvFiles.isEmpty) {
      if (mounted && files.isNotEmpty) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l10n?.fileOpenFailed ?? 'Only .sarv manuscript files are supported.'),
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    for (final file in sarvFiles) {
      if (!mounted) break;
      final fileName = file.name.isNotEmpty ? file.name : file.path.split(RegExp(r'[/\\]')).last;
      if (!kIsWeb && file.path.isNotEmpty && File(file.path).existsSync()) {
        await _handleExternalFilePath(file.path);
      } else {
        try {
          final bytes = await file.readAsBytes();
          final jsonString = utf8.decode(bytes);
          final dynamic decoded = jsonDecode(jsonString);
          if (decoded is! Map) continue;
          final doc = core.SarvDocument.fromJson(decoded.cast<String, dynamic>());
          final workspace = context.read<WorkspaceCubit?>();
          if (workspace != null) {
            await workspace.openDocumentTab(doc, title: fileName);
          } else {
            final docCubit = context.read<DocumentCubit?>();
            docCubit?.loadDocument(doc);
          }
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            final title = doc.metadata.title.trim().isNotEmpty ? doc.metadata.title : fileName;
            final message = l10n?.fileOpenedSuccess(title) ?? 'Opened "$title"';
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                content: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(message, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            );
          }
        } catch (e, st) {
          _log.error('Failed to parse dropped file: ${file.name}', error: e, stackTrace: st);
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  l10n?.fileOpenFailed ?? 'Could not open file: ${e.toString()}',
                ),
              ),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _fileOpenSub?.cancel();
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

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDraggingFile = true),
      onDragExited: (_) => setState(() => _isDraggingFile = false),
      onDragDone: (details) async {
        setState(() => _isDraggingFile = false);
        await _handleDroppedFiles(details.files);
      },
      child: PageStorage(
        bucket: _pageStorageBucket,
        child: Stack(
          children: [
            content,
            if (_isDraggingFile)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.file_download_outlined,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n?.dragDropOverlayHint ?? 'Drop .sarv manuscript to open',
                              style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
