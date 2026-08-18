import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/deck_cards_table.dart';
import '../../../../core/text/kanji_utils.dart';
import '../../../../core/widgets/jlpt_level_chip.dart';
import '../../../reader/presentation/widgets/lookup_bottom_sheet.dart';
import 'deck_card_detail_sheet.dart';

class DeckCardTile extends StatelessWidget {
  const DeckCardTile({super.key, required this.card});

  final DeckCard card;

  /// Vocab words spelled with at least one kanji get the same dictionary
  /// lookup sheet the Search tab uses (definition, JLPT tag, and — via its
  /// own kanji chips — a tap-through to stroke order) instead of the plain
  /// deck-card sheet, since that's strictly more info for the same word.
  /// Kanji-tab cards are the character itself, not a dictionary word, so
  /// they keep the on'yomi/kun'yomi detail sheet.
  bool get _showsAsDictionaryWord =>
      card.cardType == DeckCardType.vocab && extractKanji(card.expression).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showsAsDictionaryWord
          ? showLookupBottomSheet(context, card.expression)
          : showDeckCardDetailSheet(context, card),
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
