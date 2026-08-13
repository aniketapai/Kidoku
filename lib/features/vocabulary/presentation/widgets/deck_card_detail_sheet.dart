import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/jlpt_level_chip.dart';

/// Human-readable labels for the raw Anki field names kept in
/// [DeckCard.extra] — see ingestion/convert_apkg.py for what ends up there.
const _kExtraLabels = {
  'romaji': 'Romaji',
  'onyomi': 'On\'yomi',
  'kunyomi': 'Kun\'yomi',
  'examples': 'Examples',
  'note': 'Note',
};

Future<void> showDeckCardDetailSheet(BuildContext context, DeckCard card) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => DeckCardDetailSheet(card: card),
  );
}

class DeckCardDetailSheet extends StatelessWidget {
  const DeckCardDetailSheet({super.key, required this.card});

  final DeckCard card;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final extra = card.extra != null
        ? (jsonDecode(card.extra!) as Map<String, dynamic>)
        : const <String, dynamic>{};

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (card.reading.isNotEmpty)
                          Text(card.reading,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              )),
                        Text(card.expression, style: textTheme.headlineSmall),
                      ],
                    ),
                  ),
                  JlptLevelChip(level: card.level),
                ],
              ),
              if (card.category != null) ...[
                const SizedBox(height: 4),
                Text(card.category!,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
              ],
              const SizedBox(height: 12),
              Text(card.meaning, style: textTheme.bodyLarge),
              for (final entry in extra.entries) ...[
                const SizedBox(height: 16),
                Text(_kExtraLabels[entry.key] ?? entry.key,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Text('${entry.value}', style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
