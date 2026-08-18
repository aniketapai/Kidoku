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

  /// Master switch for all local notifications — see NotificationService.
  /// Off cancels every scheduled notification regardless of the per-type
  /// toggles below.
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Daily "come study" nudge at [studyReminderHour]:[studyReminderMinute].
  BoolColumn get studyReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get studyReminderHour =>
      integer().withDefault(const Constant(20))();
  IntColumn get studyReminderMinute =>
      integer().withDefault(const Constant(0))();

  /// One-shot nudge scheduled for whenever the next deck card falls due —
  /// rescheduled as progress changes, see ReviewDueNotificationScheduler.
  BoolColumn get reviewDueRemindersEnabled =>
      boolean().withDefault(const Constant(true))();

  /// Rotating encouragement messages, one per day of the week — see
  /// MotivationalMessages.
  BoolColumn get motivationalRemindersEnabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
