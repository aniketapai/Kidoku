#!/usr/bin/env python3
"""One-time data-prep: build assets/kanji_strokes/kanji_strokes.json from
KanjiVG (https://github.com/KanjiVG/kanjivg, CC BY-SA 3.0) for every kanji
that appears in the app's seeded decks. Not shipped in the app itself —
run manually whenever the seed decks change and stroke coverage needs a
refresh:

    python3 tool/fetch_kanji_strokes.py
"""
import json
import re
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEED_FILES = [
    ROOT / "assets" / "seed" / "deck_kanji_seed.json",
    ROOT / "assets" / "seed" / "deck_vocab_seed.json",
]
OUT_FILE = ROOT / "assets" / "kanji_strokes" / "kanji_strokes.json"
KANJIVG_BASE = "https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/{code}.svg"

# Same range as lib/core/text/kanji_utils.dart's _kanjiRegex, so coverage
# matches exactly what the app can ever display.
KANJI_RANGE = re.compile(r"[一-龯]")
PATH_D_RE = re.compile(r'<path\b[^>]*\sd="([^"]+)"')


def collect_kanji() -> set[str]:
    chars: set[str] = set()
    for seed_file in SEED_FILES:
        entries = json.loads(seed_file.read_text(encoding="utf-8"))
        for entry in entries:
            chars.update(KANJI_RANGE.findall(entry.get("expression", "")))
    return chars


def fetch_strokes(char: str) -> list[str] | None:
    code = format(ord(char), "05x")
    url = KANJIVG_BASE.format(code=code)
    try:
        with urllib.request.urlopen(url, timeout=15) as resp:
            svg = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise
    strokes = PATH_D_RE.findall(svg)
    return strokes or None


def main() -> None:
    kanji = sorted(collect_kanji())
    print(f"Collected {len(kanji)} unique kanji from seed decks")

    result: dict[str, list[str]] = {}
    missing: list[str] = []

    for i, char in enumerate(kanji, 1):
        strokes = fetch_strokes(char)
        if strokes is None:
            missing.append(char)
        else:
            result[char] = strokes
        if i % 100 == 0:
            print(f"  {i}/{len(kanji)}...")
        time.sleep(0.02)  # be polite to raw.githubusercontent.com

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(
        json.dumps(result, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    print(f"Wrote {len(result)} kanji to {OUT_FILE}")
    if missing:
        print(f"Missing stroke data for {len(missing)} kanji: {''.join(missing)}")


if __name__ == "__main__":
    main()
