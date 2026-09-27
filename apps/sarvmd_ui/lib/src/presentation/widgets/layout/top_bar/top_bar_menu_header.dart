// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

/// Shared desktop-style top-bar menu header button.
///
/// Renders a labelled text trigger that opens a [MenuAnchor] on tap/click.
/// Used by File, Edit, View, and Help desktop menus to achieve uniform cascading behaviour.
class TopBarMenuHeader extends StatelessWidget {
  final String label;
  final List<Widget> menuChildren;

  const TopBarMenuHeader({
    super.key,
    required this.label,
    required this.menuChildren,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(4.0),
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
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
      },
      menuChildren: menuChildren,
    );
  }
}
