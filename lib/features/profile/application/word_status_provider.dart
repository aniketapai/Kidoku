import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/providers.dart';
import '../../../core/database/tables/user_words_table.dart';

// Hand-written (not @riverpod codegen) — see dictionary_search_provider.dart for why.
final wordStatusCountsProvider = StreamProvider.autoDispose<Map<WordStatus, int>>((ref) {
  return ref.watch(appDatabaseProvider).watchWordStatusCounts();
});
