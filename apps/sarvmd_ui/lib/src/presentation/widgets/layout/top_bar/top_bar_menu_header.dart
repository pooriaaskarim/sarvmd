// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

/// Shared desktop-style top-bar menu header button.
///
/// Renders a labelled text trigger that opens a [PopupMenuButton] on tap.
/// Used by File, View, and Help menus. The Edit menu uses [MenuAnchor] for
/// cascading submenus and is not based on this widget.
class TopBarMenuHeader extends StatelessWidget {
  final String label;
  final List<PopupMenuEntry<String>> Function(BuildContext) itemBuilder;
  final void Function(String value) onSelected;

  const TopBarMenuHeader({
    super.key,
    required this.label,
    required this.itemBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: '$label Menu',
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      color: cs.surfaceContainerHigh,
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.87),
          ),
        ),
      ),
    );
  }
}
