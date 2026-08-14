import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../library/application/story_providers.dart';
import '../../../library/domain/story.dart';
import 'profile_section_card.dart';
import 'stat_tile.dart';

/// Reading stats over the Library's graded-reader stories, plus a shortcut
/// back into whatever's still in progress — mirrors [AchievementsSection]'s
/// card so the profile screen surfaces reading the same way it surfaces
/// vocabulary and reviews.
class StoryProgressSection extends ConsumerWidget {
  const StoryProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestAsync = ref.watch(storyManifestProvider);
    final progressAsync = ref.watch(allStoryProgressProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return manifestAsync.when(
      data: (manifest) {
        final progress = progressAsync.value ?? const {};
        final completedCount = progress.values.where((p) => p.completed).length;
        final inProgress = manifest.where((meta) {
          final p = progress[meta.id];
          return p != null && !p.completed && p.lastPageIndex > 0;
        }).toList()
          ..sort((a, b) => progress[b.id]!.updatedAt.compareTo(progress[a.id]!.updatedAt));

        return ProfileSectionCard(
          title: 'Reading',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.menu_book_rounded,
                      iconColor: colorScheme.primary,
                      value: '$completedCount',
                      label: 'Completed',
                    ),
                  ),
                  Expanded(
                    child: StatTile(
                      icon: Icons.auto_stories_rounded,
                      iconColor: colorScheme.secondary,
                      value: '${inProgress.length}',
                      label: 'In progress',
                    ),
                  ),
                  Expanded(
                    child: StatTile(
                      icon: Icons.collections_bookmark_rounded,
                      iconColor: colorScheme.outline,
                      value: '${manifest.length}',
                      label: 'Available',
                    ),
                  ),
                ],
              ),
              if (inProgress.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: colorScheme.surfaceContainerHighest, height: 1),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Continue reading',
                    style: textTheme.labelMedium
                        ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ),
                const SizedBox(height: 10),
                for (final meta in inProgress.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ContinueReadingTile(
                      meta: meta,
                      lastPageIndex: progress[meta.id]!.lastPageIndex,
                      onTap: () => context.push(AppRoutes.storyReader, extra: meta),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
      loading: () => const ProfileSectionCard(
        title: 'Reading',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) => ProfileSectionCard(
        title: 'Reading',
        child: Text('Failed to load reading progress: $error'),
      ),
    );
  }
}

class _ContinueReadingTile extends StatelessWidget {
  const _ContinueReadingTile({required this.meta, required this.lastPageIndex, required this.onTap});

  final StoryMeta meta;
  final int lastPageIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fraction =
        meta.pageCount == 0 ? 0.0 : ((lastPageIndex + 1) / meta.pageCount).clamp(0.0, 1.0);

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 5,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
