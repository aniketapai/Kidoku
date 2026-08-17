import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../domain/reel.dart';

part 'reel_repository.g.dart';

class ReelRepository {
  ReelRepository(this._db);
  final AppDatabase _db;

  Future<List<ReelMeta>> loadManifest() async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/reels/manifest.json')) as List<dynamic>;
    return json.map((e) => ReelMeta.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Reel> loadReel(String file) async {
    final raw = jsonDecode(await rootBundle.loadString('assets/reels/$file'));
    return Reel.fromJson(raw as Map<String, dynamic>);
  }

  Stream<ReelProgressData?> watchProgress(String reelId) => _db.watchReelProgress(reelId);

  Stream<Map<String, ReelProgressData>> watchAllProgress() => _db.watchAllReelProgress();

  Future<void> saveProgress(String reelId, {required int lastPositionMs, required bool completed}) =>
      _db.saveReelProgress(reelId, lastPositionMs: lastPositionMs, completed: completed);
}

@riverpod
ReelRepository reelRepository(Ref ref) {
  return ReelRepository(ref.watch(appDatabaseProvider));
}
