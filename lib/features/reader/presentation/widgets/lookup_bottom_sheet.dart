import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/meanings_codec.dart';
import '../../../../core/database/tables/user_words_table.dart';
import '../../../../core/kanji/widgets/kanji_stroke_sheet.dart';
import '../../../../core/text/kanji_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jlpt_level_chip.dart';
import '../../../decks/application/deck_data_providers.dart';
import '../../application/dictionary_lookup_provider.dart';
import '../../application/user_word_actions_provider.dart';
import '../../application/user_word_provider.dart';

Future<void> showLookupBottomSheet(BuildContext context, String dictionaryForm) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => LookupBottomSheet(dictionaryForm: dictionaryForm),
  );
}

class LookupBottomSheet extends ConsumerWidget {
  const LookupBottomSheet({super.key, required this.dictionaryForm});

  final String dictionaryForm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(dictionaryLookupProvider(dictionaryForm));
    final userWordAsync = ref.watch(userWordProvider(dictionaryForm));
    final kanjiLevels = ref.watch(kanjiLevelMapProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: entryAsync.when(
          data: (entry) {
            if (entry == null) {
              return Text('No dictionary entry for "$dictionaryForm".',
                  style: textTheme.bodyMedium);
            }
            final status = userWordAsync.value?.status;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.reading,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              )),
                          Text(entry.dictionaryForm, style: textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    JlptLevelChip(level: entry.jlptLevel),
                  ],
                ),
                const SizedBox(height: 4),
                Text(entry.partOfSpeech,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
                _KanjiLevelTags(word: entry.dictionaryForm, kanjiLevels: kanjiLevels),
                const SizedBox(height: 12),
                Text(decodeMeanings(entry.meanings), style: textTheme.bodyLarge),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ref
                            .read(userWordActionsProvider.notifier)
                            .markKnown(dictionaryForm),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(status == WordStatus.known ? 'Known' : 'Mark Known'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: colorScheme.secondary),
                        onPressed: () => ref
                            .read(userWordActionsProvider.notifier)
                            .save(dictionaryForm),
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: Text(status == WordStatus.saved ? 'Saved' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Text('Lookup failed: $error'),
        ),
      ),
    );
  }
}

/// Per-kanji chips for [word]'s individual characters — distinct from the
/// word's own [JlptLevelChip], since a vocab entry can be tagged N5 while
/// spelled with a kanji that isn't actually N5 on its own. Every distinct
/// kanji is tappable to open its stroke-order animation
/// ([showKanjiStrokeSheet]); the JLPT badge only shows for characters
/// present in the imported kanji decks. Renders nothing for kana-only
/// words.
class _KanjiLevelTags extends StatelessWidget {
  const _KanjiLevelTags({required this.word, required this.kanjiLevels});

  final String word;
  final Map<String, String> kanjiLevels;

  @override
  Widget build(BuildContext context) {
    final chars = {for (final ch in extractKanji(word)) ch: true}.keys;
    if (chars.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final ch in chars)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showKanjiStrokeSheet(context, ch),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (kanjiLevels[ch] != null
                          ? JlptColors.forLevel(kanjiLevels[ch])
                          : colorScheme.onSurface)
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  kanjiLevels[ch] != null ? '$ch ${kanjiLevels[ch]}' : ch,
                  style: textTheme.labelSmall?.copyWith(
                    color: kanjiLevels[ch] != null
                        ? JlptColors.forLevel(kanjiLevels[ch])
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
