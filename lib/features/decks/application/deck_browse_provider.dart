import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/deck_cards_table.dart';
import '../../../core/text/romaji_converter.dart';
import 'deck_data_providers.dart';

class DeckBrowseFilterState {
  const DeckBrowseFilterState({this.searchText = '', this.level = 'N5'});

  final String searchText;
  final String level;

  DeckBrowseFilterState copyWith({String? searchText, String? level}) {
    return DeckBrowseFilterState(
      searchText: searchText ?? this.searchText,
      level: level ?? this.level,
    );
  }
}

/// One filter state per Vocabulary-screen tab, kept independent so
/// switching tabs doesn't reset the other tab's search/level selection.
final deckBrowseFilterProvider = StateProvider.family<DeckBrowseFilterState, DeckCardType>((
  ref,
  type,
) {
  return const DeckBrowseFilterState();
});

bool _matches(DeckCard card, String needle) {
  return card.expression.contains(needle) ||
      card.reading.contains(needle) ||
      card.meaning.toLowerCase().contains(needle);
}

/// Filtered (search text + level), original-order list for one tab. Hand-
/// written (not @riverpod codegen) since the result type is a Drift-
/// generated DataClass — see dictionary_search_provider.dart for why.
final filteredDeckCardsProvider = Provider.family<List<DeckCard>, DeckCardType>((ref, type) {
  final cards = ref.watch(deckCardsProvider).value ?? const [];
  final filter = ref.watch(deckBrowseFilterProvider(type));
  final needle = filter.searchText.trim().toLowerCase();
  // Romaji input (e.g. "taberu") doesn't literally appear in any card field,
  // so also match against its hiragana conversion — same fallback the
  // Dictionary tab's search uses (see dictionary_repository.dart).
  final kanaNeedle = romajiToHiragana(needle);

  return cards.where((c) {
    if (c.cardType != type) return false;
    if (filter.level != 'All' && c.level != filter.level) return false;
    if (needle.isEmpty) return true;
    if (_matches(c, needle)) return true;
    if (kanaNeedle != null && kanaNeedle != needle && _matches(c, kanaNeedle)) return true;
    return false;
  }).toList();
});
