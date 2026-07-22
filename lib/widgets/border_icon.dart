import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BorderIcon extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width, height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  BorderIcon({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final widget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? c.surface,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        border: Border.all(
          color: borderColor ?? c.border,
          width: 1,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(8),
      child: Center(child: child),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: widget);
    }
    return widget;
  }
}
