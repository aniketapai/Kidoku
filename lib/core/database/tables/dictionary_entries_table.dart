import 'package:drift/drift.dart';

class DictionaryEntries extends Table {
  TextColumn get dictionaryForm => text()();
  TextColumn get reading => text()();
  /// JSON-encoded list of strings.
  TextColumn get meanings => text()();
  TextColumn get partOfSpeech => text()();
  TextColumn get jlptLevel => text().nullable()();

  @override
  Set<Column> get primaryKey => {dictionaryForm};
}
