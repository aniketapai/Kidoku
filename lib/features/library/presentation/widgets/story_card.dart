import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/story.dart';

/// A single story row, styled as a soft card so stories read as distinct,
/// tappable items rather than a plain list. The JLPT level is intentionally
/// omitted from the card body since the enclosing tab already filters by
/// level — its color still shows up as a subtle accent on the icon tile.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.meta, required this.progress, required this.onTap});

  final StoryMeta meta;
  final StoryProgressData? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final completed = progress?.completed ?? false;
    final pagesRead = progress?.lastPageIndex ?? 0;
    final inProgress = !completed && pagesRead > 0;
    final fraction = meta.pageCount > 0 ? (pagesRead / meta.pageCount).clamp(0.0, 1.0) : 0.0;
    final levelColor = JlptColors.forLevel(meta.level);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.surfaceContainerHighest),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  completed ? Icons.menu_book_rounded : Icons.auto_stories_outlined,
                  size: 20,
                  color: levelColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.titleEn,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (inProgress) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 4,
                          color: colorScheme.primary,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (completed)
                Icon(Icons.check_circle_rounded, size: 20, color: colorScheme.secondary)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
