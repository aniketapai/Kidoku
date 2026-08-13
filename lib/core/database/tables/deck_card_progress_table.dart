import 'package:drift/drift.dart';

/// A [DeckCard] can be studied independently in either direction — knowing
/// the Japanese well enough to recall the English doesn't imply the
/// reverse — so SRS state is tracked per (card, direction) pair rather
/// than per card.
enum ReviewDirection { jpToEn, enToJp }

class DeckCardProgress extends Table {
  TextColumn get cardId => text()();
  TextColumn get direction => textEnum<ReviewDirection>()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get intervalIndex => integer().withDefault(const Constant(0))();

  /// When this card was first introduced into the direction's rotation —
  /// used to enforce SrsConfig.kNewDeckCardsPerDayPerDirection.
  DateTimeColumn get introducedAt => dateTime().nullable()();
  DateTimeColumn get lastReviewed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {cardId, direction};
}
