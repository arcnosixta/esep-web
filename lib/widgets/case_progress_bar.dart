import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CaseProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? fillColor;

  const CaseProgressBar({
    super.key,
    required this.progress,
    this.height = 4,
    this.backgroundColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              color: backgroundColor ?? AppColors.surfaceLight,
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                color: fillColor ?? AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
