import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/database/tables/deck_card_progress_table.dart';

part 'deck_repository.g.dart';

class DeckRepository {
  DeckRepository(this._db);
  final AppDatabase _db;

  Stream<List<DeckCard>> watchDeckCards() => _db.watchDeckCards();

  Stream<Map<String, DeckCardProgressData>> watchAllDeckCardProgress() =>
      _db.watchAllDeckCardProgress();

  Future<DeckGradeUndo> gradeReview(String cardId, ReviewDirection direction, {required bool correct}) =>
      _db.gradeDeckCardReview(cardId, direction, correct: correct);

  Future<void> undoGradeReview(
    String cardId,
    ReviewDirection direction,
    DeckCardProgressData? previousProgress,
    int reviewEventId,
  ) => _db.undoGradeDeckCardReview(cardId, direction, previousProgress, reviewEventId);

  Stream<int?> watchNewDeckCardsPerDayPerDirection() => _db.watchNewDeckCardsPerDayPerDirection();

  Future<void> writeNewDeckCardsPerDayPerDirection(int? value) =>
      _db.writeNewDeckCardsPerDayPerDirection(value);
}

@riverpod
DeckRepository deckRepository(Ref ref) {
  return DeckRepository(ref.watch(appDatabaseProvider));
}
