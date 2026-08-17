import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/reel_repository.dart';
import '../domain/reel.dart';

// Hand-written (not @riverpod codegen), same rationale as
// storyManifestProvider/storyProvider: family providers over a plain
// repository call.

final reelManifestProvider = FutureProvider.autoDispose<List<ReelMeta>>((ref) {
  return ref.watch(reelRepositoryProvider).loadManifest();
});

final reelProvider = FutureProvider.autoDispose.family<Reel, String>((ref, file) {
  return ref.watch(reelRepositoryProvider).loadReel(file);
});

final reelProgressProvider =
    StreamProvider.autoDispose.family<ReelProgressData?, String>((ref, reelId) {
  return ref.watch(reelRepositoryProvider).watchProgress(reelId);
});

final reelProgressActionsProvider = Provider.autoDispose<ReelProgressActions>((ref) {
  return ReelProgressActions(ref);
});

class ReelProgressActions {
  ReelProgressActions(this._ref);
  final Ref _ref;

  Future<void> save(String reelId, {required int lastPositionMs, required bool completed}) {
    return _ref
        .read(reelRepositoryProvider)
        .saveProgress(reelId, lastPositionMs: lastPositionMs, completed: completed);
  }
}
