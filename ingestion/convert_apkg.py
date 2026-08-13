#!/usr/bin/env python3
"""Builds assets/seed/deck_vocab_seed.json and deck_kanji_seed.json from the
JLPT Anki decks dropped in the repo root (N5/N4/N3 vocab, N5/N4/N3 kanji).

An .apkg is just a zip file wrapping a SQLite collection
(collection.anki21, or collection.anki2 on older exports) plus a media
folder — no third-party library needed, sqlite3 is stdlib. Every note in
every deck is converted to one row, in original order, with no dedup and
no filtering: the app wants "whatever is in the deck, as-is" (see
lib/core/database/seed/seed_loader.dart for how these two JSON files get
loaded into the deck_cards table).

Deliberately dropped: the [sound:*.mp3] audio references in the vocab
decks' Audio field — not bundled into the app for now, per the v1 scope
decision recorded in the plan.

Usage:
    python3 convert_apkg.py
"""

import json
import re
import sqlite3
import tempfile
import zipfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_VOCAB_PATH = ROOT / "assets" / "seed" / "deck_vocab_seed.json"
OUTPUT_KANJI_PATH = ROOT / "assets" / "seed" / "deck_kanji_seed.json"

_FIELD_SEP = "\x1f"
_TAG_RE = re.compile(r"<[^>]+>")

_DECKS = [
    {
        "file": "JLPT_N5_Vocabulary_by_JTalkOnlinecom.apkg",
        "deckId": "jlpt_n5_vocab",
        "level": "N5",
        "cardType": "vocab",
        "vocabFormat": "jtalk",
    },
    {
        "file": "JLPT_N4_Vocabulary_by_JTalkOnlinecom.apkg",
        "deckId": "jlpt_n4_vocab",
        "level": "N4",
        "cardType": "vocab",
        "vocabFormat": "jtalk",
    },
    {
        "file": "Pass_JLPT_N3_Vocabulary.apkg",
        "deckId": "jlpt_n3_vocab",
        "level": "N3",
        "cardType": "vocab",
        "vocabFormat": "pass",
    },
    {
        "file": "Pass_JLPT_N5_Kanji.apkg",
        "deckId": "jlpt_n5_kanji",
        "level": "N5",
        "cardType": "kanji",
    },
    {
        "file": "Pass_JLPT_N4_Kanji.apkg",
        "deckId": "jlpt_n4_kanji",
        "level": "N4",
        "cardType": "kanji",
    },
    {
        "file": "Pass_JLPT_N3_Kanji.apkg",
        "deckId": "jlpt_n3_kanji",
        "level": "N3",
        "cardType": "kanji",
    },
]


def _clean_html(text: str) -> str:
    """Anki fields carry HTML (<br>, &nbsp;) for display in the desktop
    app; the Flutter side renders these as plain Text widgets, so convert
    line breaks to \\n and strip the rest rather than pulling in an HTML
    rendering widget for a handful of tags.
    """
    text = text.replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n")
    text = text.replace("&nbsp;", " ")
    text = _TAG_RE.sub("", text)
    return text.strip()


def _open_collection(tmp_dir: Path) -> sqlite3.Connection:
    anki21 = tmp_dir / "collection.anki21"
    anki2 = tmp_dir / "collection.anki2"
    path = anki21 if anki21.exists() else anki2
    return sqlite3.connect(path)


