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
import 'review_empty_state.dart';
import 'review_grade_buttons.dart';
import 'review_progress_bar.dart';
import 'review_segmented_control.dart';

/// Snapshot of session state taken right before a grade, so "revert" can
/// restore the local queue exactly as well as undo the SRS write the grade
/// made — see [_FreeReviewSectionState._grade] / [_revert].
class _FreeReviewHistoryEntry {
  const _FreeReviewHistoryEntry({
    required this.queueBefore,
    required this.gradedCountBefore,
    required this.totalEverBefore,
    required this.cardId,
    required this.direction,
    required this.undo,
  });

  final List<DeckCard> queueBefore;
  final int gradedCountBefore;
  final int totalEverBefore;
  final String cardId;
  final ReviewDirection direction;
  final DeckGradeUndo undo;
}

enum _FreeReviewType { vocab, kanji, kanjiVocab }

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
  String _weekLevelFilter = 'N5';

  final Set<String> _selectedKanjiLevels = {..._kLevels};

  String _kanjiVocabLevel = 'N5';
  final Set<String> _selectedKanjiVocabChunkKeys = {};

  List<DeckCard>? _queue;
  int _uniqueCount = 0;
  int _totalEver = 0;
  int _gradedCount = 0;
  int _stage = 0;
  final List<_FreeReviewHistoryEntry> _history = [];

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
          (c) =>
              c.cardType == DeckCardType.kanji &&
              _selectedKanjiLevels.contains(c.level),
        )
        .toList();
  }

  List<DeckCard> _kanjiVocabEligible(List<KanjiVocabChunk> chunks) {
    final cards = <DeckCard>[];
    for (final chunk in chunks) {
      if (_selectedKanjiVocabChunkKeys.contains(chunk.key)) {
        cards.addAll(chunk.cards);
      }
    }
    return cards;
  }

  void _start(List<DeckCard> pool) {
    if (pool.isEmpty) return;
    final shuffled = List.of(pool)..shuffle(Random());
    // Only kanji review is count-limited — vocab and kanji-vocab pools are
    // deck-based, so the whole selection is always studied.
    final limit = _type == _FreeReviewType.kanji
        ? (_count ?? shuffled.length)
        : shuffled.length;
    final selected = shuffled.take(limit).toList();
    setState(() {
      _queue = selected;
      _uniqueCount = selected.length;
      _totalEver = selected.length;
      _gradedCount = 0;
      _stage = 0;
      _history.clear();
    });
  }

  void _endSession() {
    setState(() {
      _queue = null;
      _stage = 0;
      _history.clear();
    });
  }

  Future<void> _grade(DeckCard card, {required bool correct}) async {
    final queueBefore = List.of(_queue!);
    final gradedCountBefore = _gradedCount;
    final totalEverBefore = _totalEver;
    final undo = await ref
        .read(deckReviewActionsProvider.notifier)
        .gradeReview(card.id, _direction, correct: correct);
    if (!mounted) return;
    setState(() {
      _history.add(
        _FreeReviewHistoryEntry(
          queueBefore: queueBefore,
          gradedCountBefore: gradedCountBefore,
          totalEverBefore: totalEverBefore,
          cardId: card.id,
          direction: _direction,
          undo: undo,
        ),
      );
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

  /// Undoes the most recent grade — restores the local queue to exactly
  /// how it looked beforehand and reverts the SRS write that grade made.
  /// Calling it repeatedly walks back through the whole session.
  Future<void> _revert() async {
    if (_history.isEmpty) return;
    final entry = _history.removeLast();
    await ref
        .read(deckReviewActionsProvider.notifier)
        .undoGradeReview(
          entry.cardId,
          entry.direction,
          entry.undo.previousProgress,
          entry.undo.reviewEventId,
        );
    if (!mounted) return;
    setState(() {
      _queue = entry.queueBefore;
      _gradedCount = entry.gradedCountBefore;
      _totalEver = entry.totalEverBefore;
      _stage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allCards = ref.watch(deckCardsProvider).value ?? const [];
    final weekGroups = ref.watch(vocabWeekGroupsProvider);
    final kanjiVocabChunks = ref.watch(
      kanjiVocabChunksProvider(_kanjiVocabLevel),
    );
    final queue = _queue;

    if (queue != null) {
      return _buildSession(context, queue);
    }
    return _buildConfig(context, allCards, weekGroups, kanjiVocabChunks);
  }

  Widget _buildConfig(
    BuildContext context,
    List<DeckCard> allCards,
    List<VocabWeekGroup> weekGroups,
    List<KanjiVocabChunk> kanjiVocabChunks,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final pool = switch (_type) {
      _FreeReviewType.vocab => _vocabEligible(weekGroups),
      _FreeReviewType.kanji => _kanjiEligible(allCards),
      _FreeReviewType.kanjiVocab => _kanjiVocabEligible(kanjiVocabChunks),
    };
    final eligibleCount = pool.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice any number of words, whenever you want — '
            "it's separate from the daily review queue.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          ReviewSegmentedControl<_FreeReviewType>(
            segments: const [
              ReviewSegment(value: _FreeReviewType.vocab, label: 'Vocab'),
              ReviewSegment(value: _FreeReviewType.kanji, label: 'Kanji'),
              ReviewSegment(
                value: _FreeReviewType.kanjiVocab,
                label: 'Kanji Vocab',
              ),
            ],
            selected: _type,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: 20),
          ReviewSegmentedControl<ReviewDirection>(
            segments: const [
              ReviewSegment(value: ReviewDirection.jpToEn, label: 'JP → EN'),
              ReviewSegment(value: ReviewDirection.enToJp, label: 'EN → JP'),
            ],
            selected: _direction,
            onChanged: (value) => setState(() => _direction = value),
          ),
          const SizedBox(height: 20),
          // Vocab and Kanji Vocab pools are deck-based — the picker below
          // already determines how many words are in scope, so a count
          // selector only makes sense for kanji, which is picked by level.
          if (_type == _FreeReviewType.kanji) ...[
            Text(
              'How many kanji',
              style: Theme.of(context).textTheme.labelLarge,
            ),
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
                    selectedColor: colorScheme.secondary.withValues(
                      alpha: 0.16,
                    ),
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
          ],
          switch (_type) {
            _FreeReviewType.vocab => _buildVocabPicker(context, weekGroups),
            _FreeReviewType.kanji => _buildKanjiPicker(context),
            _FreeReviewType.kanjiVocab => _buildKanjiVocabPicker(
              context,
              kanjiVocabChunks,
            ),
          },
          const SizedBox(height: 24),
          Text(
            eligibleCount == 0
                ? switch (_type) {
                    _FreeReviewType.vocab => 'Select at least one week',
                    _FreeReviewType.kanji => 'Select at least one level',
                    _FreeReviewType.kanjiVocab => 'Select at least one set',
                  }
                : '$eligibleCount word${eligibleCount == 1 ? '' : 's'} match this selection',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: eligibleCount == 0 ? null : () => _start(pool),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Start free review'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabPicker(
    BuildContext context,
    List<VocabWeekGroup> weekGroups,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _weekSearch.trim().toLowerCase();
    final levelGroups = weekGroups.where((g) => g.level == _weekLevelFilter);
    final filtered = query.isEmpty
        ? levelGroups.toList()
        : levelGroups
              .where((g) => g.label.toLowerCase().contains(query))
              .toList();
    final selectedGroups = weekGroups
        .where((g) => _selectedWeekKeys.contains(g.key))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Level', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in _kLevels)
              ChoiceChip(
                label: Text(level),
                selected: _weekLevelFilter == level,
                onSelected: (_) => setState(() => _weekLevelFilter = level),
                selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                side: BorderSide.none,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Weeks', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        ClearableSearchField(
          hintText: 'Search weeks — e.g. "Week 3" or "money"…',
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
                  onDeleted: () =>
                      setState(() => _selectedWeekKeys.remove(group.key)),
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
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.surfaceContainerHighest,
                    ),
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
                        title: Text(
                          group.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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

  Widget _buildKanjiVocabPicker(
    BuildContext context,
    List<KanjiVocabChunk> chunks,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Level', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in _kLevels)
              ChoiceChip(
                label: Text(level),
                selected: _kanjiVocabLevel == level,
                onSelected: (_) => setState(() => _kanjiVocabLevel = level),
                selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                side: BorderSide.none,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Sets', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.surfaceContainerHighest),
            ),
            child: chunks.isEmpty
                ? Center(
                    child: Text(
                      'No sets for this level',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: chunks.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    itemBuilder: (context, index) {
                      final chunk = chunks[index];
                      final selected = _selectedKanjiVocabChunkKeys.contains(
                        chunk.key,
                      );
                      return CheckboxListTile(
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: selected,
                        onChanged: (_) => setState(() {
                          if (selected) {
                            _selectedKanjiVocabChunkKeys.remove(chunk.key);
                          } else {
                            _selectedKanjiVocabChunkKeys.add(chunk.key);
                          }
                        }),
                        title: Text(
                          chunk.label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${chunk.cards.length} words',
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

  Widget _buildSession(BuildContext context, List<DeckCard> queue) {
    if (queue.isEmpty) {
      return ReviewEmptyState(
        icon: Icons.check_circle_rounded,
        title: 'Session complete',
        message: 'Reviewed $_uniqueCount word${_uniqueCount == 1 ? '' : 's'}.',
        action: FilledButton(
          onPressed: _endSession,
          child: const Text('Start another session'),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ReviewProgressBar(
                  current: _gradedCount + 1,
                  total: _totalEver,
                ),
              ),
              const SizedBox(width: 8),
              ReviewIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Revert last grade',
                onPressed: _history.isEmpty ? null : _revert,
              ),
              const SizedBox(width: 8),
              ReviewIconButton(
                icon: Icons.close_rounded,
                tooltip: 'End session',
                onPressed: _endSession,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (_stage < maxStage) setState(() => _stage++);
                },
                child: DeckFlashCard(
                  reviewCard: reviewCard,
                  revealStage: _stage,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ReviewGradeArea(
            revealed: _stage >= maxStage,
            onAgain: () => _grade(card, correct: false),
            onGood: () => _grade(card, correct: true),
          ),
        ],
      ),
    );
  }
}
