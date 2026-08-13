import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/database/tables/user_words_table.dart';
import '../application/word_status_provider.dart';
import '../data/activity_repository.dart';
import 'widgets/achievements_section.dart';
import 'widgets/activity_graph.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_section_card.dart';
import 'widgets/stat_tile.dart';

/// The router only ever shows this screen to a signed-in (non-anonymous)
/// user — see the auth redirect in app_router.dart — so there's no sign-in
/// affordance here, just the account's read-only info and stats.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
        children: [
          userAsync.when(
            data: (user) => user == null
                ? const SizedBox.shrink()
                : ProfileHeaderCard(user: user),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          const _StatsSection(),
          const SizedBox(height: 16),
          const _ActivitySection(),
          const SizedBox(height: 16),
          const AchievementsSection(),
          const SizedBox(height: 32),
          Text(
            'Dictionary data from JMdict/EDICT (Electronic Dictionary '
            'Research and Development Group), used under CC BY-SA 4.0.',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall
                ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(activityStatsProvider);
    final wordStatusAsync = ref.watch(wordStatusCountsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final stats = statsAsync.value ?? ActivityStats.empty;
    final wordStatus = wordStatusAsync.value ?? const <WordStatus, int>{};

    return ProfileSectionCard(
      title: 'Stats',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: stats.currentStreak > 0 ? Colors.deepOrange : colorScheme.outline,
                  value: '${stats.currentStreak}',
                  label: 'Day streak',
                ),
              ),
              Expanded(
                child: StatTile(
                  icon: Icons.emoji_events_rounded,
                  iconColor: colorScheme.secondary,
                  value: '${stats.longestStreak}',
                  label: 'Best streak',
                ),
              ),
              Expanded(
                child: StatTile(
                  icon: Icons.fact_check_rounded,
                  iconColor: colorScheme.primary,
                  value: '${stats.totalReviews}',
                  label: 'Reviews (1y)',
                ),
              ),
              Expanded(
                child: StatTile(
                  icon: Icons.track_changes_rounded,
                  iconColor: colorScheme.primary,
                  value: '${(stats.overallAccuracy * 100).round()}%',
                  label: 'Accuracy',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colorScheme.surfaceContainerHighest, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WordCountChip(
                  label: 'Known',
                  count: wordStatus[WordStatus.known] ?? 0,
                  color: colorScheme.primary,
                ),
              ),
              Expanded(
                child: _WordCountChip(
                  label: 'Learning',
                  count: wordStatus[WordStatus.learning] ?? 0,
                  color: colorScheme.secondary,
                ),
              ),
              Expanded(
                child: _WordCountChip(
                  label: 'Saved',
                  count: wordStatus[WordStatus.saved] ?? 0,
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WordCountChip extends StatelessWidget {
  const _WordCountChip({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text('$count', style: textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(activityStatsProvider);

    return Column(
      children: [
        ProfileSectionCard(
          title: 'Activity',
          child: statsAsync.when(
            data: (stats) => ActivityHeatmap(days: stats.days),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text('Failed to load activity: $error'),
          ),
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          title: 'Last 14 days',
          child: statsAsync.when(
            data: (stats) => ActivityGraph(days: stats.days),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text('Failed to load trend: $error'),
          ),
        ),
      ],
    );
  }
}
