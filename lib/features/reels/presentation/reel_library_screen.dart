import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clearable_search_field.dart';
import '../application/reel_providers.dart';
import '../domain/reel.dart';
import 'reels_screen.dart';

/// Landing screen for video-based learning: search + creator tags up top,
/// a browsable list of videos below. Tapping a video pushes [ReelsScreen]
/// for just that video — synced-transcript playback, one video at a time.
/// Back out to return here and pick another.
class ReelLibraryScreen extends ConsumerStatefulWidget {
  const ReelLibraryScreen({super.key});

  @override
  ConsumerState<ReelLibraryScreen> createState() => _ReelLibraryScreenState();
}

class _ReelLibraryScreenState extends ConsumerState<ReelLibraryScreen> {
  String _query = '';
  String? _selectedCreator;

  List<ReelMeta> _filter(List<ReelMeta> reels) {
    final query = _query.trim().toLowerCase();
    return reels.where((reel) {
      if (_selectedCreator != null && reel.creator != _selectedCreator) {
        return false;
      }
      if (query.isEmpty) return true;
      return reel.title.toLowerCase().contains(query) ||
          reel.titleEn.toLowerCase().contains(query) ||
          reel.creator.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final manifestAsync = ref.watch(reelManifestProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [Text('Videos', style: textTheme.headlineSmall)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClearableSearchField(
              hintText: 'Search videos or creators…',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: manifestAsync.when(
              data: (reels) {
                if (reels.isEmpty) {
                  return Center(
                    child: Text('No videos yet.', style: textTheme.bodyMedium),
                  );
                }
                final creators = {
                  for (final reel in reels) reel.creator,
                }.toList()..sort();
                final filtered = _filter(reels);

                return Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 20, right: 20),
                        children: [
                          _TagChip(
                            label: 'All',
                            selected: _selectedCreator == null,
                            onTap: () =>
                                setState(() => _selectedCreator = null),
                          ),
                          for (final creator in creators)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _TagChip(
                                label: creator,
                                selected: _selectedCreator == creator,
                                onTap: () => setState(
                                  () => _selectedCreator =
                                      _selectedCreator == creator
                                      ? null
                                      : creator,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No videos match.',
                                style: textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                110,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final meta = filtered[index];
                                return _VideoCard(
                                  meta: meta,
                                  onTap: () => context.push(
                                    AppRoutes.reelPlayer,
                                    extra: ReelPlayerArgs(meta: meta),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Couldn\'t load videos: $error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.meta, required this.onTap});

  final ReelMeta meta;
  final VoidCallback onTap;

  String get _durationLabel {
    final totalSeconds = meta.durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.surfaceContainerHighest),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 120,
                  // 16:9 at 120 wide — spelled out explicitly rather than
                  // via AspectRatio, which can't resolve a size here: this
                  // Row sits inside a ListView item, so both the width and
                  // height it hands children are unbounded, and
                  // RenderAspectRatio needs at least one bounded dimension
                  // to size itself from.
                  height: 120 * 9 / 16,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://img.youtube.com/vi/${meta.videoId}/hqdefault.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.play_circle_outline,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            child: Text(
                              _durationLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final level in meta.levels)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: JlptColors.forLevel(
                                level,
                              ).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              level,
                              style: TextStyle(
                                color: JlptColors.forLevel(level),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      meta.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.titleEn,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.creator,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
