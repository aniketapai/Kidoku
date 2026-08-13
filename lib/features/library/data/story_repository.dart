import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../domain/story.dart';

part 'story_repository.g.dart';

const _kMinLoadTime = Duration(seconds: 1);

class StoryRepository {
  StoryRepository(this._db);
  final AppDatabase _db;

  Future<List<StoryMeta>> loadManifest() async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/stories/manifest.json')) as List<dynamic>;
    return json.map((e) => StoryMeta.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Loads and parses the story, holding the result back until at least
  /// [_kMinLoadTime] has passed. Parsing itself is near-instant, but pairing
  /// it with the route's push transition would otherwise let the heavy
  /// token-by-token reader tree build mid-animation — the stutter the
  /// reader felt as "lag". Padding this out keeps the loading spinner on
  /// screen long enough for the transition to settle first.
  Future<Story> loadStory(String file) async {
    final results = await Future.wait([
      rootBundle.loadString('assets/stories/$file').then((raw) => jsonDecode(raw)),
      Future<void>.delayed(_kMinLoadTime),
    ]);
    return Story.fromJson(results[0] as Map<String, dynamic>);
  }

  Stream<StoryProgressData?> watchProgress(String storyId) => _db.watchStoryProgress(storyId);

  Stream<Map<String, StoryProgressData>> watchAllProgress() => _db.watchAllStoryProgress();

  Future<void> saveProgress(String storyId, {required int lastPageIndex, required bool completed}) =>
      _db.saveStoryProgress(storyId, lastPageIndex: lastPageIndex, completed: completed);

  Stream<double?> watchReaderFontScale() => _db.watchReaderFontScale();

  Future<void> saveReaderFontScale(double? scale) => _db.writeReaderFontScale(scale);
}

@riverpod
StoryRepository storyRepository(Ref ref) {
  return StoryRepository(ref.watch(appDatabaseProvider));
}
