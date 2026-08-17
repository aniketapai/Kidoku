class ChatCoachResult {
  const ChatCoachResult({
    required this.japanese,
    required this.reading,
    required this.explanation,
    this.context = '',
  });

  factory ChatCoachResult.fromJson(Map<String, dynamic> json) {
    return ChatCoachResult(
      japanese: json['japanese'] as String? ?? '',
      reading: json['reading'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      context: json['context'] as String? ?? '',
    );
  }

  /// The suggested Japanese phrasing — a reply, a translation, or whatever
  /// text the learner asked for, ready to copy into their own chat.
  final String japanese;

  /// Hiragana/katakana reading of [japanese].
  final String reading;

  /// Short note on why this phrasing fits the register, or feedback on a
  /// draft the learner wrote themselves.
  final String explanation;

  /// Plain-English gist of a message the learner pasted from someone else,
  /// shown before [japanese] so they know what they're replying to. Empty
  /// when the learner isn't asking about someone else's message.
  final String context;
}
