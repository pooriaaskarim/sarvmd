// Copyright (c) 2026 Pooria Askari Moqaddam. All rights reserved.
// Licensed under the Business Source License 1.1 (BUSL-1.1).

import 'package:flutter/material.dart';

/// Prominent split export CTA button in the right zone of the top bar.
///
/// The left segment triggers the primary export action ([onPrimaryPressed]).
/// The right chevron opens a [PopupMenuButton] with additional export format
/// options, routing selections to [onMenuSelected].
class SplitExportButton extends StatelessWidget {
  final String label;
  final VoidCallback onPrimaryPressed;
  final void Function(String value) onMenuSelected;

  const SplitExportButton({
    super.key,
    required this.label,
    required this.onPrimaryPressed,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 32.0,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary export action
          InkWell(
            onTap: onPrimaryPressed,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              bottomLeft: Radius.circular(8.0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Row(
                children: [
                  Icon(Icons.file_upload_outlined, size: 15.0, color: cs.onPrimary),
                  const SizedBox(width: 5.0),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: cs.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Divider between the two halves
          Container(
            width: 1.0,
            height: 18.0,
            color: cs.onPrimary.withValues(alpha: 0.3),
          ),
          // Export options dropdown
          PopupMenuButton<String>(
            tooltip: 'Export Options',
            offset: const Offset(0, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            color: cs.surfaceContainerHigh,
            onSelected: onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 16.0, color: cs.primary),
                    const SizedBox(width: 10.0),
                    const Text('Export PDF / TeX / SVG…'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
              child: Icon(
                Icons.arrow_drop_down_rounded,
                size: 18.0,
                color: cs.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
