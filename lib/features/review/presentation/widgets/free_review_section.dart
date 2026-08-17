import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/deck_card_progress_table.dart';
import '../../../../core/database/tables/deck_cards_table.dart';
import '../../../../core/widgets/clearable_search_field.dart';
import '../../../decks/application/deck_data_providers.dart';
import '../../../decks/application/deck_review_actions_provider.dart';
import '../../../decks/application/deck_review_provider.dart';
import 'deck_flash_card.dart';

enum _FreeReviewType { vocab, kanji }

const _kLevels = ['N5', 'N4', 'N3'];
const _kCounts = [10, 20, 30, 50, 100];

/// A resurfaced "Again" card doesn't come back immediately (that would just
/// be re-showing the same card twice in a row) — it's reinserted somewhere
/// between 3 and 7 cards later in the queue, so the session still flows
/// while the miss isn't forgotten either.
const _kAgainMinGap = 3;
const _kAgainJitter = 5;

/// A standalone practice session, separate from the daily-gated Decks
/// queue in [deckReviewQueueProvider]: the user builds a pool either by
/// searching for and combining specific vocab week decks (see
/// [vocabWeekGroupsProvider]) or, for kanji (which has no week grouping),
/// by JLPT level — then a random sample is drawn from that pool, ignoring
/// due dates and the [newDeckCardsPerDayProvider] daily allowance entirely.
/// Grading still updates the same SRS progress rows, so it isn't wasted
/// study time; it just isn't gated by "today's" limits. Within a session,
/// grading a card "Again" requeues it later (see [_kAgainMinGap]) instead
/// of dropping it — the session's total count grows as misses happen.
class FreeReviewSection extends ConsumerStatefulWidget {
  const FreeReviewSection({super.key});

  @override
  ConsumerState<FreeReviewSection> createState() => _FreeReviewSectionState();
}

class _FreeReviewSectionState extends ConsumerState<FreeReviewSection> {
  _FreeReviewType _type = _FreeReviewType.vocab;
  ReviewDirection _direction = ReviewDirection.jpToEn;
  int? _count = 20;

  final Set<String> _selectedWeekKeys = {};
  String _weekSearch = '';

  final Set<String> _selectedKanjiLevels = {..._kLevels};

  List<DeckCard>? _queue;
  int _uniqueCount = 0;
  int _totalEver = 0;
  int _gradedCount = 0;
  int _stage = 0;

  List<DeckCard> _vocabEligible(List<VocabWeekGroup> weekGroups) {
    final cards = <DeckCard>[];
    for (final group in weekGroups) {
      if (_selectedWeekKeys.contains(group.key)) cards.addAll(group.cards);
    }
    return cards;
  }

  List<DeckCard> _kanjiEligible(List<DeckCard> allCards) {
    return allCards
        .where(
          (c) => c.cardType == DeckCardType.kanji && _selectedKanjiLevels.contains(c.level),
        )
        .toList();
  }

  void _start(List<DeckCard> pool) {
    if (pool.isEmpty) return;
    final shuffled = List.of(pool)..shuffle(Random());
    final selected = shuffled.take(_count ?? shuffled.length).toList();
    setState(() {
      _queue = selected;
      _uniqueCount = selected.length;
      _totalEver = selected.length;
      _gradedCount = 0;
      _stage = 0;
    });
  }

  void _endSession() {
    setState(() {
      _queue = null;
      _stage = 0;
    });
  }

