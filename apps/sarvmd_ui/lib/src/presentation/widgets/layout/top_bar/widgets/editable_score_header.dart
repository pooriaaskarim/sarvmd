// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

import '../../../../../logic/score/score_cubit.dart';

/// Center-zone dual inline-editable score header.
///
/// Renders the score **Title** and **Composer** as tappable labels that switch
/// to inline [TextField]s on tap.  On submit (Enter or tap-outside), dispatches
/// [core.SetTitleCommand] / [core.SetComposerCommand] through [ScoreCubit].
///
/// In compact mode ([isCompact] == true) only the title is shown.
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
  bool _isEditingComposer = false;
  late TextEditingController _titleController;
  late TextEditingController _composerController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _composerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.score.title);
    _composerController = TextEditingController(text: widget.score.composer);
  }

  @override
  void didUpdateWidget(covariant EditableScoreHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditingTitle && oldWidget.score.title != widget.score.title) {
      _titleController.text = widget.score.title;
    }
    if (!_isEditingComposer && oldWidget.score.composer != widget.score.composer) {
      _composerController.text = widget.score.composer;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _composerController.dispose();
    _titleFocusNode.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _submitTitle() {
    if (!_isEditingTitle) return;
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.score.title) {
      context.read<ScoreCubit>().execute(
            core.SetTitleCommand(newTitle, widget.score.title),
          );
    } else {
      _titleController.text = widget.score.title;
    }
    setState(() => _isEditingTitle = false);
  }

  void _submitComposer() {
    if (!_isEditingComposer) return;
    final newComposer = _composerController.text.trim();
    if (newComposer != widget.score.composer) {
      context.read<ScoreCubit>().execute(
            core.SetComposerCommand(newComposer, widget.score.composer),
          );
    } else {
      _composerController.text = widget.score.composer;
    }
    setState(() => _isEditingComposer = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final titleWidget = _isEditingTitle
        ? SizedBox(
            width: 140.0,
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
              setState(() => _isEditingTitle = true);
              _titleFocusNode.requestFocus();
            },
            borderRadius: BorderRadius.circular(5.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Text(
                widget.score.title.isEmpty ? 'New Score' : widget.score.title,
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

    final composerWidget = _isEditingComposer
        ? SizedBox(
            width: 120.0,
            height: 28.0,
            child: TextField(
              controller: _composerController,
              focusNode: _composerFocusNode,
              autofocus: true,
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                isDense: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6.0),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _submitComposer(),
              onTapOutside: (_) => _submitComposer(),
            ),
          )
        : InkWell(
            onTap: () {
              setState(() => _isEditingComposer = true);
              _composerFocusNode.requestFocus();
            },
            borderRadius: BorderRadius.circular(5.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Text(
                widget.score.composer.isEmpty ? 'Composer' : widget.score.composer,
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle:
                      widget.score.composer.isEmpty ? FontStyle.italic : FontStyle.normal,
                  color: cs.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: titleWidget),
        Text(
          ' • ',
          style: TextStyle(fontSize: 12.0, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
        ),
        Flexible(child: composerWidget),
        const SizedBox(width: 6.0),
        // Layout status pill (e.g. "A4 • PORTRAIT")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 0.8),
          ),
          child: Text(
            '${widget.configState.pageSize.name.toUpperCase()} • ${widget.configState.orientation.name.toUpperCase()}',
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
