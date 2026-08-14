import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables/deck_card_progress_table.dart';
import '../../../core/database/tables/deck_cards_table.dart';
import '../../../core/srs/srs_config.dart';
import '../../decks/application/deck_review_actions_provider.dart';
import '../../decks/application/deck_review_provider.dart';
import 'widgets/deck_flash_card.dart';
import 'widgets/free_review_section.dart';
import 'widgets/my_words_section.dart';

enum _ReviewMode { myWords, decks, freeReview }

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _ReviewMode _mode = _ReviewMode.myWords;

  bool _isDeckFlipped = false;
  String? _currentDeckCardKey;

  void _gradeDeck(DeckReviewCard card, {required bool correct}) {
    ref
        .read(deckReviewActionsProvider.notifier)
        .gradeReview(card.card.id, card.direction, correct: correct);
    setState(() => _isDeckFlipped = false);
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: SegmentedButton<_ReviewMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              segments: const [
                ButtonSegment(
                  value: _ReviewMode.myWords,
                  label: Text('My Words', softWrap: false, overflow: TextOverflow.ellipsis),
                ),
                ButtonSegment(
                  value: _ReviewMode.decks,
                  label: Text('Decks', softWrap: false, overflow: TextOverflow.ellipsis),
                ),
                ButtonSegment(
                  value: _ReviewMode.freeReview,
                  label: Text('Free Review', softWrap: false, overflow: TextOverflow.ellipsis),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) => setState(() => _mode = selection.first),
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
          child: SegmentedButton<ReviewDirection>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ReviewDirection.jpToEn, label: Text('JP → EN')),
              ButtonSegment(value: ReviewDirection.enToJp, label: Text('EN → JP')),
            ],
            selected: {direction},
            onSelectionChanged: (selection) =>
                ref.read(reviewDirectionProvider.notifier).state = selection.first,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'New words/day: $newCardsPerDay',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showNewCardsPerDayDialog(context, newCardsPerDay),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.tune_rounded, size: 18, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
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
                'All': null,
                'Kanji': DeckCardType.kanji,
                'Vocab': DeckCardType.vocab,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.key),
                    selected: filter.type == entry.value,
                    onSelected: (_) => filterNotifier.update(
                      (s) => entry.value == null
                          ? s.copyWith(clearType: true)
                          : s.copyWith(type: entry.value),
                    ),
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
              ? const _EmptyState()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
                  child: Builder(
                    builder: (context) {
                      final card = queue.first;
                      final key = '${card.card.id}|${card.direction.name}';
                      if (_currentDeckCardKey != key) {
                        _currentDeckCardKey = key;
                        _isDeckFlipped = false;
                      }

                      return Column(
                        children: [
                          Text(
                            '${queue.length} due',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () => setState(() => _isDeckFlipped = !_isDeckFlipped),
                                child: DeckFlashCard(reviewCard: card, isFlipped: _isDeckFlipped),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_isDeckFlipped)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _gradeDeck(card, correct: false),
                                    child: const Text('Again'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _gradeDeck(card, correct: true),
                                    child: const Text('Good'),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Tap the card to reveal',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('All caught up', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Nothing due for review right now.', textAlign: TextAlign.center),
          ],
        ),
      ),
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
