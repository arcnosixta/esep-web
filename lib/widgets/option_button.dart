import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OptionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const OptionButton({
    super.key,
    required this.text,
    required this.icon,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.accent;
    final fg = textColor ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: width != null ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