def _read_collection(apkg_path: Path) -> tuple[dict, dict, list[sqlite3.Row]]:
    """Returns (models, note_id -> deck_name, notes rows)."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        with zipfile.ZipFile(apkg_path) as zf:
            zf.extractall(tmp_dir)

        con = _open_collection(tmp_dir)
        con.row_factory = sqlite3.Row
        cur = con.cursor()

        cur.execute("select models, decks from col")
        models_raw, decks_raw = cur.fetchone()
        models = json.loads(models_raw)
        decks = {d["id"]: d["name"] for d in json.loads(decks_raw).values()}

        cur.execute("select nid, did from cards")
        note_deck = {}
        for nid, did in cur.fetchall():
            # A note can have multiple cards (e.g. "and reversed" models);
            # they all belong to the same deck, so first-seen is fine.
            note_deck.setdefault(nid, decks.get(did, ""))

        cur.execute("select id, mid, flds from notes order by id")
        notes = cur.fetchall()

        con.close()
        return models, note_deck, notes


def _field_index(model: dict, name: str) -> int | None:
    for i, f in enumerate(model["flds"]):
        if f["name"] == name:
            return i
    return None


def _convert_vocab(apkg_path: Path, deck_id: str, level: str) -> list[dict[str, Any]]:
    models, note_deck, notes = _read_collection(apkg_path)
    entries = []
    for sort_order, note in enumerate(notes):
        model = models[str(note["mid"])]
        fields = note["flds"].split(_FIELD_SEP)
        idx = {name: _field_index(model, name) for name in ("Front", "Back", "Kanji/Reading", "Romaji")}

        def field(name: str) -> str:
            i = idx[name]
            return fields[i].strip() if i is not None and i < len(fields) else ""

        front = _clean_html(field("Front"))
        back = _clean_html(field("Back"))
        kanji_reading = _clean_html(field("Kanji/Reading"))
        romaji = _clean_html(field("Romaji"))

        if not front and not back:
            continue

        deck_name = note_deck.get(note["id"], "")
        category = deck_name.split("::")[-1] if "::" in deck_name else None

        extra = {}
        if romaji:
            extra["romaji"] = romaji

        entries.append({
            "id": f"{deck_id}_{note['id']}",
            "deckId": deck_id,
            "level": level,
            "cardType": "vocab",
            "category": category,
            "expression": kanji_reading or front,
            "reading": front,
            "meaning": back,
            "extra": extra or None,
            "sortOrder": sort_order,
        })
    return entries


def _convert_vocab_pass(apkg_path: Path, deck_id: str, level: str) -> list[dict[str, Any]]:
    """Pass_JLPT_N3_Vocabulary.apkg uses a different note model than the
    JTalk N5/N4 vocab decks (kanji/kana/pos/english/ex1.../ex2... fields
    instead of Front/Back/Kanji-Reading/Romaji) — same "as-is" import,
    different field names.
    """
    models, note_deck, notes = _read_collection(apkg_path)
    entries = []
    for sort_order, note in enumerate(notes):
        model = models[str(note["mid"])]
        fields = note["flds"].split(_FIELD_SEP)
        idx = {
            name: _field_index(model, name)
            for name in ("kanji", "kana", "pos", "english", "ex1_ja", "ex1_en", "ex2_ja", "ex2_en", "note")
        }

        def field(name: str) -> str:
            i = idx[name]
            return fields[i].strip() if i is not None and i < len(fields) else ""

        kanji = _clean_html(field("kanji"))
        kana = _clean_html(field("kana"))
        english = _clean_html(field("english"))
        pos = _clean_html(field("pos"))
        note_field = _clean_html(field("note"))

        if not kanji and not kana:
            continue

        deck_name = note_deck.get(note["id"], "")
        category = deck_name.split("::")[-1] if "::" in deck_name else None

        examples = []
        for ja_name, en_name in (("ex1_ja", "ex1_en"), ("ex2_ja", "ex2_en")):
            ja = _clean_html(field(ja_name))
            en = _clean_html(field(en_name))
            if ja or en:
                examples.append(" — ".join(p for p in (ja, en) if p))

        extra = {}
        if pos:
            extra["pos"] = pos
        if examples:
            extra["examples"] = "\n".join(examples)
        if note_field:
            extra["note"] = note_field

        entries.append({
            "id": f"{deck_id}_{note['id']}",
            "deckId": deck_id,
            "level": level,
            "cardType": "vocab",
            "category": category,
            "expression": kanji or kana,
            "reading": kana,
            "meaning": english,
            "extra": extra or None,
            "sortOrder": sort_order,
        })
    return entries


_N3_TOPICS: list[tuple[str, list[str]]] = [
    ("Family and People", ["father", "mother", "brother", "sister", "child", "wife", "husband",
        "parent", "relative", "grandmother", "grandfather", "friend", "guest", "stranger", "adult",
        "elderly", "baby", "infant", "youth", "couple", "spouse", "sibling", "acquaintance", "neighbor",
        "self", "human being", "individual", "personality", "character (of a person)"]),
    ("Body and Health", ["body", "hand", "arm", "leg", "head", "eye", "ear", "nose", "mouth", "skin",
        "blood", "bone", "illness", "disease", "medicine", "hospital", "doctor", "pain", "injury",
        "health", "cure", "treatment", "symptom", "fever", "wound", "surgery", "nurse", "physical",
        "muscle", "stomach", "chest", "throat", "fatigue", "tired"]),
    ("Emotions and Feelings", ["feel", "feeling", "emotion", "happy", "sad", "angry", "afraid", "fear",
        "surprise", "worry", "anxious", "relief", "disappoint", "satisfaction", "love", "hate", "shame",
        "pleasure", "joy", "regret", "nervous", "embarrass", "lonely", "jealous", "sympathy", "comfort",
        "impression", "excitement", "calm", "stress", "confidence", "hope", "despair", "grateful",
        "gratitude", "irritat"]),
    ("Time and Calendar", ["day", "week", "month", "year", "hour", "minute", "second", "morning",
        "evening", "night", "afternoon", "season", "date", "period", "century", "era", "schedule",
        "deadline", "moment", "recent", "future", "past", "present time", "calendar", "anniversary"]),
    ("House and Daily Life", ["house", "home", "room", "furniture", "kitchen", "bath", "clean", "wash",
        "sleep", "wake", "daily life", "living", "apartment", "door", "window", "wall", "floor", "roof",
        "garden", "neighborhood", "household", "chore"]),
    ("Food and Drink", ["food", "eat", "drink", "cook", "meal", "rice", "vegetable", "fruit", "meat",
        "fish", "taste", "flavor", "restaurant", "recipe", "ingredient", "dish", "menu", "snack",
        "sweet", "bitter", "sour", "spicy", "boil", "fry", "bake", "seasoning", "diet", "nutrition",
        "kitchen", "chopstick", "beverage", "alcohol", "tea", "sweets", "dessert"]),
    ("Nature and Weather", ["rain", "snow", "wind", "sun", "moon", "star", "sky", "mountain", "river",
        "sea", "ocean", "tree", "plant", "flower", "weather", "nature", "forest", "cloud", "storm",
        "typhoon", "thunder", "temperature", "climate", "leaf", "root", "soil", "earth", "lake", "island",
        "wave", "shore", "rock", "stone", "ice", "fog"]),
    ("Animals", ["animal", "dog", "cat", "bird", "insect", "cow", "horse", "pig", "chicken", "wild",
        "pet", "creature", "tail", "wing", "nest", "livestock"]),
    ("Clothing and Appearance", ["clothes", "clothing", "wear", "dress", "shirt", "shoes", "fashion",
        "appearance", "beauty", "makeup", "outfit", "costume", "fabric", "cloth", "button", "pocket"]),
    ("Places and Directions", ["place", "town", "city", "village", "area", "direction", "north", "south",
        "east", "west", "left", "right", "near", "far", "building", "park", "location", "surroundings",
        "region", "district", "spot", "site", "space (physical)"]),
    ("Travel and Transportation", ["travel", "trip", "train", "car", "bus", "airplane", "airport",
        "station", "road", "street", "map", "ticket", "journey", "abroad", "tourist", "luggage",
        "passport", "traffic", "vehicle", "drive", "ride", "bicycle", "highway", "route", "destination",
        "boat", "ship", "taxi", "passenger", "departure", "arrival"]),
    ("Education and School", ["school", "study", "student", "teacher", "class", "lesson", "exam",
        "university", "education", "learn", "homework", "subject", "grade", "graduate", "textbook",
        "knowledge", "training", "skill", "course", "test", "professor", "academic"]),
    ("Work and Business", ["work", "job", "company", "business", "office", "employee", "employer",
        "salary", "meeting", "contract", "customer", "manager", "career", "industry", "factory",
        "product", "manufactur", "colleague", "boss", "staff", "resign", "hire", "promotion",
        "organization", "department", "task", "duty", "profession", "workplace", "labor"]),
    ("Money and Shopping", ["money", "price", "cost", "pay", "buy", "sell", "shop", "store", "purchase",
        "expense", "discount", "sale", "budget", "cash", "bank", "loan", "debt", "fee", "fund", "wealth",
        "poor", "rich", "economy", "economic", "tax", "profit", "value (monetary)", "coin", "bill (money)",
        "savings", "invest"]),
    ("Communication and Media", ["talk", "speak", "say", "conversation", "language", "word", "letter",
        "news", "newspaper", "television", "phone", "message", "information", "internet", "email",
        "signal", "announce", "communicat", "report", "broadcast", "publish", "magazine", "article",
        "advertisement", "explain", "translate", "discussion", "opinion", "rumor", "greeting"]),
    ("Technology and Science", ["machine", "computer", "technology", "science", "electric", "energy",
        "experiment", "research", "device", "equipment", "engine", "system", "invent",
        "material (substance)", "chemical", "digital", "battery", "software", "data"]),
    ("Society and Culture", ["society", "culture", "custom", "tradition", "government", "law", "politics",
        "nation", "election", "citizen", "religion", "war", "peace", "history", "community", "public",
        "social", "rule", "right (legal)", "crime", "police", "court", "justice", "ceremony", "festival",
        "generation", "population"]),
    ("Quantity and Measurement", ["amount", "quantity", "number", "size", "length", "weight", "shape",
        "circle", "square", "measure", "degree", "level", "percent", "ratio", "speed", "distance",
        "volume", "capacity", "scale", "range", "limit", "average", "total", "half", "double", "triple"]),
    ("Abstract Concepts and Ideas", ["method", "effect", "result", "success", "failure", "attitude",
        "influence", "common sense", "expectation", "purpose", "reason", "cause", "possibility",
        "necessity", "importance", "situation", "condition", "state (condition)", "matter", "fact",
        "truth", "meaning", "idea", "thought", "opinion", "concept", "principle", "standard",
        "quality", "tendency", "trend", "prospect", "achievement", "accomplishment", "decision",
        "judgement", "plan", "goal", "comparison", "contrast", "connection", "relationship",
        "structure", "process", "activity", "chance", "opportunity", "ability", "circumstance",
        "complaint", "aid", "support", "attack", "construction", "guidance", "resident", "inhabitant",
        "population", "mankind", "humanity", "committee", "vote", "president", "employment"]),
]

_N3_POS_BUCKETS: list[tuple[str, Any]] = [
    ("Verbs (transitive)", lambda pos: "vt" in pos.split(",") and "vi" not in pos.split(",")),
    ("Verbs (intransitive)", lambda pos: "vi" in pos.split(",") and "vt" not in pos.split(",")),
    ("Suru Verbs", lambda pos: "vs" in pos.split(",")),
    ("な Adjectives", lambda pos: "adj-na" in pos.split(",")),
    ("い Adjectives", lambda pos: "adj-i" in pos.split(",")),
    ("Adverbs", lambda pos: any(p.startswith("adv") for p in pos.split(","))),
    ("Expressions", lambda pos: "exp" in pos.split(",")),
    ("Conjunctions", lambda pos: "conj" in pos.split(",")),
]

_N3_CATEGORY_ORDER = (
    [name for name, _ in _N3_TOPICS] + [name for name, _ in _N3_POS_BUCKETS] + ["General Vocabulary"]
)
_N3_NON_WORD_RE = re.compile(r"[^a-z ]")
_N3_TARGET_SECTION_SIZE = 16


def _n3_match_topic(meaning: str) -> str | None:
    normalized = _N3_NON_WORD_RE.sub(" ", meaning.lower())
    for name, keywords in _N3_TOPICS:
        for keyword in keywords:
            if keyword in normalized:
                return name
    return None


def _n3_match_pos(pos: str) -> str | None:
    if not pos:
        return None
    for name, matches in _N3_POS_BUCKETS:
        if matches(pos):
            return name
    return None


def _n3_balanced_chunks(items: list[dict[str, Any]], target: int) -> list[list[dict[str, Any]]]:
    if not items:
        return []
    num_chunks = max(1, round(len(items) / target))
    base, remainder = divmod(len(items), num_chunks)
    sizes = [base + (1 if i < remainder else 0) for i in range(num_chunks)]
    chunks = []
    i = 0
    for size in sizes:
        chunks.append(items[i : i + size])
        i += size
    return chunks


def _n3_roman(n: int) -> str:
    vals = [(10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    out = []
    for value, symbol in vals:
        while n >= value:
            out.append(symbol)
            n -= value
    return "".join(out)


def _categorize_n3_vocab(entries: list[dict[str, Any]]) -> None:
    """Pass_JLPT_N3_Vocabulary.apkg is a single flat deck with no
    "Week X.Y Topic" subdecks like the N5/N4 JTalk decks have, so every
    entry above comes out with category=None. This buckets each entry by
    topic keyword match against its English meaning, falling back to a
    part-of-speech bucket (verbs/adjectives/adverbs/etc.) and finally a
    catch-all, then interleaves the buckets round-robin into "Week X.Y
    Name" sections (6 per week) the same way the vocabulary screen already
    groups and orders N5/N4 cards. Every entry keeps its id/expression/
    reading/meaning/extra — only category and sortOrder are assigned.
    """
    buckets: dict[str, list[dict[str, Any]]] = {name: [] for name in _N3_CATEGORY_ORDER}
    for entry in entries:
        topic = _n3_match_topic(entry["meaning"])
        if topic:
            buckets[topic].append(entry)
            continue
        pos = (entry.get("extra") or {}).get("pos", "") or ""
        bucket = _n3_match_pos(pos) or "General Vocabulary"
        buckets[bucket].append(entry)

    chunked = {name: _n3_balanced_chunks(buckets[name], _N3_TARGET_SECTION_SIZE) for name in _N3_CATEGORY_ORDER}
    max_rounds = max(len(c) for c in chunked.values())

    sections: list[tuple[str, list[dict[str, Any]]]] = []
    for round_index in range(max_rounds):
        for name in _N3_CATEGORY_ORDER:
            chunks = chunked[name]
            if round_index < len(chunks):
                sections.append((name, chunks[round_index]))

    seen_counts: dict[str, int] = {}
    sort_order = 0
    for section_index, (name, items) in enumerate(sections):
        week = section_index // 6 + 1
        position = section_index % 6 + 1
        seen_counts[name] = seen_counts.get(name, 0) + 1
        suffix = "" if seen_counts[name] == 1 else f" {_n3_roman(seen_counts[name])}"
        label = f"Week {week}.{position} {name}{suffix}"
        for item in items:
            item["category"] = label
            item["sortOrder"] = sort_order
            sort_order += 1


def _convert_kanji(apkg_path: Path, deck_id: str, level: str) -> list[dict[str, Any]]:
    models, _note_deck, notes = _read_collection(apkg_path)
    entries = []
    for sort_order, note in enumerate(notes):
        model = models[str(note["mid"])]
        fields = note["flds"].split(_FIELD_SEP)
        idx = {
            name: _field_index(model, name)
            for name in ("kanji", "ja_on", "ja_kun", "meaning", "examples", "note")
        }

        def field(name: str) -> str:
            i = idx[name]
            return fields[i].strip() if i is not None and i < len(fields) else ""

        kanji = _clean_html(field("kanji"))
        onyomi = _clean_html(field("ja_on"))
        kunyomi = _clean_html(field("ja_kun"))
        meaning = _clean_html(field("meaning"))
        examples = _clean_html(field("examples"))
        note_field = _clean_html(field("note"))

        if not kanji:
            continue

        reading = " / ".join(r for r in (onyomi, kunyomi) if r)

        extra = {}
        if onyomi:
            extra["onyomi"] = onyomi
        if kunyomi:
            extra["kunyomi"] = kunyomi
        if examples:
            extra["examples"] = examples
        if note_field:
            extra["note"] = note_field

        entries.append({
            "id": f"{deck_id}_{note['id']}",
            "deckId": deck_id,
            "level": level,
            "cardType": "kanji",
            "category": None,
            "expression": kanji,
            "reading": reading,
            "meaning": meaning,
            "extra": extra or None,
            "sortOrder": sort_order,
        })
    return entries


def main() -> None:
    vocab_entries: list[dict[str, Any]] = []
    kanji_entries: list[dict[str, Any]] = []

    for deck in _DECKS:
        apkg_path = ROOT / deck["file"]
        if not apkg_path.exists():
            raise FileNotFoundError(f"Expected deck file at {apkg_path}")

        print(f"Reading {deck['file']}...")
        if deck["cardType"] == "vocab":
            entries = (
                _convert_vocab_pass(apkg_path, deck["deckId"], deck["level"])
                if deck.get("vocabFormat") == "pass"
                else _convert_vocab(apkg_path, deck["deckId"], deck["level"])
            )
            if deck["deckId"] == "jlpt_n3_vocab":
                _categorize_n3_vocab(entries)
            vocab_entries.extend(entries)
        else:
            entries = _convert_kanji(apkg_path, deck["deckId"], deck["level"])
            kanji_entries.extend(entries)
        print(f"  {len(entries)} notes")

    OUTPUT_VOCAB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_VOCAB_PATH.open("w", encoding="utf-8") as f:
        json.dump(vocab_entries, f, ensure_ascii=False, separators=(",", ":"))
    with OUTPUT_KANJI_PATH.open("w", encoding="utf-8") as f:
        json.dump(kanji_entries, f, ensure_ascii=False, separators=(",", ":"))

    print(f"Wrote {OUTPUT_VOCAB_PATH} ({len(vocab_entries)} entries)")
    print(f"Wrote {OUTPUT_KANJI_PATH} ({len(kanji_entries)} entries)")


if __name__ == "__main__":
    main()
