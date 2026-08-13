import 'package:drift/drift.dart';

/// Single-row table tracking which seed dataset version has been loaded,
/// so [SeedLoader] stays idempotent across app restarts.
class SeedMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  IntColumn get seededVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
