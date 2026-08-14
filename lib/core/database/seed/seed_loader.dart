import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app_database.dart';
import '../tables/deck_cards_table.dart';

/// Bump when assets/seed/*.json content changes, so existing installs
/// re-seed.
///
/// v3: dictionary_seed.json grew from a 42-entry hand-authored sample to a
/// full JMdict + JLPT-word-list import (~215k entries; see ingestion/), and
/// articles_seed.json gained real Aozora Bunko content alongside the
/// original N5 story batch — switched dictionary/token inserts to
/// [Batch] so a fresh install seeding ~215k rows stays fast.
///
/// v4: fixed build_dictionary.py mapping common words (の, ある, いる, ます,
/// ござる...) to obscure/wrong kanji spellings instead of the kana form
/// real text and the tokenizer actually produce; added 8 short (1-3 page)
/// Niimi Nankichi stories alongside the 2 (long) Akutagawa pieces.
///
/// v5: added deck_vocab_seed.json / deck_kanji_seed.json — the JLPT
/// Anki decks (N5/N4 vocab, N5/N4 kanji) converted as-is by
/// ingestion/convert_apkg.py, loaded into the new deck_cards table. Unlike
/// dictionaryEntries/articles, deck_card_progress (the user's SRS state
/// over these cards) is deliberately never cleared here — deckCards rows
/// use a stable id (deckId + Anki note id) precisely so a reseed can't
/// orphan it.
///
/// v6: dropped the article-reading feature (articles/tokens tables and
/// articles_seed.json) — the app is now vocab/dictionary/review only.
///
/// v7: added the N3 vocab/kanji Anki decks (Pass_JLPT_N3_Vocabulary.apkg,
/// Pass_JLPT_N3_Kanji.apkg) alongside the existing N5/N4 decks.
///
/// v8: Pass_JLPT_N3_Vocabulary.apkg is a single flat deck with no
/// "Week X.Y Topic" subdecks like the N5/N4 JTalk decks have, so every N3
/// vocab card seeded with category=null and the vocabulary screen showed
/// it as one flat "N3" group instead of sectioned like N5/N4.
/// ingestion/convert_apkg.py now buckets N3 vocab by topic/part-of-speech
/// and assigns "Week X.Y Name" categories the same way, so all 1893 N3
/// vocab entries are unchanged except for category/sortOrder.
///
/// v9: removed a stray Anki template row ("kanji" / "ja_on / ja_kun" /
/// "meaning") that had leaked into the N3 kanji deck from
/// Pass_JLPT_N3_Kanji.apkg.
///
/// v10: replaced the 30 catch-all "General Vocabulary I"..."General
/// Vocabulary XXX" N3 vocab categories (477 words dumped into meaningless
/// numbered buckets) with 34 topic-named categories in the same "Week X.Y
/// Name" style as the rest of N3/N4/N5, reusing existing N3 topics where the
/// words fit (extending their roman-numeral suffix) and adding a few new
/// topics (e.g. People and Occupations, Materials and Elements, Everyday
/// Objects and Items, Sports and Hobbies) for words that didn't fit any
/// existing topic. Also renumbered sortOrder for all 1893 N3 vocab entries
/// so every category — old and new — displays as one contiguous block in a
/// clean Week 1 → Week 26 sequence instead of the new categories being
/// interleaved into the old sortOrder gaps. No words, meanings, or other
/// fields were changed.
const kSeedVersion = 10;

/// Loads assets/seed/*.json into [AppDatabase] on first launch: real JMdict
/// dictionary entries and the JLPT Anki decks produced by the ingestion/
/// pipeline.
abstract final class SeedLoader {
  static Future<void> run(AppDatabase db) async {
    final seededVersion = await db.readSeededVersion();
    if (seededVersion != null && seededVersion >= kSeedVersion) return;

    final dictionaryJson =
        jsonDecode(await rootBundle.loadString('assets/seed/dictionary_seed.json'))
            as List<dynamic>;
    final deckVocabJson =
        jsonDecode(await rootBundle.loadString('assets/seed/deck_vocab_seed.json'))
            as List<dynamic>;
    final deckKanjiJson =
        jsonDecode(await rootBundle.loadString('assets/seed/deck_kanji_seed.json'))
            as List<dynamic>;

    await db.transaction(() async {
      await db.delete(db.dictionaryEntries).go();
      await db.delete(db.deckCards).go();

      final dictionaryEntries = dictionaryJson.cast<Map<String, dynamic>>();
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          db.dictionaryEntries,
          dictionaryEntries
              .map(
                (entry) => DictionaryEntriesCompanion.insert(
                  dictionaryForm: entry['dictionaryForm'] as String,
                  reading: entry['reading'] as String,
                  meanings: jsonEncode(entry['meanings']),
                  partOfSpeech: entry['partOfSpeech'] as String,
                  jlptLevel: Value(entry['jlptLevel'] as String?),
                ),
              )
              .toList(),
        );
      });

      final deckCardEntries = [
        ...deckVocabJson.cast<Map<String, dynamic>>(),
        ...deckKanjiJson.cast<Map<String, dynamic>>(),
      ];
      await db.batch((batch) {
        batch.insertAllOnConflictUpdate(
          db.deckCards,
          deckCardEntries
              .map(
                (entry) => DeckCardsCompanion.insert(
                  id: entry['id'] as String,
                  deckId: entry['deckId'] as String,
                  level: entry['level'] as String,
                  cardType: entry['cardType'] == 'kanji' ? DeckCardType.kanji : DeckCardType.vocab,
                  category: Value(entry['category'] as String?),
                  expression: entry['expression'] as String,
                  reading: entry['reading'] as String,
                  meaning: entry['meaning'] as String,
                  extra: Value(entry['extra'] == null ? null : jsonEncode(entry['extra'])),
                  sortOrder: entry['sortOrder'] as int,
                ),
              )
              .toList(),
        );
      });

      await db.writeSeededVersion(kSeedVersion);
    });
  }
}
