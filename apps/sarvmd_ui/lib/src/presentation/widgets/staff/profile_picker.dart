import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'mini_staff_preview.dart';

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
    return currentConfig.systemLayout == profile.systemLayout;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width based on available space to form a grid
        // We want roughly 2 items per row in a 320px sidebar.
        final crossAxisCount = constraints.maxWidth > 250 ? 2 : 1;
        final spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        // Group profiles by category
        final grouped = <core.ProfileCategory, List<core.StaffProfile>>{};
        for (final profile in core.StaffProfiles.all) {
          grouped.putIfAbsent(profile.category, () => []).add(profile);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            final category = entry.key;
            final profiles = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                  child: Text(
                    _getCategoryLabel(category),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: profiles.map((profile) {
                    final active = _isActive(profile);
                    return SizedBox(
                      width: itemWidth,
                      child: _ProfileCard(
                        profile: profile,
                        active: active,
                        onTap: () => onProfileSelected(profile),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  String _getCategoryLabel(core.ProfileCategory category) {
    switch (category) {
      case core.ProfileCategory.standard:
        return 'STANDARD';
      case core.ProfileCategory.ensemble:
        return 'ENSEMBLE';
      case core.ProfileCategory.tablature:
        return 'TABLATURE';
      case core.ProfileCategory.percussion:
        return 'PERCUSSION';
      case core.ProfileCategory.blank:
        return 'OTHER';
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.active,
    required this.onTap,
  });

  final core.StaffProfile profile;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: active ? 1.5 : 1.0,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: Center(
                child: MiniStaffPreview(
                  systemLayout: profile.systemLayout,
                  active: active,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
            ),
            if (profile.description != null) ...[
              const SizedBox(height: 2),
              Text(
                profile.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: active
                      ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
