import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/app_database.dart';
import '../../reader/data/dictionary_repository.dart';

final dictionarySearchQueryProvider = StateProvider<String>((ref) => '');

// Hand-written (not @riverpod codegen) — see dictionary_search_provider.dart for why.
final dictionarySearchResultsProvider = FutureProvider.autoDispose<List<DictionaryEntry>>((ref) {
  final query = ref.watch(dictionarySearchQueryProvider);
  return ref.watch(dictionaryRepositoryProvider).search(query);
});
