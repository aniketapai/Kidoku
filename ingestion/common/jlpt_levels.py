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


def load_jlpt_levels(cache_dir: Path) -> dict[str, str]:
    raw = net.fetch_cached(_SOURCE_URL, cache_dir / _CACHE_NAME)
    reader = csv.DictReader(io.StringIO(raw.decode("utf-8")))

    # A handful of expressions appear under more than one level (different
    # senses tagged separately upstream) — keep the easiest (highest N
    # number) so we never over-flag a word a beginner already knows.
    levels_by_expression: dict[str, set[int]] = defaultdict(set)
    for row in reader:
        match = _LEVEL_RE.search(row["tags"])
        if match:
            levels_by_expression[row["expression"]].add(int(match.group(1)))

    return {
        expression: f"N{max(levels)}"
        for expression, levels in levels_by_expression.items()
    }
