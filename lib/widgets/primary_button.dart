import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final bool outlined;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 52,
    this.outlined = false,
    this.icon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 80),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => _controller.forward() : null,
      onTapUp: enabled
          ? (_) {
              _controller.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: _buildButton(enabled),
          );
        },
      ),
    );
  }

  Widget _buildButton(bool enabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: widget.outlined
          ? BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled
                    ? AppColors.accent
                    : AppColors.accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            )
          : BoxDecoration(
              color: enabled ? AppColors.accent : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          onTap: widget.onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon,
                      color: enabled ? Colors.white : AppColors.textHint,
                      size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? Colors.white
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
