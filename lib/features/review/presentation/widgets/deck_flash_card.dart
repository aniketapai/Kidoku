import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/database/tables/deck_card_progress_table.dart';
import '../../../decks/application/deck_review_provider.dart';

/// Progressive reveal, ordered by [ReviewDirection]: JP → EN shows kanji,
/// then (on tap) the kana reading, then (on tap) the English meaning; EN →
/// JP runs the same three stops in reverse — English, then kana, then
/// kanji. [revealStage] is how many taps have happened so far (0 = only the
/// first stop is shown); use [maxStage] to know when a card is fully
/// revealed.
class DeckFlashCard extends StatelessWidget {
  const DeckFlashCard({super.key, required this.reviewCard, required this.revealStage});

  final DeckReviewCard reviewCard;
  final int revealStage;

  static int maxStage(DeckReviewCard reviewCard) =>
      reviewCard.card.reading.isNotEmpty ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final card = reviewCard.card;
    final jpToEn = reviewCard.direction == ReviewDirection.jpToEn;
    final primary = jpToEn ? card.expression : card.meaning;
    final translation = jpToEn ? card.meaning : card.expression;
    final hasKana = card.reading.isNotEmpty;
    final kanaStage = hasKana ? 1 : 0;
    final finalStage = maxStage(reviewCard);
    final showKana = hasKana && revealStage >= kanaStage;
    final showFinal = revealStage >= finalStage;

    final extra = card.extra != null
        ? (jsonDecode(card.extra!) as Map<String, dynamic>)
        : const <String, dynamic>{};

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.surfaceContainerHighest),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(primary, style: textTheme.headlineMedium, textAlign: TextAlign.center),
          if (showKana) ...[
            const SizedBox(height: 12),
            Text(card.reading,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center),
          ],
          if (showFinal) ...[
            const SizedBox(height: 20),
            Divider(color: colorScheme.surfaceContainerHighest),
            const SizedBox(height: 12),
            Text(translation, style: textTheme.bodyLarge, textAlign: TextAlign.center),
            for (final entry in extra.entries) ...[
              const SizedBox(height: 8),
              Text('${entry.value}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center),
            ],
          ],
        ],
      ),
    );
  }
}
