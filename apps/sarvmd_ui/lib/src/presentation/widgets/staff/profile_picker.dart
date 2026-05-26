import 'package:flutter/material.dart';
import 'package:sarvmd_core/sarvmd_core.dart' as core;
import 'mini_staff_preview.dart';

class ProfilePicker extends StatefulWidget {
  const ProfilePicker({
    super.key,
    required this.currentConfig,
    required this.onProfileSelected,
  });

  final core.PageConfig currentConfig;
  final ValueChanged<core.StaffProfile> onProfileSelected;

  @override
  State<ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends State<ProfilePicker> {
  core.ProfileCategory? _selectedCategory; // null means 'All'

  /// Check if a profile is currently active.
  /// A profile is "active" if the layout type and clefs match.
  bool _isActive(core.StaffProfile profile) {
    return widget.currentConfig.systemLayout == profile.systemLayout;
  }

  String _getCategoryLabel(core.ProfileCategory category) {
    switch (category) {
      case core.ProfileCategory.standard:
        return 'Standard';
      case core.ProfileCategory.ensemble:
        return 'Ensemble';
      case core.ProfileCategory.tablature:
        return 'Tablature';
      case core.ProfileCategory.percussion:
        return 'Percussion';
      case core.ProfileCategory.blank:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter profiles based on the selected category
    final filteredProfiles = core.StaffProfiles.all.where((profile) {
      if (_selectedCategory == null) return true;
      return profile.category == _selectedCategory;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width based on available space to form a grid
        // We want roughly 2 items per row in a 320px sidebar.
        final crossAxisCount = constraints.maxWidth > 250 ? 2 : 1;
        const spacing = 8.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                crossAxisCount;

        final colorScheme = Theme.of(context).colorScheme;
        final allTabs = <core.ProfileCategory?>[null, ...core.ProfileCategory.values];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sliding/Scrollable Category Pill Selector ───
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: allTabs.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = allTabs[index];
                  final label = cat == null ? 'All' : _getCategoryLabel(cat);
                  final isSelected = _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            letterSpacing: 0.3,
                          ),
                          child: Text(label),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            
            // ── Animated Switcher for Smooth Tab Transitions ───
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.04),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_selectedCategory),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: filteredProfiles.map((profile) {
                    final active = _isActive(profile);
                    return SizedBox(
                      width: itemWidth,
                      child: _ProfileCard(
                        profile: profile,
                        active: active,
                        showCategoryTag: _selectedCategory == null,
                        onTap: () => widget.onProfileSelected(profile),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({
    required this.profile,
    required this.active,
    required this.showCategoryTag,
    required this.onTap,
  });

  final core.StaffProfile profile;
  final bool active;
  final bool showCategoryTag;
  final VoidCallback onTap;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _isHovered = false;

  String _getCategoryLabel(core.ProfileCategory category) {
    switch (category) {
      case core.ProfileCategory.standard:
        return 'Standard';
      case core.ProfileCategory.ensemble:
        return 'Ensemble';
      case core.ProfileCategory.tablature:
        return 'Tablature';
      case core.ProfileCategory.percussion:
        return 'Percussion';
      case core.ProfileCategory.blank:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = widget.active;

    // Card background styling
    // Inactive card is a sleek frosted surface. Active card lights up with primary tint gradient.
    final Decoration decoration = BoxDecoration(
      gradient: active
          ? LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.12),
                colorScheme.primary.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: active
          ? null
          : _isHovered
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: active
            ? colorScheme.primary.withValues(alpha: 0.7)
            : _isHovered
                ? colorScheme.primary.withValues(alpha: 0.25)
                : colorScheme.outlineVariant.withValues(alpha: 0.12),
        width: active ? 1.5 : 1.0,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
          : _isHovered
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _isHovered ? 1.03 : 1.0,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _isHovered ? -2.0 : 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: decoration,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MiniStaffPreview(
                      systemLayout: widget.profile.systemLayout,
                      active: active,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.profile.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.bold : FontWeight.w600,
                        color: active
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        letterSpacing: 0.2,
                      ),
                    ),
                    
                    // Show description with standard clamp lines
                    if (widget.profile.description != null) ...[
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 24, // Keep card heights unified
                        child: Text(
                          widget.profile.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.25,
                            color: active
                                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.8)
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ],

                    // Category Tag (visible only under 'All' tab)
                    if (widget.showCategoryTag) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: active
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getCategoryLabel(widget.profile.category).toUpperCase(),
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Top-right Glowing Active Checkmark Badge
                if (active)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
