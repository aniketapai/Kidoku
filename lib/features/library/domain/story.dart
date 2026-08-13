/// A single tokenized unit of story text. Punctuation and untranslatable
/// proper nouns have no [dictionaryForm] and render as plain, non-tappable
/// text; every other token points at a [DictionaryEntries.dictionaryForm]
/// row so tapping it can reuse the same lookup sheet the Dictionary tab
/// uses.
class StoryToken {
  const StoryToken({required this.surface, this.reading, this.dictionaryForm});

  factory StoryToken.fromJson(Map<String, dynamic> json) => StoryToken(
    surface: json['s'] as String,
    reading: json['r'] as String?,
    dictionaryForm: json['d'] as String?,
  );

  final String surface;

  /// Furigana shown above [surface], or null when [surface] is pure
  /// kana/punctuation and needs no reading gloss.
  final String? reading;

  final String? dictionaryForm;

  bool get isTappable => dictionaryForm != null;
}

/// One sentence's worth of tokens plus its English gloss — the reader's
/// unit of display, so a translation always sits directly under the
/// Japanese it belongs to instead of one gloss per whole paragraph.
class StorySentence {
  const StorySentence({required this.tokens, required this.en});

  factory StorySentence.fromJson(Map<String, dynamic> json) => StorySentence(
    tokens: (json['tokens'] as List<dynamic>)
        .map((token) => StoryToken.fromJson(token as Map<String, dynamic>))
        .toList(),
    en: json['en'] as String,
  );

  final List<StoryToken> tokens;
  final String en;
}

class StoryPage {
  const StoryPage({required this.sentences});

  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
    sentences: (json['sentences'] as List<dynamic>)
        .map((sentence) => StorySentence.fromJson(sentence as Map<String, dynamic>))
        .toList(),
  );

  final List<StorySentence> sentences;
}

class Story {
  const Story({
    required this.id,
    required this.level,
    required this.title,
    required this.titleReading,
    required this.titleEn,
    required this.pages,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'] as String,
    level: json['level'] as String,
    title: json['title'] as String,
    titleReading: json['titleReading'] as String?,
    titleEn: json['titleEn'] as String,
    pages: (json['pages'] as List<dynamic>)
        .map((page) => StoryPage.fromJson(page as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final String level;
  final String title;
  final String? titleReading;
  final String titleEn;
  final List<StoryPage> pages;
}

/// Lightweight listing entry from assets/stories/manifest.json — enough to
/// render the Library grid without loading every story's full token tree.
class StoryMeta {
  const StoryMeta({
    required this.id,
    required this.level,
    required this.title,
    required this.titleEn,
    required this.file,
    required this.pageCount,
  });

  factory StoryMeta.fromJson(Map<String, dynamic> json) => StoryMeta(
    id: json['id'] as String,
    level: json['level'] as String,
    title: json['title'] as String,
    titleEn: json['titleEn'] as String,
    file: json['file'] as String,
    pageCount: json['pageCount'] as int,
  );

  final String id;
  final String level;
  final String title;
  final String titleEn;
  final String file;
  final int pageCount;
}
