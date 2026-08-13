import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../reader/data/dictionary_repository.dart';
import '../../reader/data/user_word_repository.dart';

// Hand-written (not @riverpod codegen): DueWord wraps Drift-generated
// DataClasses (UserWord/DictionaryEntry) declared in a `part` file, which
// triggers riverpod_generator's InvalidTypeException — see
// dictionary_search_provider.dart for the same workaround.
class DueWord {
  const DueWord({required this.userWord, required this.entry});

  final UserWord userWord;
  final DictionaryEntry? entry;
}

final dueWordsProvider = StreamProvider.autoDispose<List<DueWord>>((ref) async* {
  final userWordRepository = ref.watch(userWordRepositoryProvider);
  final dictionaryRepository = ref.watch(dictionaryRepositoryProvider);

  await for (final words in userWordRepository.watchDue()) {
    final entries = await Future.wait(
      words.map((w) => dictionaryRepository.lookup(w.dictionaryForm)),
    );
    yield [
      for (var i = 0; i < words.length; i++) DueWord(userWord: words[i], entry: entries[i]),
    ];
  }
});
