import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/achievements_table.dart';
import '../../application/achievement_actions_provider.dart';
import '../../application/achievements_provider.dart';
import 'add_achievement_dialog.dart';
import 'certificate_viewer.dart';
import 'profile_section_card.dart';

class AchievementsSection extends ConsumerWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return ProfileSectionCard(
      title: 'Achievements',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Add certificate',
        onPressed: () => showAddAchievementDialog(context),
      ),
      child: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) return const _EmptyAchievements();
          return Column(
            children: [
              for (final achievement in achievements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AchievementCard(achievement: achievement),
                ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Text('Failed to load achievements: $error'),
      ),
    );
  }
}

class _EmptyAchievements extends StatelessWidget {
  const _EmptyAchievements();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'No certificates yet — tap + to log a JLPT or NAT-TEST result.',
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _AchievementCard extends ConsumerWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isJlpt = achievement.type == CertificateType.jlpt;
    final badgeColor = isJlpt ? colorScheme.primary : colorScheme.secondary;
    final earned = achievement.earnedAt;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Thumbnail(
            imagePath: achievement.imagePath,
            badgeColor: badgeColor,
            onTap: achievement.imagePath == null
                ? null
                : () => showCertificateViewer(context, achievement.imagePath!),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isJlpt ? 'JLPT ${achievement.level}' : 'NAT-TEST Level ${achievement.level}',
                  style: textTheme.titleSmall,
                ),
                Text(
                  '${earned.year}-${earned.month.toString().padLeft(2, '0')}-'
                  '${earned.day.toString().padLeft(2, '0')}'
                  '${achievement.note != null ? ' · ${achievement.note}' : ''}',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Remove',
            onPressed: () => ref.read(achievementActionsProvider.notifier).delete(achievement.id),
          ),
        ],
      ),
    );
  }
}

/// The certificate photo, minimized to a small thumbnail — tap to view it
/// full-size. Falls back to a plain badge icon when no photo was attached.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath, required this.badgeColor, required this.onTap});

  final String? imagePath;
  final Color badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = imagePath == null
        ? Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: badgeColor.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(Icons.workspace_premium_rounded, color: badgeColor),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(imagePath!),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: content,
    );
  }
}
