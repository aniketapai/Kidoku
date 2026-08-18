import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/deck_card_progress_table.dart';
import '../data/deck_repository.dart';

part 'deck_review_actions_provider.g.dart';

@riverpod
class DeckReviewActions extends _$DeckReviewActions {
  @override
  void build() {}

  Future<DeckGradeUndo> gradeReview(String cardId, ReviewDirection direction, {required bool correct}) {
    return ref.read(deckRepositoryProvider).gradeReview(cardId, direction, correct: correct);
  }

  Future<void> undoGradeReview(
    String cardId,
    ReviewDirection direction,
    DeckCardProgressData? previousProgress,
    int reviewEventId,
  ) {
    return ref
        .read(deckRepositoryProvider)
        .undoGradeReview(cardId, direction, previousProgress, reviewEventId);
  }

  Future<void> setNewDeckCardsPerDay(int value) {
    return ref.read(deckRepositoryProvider).writeNewDeckCardsPerDayPerDirection(value);
  }
}
