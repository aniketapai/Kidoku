"""Fetches the elzup/jlpt-word-list dataset (MIT licensed, derived from the
well-known Tanos.co.uk JLPT level list) and exposes it as a
expression -> "N1".."N5" map.

JMdict itself carries no JLPT tagging (steps.md section 5: "there's no
official exhaustive JLPT word list" — every level assignment here is an
estimate, same caveat the app's hand-authored seed data already carries.
"""

import csv
import io
import re
from collections import defaultdict
from pathlib import Path

from . import net

_SOURCE_URL = (
    "https://raw.githubusercontent.com/elzup/jlpt-word-list/master/out/all.csv"
)
_LEVEL_RE = re.compile(r"JLPT_(\d)")
_CACHE_NAME = "jlpt_all.csv"

# The upstream list is compiled from formal JLPT vocabulary lists, which
# (being vocabulary lists, not phrasebooks) systematically omit or mis-tag
# everyday set phrases/greetings — e.g. it tags こんにちは and ありがとう as
# N2/N3, and doesn't tag すみません or よろしく at all. These are taught in
# the first lesson of every N5 course, so hand-override them rather than
# trust the source data.
_OVERRIDES = {
    "こんにちは": "N5",
    "今日は": "N5",
    "こんばんは": "N5",
    "おはよう": "N5",
    "おはようございます": "N5",
    "さようなら": "N5",
    "すみません": "N5",
    "ありがとう": "N5",
    "ありがとうございます": "N5",
    "おやすみ": "N5",
    "おやすみなさい": "N5",
    "いただきます": "N5",
    "ごちそうさま": "N5",
    "ごちそうさまでした": "N5",
    "どういたしまして": "N5",
    "はじめまして": "N5",
    "よろしく": "N5",
    "よろしくお願いします": "N5",
    "失礼します": "N5",
    "お願いします": "N5",
    "ただいま": "N5",
    "お帰りなさい": "N5",
}


def load_jlpt_levels(cache_dir: Path) -> dict[str, str]:
    raw = net.fetch_cached(_SOURCE_URL, cache_dir / _CACHE_NAME)
    reader = csv.DictReader(io.StringIO(raw.decode("utf-8")))

    # A handful of expressions appear under more than one level (different
    # senses tagged separately upstream, or — common for a single row —
    # more than one JLPT_<n> tag on the same row) — keep the easiest
    # (highest N number) so we never over-flag a word a beginner already
    # knows. `.finditer` (not `.search`, which only returns the first
    # match) so every JLPT_<n> tag on a row is counted, not just whichever
    # happens to appear first in the tag string.
    levels_by_expression: dict[str, set[int]] = defaultdict(set)
    for row in reader:
        for match in _LEVEL_RE.finditer(row["tags"]):
            levels_by_expression[row["expression"]].add(int(match.group(1)))

    levels = {
        expression: f"N{max(digits)}"
        for expression, digits in levels_by_expression.items()
    }
    levels.update(_OVERRIDES)
    return levels
