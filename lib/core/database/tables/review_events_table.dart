import 'package:drift/drift.dart';

/// One row per graded review (dictionary word or deck card) — the log the
/// profile screen's activity heatmap and trend graph are computed from.
/// [UserWord.lastSeen]/[DeckCardProgress.lastReviewed] only keep the *most
/// recent* timestamp per item, so they can't reconstruct history; this
/// table exists purely to answer "how much did I review, and when."
class ReviewEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get occurredAt => dateTime()();
  BoolColumn get correct => boolean()();
}
