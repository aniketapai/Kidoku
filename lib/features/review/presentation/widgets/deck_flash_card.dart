import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/database/tables/deck_card_progress_table.dart';
import '../../../decks/application/deck_review_provider.dart';

class DeckFlashCard extends StatelessWidget {
  const DeckFlashCard({super.key, required this.reviewCard, required this.isFlipped});

  final DeckReviewCard reviewCard;
  final bool isFlipped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final card = reviewCard.card;
    final jpToEn = reviewCard.direction == ReviewDirection.jpToEn;
    final front = jpToEn ? card.expression : card.meaning;
    final frontSubtitle = jpToEn && card.reading.isNotEmpty ? card.reading : null;
    final back = jpToEn ? card.meaning : card.expression;
    final backSubtitle = !jpToEn && card.reading.isNotEmpty ? card.reading : null;

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
          if (frontSubtitle != null)
            Text(frontSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                )),
          Text(front, style: textTheme.headlineMedium, textAlign: TextAlign.center),
          if (isFlipped) ...[
            const SizedBox(height: 20),
            Divider(color: colorScheme.surfaceContainerHighest),
            const SizedBox(height: 12),
            if (backSubtitle != null)
              Text(backSubtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  )),
            Text(back, style: textTheme.bodyLarge, textAlign: TextAlign.center),
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
