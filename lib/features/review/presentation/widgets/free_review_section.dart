import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/deck_card_progress_table.dart';
import '../../../../core/database/tables/deck_cards_table.dart';
import '../../../decks/application/deck_data_providers.dart';
import '../../../decks/application/deck_review_actions_provider.dart';
import '../../../decks/application/deck_review_provider.dart';
import 'deck_flash_card.dart';

const _kLevels = ['N5', 'N4', 'N3'];
const _kCounts = [10, 20, 30, 50, 100];
const _kTypeLabels = {DeckCardType.kanji: 'Kanji', DeckCardType.vocab: 'Vocab'};

/// A standalone practice session, separate from the daily-gated Decks
/// queue in [deckReviewQueueProvider]: the user picks how many cards, which
/// JLPT level tags, and kanji/vocab/both, and the session pulls a random
/// sample straight from [deckCardsProvider] — ignoring due dates and the
/// [newDeckCardsPerDayProvider] daily allowance entirely. Grading still
/// updates the same SRS progress rows, so it isn't wasted study time; it
/// just isn't gated by "today's" limits.
class FreeReviewSection extends ConsumerStatefulWidget {
  const FreeReviewSection({super.key});

  @override
  ConsumerState<FreeReviewSection> createState() => _FreeReviewSectionState();
}

class _FreeReviewSectionState extends ConsumerState<FreeReviewSection> {
  final Set<String> _selectedLevels = {..._kLevels};
  final Set<DeckCardType> _selectedTypes = {..._kTypeLabels.keys};
  int? _count = 20;
  ReviewDirection _direction = ReviewDirection.jpToEn;

  List<DeckCard>? _session;
  int _index = 0;
  bool _isFlipped = false;

  List<DeckCard> _eligible(List<DeckCard> allCards) {
    return allCards
        .where((c) => _selectedLevels.contains(c.level) && _selectedTypes.contains(c.cardType))
        .toList();
  }

  void _start(List<DeckCard> allCards) {
    final eligible = _eligible(allCards);
    if (eligible.isEmpty) return;
    final shuffled = List.of(eligible)..shuffle(Random());
    setState(() {
      _session = shuffled.take(_count ?? shuffled.length).toList();
      _index = 0;
      _isFlipped = false;
    });
  }

  void _endSession() {
    setState(() {
      _session = null;
      _index = 0;
      _isFlipped = false;
    });
  }

  void _grade(DeckCard card, {required bool correct}) {
    ref.read(deckReviewActionsProvider.notifier).gradeReview(card.id, _direction, correct: correct);
    setState(() {
      _index++;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCards = ref.watch(deckCardsProvider).value ?? const [];
    final session = _session;

    if (session != null) {
      return _buildSession(context, session);
    }
    return _buildConfig(context, allCards);
  }

  Widget _buildConfig(BuildContext context, List<DeckCard> allCards) {
    final colorScheme = Theme.of(context).colorScheme;
    final eligibleCount = _eligible(allCards).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice any number of words, whenever you want — '
            "it's separate from the daily review queue.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          SegmentedButton<ReviewDirection>(
            segments: const [
              ButtonSegment(value: ReviewDirection.jpToEn, label: Text('JP → EN')),
              ButtonSegment(value: ReviewDirection.enToJp, label: Text('EN → JP')),
            ],
            showSelectedIcon: false,
            selected: {_direction},
            onSelectionChanged: (selection) => setState(() => _direction = selection.first),
          ),
          const SizedBox(height: 20),
          Text('How many words', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final count in _kCounts)
                ChoiceChip(
                  label: Text('$count'),
                  selected: _count == count,
                  onSelected: (_) => setState(() => _count = count),
                  selectedColor: colorScheme.secondary.withValues(alpha: 0.16),
                  side: BorderSide.none,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ChoiceChip(
                label: const Text('All'),
                selected: _count == null,
                onSelected: (_) => setState(() => _count = null),
                selectedColor: colorScheme.secondary.withValues(alpha: 0.16),
                side: BorderSide.none,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Levels', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in _kLevels)
                FilterChip(
                  label: Text(level),
                  selected: _selectedLevels.contains(level),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selectedLevels.add(level);
                    } else {
                      _selectedLevels.remove(level);
                    }
                  }),
                  selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                  side: BorderSide.none,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _kTypeLabels.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _selectedTypes.contains(entry.key),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _selectedTypes.add(entry.key);
                    } else {
                      _selectedTypes.remove(entry.key);
                    }
                  }),
                  selectedColor: colorScheme.secondary.withValues(alpha: 0.16),
                  side: BorderSide.none,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _selectedLevels.isEmpty
                ? 'Select at least one level'
                : _selectedTypes.isEmpty
                ? 'Select at least one type'
                : '$eligibleCount word${eligibleCount == 1 ? '' : 's'} match this selection',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: eligibleCount == 0 ? null : () => _start(allCards),
              child: const Text('Start free review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSession(BuildContext context, List<DeckCard> session) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_index >= session.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text('Session complete', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Reviewed ${session.length} word${session.length == 1 ? '' : 's'}.'),
              const SizedBox(height: 20),
              FilledButton(onPressed: _endSession, child: const Text('Start another session')),
            ],
          ),
        ),
      );
    }

    final card = session[_index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_index + 1} of ${session.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              TextButton(onPressed: _endSession, child: const Text('End session')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _isFlipped = !_isFlipped),
                child: DeckFlashCard(
                  reviewCard: DeckReviewCard(card: card, direction: _direction),
                  isFlipped: _isFlipped,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isFlipped)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _grade(card, correct: false),
                    child: const Text('Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _grade(card, correct: true),
                    child: const Text('Good'),
                  ),
                ),
              ],
            )
          else
            Text(
              'Tap the card to reveal',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
        ],
      ),
    );
  }
}