  void _grade(DeckCard card, {required bool correct}) {
    ref.read(deckReviewActionsProvider.notifier).gradeReview(card.id, _direction, correct: correct);
    setState(() {
      final queue = _queue!;
      queue.removeAt(0);
      _gradedCount++;
      if (!correct) {
        final offset = _kAgainMinGap + Random().nextInt(_kAgainJitter);
        queue.insert(min(offset, queue.length), card);
        _totalEver++;
      }
      _stage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCards = ref.watch(deckCardsProvider).value ?? const [];
    final weekGroups = ref.watch(vocabWeekGroupsProvider);
    final queue = _queue;

    if (queue != null) {
      return _buildSession(context, queue);
    }
    return _buildConfig(context, allCards, weekGroups);
  }

  Widget _buildConfig(
    BuildContext context,
    List<DeckCard> allCards,
    List<VocabWeekGroup> weekGroups,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final pool = _type == _FreeReviewType.vocab
        ? _vocabEligible(weekGroups)
        : _kanjiEligible(allCards);
    final eligibleCount = pool.length;

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
          SegmentedButton<_FreeReviewType>(
            segments: const [
              ButtonSegment(value: _FreeReviewType.vocab, label: Text('Vocab')),
              ButtonSegment(value: _FreeReviewType.kanji, label: Text('Kanji')),
            ],
            showSelectedIcon: false,
            selected: {_type},
            onSelectionChanged: (selection) => setState(() => _type = selection.first),
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
          const SizedBox(height: 20),
          if (_type == _FreeReviewType.vocab)
            _buildVocabPicker(context, weekGroups)
          else
            _buildKanjiPicker(context),
          const SizedBox(height: 24),
          Text(
            eligibleCount == 0
                ? (_type == _FreeReviewType.vocab
                      ? 'Select at least one week'
                      : 'Select at least one level')
                : '$eligibleCount word${eligibleCount == 1 ? '' : 's'} match this selection',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: eligibleCount == 0 ? null : () => _start(pool),
              child: const Text('Start free review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabPicker(BuildContext context, List<VocabWeekGroup> weekGroups) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _weekSearch.trim().toLowerCase();
    final filtered = query.isEmpty
        ? weekGroups
        : weekGroups.where((g) => g.label.toLowerCase().contains(query)).toList();
    final selectedGroups = weekGroups.where((g) => _selectedWeekKeys.contains(g.key)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weeks', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in _kLevels)
              FilterChip(
                label: Text(level),
                selected:
                    weekGroups.any((g) => g.level == level) &&
                    weekGroups
                        .where((g) => g.level == level)
                        .every((g) => _selectedWeekKeys.contains(g.key)),
                onSelected: (selected) => setState(() {
                  final keysForLevel = weekGroups
                      .where((g) => g.level == level)
                      .map((g) => g.key);
                  if (selected) {
                    _selectedWeekKeys.addAll(keysForLevel);
                  } else {
                    _selectedWeekKeys.removeAll(keysForLevel);
                  }
                }),
                selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                side: BorderSide.none,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClearableSearchField(
          hintText: 'Search weeks — e.g. "N4 Week 3" or "money"…',
          onChanged: (value) => setState(() => _weekSearch = value),
        ),
        if (selectedGroups.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final group in selectedGroups)
                InputChip(
                  label: Text(group.label),
                  onDeleted: () => setState(() => _selectedWeekKeys.remove(group.key)),
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.surfaceContainerHighest),
            ),
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No weeks match your search',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: colorScheme.surfaceContainerHighest),
                    itemBuilder: (context, index) {
                      final group = filtered[index];
                      final selected = _selectedWeekKeys.contains(group.key);
                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selected,
                        onChanged: (_) => setState(() {
                          if (selected) {
                            _selectedWeekKeys.remove(group.key);
                          } else {
                            _selectedWeekKeys.add(group.key);
                          }
                        }),
                        title: Text(group.label, style: Theme.of(context).textTheme.bodyMedium),
                        subtitle: Text(
                          '${group.cards.length} words',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanjiPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Levels', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in _kLevels)
              FilterChip(
                label: Text(level),
                selected: _selectedKanjiLevels.contains(level),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _selectedKanjiLevels.add(level);
                  } else {
                    _selectedKanjiLevels.remove(level);
                  }
                }),
                selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                side: BorderSide.none,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSession(BuildContext context, List<DeckCard> queue) {
    final colorScheme = Theme.of(context).colorScheme;

    if (queue.isEmpty) {
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
              Text('Reviewed $_uniqueCount word${_uniqueCount == 1 ? '' : 's'}.'),
              const SizedBox(height: 20),
              FilledButton(onPressed: _endSession, child: const Text('Start another session')),
            ],
          ),
        ),
      );
    }

    final card = queue.first;
    final reviewCard = DeckReviewCard(card: card, direction: _direction);
    final maxStage = DeckFlashCard.maxStage(reviewCard);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_gradedCount + 1} of $_totalEver',
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
                onTap: () {
                  if (_stage < maxStage) setState(() => _stage++);
                },
                child: DeckFlashCard(reviewCard: reviewCard, revealStage: _stage),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_stage >= maxStage)
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
