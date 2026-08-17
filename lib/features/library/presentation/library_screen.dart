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
    return DefaultTabController(
      length: _kLevels.length,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Text('Library', style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [for (final level in _kLevels) Tab(text: level)],
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return manifestAsync.when(
      data: (manifest) {
        final stories = manifest.where((s) => s.level == level).toList();
        if (stories.isEmpty) {
          return Center(child: Text('No stories yet', style: textTheme.bodyMedium));
        }
        final progress = progressAsync.value ?? const {};

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: stories.length,
          separatorBuilder: (_, _) => Padding(
            padding: const EdgeInsets.only(left: 54),
            child: Divider(height: 1, color: colorScheme.surfaceContainerHighest),
          ),
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
      error: (error, stackTrace) =>
          Center(child: Text('Could not load stories.', style: TextStyle(color: colorScheme.error))),
    );
  }
}
