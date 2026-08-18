import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../application/story_providers.dart';
import 'widgets/story_card.dart';

const _kLevels = ['N5', 'N4', 'N3'];

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: _kLevels.length,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.auto_stories_rounded, color: colorScheme.onPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stories',
                          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Graded readers for your level',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  splashBorderRadius: BorderRadius.circular(10),
                  labelColor: colorScheme.onPrimary,
                  unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
                  tabs: [for (final level in _kLevels) Tab(text: level)],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _StoryList(level: 'N5'),
                  _StoryList(level: 'N4'),
                  _StoryList(level: 'N3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryList extends ConsumerWidget {
  const _StoryList({required this.level});

  final String level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifestAsync = ref.watch(storyManifestProvider);
    final progressAsync = ref.watch(allStoryProgressProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return manifestAsync.when(
      data: (manifest) {
        final stories = manifest.where((s) => s.level == level).toList();
        if (stories.isEmpty) {
          return _EmptyState(
            icon: Icons.auto_stories_outlined,
            message: 'No stories yet',
          );
        }
        final progress = progressAsync.value ?? const {};

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          itemCount: stories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final meta = stories[index];
            return StoryCard(
              meta: meta,
              progress: progress[meta.id],
              onTap: () => context.push(AppRoutes.storyReader, extra: meta),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _EmptyState(
        icon: Icons.error_outline_rounded,
        message: 'Could not load stories.',
        color: colorScheme.error,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.color});

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tint = color ?? colorScheme.onSurface.withValues(alpha: 0.35);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: tint),
          const SizedBox(height: 12),
          Text(message, style: textTheme.bodyMedium?.copyWith(color: tint)),
        ],
      ),
    );
  }
}
