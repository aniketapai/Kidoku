import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/deck_card_progress_table.dart';
import '../../../core/srs/srs_config.dart';
import '../../decks/application/deck_review_actions_provider.dart';
import '../../decks/application/deck_review_provider.dart';
import 'widgets/deck_flash_card.dart';
import 'widgets/free_review_section.dart';
import 'widgets/my_words_section.dart';
import 'widgets/review_empty_state.dart';
import 'widgets/review_grade_buttons.dart';
import 'widgets/review_progress_bar.dart';
import 'widgets/review_segmented_control.dart';

enum _ReviewMode { myWords, decks, freeReview }

/// One graded deck card, remembered so a "revert" can put it — and the SRS
/// state it changed — back exactly as it was. Popped in LIFO order, so
/// reverting repeatedly walks back through the whole session to the first
/// word graded.
class _DeckGradeRecord {
  const _DeckGradeRecord({
    required this.cardId,
    required this.direction,
    required this.undo,
  });

  final String cardId;
  final ReviewDirection direction;
  final DeckGradeUndo undo;
}

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _ReviewMode _mode = _ReviewMode.myWords;

  int _deckStage = 0;
  String? _currentDeckCardKey;
  final List<_DeckGradeRecord> _deckHistory = [];

  Future<void> _gradeDeck(DeckReviewCard card, {required bool correct}) async {
    final undo = await ref
        .read(deckReviewActionsProvider.notifier)
        .gradeReview(card.card.id, card.direction, correct: correct);
    if (!mounted) return;
    setState(() {
      _deckHistory.add(
        _DeckGradeRecord(cardId: card.card.id, direction: card.direction, undo: undo),
      );
      _deckStage = 0;
    });
  }

  Future<void> _revertDeck() async {
    if (_deckHistory.isEmpty) return;
    final record = _deckHistory.removeLast();
    await ref
        .read(deckReviewActionsProvider.notifier)
        .undoGradeReview(
          record.cardId,
          record.direction,
          record.undo.previousProgress,
          record.undo.reviewEventId,
        );
    if (!mounted) return;
    setState(() => _deckStage = 0);
  }

  Future<void> _showNewCardsPerDayDialog(BuildContext context, int current) async {
    final value = await showDialog<int>(
      context: context,
      builder: (context) => _NewCardsPerDayDialog(initialValue: current),
    );
    if (value != null) {
      ref.read(deckReviewActionsProvider.notifier).setNewDeckCardsPerDay(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: ReviewSegmentedControl<_ReviewMode>(
              segments: const [
                ReviewSegment(
                  value: _ReviewMode.myWords,
                  label: 'My Words',
                  icon: Icons.bookmark_rounded,
                ),
                ReviewSegment(
                  value: _ReviewMode.decks,
                  label: 'Decks',
                  icon: Icons.style_rounded,
                ),
                ReviewSegment(
                  value: _ReviewMode.freeReview,
                  label: 'Free Review',
                  icon: Icons.shuffle_rounded,
                ),
              ],
              selected: _mode,
              onChanged: (value) => setState(() => _mode = value),
            ),
          ),
          Expanded(
            child: switch (_mode) {
              _ReviewMode.myWords => const MyWordsSection(),
              _ReviewMode.decks => _buildDecks(context),
              _ReviewMode.freeReview => const FreeReviewSection(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDecks(BuildContext context) {
    final direction = ref.watch(reviewDirectionProvider);
    final filter = ref.watch(deckReviewFilterProvider);
    final filterNotifier = ref.read(deckReviewFilterProvider.notifier);
    final queue = ref.watch(deckReviewQueueProvider);
    final newCardsPerDay =
        ref.watch(newDeckCardsPerDayProvider).value ?? SrsConfig.kNewDeckCardsPerDayPerDirection;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: ReviewSegmentedControl<ReviewDirection>(
            segments: const [
              ReviewSegment(value: ReviewDirection.jpToEn, label: 'JP → EN'),
              ReviewSegment(value: ReviewDirection.enToJp, label: 'EN → JP'),
            ],
            selected: direction,
            onChanged: (value) => ref.read(reviewDirectionProvider.notifier).state = value,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showNewCardsPerDayDialog(context, newCardsPerDay),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'New words/day: $newCardsPerDay',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final level in const ['All', 'N5', 'N4', 'N3'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(level),
                    selected: filter.level == level,
                    onSelected: (_) => filterNotifier.update((s) => s.copyWith(level: level)),
                    selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                    side: BorderSide.none,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              for (final entry in const {
                'Kanji': DeckReviewPool.kanji,
                'Vocab': DeckReviewPool.vocab,
                'Kanji Vocab': DeckReviewPool.kanjiVocab,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.key),
                    selected: filter.pool == entry.value,
                    onSelected: (_) => filterNotifier.update((s) => s.copyWith(pool: entry.value)),
                    selectedColor: colorScheme.secondary.withValues(alpha: 0.16),
                    side: BorderSide.none,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? const ReviewEmptyState(
                  icon: Icons.style_rounded,
                  title: 'All caught up',
                  message: 'Nothing due for review right now.',
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
                  child: Builder(
                    builder: (context) {
                      final card = queue.first;
                      final key = '${card.card.id}|${card.direction.name}';
                      if (_currentDeckCardKey != key) {
                        _currentDeckCardKey = key;
                        _deckStage = 0;
                      }
                      final maxStage = DeckFlashCard.maxStage(card);

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ReviewCountBadge(count: queue.length, label: 'due'),
                              ReviewIconButton(
                                icon: Icons.undo_rounded,
                                tooltip: 'Revert last grade',
                                onPressed: _deckHistory.isEmpty ? null : _revertDeck,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (_deckStage < maxStage) setState(() => _deckStage++);
                                },
                                child: DeckFlashCard(reviewCard: card, revealStage: _deckStage),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ReviewGradeArea(
                            revealed: _deckStage >= maxStage,
                            onAgain: () => _gradeDeck(card, correct: false),
                            onGood: () => _gradeDeck(card, correct: true),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Lets the user override how many new deck cards are introduced per
/// direction per day (see [SrsConfig.kNewDeckCardsPerDayPerDirection] /
/// [newDeckCardsPerDayProvider]) instead of the fixed default.
class _NewCardsPerDayDialog extends StatefulWidget {
  const _NewCardsPerDayDialog({required this.initialValue});

  final int initialValue;

  @override
  State<_NewCardsPerDayDialog> createState() => _NewCardsPerDayDialogState();
}

class _NewCardsPerDayDialogState extends State<_NewCardsPerDayDialog> {
  late int _value = widget.initialValue;

  static const _min = 5;
  static const _max = 100;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New words per day'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How many new words to introduce per direction each day.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text('$_value', style: Theme.of(context).textTheme.headlineMedium),
          Slider(
            value: _value.toDouble(),
            min: _min.toDouble(),
            max: _max.toDouble(),
            divisions: (_max - _min) ~/ 5,
            label: '$_value',
            onChanged: (v) => setState(() => _value = (v / 5).round() * 5),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_value), child: const Text('Save')),
      ],
    );
  }
}
