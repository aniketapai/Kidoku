import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
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

  Future<void> _push(String dictionaryForm) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final row = await (_db.select(_db.userWords)
          ..where((t) => t.dictionaryForm.equals(dictionaryForm)))
        .getSingleOrNull();
    if (row == null) return;

    await _firestore.collection('users').doc(uid).collection('words').doc(dictionaryForm).set({
      'status': row.status.name,
      'savedAt': row.savedAt?.toIso8601String(),
      'lastSeen': row.lastSeen.toIso8601String(),
    });
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
}

@riverpod
UserWordRepository userWordRepository(Ref ref) {
  return UserWordRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(firestoreProvider),
    ref.watch(authRepositoryProvider),
  );
}
