import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../srs/srs_config.dart';
import 'tables/achievements_table.dart';
import 'tables/deck_card_progress_table.dart';
import 'tables/deck_cards_table.dart';
import 'tables/dictionary_entries_table.dart';
import 'tables/reel_progress_table.dart';
import 'tables/review_events_table.dart';
import 'tables/seed_meta_table.dart';
import 'tables/story_progress_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/user_words_table.dart';

part 'app_database.g.dart';

/// What a [AppDatabase.gradeDeckCardReview] call changed, captured so the
/// grade can later be undone via [AppDatabase.undoGradeDeckCardReview].
typedef DeckGradeUndo = ({
  DeckCardProgressData? previousProgress,
  int reviewEventId,
});

/// This device's local-notification preferences — see
/// [AppDatabase.watchNotificationSettings].
typedef NotificationSettingsData = ({
  bool notificationsEnabled,
  bool studyReminderEnabled,
  int studyReminderHour,
  int studyReminderMinute,
  bool reviewDueRemindersEnabled,
  bool motivationalRemindersEnabled,
});

@DriftDatabase(
  tables: [
    DictionaryEntries,
    UserWords,
    SeedMeta,
    DeckCards,
    DeckCardProgress,
    ReviewEvents,
    Achievements,
    UserSettings,
    StoryProgress,
    ReelProgress,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 3) {
        await m.createTable(deckCards);
        await m.createTable(deckCardProgress);
      }
      if (from < 4) {
        await m.createTable(reviewEvents);
        await m.createTable(achievements);
      }
      if (from < 5) {
        await m.addColumn(achievements, achievements.imagePath);
      }
      if (from < 6) {
        await m.createTable(userSettings);
      }
      if (from < 7) {
        await m.createTable(storyProgress);
      }
      if (from < 8) {
        await m.addColumn(userSettings, userSettings.readerFontScale);
      }
      if (from < 9) {
        await m.createTable(reelProgress);
      }
      if (from < 10) {
        await m.addColumn(userSettings, userSettings.notificationsEnabled);
        await m.addColumn(userSettings, userSettings.studyReminderEnabled);
        await m.addColumn(userSettings, userSettings.studyReminderHour);
        await m.addColumn(userSettings, userSettings.studyReminderMinute);
        await m.addColumn(userSettings, userSettings.reviewDueRemindersEnabled);
        await m.addColumn(
          userSettings,
          userSettings.motivationalRemindersEnabled,
        );
      }
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(name: 'yomu');

  // --- Seed metadata ---

  Future<int?> readSeededVersion() async {
    final row = await (select(
      seedMeta,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return row?.seededVersion;
  }

  Future<void> writeSeededVersion(int version) async {
    await into(seedMeta).insertOnConflictUpdate(
      SeedMetaCompanion.insert(id: const Value(0), seededVersion: version),
    );
  }

  // --- User settings ---

  /// The user's override for how many new deck cards enter a review
  /// direction's rotation per day, or null to use
  /// [SrsConfig.kNewDeckCardsPerDayPerDirection].
  Stream<int?> watchNewDeckCardsPerDayPerDirection() {
    return (select(userSettings)..where((t) => t.id.equals(0)))
        .watchSingleOrNull()
        .map((row) => row?.newDeckCardsPerDayPerDirection);
  }

  Future<void> writeNewDeckCardsPerDayPerDirection(int? value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        id: const Value(0),
        newDeckCardsPerDayPerDirection: Value(value),
      ),
    );
  }

  /// The story reader's font-size multiplier, or null to use the default
  /// (1.0).
  Stream<double?> watchReaderFontScale() {
    return (select(userSettings)..where((t) => t.id.equals(0)))
        .watchSingleOrNull()
        .map((row) => row?.readerFontScale);
  }

  Future<void> writeReaderFontScale(double? value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        id: const Value(0),
        readerFontScale: Value(value),
      ),
    );
  }

  /// This device's local-notification preferences — defaults (all on,
  /// 8:00 PM study reminder) apply until the row exists, matching the
  /// column defaults in UserSettings so a fresh install and an explicit
  /// "reset to defaults" write behave the same.
  Stream<NotificationSettingsData> watchNotificationSettings() {
    return (select(
      userSettings,
    )..where((t) => t.id.equals(0))).watchSingleOrNull().map(
      (row) => (
        notificationsEnabled: row?.notificationsEnabled ?? true,
        studyReminderEnabled: row?.studyReminderEnabled ?? true,
        studyReminderHour: row?.studyReminderHour ?? 20,
        studyReminderMinute: row?.studyReminderMinute ?? 0,
        reviewDueRemindersEnabled: row?.reviewDueRemindersEnabled ?? true,
        motivationalRemindersEnabled: row?.motivationalRemindersEnabled ?? true,
      ),
    );
  }

  Future<void> writeNotificationsEnabled(bool value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        id: const Value(0),
        notificationsEnabled: Value(value),
      ),
    );
  }

  Future<void> writeStudyReminderEnabled(bool value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        id: const Value(0),
        studyReminderEnabled: Value(value),
      ),
    );
  }

  Future<void> writeStudyReminderTime(int hour, int minute) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        id: const Value(0),
        studyReminderHour: Value(hour),
        studyReminderMinute: Value(minute),
      ),
    );
  }

  Future<void> writeReviewDueRemindersEnabled(bool value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        id: const Value(0),
        reviewDueRemindersEnabled: Value(value),
      ),
    );
  }

  Future<void> writeMotivationalRemindersEnabled(bool value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(
        id: const Value(0),
        motivationalRemindersEnabled: Value(value),
      ),
    );
  }

  // --- Dictionary ---

  Future<DictionaryEntry?> lookupDictionaryEntry(String dictionaryForm) =>
      (select(dictionaryEntries)
            ..where((t) => t.dictionaryForm.equals(dictionaryForm)))
          .getSingleOrNull();

  /// Batched form of [lookupDictionaryEntry] — one `WHERE ... IN (...)`
  /// query instead of one query per word, for screens (My Words) that
  /// render a whole saved-word list at once.
  Future<Map<String, DictionaryEntry>> lookupDictionaryEntries(
    List<String> dictionaryForms,
  ) async {
    if (dictionaryForms.isEmpty) return const {};
    final rows = await (select(
      dictionaryEntries,
    )..where((t) => t.dictionaryForm.isIn(dictionaryForms))).get();
    return {for (final row in rows) row.dictionaryForm: row};
  }

  /// Prefix match on the Japanese form/reading (what a learner typing
  /// kana/kanji — or romaji converted to kana — expects), most specific
  /// (shortest dictionaryForm) first as a cheap "more specific" proxy.
  Future<List<DictionaryEntry>> searchJapanesePrefix(
    String query, {
    int limit = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty || limit <= 0) return const [];

    return (select(dictionaryEntries)
          ..where((t) => t.dictionaryForm.like('$q%') | t.reading.like('$q%'))
          ..orderBy([(t) => OrderingTerm.asc(t.dictionaryForm.length)])
          ..limit(limit))
        .get();
  }

  /// Whole-word match on English meanings — backs the Dictionary tab's
  /// search box as a fallback when the query isn't Japanese/romaji.
  ///
  /// Two-stage: a plain SQL substring LIKE narrows candidates (cheap, no
  /// FTS table to maintain), then a `\b`-bounded regex re-filters in Dart —
  /// a raw substring match alone would let "eat" match inside
  /// "meat"/"seat"/"great", burying the actual verb 食べる under unrelated
  /// nouns that happen to contain the letters.
  Future<List<DictionaryEntry>> searchMeanings(
    String query, {
    int limit = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty || limit <= 0) return const [];

    // SQLite can't use an index for a leading-wildcard LIKE, so this scans
    // regardless of the limit — the generous cap here is about not
    // truncating the word-boundary-filtered results below (a "%eat%"
    // substring scan alone finds hundreds of unrelated matches like
    // "great"/"treat"/"wheat" before it reaches 食べる), not about query cost.
    final meaningCandidates =
        await (select(dictionaryEntries)
              ..where((t) => t.meanings.like('%$q%'))
              ..orderBy([(t) => OrderingTerm.asc(t.dictionaryForm.length)])
              ..limit(2000))
            .get();

    final wordBoundary = RegExp(
      r'\b' + RegExp.escape(q) + r'\b',
      caseSensitive: false,
    );
    return meaningCandidates
        .where((e) => wordBoundary.hasMatch(e.meanings))
        .take(limit)
        .toList();
  }

  // --- User words ---

  Stream<UserWord?> watchUserWord(String dictionaryForm) => (select(
    userWords,
  )..where((t) => t.dictionaryForm.equals(dictionaryForm))).watchSingleOrNull();

  /// Marks a word saved — i.e. not known yet. No SRS scheduling: My Words
  /// just lists every saved word, split into Saved/Known client-side.
  Future<void> markWordSaved(String dictionaryForm) {
    final now = DateTime.now();
    return into(userWords).insertOnConflictUpdate(
      UserWordsCompanion.insert(
        dictionaryForm: dictionaryForm,
        status: WordStatus.saved,
        lastSeen: now,
        savedAt: Value(now),
      ),
    );
  }

  /// Marks a word already known.
  Future<void> markWordKnown(String dictionaryForm) {
    final now = DateTime.now();
    return into(userWords).insertOnConflictUpdate(
      UserWordsCompanion.insert(
        dictionaryForm: dictionaryForm,
        status: WordStatus.known,
        lastSeen: now,
        savedAt: Value(now),
      ),
    );
  }

  /// Removes a word from My Words entirely (not a status change) — used by
  /// the delete action on the Saved/Known lists.
  Future<void> deleteUserWord(String dictionaryForm) {
    return (delete(
      userWords,
    )..where((t) => t.dictionaryForm.equals(dictionaryForm))).go();
  }

  /// Every saved/known word, most recently saved first — backs the My Words
  /// list (no due-date gating; the UI splits Saved vs. Known client-side).
  Stream<List<UserWord>> watchAllUserWords() {
    return (select(userWords)..orderBy([
          (t) => OrderingTerm.desc(t.savedAt),
          (t) => OrderingTerm.desc(t.lastSeen),
        ]))
        .watch();
  }

  /// Count of words not yet marked known — backs the bottom-nav Review
  /// badge. [WordStatus.learning] is a legacy status no longer written (it
  /// predates My Words dropping SRS grading) but still counts as "not known"
  /// for any pre-existing rows.
  Stream<int> watchDueReviewCount() {
    return select(userWords).watch().map((rows) {
      return rows.where((r) => r.status != WordStatus.known).length;
    });
  }

  /// Word counts by [WordStatus] — backs the profile screen's stat row.
  Stream<Map<WordStatus, int>> watchWordStatusCounts() {
    return select(userWords).watch().map((rows) {
      final counts = {for (final s in WordStatus.values) s: 0};
      for (final r in rows) {
        counts[r.status] = (counts[r.status] ?? 0) + 1;
      }
      return counts;
    });
  }

  // --- Deck cards (JLPT Anki deck import) ---

  // sortOrder restarts at 0 within each deck (see ingestion/convert_apkg.py),
  // so ordering by it alone ties across decks and — since the Decks review
  // queue and Vocabulary "All" filter both walk this list in order —
  // interleaves unrelated decks card-by-card instead of finishing one
  // before starting the next. deckId first keeps each deck contiguous.
  Stream<List<DeckCard>> watchDeckCards() =>
      (select(deckCards)..orderBy([
            (t) => OrderingTerm.asc(t.deckId),
            (t) => OrderingTerm.asc(t.sortOrder),
          ]))
          .watch();

  /// One shared live query for deck review progress, avoiding a separate
  /// DB-backed subscription per card. Keyed by "cardId|direction" since
  /// (cardId, direction) is the table's actual primary key.
  Stream<Map<String, DeckCardProgressData>> watchAllDeckCardProgress() =>
      select(deckCardProgress).watch().map(
        (rows) => {
          for (final row in rows) '${row.cardId}|${row.direction.name}': row,
        },
      );

  /// Grades a deck-card review — mirrors [gradeReview]'s advance/reset
  /// logic over the same [SrsConfig.intervalsDays] curve. `row == null`
  /// (a card graded for the first time) behaves the same way [gradeReview]
  /// treats a brand-new word: `currentIndex` of -1 lands on interval index
  /// 0 either way, and this insert is what first creates the progress row
  /// (and stamps [DeckCardProgress.introducedAt]) — there's no separate
  /// "introduce" step; the application layer decides which not-yet-graded
  /// cards to surface (and caps how many per day) by comparing
  /// [watchDeckCards] against [watchAllDeckCardProgress] itself.
  Future<DeckGradeUndo> gradeDeckCardReview(
    String cardId,
    ReviewDirection direction, {
    required bool correct,
  }) async {
    return transaction(() async {
      final row =
          await (select(deckCardProgress)..where(
                (t) =>
                    t.cardId.equals(cardId) &
                    t.direction.equals(direction.name),
              ))
              .getSingleOrNull();
      final currentIndex = row?.intervalIndex ?? -1;
      final newIndex = correct
          ? (currentIndex + 1).clamp(0, SrsConfig.intervalsDays.length - 1)
          : 0;
      final now = DateTime.now();
      await into(deckCardProgress).insertOnConflictUpdate(
        DeckCardProgressCompanion.insert(
          cardId: cardId,
          direction: direction,
          introducedAt: Value(row?.introducedAt ?? now),
          intervalIndex: Value(newIndex),
          dueAt: Value(
            now.add(Duration(days: SrsConfig.intervalsDays[newIndex])),
          ),
          lastReviewed: Value(now),
        ),
      );
      final reviewEventId = await logReviewEvent(correct: correct, at: now);
      return (previousProgress: row, reviewEventId: reviewEventId);
    });
  }

  /// Reverts a single [gradeDeckCardReview] call — restores the progress
  /// row exactly as it was beforehand (or removes it, if the card had never
  /// been graded before) and deletes the review event it logged, so an
  /// undone grade leaves no trace in either the SRS state or the activity
  /// log. Powers the review screens' "revert" buttons.
  Future<void> undoGradeDeckCardReview(
    String cardId,
    ReviewDirection direction,
    DeckCardProgressData? previousProgress,
    int reviewEventId,
  ) async {
    await transaction(() async {
      if (previousProgress == null) {
        await (delete(deckCardProgress)..where(
              (t) =>
                  t.cardId.equals(cardId) & t.direction.equals(direction.name),
            ))
            .go();
      } else {
        await into(deckCardProgress).insertOnConflictUpdate(
          DeckCardProgressCompanion.insert(
            cardId: previousProgress.cardId,
            direction: previousProgress.direction,
            introducedAt: Value(previousProgress.introducedAt),
            intervalIndex: Value(previousProgress.intervalIndex),
            dueAt: Value(previousProgress.dueAt),
            lastReviewed: Value(previousProgress.lastReviewed),
          ),
        );
      }
      await (delete(
        reviewEvents,
      )..where((t) => t.id.equals(reviewEventId))).go();
    });
  }

  // --- Review activity log (profile heatmap/graph) ---

  Future<int> logReviewEvent({required bool correct, DateTime? at}) {
    return into(reviewEvents).insert(
      ReviewEventsCompanion.insert(
        occurredAt: at ?? DateTime.now(),
        correct: correct,
      ),
    );
  }

  /// All review events on or after [since] (inclusive), oldest first — the
  /// profile screen buckets these by local calendar day itself.
  Stream<List<ReviewEvent>> watchReviewEventsSince(DateTime since) {
    return (select(reviewEvents)
          ..where((t) => t.occurredAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.asc(t.occurredAt)]))
        .watch();
  }

  // --- Achievements (JLPT / NAT-TEST certificates) ---

  Stream<List<Achievement>> watchAchievements() {
    return (select(
      achievements,
    )..orderBy([(t) => OrderingTerm.desc(t.earnedAt)])).watch();
  }

  Future<void> addAchievement({
    required CertificateType type,
    required String level,
    required DateTime earnedAt,
    String? note,
    String? imagePath,
  }) {
    return into(achievements).insert(
      AchievementsCompanion.insert(
        type: type,
        level: level,
        earnedAt: earnedAt,
        note: Value(note),
        imagePath: Value(imagePath),
      ),
    );
  }

  Future<void> deleteAchievement(int id) {
    return (delete(achievements)..where((t) => t.id.equals(id))).go();
  }

  // --- Story reading progress (Library token-reading stories) ---

  Stream<StoryProgressData?> watchStoryProgress(String storyId) => (select(
    storyProgress,
  )..where((t) => t.storyId.equals(storyId))).watchSingleOrNull();

  /// One shared live query for every story's progress, mirroring
  /// [watchAllDeckCardProgress] — the Library grid needs all of them at
  /// once rather than a separate subscription per story card.
  Stream<Map<String, StoryProgressData>> watchAllStoryProgress() => select(
    storyProgress,
  ).watch().map((rows) => {for (final row in rows) row.storyId: row});

  Future<void> saveStoryProgress(
    String storyId, {
    required int lastPageIndex,
    required bool completed,
  }) {
    return into(storyProgress).insertOnConflictUpdate(
      StoryProgressCompanion.insert(
        storyId: storyId,
        lastPageIndex: Value(lastPageIndex),
        completed: Value(completed),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // --- Reel watch progress (Reels vertical feed) ---

  Stream<ReelProgressData?> watchReelProgress(String reelId) => (select(
    reelProgress,
  )..where((t) => t.reelId.equals(reelId))).watchSingleOrNull();

  /// One shared live query for every reel's progress, mirroring
  /// [watchAllStoryProgress].
  Stream<Map<String, ReelProgressData>> watchAllReelProgress() => select(
    reelProgress,
  ).watch().map((rows) => {for (final row in rows) row.reelId: row});

  Future<void> saveReelProgress(
    String reelId, {
    required int lastPositionMs,
    required bool completed,
  }) {
    return into(reelProgress).insertOnConflictUpdate(
      ReelProgressCompanion.insert(
        reelId: reelId,
        lastPositionMs: Value(lastPositionMs),
        completed: Value(completed),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Wipes every locally-stored per-user table, leaving the shared seed
  /// content (dictionary entries, seed metadata, deck cards) untouched.
  /// Called on account deletion so a subsequent sign-in on this device
  /// doesn't inherit the deleted account's progress.
  Future<void> clearUserData() {
    return transaction(() async {
      await delete(userWords).go();
      await delete(deckCardProgress).go();
      await delete(reviewEvents).go();
      await delete(achievements).go();
      await delete(userSettings).go();
      await delete(storyProgress).go();
      await delete(reelProgress).go();
    });
  }

  // --- Cloud backup (BackupRepository) ---

  /// True if this device has any locally-stored review/progress history —
  /// the signal the sign-in screen uses to decide whether this looks like a
  /// fresh device worth offering a cloud-backup restore for. Deliberately
  /// excludes [UserWords], which is already pulled from Firestore on every
  /// sign-in regardless (see UserWordRepository.pullFromRemote).
  Future<bool> hasAnyLocalProgress() async {
    final counts = await Future.wait([
      (select(deckCardProgress)..limit(1)).get(),
      (select(reviewEvents)..limit(1)).get(),
      (select(achievements)..limit(1)).get(),
      (select(storyProgress)..limit(1)).get(),
      (select(reelProgress)..limit(1)).get(),
    ]);
    return counts.any((rows) => rows.isNotEmpty);
  }

  Future<List<UserWord>> getAllUserWords() => select(userWords).get();

  Future<List<DeckCardProgressData>> getAllDeckCardProgress() =>
      select(deckCardProgress).get();

  Future<List<ReviewEvent>> getAllReviewEvents() => select(reviewEvents).get();

  Future<List<Achievement>> getAllAchievements() => select(achievements).get();

  Future<UserSetting?> getUserSettingsRow() =>
      (select(userSettings)..where((t) => t.id.equals(0))).getSingleOrNull();

  Future<List<StoryProgressData>> getAllStoryProgress() =>
      select(storyProgress).get();

  Future<List<ReelProgressData>> getAllReelProgress() =>
      select(reelProgress).get();
}
