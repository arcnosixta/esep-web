import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Основная кнопка приложения: лёгкое «сжатие» при нажатии
/// (scale 0.97 + подъём тени), плавный возврат при отпускании.
class OptionButton extends StatefulWidget {
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
  State<OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<OptionButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (mounted && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bg = widget.backgroundColor ?? c.accent;
    final fg = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                widget.width != null ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(widget.icon, color: fg, size: 18),
              const SizedBox(width: 10),
              Text(
                widget.text,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
