import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import '../../../../l10n/app_localizations.dart';

/// Segmented button control for selecting bracket/brace/none connectors.
class ConnectorPicker extends StatelessWidget {
  const ConnectorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final core.SystemConnector value;
  final ValueChanged<core.SystemConnector> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<core.SystemConnector>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment<core.SystemConnector>(
          value: core.SystemConnector.none,
          label: Text(
            l10n.connectorNone,
            style: TextStyle(fontSize: compact ? 9 : 10),
          ),
        ),
        ButtonSegment<core.SystemConnector>(
          value: core.SystemConnector.bracket,
          label: Text(
            l10n.connectorBracket,
            style: TextStyle(fontSize: compact ? 9 : 10),
          ),
        ),
        ButtonSegment<core.SystemConnector>(
          value: core.SystemConnector.brace,
          label: Text(
            l10n.connectorBrace,
            style: TextStyle(fontSize: compact ? 9 : 10),
          ),
        ),
      ],
      selected: {value},
      onSelectionChanged: (set) => onChanged(set.first),
      style: SegmentedButton.styleFrom(
        visualDensity: compact
            ? VisualDensity.compact
            : const VisualDensity(horizontal: -2, vertical: -2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Compact popup menu button for picking system connectors in narrow toolbars.
class ConnectorMenuButton extends StatelessWidget {
  const ConnectorMenuButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final core.SystemConnector value;
  final ValueChanged<core.SystemConnector> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final IconData iconData = switch (value) {
      core.SystemConnector.brace => Icons.code,
      core.SystemConnector.bracket => Icons.reorder,
      core.SystemConnector.subBracket => Icons.reorder,
      core.SystemConnector.none => Icons.linear_scale,
    };

    return PopupMenuButton<core.SystemConnector>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: l10n.systemGrouping,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 14, color: cs.primary),
            Icon(Icons.arrow_drop_down,
                size: 12, color: cs.primary.withValues(alpha: 0.7)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: core.SystemConnector.none,
          child: Row(
            children: [
              Icon(Icons.linear_scale, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(l10n.connectorNone, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: core.SystemConnector.bracket,
          child: Row(
            children: [
              Icon(Icons.reorder, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.connectorBracket, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem(
          value: core.SystemConnector.brace,
          child: Row(
            children: [
              Icon(Icons.code, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.connectorBrace, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
