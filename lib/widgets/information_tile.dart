import 'package:flutter/material.dart';
import 'border_icon.dart';

class InformationTile extends StatelessWidget {
  final String content;
  final String name;
  final IconData? icon;
  final double? size;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? valueColor;

  const InformationTile({
    super.key,
    required this.content,
    required this.name,
    this.icon,
    this.size,
    this.backgroundColor,
    this.borderColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final tileSize = size ?? MediaQuery.of(context).size.width * 0.20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BorderIcon(
          width: tileSize,
          height: tileSize,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          child: icon != null
              ? Icon(icon, size: 22, color: valueColor)
              : Text(
                  content,
                  style: theme.headlineSmall?.copyWith(
                    color: valueColor,
                    fontSize: 18,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: theme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
