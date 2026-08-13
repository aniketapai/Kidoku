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

  Future<void> gradeReview(String cardId, ReviewDirection direction, {required bool correct}) =>
      _db.gradeDeckCardReview(cardId, direction, correct: correct);

  Stream<int?> watchNewDeckCardsPerDayPerDirection() => _db.watchNewDeckCardsPerDayPerDirection();

  Future<void> writeNewDeckCardsPerDayPerDirection(int? value) =>
      _db.writeNewDeckCardsPerDayPerDirection(value);
}

@riverpod
DeckRepository deckRepository(Ref ref) {
  return DeckRepository(ref.watch(appDatabaseProvider));
}
