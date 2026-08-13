import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/meanings_codec.dart';
import '../../../core/widgets/clearable_search_field.dart';
import '../../../core/widgets/jlpt_level_chip.dart';
import '../../reader/presentation/widgets/lookup_bottom_sheet.dart';
import '../application/dictionary_search_provider.dart';

class DictionaryScreen extends ConsumerWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(dictionarySearchQueryProvider);
    final resultsAsync = ref.watch(dictionarySearchResultsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ClearableSearchField(
              hintText: 'Search Japanese or English…',
              textInputAction: TextInputAction.search,
              onChanged: (value) => ref.read(dictionarySearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? _EmptyState(colorScheme: colorScheme)
                : resultsAsync.when(
                    data: (results) {
                      if (results.isEmpty) {
                        return Center(
                          child: Text('No matches for "$query"', style: textTheme.bodyMedium),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = results[index];
                          return _ResultTile(
                            dictionaryForm: entry.dictionaryForm,
                            reading: entry.reading,
                            meaning: decodeMeanings(entry.meanings),
                            partOfSpeech: entry.partOfSpeech,
                            jlptLevel: entry.jlptLevel,
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(child: Text('Search failed: $error')),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.dictionaryForm,
    required this.reading,
    required this.meaning,
    required this.partOfSpeech,
    required this.jlptLevel,
  });

  final String dictionaryForm;
  final String reading;
  final String meaning;
  final String partOfSpeech;
  final String? jlptLevel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showLookupBottomSheet(context, dictionaryForm),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.surfaceContainerHighest),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          dictionaryForm,
                          style: textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          reading,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meaning,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    partOfSpeech,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            JlptLevelChip(level: jlptLevel),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text('Dictionary', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Look up any Japanese or English word.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
