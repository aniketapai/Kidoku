/// A single tokenized, timed unit of a reel's transcript — same {s, r, d}
/// shape as [StoryToken] in lib/features/library/domain/story.dart, plus
/// the timing window the ingestion pipeline (ingestion/reels/align_reel.py)
/// assigned it. Punctuation has no [dictionaryForm] and renders as plain,
/// non-tappable text; every other token points at a
/// [DictionaryEntries.dictionaryForm] row, same lookup sheet the stories
/// reader and Dictionary tab already use.
class ReelToken {
  const ReelToken({
    required this.surface,
    this.reading,
    this.dictionaryForm,
    required this.startMs,
    required this.endMs,
  });

  factory ReelToken.fromJson(Map<String, dynamic> json) => ReelToken(
    surface: json['s'] as String,
    reading: json['r'] as String?,
    dictionaryForm: json['d'] as String?,
    startMs: json['startMs'] as int,
    endMs: json['endMs'] as int,
  );

  final String surface;

  /// Furigana shown above [surface], or null when [surface] is pure
  /// kana/punctuation and needs no reading gloss.
  final String? reading;

  final String? dictionaryForm;

  /// Milliseconds into the video, on YouTube's own playback clock, this
  /// token is spoken — `[startMs, endMs)`.
  final int startMs;
  final int endMs;

  bool get isTappable => dictionaryForm != null;
}

/// One sentence's worth of tokens plus its timing window and optional
/// English gloss — the transcript panel's unit of display and highlighting.
class ReelSentence {
  const ReelSentence({
    required this.tokens,
    required this.startMs,
    required this.endMs,
    this.en,
  });

  factory ReelSentence.fromJson(Map<String, dynamic> json) => ReelSentence(
    tokens: (json['tokens'] as List<dynamic>)
        .map((token) => ReelToken.fromJson(token as Map<String, dynamic>))
        .toList(),
    startMs: json['startMs'] as int,
    endMs: json['endMs'] as int,
    en: json['en'] as String?,
  );

  final List<ReelToken> tokens;
  final int startMs;
  final int endMs;
  final String? en;
}

class Reel {
  const Reel({
    required this.id,
    required this.videoId,
    required this.level,
    required this.title,
    required this.titleEn,
    required this.durationMs,
    required this.sentences,
  });

  factory Reel.fromJson(Map<String, dynamic> json) => Reel(
    id: json['id'] as String,
    videoId: json['videoId'] as String,
    level: json['level'] as String,
    title: json['title'] as String,
    titleEn: json['titleEn'] as String,
    durationMs: json['durationMs'] as int,
    sentences: (json['sentences'] as List<dynamic>)
        .map((sentence) => ReelSentence.fromJson(sentence as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final String videoId;
  final String level;
  final String title;
  final String titleEn;
  final int durationMs;
  final List<ReelSentence> sentences;
}

/// Lightweight listing entry from assets/reels/manifest.json — enough to
/// build the vertical feed's page list without loading every reel's full
/// transcript up front.
class ReelMeta {
  const ReelMeta({
    required this.id,
    required this.videoId,
    required this.levels,
    required this.title,
    required this.titleEn,
    required this.file,
    required this.durationMs,
    required this.creator,
    this.cropBottom = 0.0,
  });

  /// Accepts either the current `"levels": ["N5", "N4"]` array or the
  /// older single-value `"level": "N5"` field, so manifest entries written
  /// before multi-level support don't need a migration pass.
  factory ReelMeta.fromJson(Map<String, dynamic> json) => ReelMeta(
    id: json['id'] as String,
    videoId: json['videoId'] as String,
    levels: json['levels'] != null
        ? (json['levels'] as List<dynamic>).cast<String>()
        : [json['level'] as String],
    title: json['title'] as String,
    titleEn: json['titleEn'] as String,
    file: json['file'] as String,
    durationMs: json['durationMs'] as int,
    creator: json['creator'] as String,
    cropBottom: (json['cropBottom'] as num?)?.toDouble() ?? 0.0,
  );

  final String id;
  final String videoId;

  /// JLPT levels this video is tagged with — most creators' content sits
  /// squarely in one level, but some (e.g. mixed-difficulty channels)
  /// legitimately span two, so this is a list rather than a single value.
  final List<String> levels;
  final String title;
  final String titleEn;
  final String file;
  final int durationMs;

  /// The YouTube channel/content creator this video belongs to — the tag
  /// the video-library browse screen groups and filters by. One creator's
  /// videos are treated as one "playlist" for this purpose (see
  /// ingestion/reels/README.md).
  final String creator;

  /// Fraction of the source video's height, measured from the bottom, to
  /// crop out of view — for source videos that have hardcoded captions or
  /// a watermark baked into the picture (common for creators who repost
  /// vertical short-form content as standard 16:9 uploads). 0 means no
  /// crop. Applied in ReelPlayerPage via Align/ClipRect (a true crop, not
  /// a zoom — the rest of the frame stays at its original scale). Tuned
  /// per-video during ingestion (see ingestion/reels/align_reel.py's
  /// --crop-bottom) since not every reel has this problem, and the band
  /// size varies when it does.
  final double cropBottom;
}
