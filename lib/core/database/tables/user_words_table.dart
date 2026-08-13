import 'package:drift/drift.dart';

enum WordStatus { known, learning, saved }

class UserWords extends Table {
  TextColumn get dictionaryForm => text()();
  TextColumn get status => textEnum<WordStatus>()();
  DateTimeColumn get savedAt => dateTime().nullable()();
  DateTimeColumn get lastSeen => dateTime()();
  DateTimeColumn get srsDueAt => dateTime().nullable()();
  IntColumn get srsInterval => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {dictionaryForm};
}
