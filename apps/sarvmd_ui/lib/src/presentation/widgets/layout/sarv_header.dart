import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The primary branding header for SarvMD, featuring the handwriting logo
/// and the 'Manuscript Designer' subtitle in IranNastaliq.
class SarvHeader extends StatelessWidget {
  const SarvHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/handwriting/Sarv Handwriting.svg',
            height: 64,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Manuscript Designer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              fontSize: 18,
              fontFamily: 'IranNastaliq',
              letterSpacing: 1.2,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
