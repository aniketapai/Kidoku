import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/database/tables/deck_card_progress_table.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../decks/application/deck_review_provider.dart';
import 'flash_card_shell.dart';

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
    final accentColor = JlptColors.forLevel(card.level);

    final extra = card.extra != null
        ? (jsonDecode(card.extra!) as Map<String, dynamic>)
        : const <String, dynamic>{};

    return FlashCardShell(
      cardKey: '${card.id}|${reviewCard.direction.name}',
      accentColor: accentColor,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              primary,
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (showKana)
              RevealFadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    card.reading,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (showFinal)
              RevealFadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        width: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        translation,
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      for (final entry in extra.entries) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${entry.value}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
