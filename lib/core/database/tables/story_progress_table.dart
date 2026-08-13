import 'package:drift/drift.dart';

/// Per-story reading position for the Library's token-reading stories
/// (assets/stories/*, not database-backed content — only progress over it
/// lives here). [storyId] matches a story's id in assets/stories/manifest.json.
class StoryProgress extends Table {
  TextColumn get storyId => text()();
  IntColumn get lastPageIndex => integer().withDefault(const Constant(0))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {storyId};
}
