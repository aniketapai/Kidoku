import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/jlpt_level_chip.dart';
import 'deck_card_detail_sheet.dart';

class DeckCardTile extends StatelessWidget {
  const DeckCardTile({super.key, required this.card});

  final DeckCard card;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showDeckCardDetailSheet(context, card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.surfaceContainerHighest),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          card.expression,
                          style: textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card.reading.isNotEmpty && card.reading != card.expression) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            card.reading,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(card.meaning,
                      style: textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            JlptLevelChip(level: card.level),
          ],
        ),
      ),
    );
  }
}
