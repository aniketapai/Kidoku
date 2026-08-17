import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/text/romaji_converter.dart';

part 'dictionary_repository.g.dart';

class DictionaryRepository {
  DictionaryRepository(this._db);
  final AppDatabase _db;

  Future<DictionaryEntry?> lookup(String dictionaryForm) =>
      _db.lookupDictionaryEntry(dictionaryForm);

  Future<Map<String, DictionaryEntry>> lookupMany(List<String> dictionaryForms) =>
      _db.lookupDictionaryEntries(dictionaryForms);

  /// Searches by the raw query (Japanese form/reading prefix, or English
  /// meaning) and, when the query looks like romaji (e.g. "taberu"), also
  /// by its hiragana conversion — otherwise typing romaji never matches the
  /// kana readings stored in the dictionary at all.
  ///
  /// Japanese/romaji form matches always outrank English meaning matches,
  /// regardless of which query produced them: a meaning field can contain
  /// an unrelated romanized word (e.g. "kabushiki kaisha" showing up in the
  /// gloss for an unrelated entry), and that substring hit is a much weaker
  /// signal than an exact reading match on the word itself. Ranking English
  /// hits first used to bury e.g. "kaisha" (会社) under a page of loosely
  /// related company-related entries.
  Future<List<DictionaryEntry>> search(String query, {int limit = 50}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final seen = <String>{};
    final japaneseHits = <DictionaryEntry>[];
    for (final e in await _db.searchJapanesePrefix(trimmed, limit: limit)) {
      if (seen.add(e.dictionaryForm)) japaneseHits.add(e);
    }

    final kana = romajiToHiragana(trimmed);
    if (kana != null && kana != trimmed) {
      for (final e in await _db.searchJapanesePrefix(kana, limit: limit)) {
        if (seen.add(e.dictionaryForm)) japaneseHits.add(e);
      }
    }

    if (japaneseHits.length >= limit) return japaneseHits.take(limit).toList();

    final meaningHits = await _db.searchMeanings(trimmed, limit: limit - japaneseHits.length);
    return [
      ...japaneseHits,
      ...meaningHits.where((e) => seen.add(e.dictionaryForm)),
    ].take(limit).toList();
  }
}

@riverpod
DictionaryRepository dictionaryRepository(Ref ref) {
  return DictionaryRepository(ref.watch(appDatabaseProvider));
}
