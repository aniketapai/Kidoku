final RegExp _kanjiRegex = RegExp(r'[一-龯]');

/// Every CJK ideograph in [text], in order, duplicates included — callers
/// that need distinct characters can wrap the result in a `Set`.
Iterable<String> extractKanji(String text) => _kanjiRegex.allMatches(text).map((m) => m[0]!);
