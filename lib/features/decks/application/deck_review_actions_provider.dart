import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/tables/deck_card_progress_table.dart';
import '../data/deck_repository.dart';

part 'deck_review_actions_provider.g.dart';

@riverpod
class DeckReviewActions extends _$DeckReviewActions {
  @override
  void build() {}

  Future<void> gradeReview(String cardId, ReviewDirection direction, {required bool correct}) {
    return ref.read(deckRepositoryProvider).gradeReview(cardId, direction, correct: correct);
  }

  Future<void> setNewDeckCardsPerDay(int value) {
    return ref.read(deckRepositoryProvider).writeNewDeckCardsPerDayPerDirection(value);
  }
}
