import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class JlptLevelChip extends StatelessWidget {
  const JlptLevelChip({super.key, required this.level});

  final String? level;

  @override
  Widget build(BuildContext context) {
    if (level == null) return const SizedBox.shrink();
    final color = JlptColors.forLevel(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level!,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
