#!/usr/bin/env python3
"""Builds assets/seed/dictionary_seed.json from JMdict + a JLPT word list.

Replaces the 42-entry hand-authored dictionary with a full import, per
steps.md section 5 ("pre-convert JMdict to ... ship as prepackaged ...
Cache dictionary lookups so re-reading an article never re-queries" — the
app already does the caching part via its Drift table; this script is the
"pre-convert" step, run offline rather than in a Cloud Function since no
server pipeline exists yet, same rationale DifficultyScorer's docstring
already gives for running scoring locally).

Usage:
    pip install -r requirements.txt
    python3 build_dictionary.py
"""

import json
import tarfile
import time
from pathlib import Path

from common import net
from common.jlpt_levels import load_jlpt_levels
from common.pos_mapping import jmdict_pos_category
from common.text_utils import strip_quotes

ROOT = Path(__file__).resolve().parent.parent
CACHE_DIR = Path(__file__).resolve().parent / ".cache"
OUTPUT_PATH = ROOT / "assets" / "seed" / "dictionary_seed.json"

_GITHUB_RELEASE_API = (
    "https://api.github.com/repos/scriptin/jmdict-simplified/releases/latest"
)
_MAX_MEANINGS_PER_ENTRY = 5
_MAX_SENSES_CONSIDERED = 3
# JMdict marks these kanji/kana forms as "don't show as a primary form" —
# search-only spellings that exist for lookup completeness, not display.
_NON_DISPLAY_TAGS = {"sK", "sk"}


def _resolve_jmdict_asset_url() -> str:
    import requests

    response = requests.get(_GITHUB_RELEASE_API, timeout=30)
    response.raise_for_status()
    release = response.json()
    for asset in release["assets"]:
        name = asset["name"]
        if name.startswith("jmdict-eng-") and name.endswith(".json.tgz"):
            return asset["browser_download_url"]
    raise RuntimeError("No jmdict-eng-*.json.tgz asset found in latest release")


def _load_jmdict() -> dict:
    json_cache = CACHE_DIR / "jmdict-eng.json"
    if not json_cache.exists():
        tgz_bytes = net.fetch_cached(_resolve_jmdict_asset_url(), CACHE_DIR / "jmdict-eng.json.tgz")
        with tarfile.open(fileobj=__import__("io").BytesIO(tgz_bytes)) as tar:
            member = next(m for m in tar.getmembers() if m.name.endswith(".json"))
            extracted = tar.extractfile(member)
            assert extracted is not None
            json_cache.write_bytes(extracted.read())
    with json_cache.open("rb") as f:
        return json.load(f)


def _pick_reading(kana_forms: list[dict]) -> dict | None:
    """Picks the single reading shown for display purposes: prefer
    `common`, skip search-only spellings (fall back to the raw list if
    every reading is search-only — every entry has *some* kana).
    """
    displayable = [f for f in kana_forms if not (set(f.get("tags", [])) & _NON_DISPLAY_TAGS)]
    if not displayable:
        displayable = kana_forms
    if not displayable:
        return None
    for form in displayable:
        if form.get("common"):
            return form
    return displayable[0]


def _valid_kanji_texts(forms: list[dict]) -> list[tuple[str, bool]]:
    """Every kanji spelling worth indexing as a lookup key, as (text,
    common) pairs — excludes only sK/sk ("search-only, never display")
    forms. Rare-but-real spellings (rK) are kept: literary/older text (the
    Aozora Bunko ingestion's whole reason for existing) uses them — e.g.
    云う for 言う, 蜘蛛 for the technically-"usually kana" くも — and a
    tokenizer preserves whatever spelling the source text actually used,
    so the dictionary needs to resolve it, not just the "textbook" form.
    """
    return [
        (f["text"], bool(f.get("common")))
        for f in forms
        if not (set(f.get("tags", [])) & _NON_DISPLAY_TAGS)
    ]


