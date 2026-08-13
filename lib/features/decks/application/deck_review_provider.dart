import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/deck_card_progress_table.dart';
import '../../../core/database/tables/deck_cards_table.dart';
import '../../../core/srs/srs_config.dart';
import '../data/deck_repository.dart';
import 'deck_data_providers.dart';

class DeckReviewFilterState {
  const DeckReviewFilterState({this.level = 'All', this.type});

  final String level;
  final DeckCardType? type; // null = All

  DeckReviewFilterState copyWith({String? level, DeckCardType? type, bool clearType = false}) {
    return DeckReviewFilterState(
      level: level ?? this.level,
      type: clearType ? null : (type ?? this.type),
    );
  }
}

final reviewDirectionProvider = StateProvider<ReviewDirection>((ref) => ReviewDirection.jpToEn);

final deckReviewFilterProvider = StateProvider<DeckReviewFilterState>(
  (ref) => const DeckReviewFilterState(),
);

/// The user's override for [SrsConfig.kNewDeckCardsPerDayPerDirection], set
/// via the Decks review tab — falls back to the built-in default until the
/// user picks a value.
final newDeckCardsPerDayProvider = StreamProvider<int>((ref) {
  return ref
      .watch(deckRepositoryProvider)
      .watchNewDeckCardsPerDayPerDirection()
      .map((value) => value ?? SrsConfig.kNewDeckCardsPerDayPerDirection);
});

/// A card up for review in Decks mode. [progress] is null for a card never
/// graded in this direction before — see [AppDatabase.gradeDeckCardReview]
/// for why that's enough to treat it as "new" without a separate
/// "introduce" step.
class DeckReviewCard {
  const DeckReviewCard({required this.card, required this.direction, this.progress});

  final DeckCard card;
  final ReviewDirection direction;
  final DeckCardProgressData? progress;
}

/// Due-for-review cards (progress row exists, due date has passed) plus
/// not-yet-graded cards up to today's remaining [newDeckCardsPerDayProvider]
/// allowance, filtered by the selected level/type. Hand-written (not
/// @riverpod codegen) — see dictionary_search_provider.dart for why.
final deckReviewQueueProvider = Provider<List<DeckReviewCard>>((ref) {
  final direction = ref.watch(reviewDirectionProvider);
  final filter = ref.watch(deckReviewFilterProvider);
  final cards = ref.watch(deckCardsProvider).value ?? const [];
  final progressByKey = ref.watch(deckCardProgressProvider).value ?? const {};
  final newCardsPerDay =
      ref.watch(newDeckCardsPerDayProvider).value ?? SrsConfig.kNewDeckCardsPerDayPerDirection;
  final now = DateTime.now();

  final eligible = cards.where((c) {
    if (filter.level != 'All' && c.level != filter.level) return false;
    if (filter.type != null && c.cardType != filter.type) return false;
    return true;
  });

  final due = <DeckReviewCard>[];
  final unseen = <DeckReviewCard>[];
  var introducedToday = 0;

  for (final card in eligible) {
    final progress = progressByKey['${card.id}|${direction.name}'];
    if (progress == null) {
      unseen.add(DeckReviewCard(card: card, direction: direction));
      continue;
    }
    final introducedAt = progress.introducedAt;
    if (introducedAt != null &&
        introducedAt.year == now.year &&
        introducedAt.month == now.month &&
        introducedAt.day == now.day) {
      introducedToday++;
    }
    if (progress.dueAt != null && !progress.dueAt!.isAfter(now)) {
      due.add(DeckReviewCard(card: card, direction: direction, progress: progress));
    }
  }

  due.sort((a, b) => a.progress!.dueAt!.compareTo(b.progress!.dueAt!));

  final newAllowance = (newCardsPerDay - introducedToday).clamp(0, unseen.length);

  return [...due, ...unseen.take(newAllowance)];
});
