import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../srs/srs_config.dart';
import 'tables/achievements_table.dart';
import 'tables/deck_card_progress_table.dart';
import 'tables/deck_cards_table.dart';
import 'tables/dictionary_entries_table.dart';
import 'tables/review_events_table.dart';
import 'tables/seed_meta_table.dart';
import 'tables/story_progress_table.dart';
import 'tables/user_settings_table.dart';
import 'tables/user_words_table.dart';

part 'app_database.g.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 8;

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
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(name: 'yomu');

  // --- Seed metadata ---

  Future<int?> readSeededVersion() async {
    final row = await (select(seedMeta)..where((t) => t.id.equals(0))).getSingleOrNull();
    return row?.seededVersion;
  }

  Future<void> writeSeededVersion(int version) async {
    await into(
      seedMeta,
    ).insertOnConflictUpdate(SeedMetaCompanion.insert(id: const Value(0), seededVersion: version));
  }

  // --- User settings ---

  /// The user's override for how many new deck cards enter a review
  /// direction's rotation per day, or null to use
  /// [SrsConfig.kNewDeckCardsPerDayPerDirection].
  Stream<int?> watchNewDeckCardsPerDayPerDirection() {
    return (select(userSettings)..where((t) => t.id.equals(0))).watchSingleOrNull().map(
      (row) => row?.newDeckCardsPerDayPerDirection,
    );
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
    return (select(userSettings)..where((t) => t.id.equals(0))).watchSingleOrNull().map(
      (row) => row?.readerFontScale,
    );
  }

  Future<void> writeReaderFontScale(double? value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(id: const Value(0), readerFontScale: Value(value)),
    );
  }

  // --- Dictionary ---

  Future<DictionaryEntry?> lookupDictionaryEntry(String dictionaryForm) => (select(
    dictionaryEntries,
  )..where((t) => t.dictionaryForm.equals(dictionaryForm))).getSingleOrNull();

  /// Prefix match on the Japanese form/reading (what a learner typing
  /// kana/kanji — or romaji converted to kana — expects), most specific
  /// (shortest dictionaryForm) first as a cheap "more specific" proxy.
  Future<List<DictionaryEntry>> searchJapanesePrefix(String query, {int limit = 50}) async {
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
  Future<List<DictionaryEntry>> searchMeanings(String query, {int limit = 50}) async {
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

    final wordBoundary = RegExp(r'\b' + RegExp.escape(q) + r'\b', caseSensitive: false);
    return meaningCandidates.where((e) => wordBoundary.hasMatch(e.meanings)).take(limit).toList();
  }

  // --- User words ---

  Stream<UserWord?> watchUserWord(String dictionaryForm) => (select(
    userWords,
  )..where((t) => t.dictionaryForm.equals(dictionaryForm))).watchSingleOrNull();

  /// Queues a word for SRS review, due immediately.
  Future<void> markWordSaved(String dictionaryForm) {
    final now = DateTime.now();
    return into(userWords).insertOnConflictUpdate(
      UserWordsCompanion.insert(
        dictionaryForm: dictionaryForm,
        status: WordStatus.saved,
        lastSeen: now,
        savedAt: Value(now),
        srsDueAt: Value(now),
        srsInterval: const Value(0),
      ),
    );
  }

  /// Marks a word already known, removing it from the SRS review rotation.
  Future<void> markWordKnown(String dictionaryForm) {
    final now = DateTime.now();
    return into(userWords).insertOnConflictUpdate(
      UserWordsCompanion.insert(
        dictionaryForm: dictionaryForm,
        status: WordStatus.known,
        lastSeen: now,
        savedAt: Value(now),
        srsDueAt: const Value(null),
        srsInterval: const Value(0),
      ),
    );
  }

  /// Grades a review: advances (or resets, on failure) the word's position
  /// in [SrsConfig.intervalsDays] and reschedules its next due date.
  Future<void> gradeReview(String dictionaryForm, {required bool correct}) async {
    final row = await (select(
      userWords,
    )..where((t) => t.dictionaryForm.equals(dictionaryForm))).getSingleOrNull();
    final currentIndex = row?.srsInterval ?? -1;
    final newIndex = correct ? (currentIndex + 1).clamp(0, SrsConfig.intervalsDays.length - 1) : 0;
    final now = DateTime.now();
    await into(userWords).insertOnConflictUpdate(
      UserWordsCompanion.insert(
        dictionaryForm: dictionaryForm,
        status: WordStatus.learning,
        lastSeen: now,
        savedAt: Value(row?.savedAt ?? now),
        srsInterval: Value(newIndex),
        srsDueAt: Value(now.add(Duration(days: SrsConfig.intervalsDays[newIndex]))),
      ),
    );
    await logReviewEvent(correct: correct, at: now);
  }

  /// Filters/sorts client-side (rather than a SQL WHERE bound to `now`) so
  /// "due" is evaluated fresh on every emission — a SQL-bound comparison
  /// captures `now` once when the stream is first built and never updates
  /// it, so a word saved later in the same session would never re-trigger
  /// that stale comparison and could never appear as due until the app
  /// restarted and rebuilt the stream with a newer `now`.
  Stream<List<UserWord>> watchDueUserWords() {
    return select(userWords).watch().map((rows) {
      final now = DateTime.now();
      final due = rows.where((r) => r.srsDueAt != null && !r.srsDueAt!.isAfter(now)).toList()
        ..sort((a, b) => a.srsDueAt!.compareTo(b.srsDueAt!));
      return due;
    });
  }

  Stream<int> watchDueReviewCount() {
    return select(userWords).watch().map((rows) {
      final now = DateTime.now();
      return rows.where((r) => r.srsDueAt != null && !r.srsDueAt!.isAfter(now)).length;
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
  Stream<List<DeckCard>> watchDeckCards() => (select(
    deckCards,
  )..orderBy([(t) => OrderingTerm.asc(t.deckId), (t) => OrderingTerm.asc(t.sortOrder)])).watch();

  /// One shared live query for deck review progress, avoiding a separate
  /// DB-backed subscription per card. Keyed by "cardId|direction" since
  /// (cardId, direction) is the table's actual primary key.
  Stream<Map<String, DeckCardProgressData>> watchAllDeckCardProgress() => select(
    deckCardProgress,
  ).watch().map((rows) => {for (final row in rows) '${row.cardId}|${row.direction.name}': row});

  /// Grades a deck-card review — mirrors [gradeReview]'s advance/reset
  /// logic over the same [SrsConfig.intervalsDays] curve. `row == null`
  /// (a card graded for the first time) behaves the same way [gradeReview]
  /// treats a brand-new word: `currentIndex` of -1 lands on interval index
  /// 0 either way, and this insert is what first creates the progress row
  /// (and stamps [DeckCardProgress.introducedAt]) — there's no separate
  /// "introduce" step; the application layer decides which not-yet-graded
  /// cards to surface (and caps how many per day) by comparing
  /// [watchDeckCards] against [watchAllDeckCardProgress] itself.
  Future<void> gradeDeckCardReview(
    String cardId,
    ReviewDirection direction, {
    required bool correct,
  }) async {
    final row =
        await (select(deckCardProgress)
              ..where((t) => t.cardId.equals(cardId) & t.direction.equals(direction.name)))
            .getSingleOrNull();
    final currentIndex = row?.intervalIndex ?? -1;
    final newIndex = correct ? (currentIndex + 1).clamp(0, SrsConfig.intervalsDays.length - 1) : 0;
    final now = DateTime.now();
    await into(deckCardProgress).insertOnConflictUpdate(
      DeckCardProgressCompanion.insert(
        cardId: cardId,
        direction: direction,
        introducedAt: Value(row?.introducedAt ?? now),
        intervalIndex: Value(newIndex),
        dueAt: Value(now.add(Duration(days: SrsConfig.intervalsDays[newIndex]))),
        lastReviewed: Value(now),
      ),
    );
    await logReviewEvent(correct: correct, at: now);
  }

  // --- Review activity log (profile heatmap/graph) ---

  Future<void> logReviewEvent({required bool correct, DateTime? at}) {
    return into(
      reviewEvents,
    ).insert(ReviewEventsCompanion.insert(occurredAt: at ?? DateTime.now(), correct: correct));
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
    return (select(achievements)..orderBy([(t) => OrderingTerm.desc(t.earnedAt)])).watch();
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
}
