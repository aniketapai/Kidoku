import 'package:drift/drift.dart';

enum DeckCardType { vocab, kanji }

/// A single note imported as-is from one of the JLPT Anki decks (see
/// ingestion/convert_apkg.py) — distinct from [DictionaryEntries], which is
/// the deduplicated JMdict lookup table. [id] is derived from the deck id
/// and the Anki note's own stable id so re-seeding (delete+reinsert, same
/// as dictionaryEntries) never orphans a [DeckCardProgress] row.
class DeckCards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text()();
  TextColumn get level => text()();
  TextColumn get cardType => textEnum<DeckCardType>()();
  TextColumn get category => text().nullable()();
  TextColumn get expression => text()();
  TextColumn get reading => text()();
  TextColumn get meaning => text()();

  /// JSON-encoded map of remaining raw Anki fields (romaji; onyomi/kunyomi/
  /// examples/note for kanji) not promoted to their own column, kept for
  /// full fidelity per the "add it as it is" import requirement.
  TextColumn get extra => text().nullable()();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
