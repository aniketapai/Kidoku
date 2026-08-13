import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/providers.dart';

part 'due_review_count_provider.g.dart';

@riverpod
Stream<int> dueReviewCount(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchDueReviewCount();
}
