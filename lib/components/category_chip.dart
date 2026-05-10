import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final Color color;
  final String icon; // emoji or text
  final String? label;
  final double size;
  final VoidCallback? onTap;

  const CategoryChip({
    Key? key,
    required this.color,
    required this.icon,
    this.label,
    this.size = 28,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(icon, style: TextStyle(fontSize: size * 0.6)),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(label!, style: TextStyle(fontSize: 14)),
        ]
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
