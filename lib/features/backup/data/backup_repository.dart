import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/database/tables/achievements_table.dart';
import '../../../core/database/tables/deck_card_progress_table.dart';
import '../../../core/database/tables/user_words_table.dart';
import '../../../core/firebase/providers.dart';

part 'backup_repository.g.dart';

/// Manual, user-triggered full snapshot of every locally-stored per-user
/// table (see [AppDatabase.clearUserData] for the exact table set) up to
/// Firestore, plus the timestamp of the last such snapshot. Unlike
/// [UserWordRepository]'s per-word best-effort push, every method here
/// surfaces failures to the caller — this only ever runs in response to an
/// explicit "Back up now" tap (or a restore prompt), so the UI needs to know
/// if it didn't work.
class BackupRepository {
  BackupRepository(this._db, this._firestore, this._auth);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  static const _chunkSize = 400;

  DocumentReference<Map<String, dynamic>>? _userDoc() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  Future<DateTime?> lastBackupAt() async {
    final userDoc = _userDoc();
    if (userDoc == null) return null;
    final snapshot = await userDoc.collection('backupMeta').doc('info').get();
    final timestamp = snapshot.data()?['lastBackupAt'] as Timestamp?;
    return timestamp?.toDate();
  }

  Future<bool> hasRemoteBackup() async => await lastBackupAt() != null;

  /// Overwrites every backup collection with the current local state, then
  /// stamps the backup time. Each table's collection is fully cleared before
  /// the new rows are written so deleted-locally rows (e.g. a removed
  /// achievement) don't linger in the cloud copy.
  Future<void> performBackup() async {
    final userDoc = _userDoc();
    if (userDoc == null) return;

    await _resyncUserWords(userDoc);

    final deckCardProgress = await _db.getAllDeckCardProgress();
    await _replaceCollection(
      userDoc.collection('backupDeckCardProgress'),
      {
        for (final row in deckCardProgress)
          '${row.cardId}_${row.direction.name}': {
            'cardId': row.cardId,
            'direction': row.direction.name,
            'dueAt': row.dueAt?.toIso8601String(),
            'intervalIndex': row.intervalIndex,
            'introducedAt': row.introducedAt?.toIso8601String(),
            'lastReviewed': row.lastReviewed?.toIso8601String(),
          },
      },
    );

    final reviewEvents = await _db.getAllReviewEvents();
    await _replaceCollection(
      userDoc.collection('backupReviewEvents'),
      {
        for (final row in reviewEvents)
          row.id.toString(): {
            'occurredAt': row.occurredAt.toIso8601String(),
            'correct': row.correct,
          },
      },
    );

    final achievements = await _db.getAllAchievements();
    await _replaceCollection(
      userDoc.collection('backupAchievements'),
      {
        // imagePath is deliberately omitted — it's a local file path that
        // won't exist on a different device.
        for (final row in achievements)
          row.id.toString(): {
            'type': row.type.name,
            'level': row.level,
            'earnedAt': row.earnedAt.toIso8601String(),
            'note': row.note,
          },
      },
    );

    final storyProgress = await _db.getAllStoryProgress();
    await _replaceCollection(
      userDoc.collection('backupStoryProgress'),
      {
        for (final row in storyProgress)
          row.storyId: {
            'lastPageIndex': row.lastPageIndex,
            'completed': row.completed,
            'updatedAt': row.updatedAt.toIso8601String(),
          },
      },
    );

    final reelProgress = await _db.getAllReelProgress();
    await _replaceCollection(
      userDoc.collection('backupReelProgress'),
      {
        for (final row in reelProgress)
          row.reelId: {
            'lastPositionMs': row.lastPositionMs,
            'completed': row.completed,
            'updatedAt': row.updatedAt.toIso8601String(),
          },
      },
    );

    final settings = await _db.getUserSettingsRow();
    await userDoc.collection('backupSettings').doc('singleton').set({
      'newDeckCardsPerDayPerDirection': settings?.newDeckCardsPerDayPerDirection,
      'readerFontScale': settings?.readerFontScale,
    });

    await userDoc.collection('backupMeta').doc('info').set({
      'lastBackupAt': FieldValue.serverTimestamp(),
    });
  }

  /// Full resync of every local word, not just recently-changed ones — a
  /// backup is a good moment to repair any words a prior best-effort
  /// [UserWordRepository._push] silently dropped while offline.
  Future<void> _resyncUserWords(DocumentReference<Map<String, dynamic>> userDoc) async {
    final words = await _db.getAllUserWords();
    await _replaceCollection(
      userDoc.collection('words'),
      {
        for (final row in words)
          row.dictionaryForm: {
            'status': row.status.name,
            'savedAt': row.savedAt?.toIso8601String(),
            'lastSeen': row.lastSeen.toIso8601String(),
          },
      },
    );
  }

