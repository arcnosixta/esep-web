import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// Медленно плывущие цветные «пятна» на фоне экрана (aurora).
///
/// Три радиальных градиента с низкой прозрачностью циркулируют
/// с разными скоростями — фон «дышит», но не мешает читаемости.
/// В тёмной теме пятна заметнее, в светлой — деликатнее.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: Stack(
        children: [
          // Синее пятно — верхний левый угол.
          Positioned(
            top: -140,
            left: -100,
            child: _Blob(
              size: 360,
              color: c.accent.withValues(alpha: dark ? 0.20 : 0.10),
            ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).move(
                  duration: 11.seconds,
                  begin: const Offset(0, 0),
                  end: const Offset(64, 44),
                  curve: Curves.easeInOut,
                ),
          ),
          // Золотое пятно — правая сторона, чуть ниже.
          Positioned(
            top: 200,
            right: -120,
            child: _Blob(
              size: 320,
              color: c.gold.withValues(alpha: dark ? 0.16 : 0.08),
            ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).move(
                  duration: 14.seconds,
                  begin: const Offset(0, 0),
                  end: const Offset(-56, 64),
                  curve: Curves.easeInOut,
                ),
          ),
          // Светло-синее пятно — внизу слева.
          Positioned(
            bottom: -160,
            left: 40,
            child: _Blob(
              size: 400,
              color: c.accentLight.withValues(alpha: dark ? 0.14 : 0.07),
            ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).move(
                  duration: 17.seconds,
                  begin: const Offset(0, 0),
                  end: const Offset(84, -48),
                  curve: Curves.easeInOut,
                ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
