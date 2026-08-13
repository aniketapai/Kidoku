/// Simplified graduated-interval SRS curve (steps.md sections 8, 14).
/// [UserWord.srsInterval] stores an index into this
/// list rather than a raw day count. This stands in for true SM-2 — which
/// needs a per-word ease factor the current schema doesn't carry — and is
/// the "custom" curve the spec leaves as an open config knob. Swap in real
/// SM-2 by adding an easeFactor column and replacing the grading logic in
/// AppDatabase.gradeReview.
abstract final class SrsConfig {
  static const intervalsDays = [1, 3, 7, 14, 30, 90];

  /// Caps how many not-yet-studied [DeckCard]s (see deck_cards_table.dart)
  /// enter a direction's review rotation per day — the JLPT decks are
  /// 800-1500 notes each, so introducing everything at once on day one
  /// would dump a wall of due cards on a new user, unlike the Reader's
  /// "save word" flow which queues a single word immediately.
  static const kNewDeckCardsPerDayPerDirection = 20;
}
