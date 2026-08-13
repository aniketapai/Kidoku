# Yomu content ingestion

Offline pipeline that produces `assets/seed/dictionary_seed.json` and the
JLPT deck seed JSON — the app never fetches or tokenizes content on-device.
Run this, commit the regenerated JSON, ship it.

## Setup

```
cd ingestion
pip install -r requirements.txt
```

## Dictionary (JMdict + JLPT)

```
python3 build_dictionary.py
```

Downloads the latest `jmdict-eng` release from
[scriptin/jmdict-simplified](https://github.com/scriptin/jmdict-simplified)
and the [elzup/jlpt-word-list](https://github.com/elzup/jlpt-word-list)
dataset (both cached under `.cache/` after the first run), joins them, and
overwrites `assets/seed/dictionary_seed.json` with every JMdict entry that
has a usable reading and at least one English gloss (~215k entries as of
JMdict 3.6.x). JLPT level is an estimate — JMdict itself carries no
official level data, same caveat steps.md section 5 already calls out.

Re-run whenever you want to pick up a newer JMdict/JLPT-list release;
delete `.cache/` first to force a fresh download.

These scripts are re-run tools, not one-shot: nothing here talks to
Firestore or a Cloud Function — output lands as committed JSON assets,
consistent with how the app already seeds its Drift database
(`lib/core/database/seed/seed_loader.dart`).

## JLPT decks (Anki imports)

```
python3 convert_apkg.py
```

Reads the four `.apkg` deck files expected in the repo root (N5/N4
vocabulary from JTalkOnline.com, N5/N4 kanji from passjapanesetest.com),
each just a zipped SQLite Anki collection, and overwrites
`assets/seed/deck_vocab_seed.json` / `assets/seed/deck_kanji_seed.json`.
Every note becomes one row, in original deck order, with no dedup — the
app wants these decks as-is. Deck audio ([sound:*.mp3] fields) is dropped;
not bundled into the app for now.
