import '../domain/reel.dart';

/// Which sentence/token in a [Reel] is current at a given playback
/// position — the karaoke-highlighting lookup the transcript panel redraws
/// against on every position tick from the YouTube player.
class ReelSyncPosition {
  const ReelSyncPosition({required this.sentenceIndex, required this.tokenIndex});

  /// Before the first sentence starts, or after the last one ends.
  static const none = ReelSyncPosition(sentenceIndex: -1, tokenIndex: -1);

  final int sentenceIndex;
  final int tokenIndex;

  bool get isNone => sentenceIndex < 0;
}

/// Linear scan is deliberate here over a binary search: reels top out at a
/// few dozen sentences, and this runs at the player's ~10Hz position-update
/// rate, so the constant-factor simplicity isn't worth the bookkeeping.
ReelSyncPosition locateReelPosition(Reel reel, int positionMs) {
  for (var si = 0; si < reel.sentences.length; si++) {
    final sentence = reel.sentences[si];
    if (positionMs < sentence.startMs) break;
    if (positionMs < sentence.endMs) {
      for (var ti = 0; ti < sentence.tokens.length; ti++) {
        if (positionMs < sentence.tokens[ti].endMs) {
          return ReelSyncPosition(sentenceIndex: si, tokenIndex: ti);
        }
      }
      return ReelSyncPosition(sentenceIndex: si, tokenIndex: sentence.tokens.length - 1);
    }
  }
  return ReelSyncPosition.none;
}