def _collect_meanings(senses: list[dict]) -> list[str]:
    meanings: list[str] = []
    for sense in senses[:_MAX_SENSES_CONSIDERED]:
        for gloss in sense.get("gloss", []):
            if gloss.get("lang") != "eng":
                continue
            text = strip_quotes(gloss["text"].strip())
            if text and text not in meanings:
                meanings.append(text)
            if len(meanings) >= _MAX_MEANINGS_PER_ENTRY:
                return meanings
    return meanings


def _primary_pos_codes(senses: list[dict]) -> list[str]:
    for sense in senses:
        pos = sense.get("partOfSpeech", [])
        if pos:
            return pos
    return []


def build_entries(jmdict: dict, jlpt_levels: dict[str, str]) -> list[dict]:
    # Index every legitimate spelling a word can appear as in real text —
    # its kana reading *and* each non-search-only kanji variant — as its
    # own key pointing at the same reading/meanings/pos, rather than
    # picking one "canonical" dictionaryForm and discarding the rest. A
    # tokenizer's lemmatized output preserves whatever spelling the source
    # text used, and literary/older text routinely uses a kanji spelling
    # (or an alternate rK one) for words JMdict tags "usually kana" —
    # collapsing to a single form means real tokens miss the dictionary.
    entries: dict[str, dict] = {}

    for word in jmdict["words"]:
        senses = word.get("sense", [])
        meanings = _collect_meanings(senses)
        if not meanings:
            continue

        kana_form = _pick_reading(word.get("kana", []))
        if kana_form is None:
            continue
        reading = kana_form["text"]

        kanji_keys = _valid_kanji_texts(word.get("kanji", []))
        # Only index the bare kana reading as its own key when it's the
        # *only* legitimate spelling (no valid kanji at all — ます, の) or
        # JMdict's own 'uk' tag says kana is how this is normally written
        # despite a valid kanji form existing (ある, 蜘蛛). Otherwise the
        # reading alone is genuinely ambiguous between unrelated words — 入る
        # ("to enter") and the auxiliary いる both read いる — and indexing
        # every word's reading regardless would let whichever happens to
        # look more "common" steal a homophone's kana spelling.
        add_kana_key = not kanji_keys or any("uk" in s.get("misc", []) for s in senses)
        keys = set(kanji_keys)
        if add_kana_key:
            keys.add((reading, bool(kana_form.get("common"))))

        pos = jmdict_pos_category(_primary_pos_codes(senses))
        for key, is_common in keys:
            existing = entries.get(key)
            if existing is not None:
                # On a collision, prefer whichever entry is common; if both
                # (or neither) are, prefer the more polysemous one as a
                # proxy for "the fundamental word", not just whichever
                # JMdict happened to list last — e.g. ある collides
                # existential 有る/在る (6 senses) with 或る "a certain"
                # (1 sense); the former is what a learner means by "ある"
                # the overwhelming majority of the time.
                if existing["_common"] and not is_common:
                    continue
                if existing["_common"] == is_common and existing["_senseCount"] >= len(senses):
                    continue

            entries[key] = {
                "dictionaryForm": key,
                "reading": reading,
                "meanings": meanings,
                "partOfSpeech": pos,
                "jlptLevel": jlpt_levels.get(key) or jlpt_levels.get(reading),
                "_common": is_common,
                "_senseCount": len(senses),
            }

    for entry in entries.values():
        del entry["_common"]
        del entry["_senseCount"]
    return sorted(entries.values(), key=lambda e: e["dictionaryForm"])


def main() -> None:
    start = time.time()
    print("Loading JLPT level list...")
    jlpt_levels = load_jlpt_levels(CACHE_DIR)
    print(f"  {len(jlpt_levels)} leveled words")

    print("Loading JMdict (downloads ~11MB on first run, cached after)...")
    jmdict = _load_jmdict()
    print(f"  {len(jmdict['words'])} raw JMdict entries")

    print("Building dictionary entries...")
    entries = build_entries(jmdict, jlpt_levels)
    print(f"  {len(entries)} unique dictionaryForm entries")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, separators=(",", ":"))

    print(f"Wrote {OUTPUT_PATH} ({OUTPUT_PATH.stat().st_size / 1_000_000:.1f} MB) in {time.time() - start:.1f}s")


if __name__ == "__main__":
    main()
