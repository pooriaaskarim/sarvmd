// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';
import '../../../core/theme/layout_policy.dart';

/// A declarative, highly polished settings row primitive for SarvMD UI.
///
/// Automatically handles label and control positioning based on the active
/// layout policy and locale text direction without requiring manual `isPersian`
/// array swapping inside parent widgets:
/// - Under RTL (Persian) in BilingualFluid mode: Label on Right, Control on Left.
/// - Under LTR (English) or CanvasStrict mode: Label on Left, Control on Right.
class PropertyRow extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.label,
    required this.control,
    this.spacing = 8.0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// The text widget or string for the property label.
  final Widget label;

  /// The interactive control (e.g. TextField, Dropdown, Switch, Button).
  final Widget control;

  /// Horizontal spacing between the label and control.
  final double spacing;

  /// Cross axis alignment for the row.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final isCanvasStrict = LayoutPolicy.isCanvasStrict(context);
    final isRtl = !isCanvasStrict &&
        Localizations.localeOf(context).languageCode == 'fa';

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (isRtl) ...[
          control,
          SizedBox(width: spacing),
          Expanded(
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.right,
              child: label,
            ),
          ),
        ] else ...[
          Expanded(
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.left,
              child: label,
            ),
          ),
          SizedBox(width: spacing),
          control,
        ],
      ],
    );
  }
}
