// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../../l10n/app_localizations.dart';
import '../../../../../logic/score/score_cubit.dart';

/// Center-zone inline-editable score header.
///
/// Renders the score **Title** (single source of truth for score title & export name)
/// as a tappable label that switches to an inline [TextField] on tap.
/// On submit (Enter or tap-outside), dispatches [core.SetTitleCommand] through [ScoreCubit].
///
/// If cleared (empty input), falls back to the default file name format generated from page config.
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
      context.read<ScoreCubit>().execute(
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

    final titleWidget = _isEditingTitle
        ? SizedBox(
            width: 180.0,
            height: 28.0,
            child: TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: effectiveTitle,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                isDense: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _submitTitle(),
              onTapOutside: (_) => _submitTitle(),
            ),
          )
        : InkWell(
            onTap: () {
              setState(() {
                _isEditingTitle = true;
                _titleController.text = widget.score.title.isEmpty
                    ? effectiveTitle
                    : widget.score.title;
              });
              _titleFocusNode.requestFocus();
            },
            borderRadius: BorderRadius.circular(5.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Text(
                effectiveTitle,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
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
