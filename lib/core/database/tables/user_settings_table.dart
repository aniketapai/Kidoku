import 'package:drift/drift.dart';

/// Single-row table of user-adjustable review settings — mirrors
/// [SeedMeta]'s singleton-row pattern.
class UserSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();

  /// User-facing override for [SrsConfig.kNewDeckCardsPerDayPerDirection].
  /// Null until the user changes it from the default in the Decks review UI.
  IntColumn get newDeckCardsPerDayPerDirection => integer().nullable()();

  /// Multiplier applied to the story reader's base font size. Null until the
  /// user changes it from the default (1.0) in the reader's text-size
  /// control — kept separate from furigana visibility, which is a
  /// per-session toggle rather than a persisted preference.
  RealColumn get readerFontScale => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
