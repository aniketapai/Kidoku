import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/story.dart';

/// A single flat row in the story list. Deliberately has no card border or
/// background of its own — with dozens of stories per level, per-row
/// chrome compounds into visual noise, so rows rely on the shared list
/// divider for separation instead. The JLPT level is intentionally omitted
/// here since the enclosing tab already filters by level.
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

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                completed ? Icons.menu_book_rounded : Icons.auto_stories_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    meta.titleEn,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (completed)
              Icon(Icons.check_circle_rounded, size: 18, color: colorScheme.secondary)
            else if (inProgress)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 2.2,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
