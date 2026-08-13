"""Maps part-of-speech tags from JMdict (English abbreviation codes) and
Janome (IPADic Japanese labels) onto the small set of category strings the
app displays (see the hand-authored assets/seed/*.json for the existing
vocabulary: noun, particle, auxiliary, i-adjective, verb, ...).
"""

# Ordered so the first matching prefix wins when a JMdict sense carries
# several tags (e.g. ["n", "vs"] for a noun that can also take suru).
_JMDICT_PREFIX_CATEGORIES = [
    ("adj-i", "i-adjective"),
    ("adj-na", "na-adjective"),
    ("adj-nari", "na-adjective"),
    ("adj-ix", "i-adjective"),
    ("adj", "adjective"),
    ("v", "verb"),
    ("n-adv", "noun"),
    ("n-pref", "noun"),
    ("n-suf", "noun"),
    ("n-t", "noun"),
    ("n", "noun"),
    ("pn", "pronoun"),
    ("adv", "adverb"),
    ("prt", "particle"),
    ("conj", "conjunction"),
    ("int", "interjection"),
    ("aux-v", "auxiliary"),
    ("aux-adj", "auxiliary"),
    ("aux", "auxiliary"),
    ("pref", "prefix"),
    ("suf", "suffix"),
    ("ctr", "counter"),
    ("exp", "expression"),
    ("cop", "copula"),
    ("num", "numeral"),
]


def jmdict_pos_category(pos_codes: list[str]) -> str:
    for code in pos_codes:
        for prefix, category in _JMDICT_PREFIX_CATEGORIES:
            if code.startswith(prefix):
                return category
    return "other"


# Janome/IPADic's top-level 品詞 (part-of-speech) label, as the first
# comma-separated field of Token.part_of_speech.
_JANOME_CATEGORIES = {
    "名詞": "noun",
    "動詞": "verb",
    "形容詞": "i-adjective",
    "形容動詞": "na-adjective",
    "副詞": "adverb",
    "助詞": "particle",
    "助動詞": "auxiliary",
    "接続詞": "conjunction",
    "連体詞": "adnominal",
    "感動詞": "interjection",
    "接頭詞": "prefix",
    "記号": "symbol",
    "フィラー": "filler",
}


def janome_pos_category(part_of_speech: str) -> str:
    top_level = part_of_speech.split(",", 1)[0]
    return _JANOME_CATEGORIES.get(top_level, "other")
