import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Универсальная карточка ESEP: при наведении (web) слегка приподнимается,
/// усиливается тень и подсвечивается рамка; при нажатии — лёгкое сжатие.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.onTap != null
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.onTap != null
            ? () => setState(() => _pressed = false)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
          padding: widget.padding,
          transform: Matrix4.translationValues(
            0.0,
            _pressed ? 1.0 : (_hovered ? -2.0 : 0.0),
            0.0,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? c.accent.withValues(alpha: 0.35)
                  : c.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _hovered ? 0.08 : 0.03,
                ),
                blurRadius: _hovered ? 24 : 10,
                offset: Offset(0, _hovered ? 8 : 3),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
