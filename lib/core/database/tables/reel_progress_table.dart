import 'package:drift/drift.dart';

/// Per-reel watch position for the Reels vertical feed
/// (assets/reels/*, not database-backed content — only progress over it
/// lives here). [reelId] matches a reel's id in assets/reels/manifest.json.
class ReelProgress extends Table {
  TextColumn get reelId => text()();
  IntColumn get lastPositionMs => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {reelId};
}