  Future<void> _replaceCollection(
    CollectionReference<Map<String, dynamic>> ref,
    Map<String, Map<String, dynamic>> docs,
  ) async {
    final existing = await ref.get();
    for (final chunk in _chunked(existing.docs)) {
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    for (final chunk in _chunked(docs.entries.toList())) {
      final batch = _firestore.batch();
      for (final entry in chunk) {
        batch.set(ref.doc(entry.key), entry.value);
      }
      await batch.commit();
    }
  }

  Iterable<List<T>> _chunked<T>(List<T> items) sync* {
    for (var i = 0; i < items.length; i += _chunkSize) {
      yield items.sublist(i, i + _chunkSize > items.length ? items.length : i + _chunkSize);
    }
  }

  /// Pulls every backup collection down into the local Drift tables,
  /// upserting so it's safe to call even if some local rows already exist.
  ///
  /// Each collection is restored inside its own try/catch: a malformed or
  /// unexpected row in one collection (e.g. a stale enum name in
  /// backupDeckCardProgress) must not abort the whole restore and silently
  /// take every collection after it down too — that's how a device could
  /// come back with everything except, say, story progress, with no error
  /// ever surfacing (the caller's own catch is silent, see sign_in_screen).
  /// Failures are collected and rethrown together at the end so the caller
  /// still learns the restore was incomplete.
  Future<void> restoreBackup() async {
    final userDoc = _userDoc();
    if (userDoc == null) return;

    final errors = <Object>[];

    await _restoreCollection(errors, () async {
      final wordsSnapshot = await userDoc.collection('words').get();
      for (final doc in wordsSnapshot.docs) {
        final data = doc.data();
        await _db.into(_db.userWords).insertOnConflictUpdate(
              UserWordsCompanion.insert(
                dictionaryForm: doc.id,
                status: WordStatus.values.byName(data['status'] as String),
                lastSeen: DateTime.parse(data['lastSeen'] as String),
                savedAt: Value(
                  data['savedAt'] != null ? DateTime.parse(data['savedAt'] as String) : null,
                ),
              ),
            );
      }
    });

    await _restoreCollection(errors, () async {
      final deckCardProgressSnapshot = await userDoc.collection('backupDeckCardProgress').get();
      for (final doc in deckCardProgressSnapshot.docs) {
        final data = doc.data();
        await _db.into(_db.deckCardProgress).insertOnConflictUpdate(
              DeckCardProgressCompanion.insert(
                cardId: data['cardId'] as String,
                direction: ReviewDirection.values.byName(data['direction'] as String),
                dueAt: Value(_parseNullableDate(data['dueAt'])),
                intervalIndex: Value(data['intervalIndex'] as int? ?? 0),
                introducedAt: Value(_parseNullableDate(data['introducedAt'])),
                lastReviewed: Value(_parseNullableDate(data['lastReviewed'])),
              ),
            );
      }
    });

    await _restoreCollection(errors, () async {
      final reviewEventsSnapshot = await userDoc.collection('backupReviewEvents').get();
      for (final doc in reviewEventsSnapshot.docs) {
        final data = doc.data();
        await _db.logReviewEvent(
          correct: data['correct'] as bool,
          at: DateTime.parse(data['occurredAt'] as String),
        );
      }
    });

    await _restoreCollection(errors, () async {
      final achievementsSnapshot = await userDoc.collection('backupAchievements').get();
      for (final doc in achievementsSnapshot.docs) {
        final data = doc.data();
        await _db.addAchievement(
          type: CertificateType.values.byName(data['type'] as String),
          level: data['level'] as String,
          earnedAt: DateTime.parse(data['earnedAt'] as String),
          note: data['note'] as String?,
        );
      }
    });

    await _restoreCollection(errors, () async {
      final storyProgressSnapshot = await userDoc.collection('backupStoryProgress').get();
      for (final doc in storyProgressSnapshot.docs) {
        final data = doc.data();
        await _db.saveStoryProgress(
          doc.id,
          lastPageIndex: data['lastPageIndex'] as int? ?? 0,
          completed: data['completed'] as bool? ?? false,
        );
      }
    });

    await _restoreCollection(errors, () async {
      final reelProgressSnapshot = await userDoc.collection('backupReelProgress').get();
      for (final doc in reelProgressSnapshot.docs) {
        final data = doc.data();
        await _db.saveReelProgress(
          doc.id,
          lastPositionMs: data['lastPositionMs'] as int? ?? 0,
          completed: data['completed'] as bool? ?? false,
        );
      }
    });

    await _restoreCollection(errors, () async {
      final settingsSnapshot = await userDoc.collection('backupSettings').doc('singleton').get();
      final settingsData = settingsSnapshot.data();
      if (settingsData != null) {
        await _db.writeNewDeckCardsPerDayPerDirection(
          settingsData['newDeckCardsPerDayPerDirection'] as int?,
        );
        await _db.writeReaderFontScale(settingsData['readerFontScale'] as double?);
      }
    });

    if (errors.isNotEmpty) {
      throw StateError('Restore finished with ${errors.length} failed collection(s): $errors');
    }
  }

  Future<void> _restoreCollection(List<Object> errors, Future<void> Function() restore) async {
    try {
      await restore();
    } catch (e) {
      errors.add(e);
    }
  }

  DateTime? _parseNullableDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}

@riverpod
BackupRepository backupRepository(Ref ref) {
  return BackupRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(firestoreProvider),
    ref.watch(authRepositoryProvider),
  );
}
