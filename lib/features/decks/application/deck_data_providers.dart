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
