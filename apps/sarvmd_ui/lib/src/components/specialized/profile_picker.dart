import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;

class ProfilePicker extends StatelessWidget {
  const ProfilePicker({
    super.key,
    required this.currentConfig,
    required this.onProfileSelected,
  });

  final core.PageConfig currentConfig;
  final ValueChanged<core.StaffProfile> onProfileSelected;

  /// Check if a profile is currently active.
  /// A profile is "active" if the layout type and clefs match.
  bool _isActive(core.StaffProfile profile) {
    return currentConfig.layoutType == profile.layoutType &&
        currentConfig.primaryClef == profile.primaryClef &&
        currentConfig.secondaryClef == profile.secondaryClef;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: core.StaffProfiles.all.map((profile) {
        final active = _isActive(profile);
        return GestureDetector(
          onTap: () => onProfileSelected(profile),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: active ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              profile.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
