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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width based on available space to form a grid
        // We want roughly 2 items per row in a 320px sidebar.
        final crossAxisCount = constraints.maxWidth > 250 ? 2 : 1;
        final spacing = 8.0;
        final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: core.StaffProfiles.all.map((profile) {
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
        );
      },
    );
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
                child: _MiniStaffPreview(
                  layoutType: profile.layoutType,
                  primaryClef: profile.primaryClef?.symbol,
                  secondaryClef: profile.secondaryClef?.symbol,
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

class _MiniStaffPreview extends StatelessWidget {
  const _MiniStaffPreview({
    required this.layoutType,
    this.primaryClef,
    this.secondaryClef,
    required this.active,
  });

  final core.LayoutType layoutType;
  final core.ClefSymbol? primaryClef;
  final core.ClefSymbol? secondaryClef;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? colorScheme.primary : colorScheme.onSurfaceVariant;
    
    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: _MiniStaffPainter(
        layoutType: layoutType,
        primaryClef: primaryClef,
        secondaryClef: secondaryClef,
        color: color,
      ),
    );
  }
}

class _MiniStaffPainter extends CustomPainter {
  _MiniStaffPainter({
    required this.layoutType,
    this.primaryClef,
    this.secondaryClef,
    required this.color,
  });

  final core.LayoutType layoutType;
  final core.ClefSymbol? primaryClef;
  final core.ClefSymbol? secondaryClef;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final lineGap = 2.0;
    
    void drawStaff(double topY) {
      for (int i = 0; i < 5; i++) {
        final y = topY + (i * lineGap);
        canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
      }
    }

    void drawClefProxy(core.ClefSymbol symbol, double topY) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: symbol.name.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(12, topY + (lineGap * 2) - (textPainter.height / 2)),
      );
    }

    if (layoutType == core.LayoutType.singleLine) {
      final staffTop = (size.height - (4 * lineGap)) / 2;
      drawStaff(staffTop);
      if (primaryClef != null) {
        drawClefProxy(primaryClef!, staffTop);
      }
    } else {
      // Double line (Piano)
      final totalHeight = (4 * lineGap) * 2 + 6.0; // two staffs + 6px gap
      final topStaffY = (size.height - totalHeight) / 2;
      final bottomStaffY = topStaffY + (4 * lineGap) + 6.0;

      // Draw brace proxy
      final bracePaint = Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      final bracePath = Path()
        ..moveTo(8, topStaffY)
        ..quadraticBezierTo(4, topStaffY + totalHeight / 2, 8, topStaffY + totalHeight);
      canvas.drawPath(bracePath, bracePaint);

      drawStaff(topStaffY);
      drawStaff(bottomStaffY);
      
      if (primaryClef != null) drawClefProxy(primaryClef!, topStaffY);
      if (secondaryClef != null) drawClefProxy(secondaryClef!, bottomStaffY);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniStaffPainter oldDelegate) {
    return oldDelegate.layoutType != layoutType ||
        oldDelegate.primaryClef != primaryClef ||
        oldDelegate.secondaryClef != secondaryClef ||
        oldDelegate.color != color;
  }
}
