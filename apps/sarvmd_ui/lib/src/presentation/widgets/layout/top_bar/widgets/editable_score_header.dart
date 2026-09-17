// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/document/document_cubit.dart';

/// Center-zone inline-editable score header with premium aesthetic animations & minimal underline styling.
///
/// Renders the score **Title** (single source of truth for score title & export name)
/// as a tappable label that switches to an inline [TextField] on tap.
/// On submit (Enter or tap-outside), dispatches [core.SetTitleCommand] through [DocumentCubit].
class EditableScoreHeader extends StatefulWidget {
  final core.Score score;
  final core.PageConfig configState;
  final bool isCompact;

  const EditableScoreHeader({
    super.key,
    required this.score,
    required this.configState,
    this.isCompact = false,
  });

  @override
  State<EditableScoreHeader> createState() => _EditableScoreHeaderState();
}

class _EditableScoreHeaderState extends State<EditableScoreHeader> {
  bool _isEditingTitle = false;
  bool _isHovered = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.score.title);
  }

  @override
  void didUpdateWidget(covariant EditableScoreHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingTitle && oldWidget.score.title != widget.score.title) {
      _titleController.text = widget.score.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _submitTitle() {
    if (!_isEditingTitle) return;
    final newTitle = _titleController.text.trim();
    if (newTitle != widget.score.title) {
      context.read<DocumentCubit>().execute(
            core.SetTitleCommand(newTitle, widget.score.title),
          );
    }
    setState(() => _isEditingTitle = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final effectiveTitle = core.ScoreCompiler.getEffectiveTitle(widget.score, widget.configState);
    final defaultTitle = core.ScoreCompiler.getDefaultFileName(widget.configState);
    final isCentered = widget.isCompact;

    final titleWidget = _isEditingTitle
        ? ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 140.0,
              maxWidth: widget.isCompact ? 220.0 : 340.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 28.0,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
                border: Border(
                  bottom: BorderSide(
                    color: cs.primary,
                    width: 2.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.12),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              alignment: Alignment.center,
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                autofocus: true,
                textAlign: isCentered ? TextAlign.center : TextAlign.start,
                cursorColor: cs.primary,
                cursorWidth: 2.0,
                cursorRadius: const Radius.circular(1.0),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: 0.3,
                ),
                decoration: InputDecoration(
                  hintText: defaultTitle,
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submitTitle(),
                onTapOutside: (_) => _submitTitle(),
              ),
            ),
          )
        : MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingTitle = true;
                  _titleController.text = widget.score.title;
                });
                _titleFocusNode.requestFocus();
              },
              child: AnimatedScale(
                scale: _isHovered ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 28.0,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? cs.primary.withValues(alpha: 0.08)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.25),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
                    border: Border(
                      bottom: BorderSide(
                        color: _isHovered
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.35),
                        width: _isHovered ? 1.8 : 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: isCentered ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          effectiveTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _isHovered ? cs.primary : cs.onSurface,
                            letterSpacing: 0.3,
                          ),
                          textAlign: isCentered ? TextAlign.center : TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isHovered ? 1.0 : 0.45,
                        child: Icon(
                          Icons.edit_note_rounded,
                          size: 15.0,
                          color: _isHovered ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

    if (widget.isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [Flexible(child: titleWidget)],
      );
    }

    final orientationLabel = widget.configState.orientation == core.PageOrientation.portrait
        ? l10n.portrait.toUpperCase()
        : l10n.landscape.toUpperCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: titleWidget),
        const SizedBox(width: 8.0),
        // Layout status pill (e.g. "A4 • PORTRAIT")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 0.8),
          ),
          child: Text(
            '${widget.configState.pageSize.name.toUpperCase()} • $orientationLabel',
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: cs.onPrimaryContainer,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
