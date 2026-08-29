import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-bleed white-to-pale-green gradient backdrop with two soft green
/// glow blobs, used behind every screen so the app reads as one consistent
/// surface rather than a flat default background.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _Glow(
            color: AppColors.primary.withValues(alpha: 0.14),
            size: 280,
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: _Glow(
            color: AppColors.accent.withValues(alpha: 0.16),
            size: 300,
          ),
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
