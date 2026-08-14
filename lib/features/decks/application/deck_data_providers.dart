import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/deck_cards_table.dart';
import '../data/deck_repository.dart';

// Hand-written (not @riverpod codegen) — see dictionary_search_provider.dart for why.

final deckCardsProvider = StreamProvider.autoDispose<List<DeckCard>>((ref) {
  return ref.watch(deckRepositoryProvider).watchDeckCards();
});

/// One shared subscription for progress across all cards/directions —
/// avoids a separate DB-backed stream per card.
final deckCardProgressProvider =
    StreamProvider.autoDispose<Map<String, DeckCardProgressData>>((ref) {
  return ref.watch(deckRepositoryProvider).watchAllDeckCardProgress();
});

/// Kanji character -> JLPT level ("N5".."N1"), derived from the imported
/// kanji decks — the single source of truth for the story reader's per-page
/// level bar and the dictionary lookup sheet's kanji tags.
final kanjiLevelMapProvider = Provider.autoDispose<Map<String, String>>((ref) {
  final cards = ref.watch(deckCardsProvider).value ?? const [];
  return {
    for (final c in cards)
      if (c.cardType == DeckCardType.kanji) c.expression: c.level,
  };
});

/// One JLPT-level-and-week/topic chunk of vocab cards (e.g. "N4 · Week 3.1
/// Money and Shopping"), matching how the seed data's [DeckCard.category]
/// groups cards — see the Vocabulary screen's own grouping for the same
/// pattern applied to browsing rather than session-building.
class VocabWeekGroup {
  const VocabWeekGroup({required this.level, required this.category, required this.cards});

  final String level;
  final String? category;
  final List<DeckCard> cards;

  String get key => '$level|${category ?? ''}';
  String get label => category != null ? '$level · $category' : level;
}

/// Vocab cards grouped by level+category, preserving first-appearance order
/// (so weeks stay in deck order: Week 1.1, Week 1.2, ...) — backs Free
/// Review's week-deck search/picker.
final vocabWeekGroupsProvider = Provider.autoDispose<List<VocabWeekGroup>>((ref) {
  final cards = ref.watch(deckCardsProvider).value ?? const [];
  final order = <String>[];
  final byKey = <String, List<DeckCard>>{};
  final labelOf = <String, ({String level, String? category})>{};

  for (final c in cards) {
    if (c.cardType != DeckCardType.vocab) continue;
    final key = '${c.level}|${c.category ?? ''}';
    if (!byKey.containsKey(key)) {
      order.add(key);
      byKey[key] = [];
      labelOf[key] = (level: c.level, category: c.category);
    }
    byKey[key]!.add(c);
  }

  return [
    for (final key in order)
      VocabWeekGroup(
        level: labelOf[key]!.level,
        category: labelOf[key]!.category,
        cards: byKey[key]!,
      ),
  ];
});
