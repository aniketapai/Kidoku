import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/user_word_repository.dart';

// Hand-written (not @riverpod codegen) — see dictionary_search_provider.dart for why.
final userWordProvider =
    StreamProvider.autoDispose.family<UserWord?, String>((ref, dictionaryForm) {
  return ref.watch(userWordRepositoryProvider).watch(dictionaryForm);
});
