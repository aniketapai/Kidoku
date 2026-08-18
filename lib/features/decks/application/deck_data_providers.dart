import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/deck_cards_table.dart';
import '../../../core/text/kanji_utils.dart';
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

/// Kanji characters seeded under each level. A handful of kanji (e.g. 会,
/// 口, 古) are seeded under two levels (re-taught between N5 and N4 decks),
/// so this keeps per-level membership sets rather than collapsing each
/// character to one owning level like [kanjiLevelMapProvider] does — that
/// collapse is fine for a single display tag, but undercounts here.
final kanjiCharsByLevelProvider = Provider.autoDispose<Map<String, Set<String>>>((ref) {
  final cards = ref.watch(deckCardsProvider).value ?? const [];
  final byLevel = <String, Set<String>>{};
  for (final c in cards) {
    if (c.cardType != DeckCardType.kanji) continue;
    byLevel.putIfAbsent(c.level, () => {}).add(c.expression);
  }
  return byLevel;
});

/// JLPT levels ordered easiest to hardest — lets the kanji-vocab pools
/// below be cumulative (e.g. the N4 pool also draws from N5 vocab/kanji).
const _kJlptLevelOrder = ['N5', 'N4', 'N3', 'N2', 'N1'];

/// Vocab cards at [level] or any easier level, each containing at least one
/// kanji character and none outside what's seeded at [level] or easier —
/// e.g. the N4 pool also pulls in N5 vocab decks, so N5's 図書館 (図 and 館
/// are N4 kanji, 書 is N5) now qualifies once N4 kanji are in scope, but
/// nothing needing an N3+ kanji does. Backs the Vocabulary screen's "Kanji
/// Vocab" tab, a standing review set separate from the normal week
/// groupings. Cards are returned grouped by level (easiest first) so a
/// cumulative pool still reads as N5 words then N4 words, not interleaved.
final kanjiVocabCardsProvider = Provider.autoDispose.family<List<DeckCard>, String>((ref, level) {
  final cards = ref.watch(deckCardsProvider).value ?? const [];
  final charsByLevel = ref.watch(kanjiCharsByLevelProvider);

  final cutoff = _kJlptLevelOrder.indexOf(level);
  final cumulativeLevels = cutoff == -1 ? [level] : _kJlptLevelOrder.take(cutoff + 1).toList();
  final allowedKanji = <String>{for (final l in cumulativeLevels) ...?charsByLevel[l]};

  return [
    for (final l in cumulativeLevels)
      for (final c in cards)
        if (c.cardType == DeckCardType.vocab && c.level == l)
          if (extractKanji(c.expression).toList() case final kanji
              when kanji.isNotEmpty && kanji.every(allowedKanji.contains))
            c,
  ];
});

/// One fixed-size chunk of a level's cumulative kanji-vocab pool (see
/// [kanjiVocabCardsProvider]), labeled by the topics it spans (e.g.
/// "Numbers – Time") rather than an actual week deck — lets Free Review
/// treat the kanji-vocab pool as a set of deck-like chunks to pick from,
/// same as it does with [VocabWeekGroup] for regular vocab.
class KanjiVocabChunk {
  const KanjiVocabChunk({
    required this.level,
    required this.index,
    required this.label,
    required this.cards,
  });

  final String level;
  final int index;
  final String label;
  final List<DeckCard> cards;

  /// Index rather than label — chunk labels are derived from topic names
  /// and aren't guaranteed unique.
  String get key => '$level:$index';
}

final _weekPrefixRegex = RegExp(r'^Week\s+[\d.]+\s+(.+)$');

/// Strips the "Week 1.1 " prefix off a category, leaving just the topic
/// name (e.g. "Numbers"), so chunk labels read as content rather than deck
/// bookkeeping.
String _topicName(String? category) {
  if (category == null) return '';
  return _weekPrefixRegex.firstMatch(category)?.group(1) ?? category;
}

/// Chunks [kanjiVocabCardsProvider]'s pool for [level] into fixed-size sets
/// of 50, ignoring week boundaries — backs Free Review's Kanji Vocab
/// picker.
final kanjiVocabChunksProvider = Provider.autoDispose.family<List<KanjiVocabChunk>, String>((
  ref,
  level,
) {
  final cards = ref.watch(kanjiVocabCardsProvider(level));
  const size = 50;
  final chunks = <KanjiVocabChunk>[];
  for (var i = 0; i < cards.length; i += size) {
    final end = (i + size < cards.length) ? i + size : cards.length;
    final chunk = cards.sublist(i, end);
    final firstTopic = _topicName(chunk.first.category);
    final lastTopic = _topicName(chunk.last.category);
    final label = firstTopic == lastTopic ? firstTopic : '$firstTopic – $lastTopic';
    chunks.add(KanjiVocabChunk(level: level, index: chunks.length, label: label, cards: chunk));
  }
  return chunks;
});

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
