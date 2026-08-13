import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/dictionary_repository.dart';

// Hand-written (not @riverpod codegen) — see dictionary_search_provider.dart for why.
final dictionaryLookupProvider =
    FutureProvider.autoDispose.family<DictionaryEntry?, String>((ref, dictionaryForm) {
  return ref.watch(dictionaryRepositoryProvider).lookup(dictionaryForm);
});
