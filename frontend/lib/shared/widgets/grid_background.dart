import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Tiled grid PNG background used on every screen.
/// Wrap the screen Stack's first child with this for consistent performance.
class GridBackground extends StatelessWidget {
  const GridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: Image.asset(
          'assets/bg_grid.png',
          repeat: ImageRepeat.repeat,
          color: AppColors.primary.withOpacity(0.07),
          colorBlendMode: BlendMode.screen,
          // Fallback: if PNG not present, show plain bgDeep
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: AppColors.bgDeep),
        ),
      ),
    );
  }
}
