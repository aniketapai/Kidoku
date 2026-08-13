import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/story_repository.dart';
import '../domain/story.dart';

// Hand-written (not @riverpod codegen), same rationale as
// dictionaryLookupProvider: family providers over a plain repository call.

final storyManifestProvider = FutureProvider.autoDispose<List<StoryMeta>>((ref) {
  return ref.watch(storyRepositoryProvider).loadManifest();
});

final storyProvider = FutureProvider.autoDispose.family<Story, String>((ref, file) {
  return ref.watch(storyRepositoryProvider).loadStory(file);
});

final storyProgressProvider =
    StreamProvider.autoDispose.family<StoryProgressData?, String>((ref, storyId) {
  return ref.watch(storyRepositoryProvider).watchProgress(storyId);
});

final allStoryProgressProvider =
    StreamProvider.autoDispose<Map<String, StoryProgressData>>((ref) {
  return ref.watch(storyRepositoryProvider).watchAllProgress();
});

final storyProgressActionsProvider = Provider.autoDispose<StoryProgressActions>((ref) {
  return StoryProgressActions(ref);
});

class StoryProgressActions {
  StoryProgressActions(this._ref);
  final Ref _ref;

  Future<void> savePage(String storyId, int pageIndex, {required bool completed}) {
    return _ref
        .read(storyRepositoryProvider)
        .saveProgress(storyId, lastPageIndex: pageIndex, completed: completed);
  }
}

/// The reader's persisted font-size multiplier — null (the default) means
/// 1.0, applied on top of each story's level-based base font size.
final readerFontScaleProvider = StreamProvider.autoDispose<double?>((ref) {
  return ref.watch(storyRepositoryProvider).watchReaderFontScale();
});

final readerFontScaleActionsProvider = Provider.autoDispose<ReaderFontScaleActions>((ref) {
  return ReaderFontScaleActions(ref);
});

class ReaderFontScaleActions {
  ReaderFontScaleActions(this._ref);
  final Ref _ref;

  Future<void> setScale(double scale) {
    return _ref.read(storyRepositoryProvider).saveReaderFontScale(scale);
  }
}
