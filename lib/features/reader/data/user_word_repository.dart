import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/auth_repository.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/database/tables/user_words_table.dart';
import '../../../core/firebase/providers.dart';

part 'user_word_repository.g.dart';

class UserWordRepository {
  UserWordRepository(this._db, this._firestore, this._auth);

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  final AuthRepository _auth;

  Stream<UserWord?> watch(String dictionaryForm) => _db.watchUserWord(dictionaryForm);

  Stream<List<UserWord>> watchAll() => _db.watchAllUserWords();

  Future<void> save(String dictionaryForm) async {
    await _db.markWordSaved(dictionaryForm);
    await _push(dictionaryForm);
  }

  Future<void> markKnown(String dictionaryForm) async {
    await _db.markWordKnown(dictionaryForm);
    await _push(dictionaryForm);
  }

  /// Best-effort remote sync: the Drift write above is the source of truth
  /// for the UI (it already committed by the time this runs), so a Firestore
  /// failure here — offline, rules rejection, quota — must not surface as an
  /// error on what the user correctly sees as a successful save/mark-known.
  /// It's swallowed rather than rethrown so callers (which mostly fire this
  /// off without awaiting) don't produce an unhandled Future rejection; the
  /// device falls behind remote until the next successful push for this
  /// word, or a fresh [pullFromRemote] on another device overwrites it.
  Future<void> _push(String dictionaryForm) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final row = await (_db.select(_db.userWords)
            ..where((t) => t.dictionaryForm.equals(dictionaryForm)))
          .getSingleOrNull();
      if (row == null) return;

      await _firestore.collection('users').doc(uid).collection('words').doc(dictionaryForm).set({
        'status': row.status.name,
        'savedAt': row.savedAt?.toIso8601String(),
        'lastSeen': row.lastSeen.toIso8601String(),
      });
    } catch (e) {
      debugPrint('UserWordRepository._push($dictionaryForm) failed: $e');
    }
  }

  /// Pulls the signed-in user's remote words into the local Drift cache.
  /// Remote wins on conflict — fine for a single-writer MVP; real
  /// multi-device conflict resolution is future work. Call after sign-in
  /// (including right after linking a Google account) so existing synced
  /// data shows up locally.
  Future<void> pullFromRemote() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snapshot = await _firestore.collection('users').doc(uid).collection('words').get();

    for (final doc in snapshot.docs) {
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
  }

  /// Deletes the signed-in user's entire remote word collection. Called
  /// right before account deletion — unlike [_push], failures here must
  /// surface so the caller doesn't delete the Firebase account while
  /// orphaned data remains in Firestore.
  Future<void> deleteAllRemoteWords() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final wordsRef = _firestore.collection('users').doc(uid).collection('words');
    final snapshot = await wordsRef.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

@riverpod
UserWordRepository userWordRepository(Ref ref) {
  return UserWordRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(firestoreProvider),
    ref.watch(authRepositoryProvider),
  );
}
