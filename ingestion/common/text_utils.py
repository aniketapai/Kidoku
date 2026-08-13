"""Shared text helpers for the ingestion pipeline."""

import re

_KATAKANA_START = ord("ァ")  # ァ
_KATAKANA_END = ord("ヶ")  # ヶ
_KATAKANA_TO_HIRAGANA_OFFSET = ord("ァ") - ord("ぁ")

_SENTENCE_BOUNDARY = re.compile(r"([。！？])")


def katakana_to_hiragana(text: str) -> str:
    """Converts katakana in `text` to hiragana; leaves other characters as-is.

    Katakana and hiragana occupy parallel Unicode ranges offset by a fixed
    amount, except for the katakana-only long vowel mark (ー), which has no
    hiragana equivalent and is left unchanged.
    """
    out = []
    for ch in text:
        code = ord(ch)
        if _KATAKANA_START <= code <= _KATAKANA_END:
            out.append(chr(code - _KATAKANA_TO_HIRAGANA_OFFSET))
        else:
            out.append(ch)
    return "".join(out)


def split_sentences(text: str) -> list[str]:
    """Splits `text` into sentences on 。！？, keeping the punctuation attached
    to the preceding sentence, and treating blank lines as boundaries too.
    """
    sentences: list[str] = []
    for paragraph in text.split("\n"):
        paragraph = paragraph.strip()
        if not paragraph:
            continue
        parts = _SENTENCE_BOUNDARY.split(paragraph)
        buf = ""
        for part in parts:
            buf += part
            if _SENTENCE_BOUNDARY.fullmatch(part):
                sentences.append(buf)
                buf = ""
        if buf.strip():
            sentences.append(buf)
    return sentences


def strip_quotes(text: str) -> str:
    """Removes literal double quotes.

    The app's DictionaryEntries.meanings decoder (meanings_codec.dart) is a
    regex over `"([^"]+)"` rather than a full JSON parse, so a gloss
    containing a literal `"` would corrupt the decoded list.
    """
    return text.replace('"', "'")
