import 'package:flutter/material.dart';

/// Число, которое «досчитывается» от 0 до value при первом появлении.
/// Используется для счётчиков статистики на дашбордах.
class AnimatedCountText extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedCountText(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(
          v.round().toString(),
          style: style,
        );
      },
    );
  }
}
