import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/meanings_codec.dart';
import '../../../../core/database/tables/user_words_table.dart';
import '../../../../core/widgets/jlpt_level_chip.dart';
import '../../../reader/presentation/widgets/lookup_bottom_sheet.dart';
import '../../application/my_words_provider.dart';

/// A resurfaced "Again" card doesn't come back immediately — it's
/// reinserted somewhere between 3 and 7 cards later in the queue, mirroring
/// Free Review's session-local requeue (see free_review_section.dart).
const _kAgainMinGap = 3;
const _kAgainJitter = 5;

/// My Words: a plain browsable list of every saved/known word — no SRS due
/// dates. Split into two tabs: Saved (not known yet) and Known. Saved words
/// can be practiced with a self-paced flip-card review, but grading never
/// changes a word's saved/known status — that only happens explicitly, via
/// the Mark Known / Save buttons in the lookup sheet opened by tapping a
/// word (see [showLookupBottomSheet]).
class MyWordsSection extends ConsumerStatefulWidget {
  const MyWordsSection({super.key});

  @override
  ConsumerState<MyWordsSection> createState() => _MyWordsSectionState();
}

class _MyWordsSectionState extends ConsumerState<MyWordsSection> {
  List<MyWordEntry>? _reviewQueue;
  int _uniqueCount = 0;
  int _totalEver = 0;
  int _gradedCount = 0;
  bool _isFlipped = false;

  void _startReview(List<MyWordEntry> saved) {
    if (saved.isEmpty) return;
    final shuffled = List.of(saved)..shuffle(Random());
    setState(() {
      _reviewQueue = shuffled;
      _uniqueCount = shuffled.length;
      _totalEver = shuffled.length;
      _gradedCount = 0;
      _isFlipped = false;
    });
  }

  void _endReview() {
    setState(() {
      _reviewQueue = null;
      _isFlipped = false;
    });
  }

  /// Session-local only — never writes to the word's saved/known status.
  /// "Again" requeues the card later in this session; "Good" just drops it
  /// from the queue. Either way the word stays exactly as saved/known as
  /// it was before the review started.
  void _grade({required bool correct}) {
    setState(() {
      final queue = _reviewQueue!;
      final card = queue.removeAt(0);
      _gradedCount++;
      if (!correct) {
        final offset = _kAgainMinGap + Random().nextInt(_kAgainJitter);
        queue.insert(min(offset, queue.length), card);
        _totalEver++;
      }
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(myWordsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return wordsAsync.when(
      data: (words) {
        final known = words.where((w) => w.userWord.status == WordStatus.known).toList();
        final saved = words.where((w) => w.userWord.status != WordStatus.known).toList();

        if (_reviewQueue != null) {
          return _buildReviewSession(context);
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
                indicatorColor: colorScheme.primary,
                tabs: [
                  Tab(text: 'Saved (${saved.length})'),
                  Tab(text: 'Known (${known.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    saved.isEmpty
                        ? const _EmptyMessage(
                            'No saved words yet. Save words you don\'t know from the '
                            'dictionary lookup sheet in the reader.',
                          )
                        : _SavedTab(words: saved, onStartReview: () => _startReview(saved)),
                    known.isEmpty
                        ? const _EmptyMessage(
                            'No known words yet. Mark words you already know from the '
                            'dictionary lookup sheet.',
                          )
                        : _WordList(words: known),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Failed to load words: $error')),
    );
  }

  Widget _buildReviewSession(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final queue = _reviewQueue!;

    if (queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text('Review complete', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Reviewed $_uniqueCount word${_uniqueCount == 1 ? '' : 's'}.'),
              const SizedBox(height: 20),
              FilledButton(onPressed: _endReview, child: const Text('Back to My Words')),
            ],
          ),
        ),
      );
    }

    final card = queue.first;

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
              TextButton(onPressed: _endReview, child: const Text('End review')),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _isFlipped = !_isFlipped),
                child: _ReviewFlashCard(entry: card, isFlipped: _isFlipped),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isFlipped)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _grade(correct: false),
                    child: const Text('Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _grade(correct: true),
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

class _SavedTab extends StatelessWidget {
  const _SavedTab({required this.words, required this.onStartReview});

  final List<MyWordEntry> words;
  final VoidCallback onStartReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${words.length} saved', style: Theme.of(context).textTheme.labelLarge),
              FilledButton.icon(
                onPressed: onStartReview,
                icon: const Icon(Icons.style_rounded, size: 18),
                label: const Text('Review'),
              ),
            ],
          ),
        ),
        Expanded(child: _WordList(words: words)),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

class _WordList extends StatelessWidget {
  const _WordList({required this.words});

  final List<MyWordEntry> words;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      itemCount: words.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _WordTile(word: words[index]),
    );
  }
}

/// Tapping a word opens the dictionary lookup sheet — the same sheet used
/// from the reader — which shows full word info and already has the Mark
/// Known / Save buttons that move a word between Saved and Known.
class _WordTile extends StatelessWidget {
  const _WordTile({required this.word});

  final MyWordEntry word;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entry = word.entry;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showLookupBottomSheet(context, word.userWord.dictionaryForm),
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
                          word.userWord.dictionaryForm,
                          style: textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry != null && entry.reading.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            entry.reading,
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
                  Text(
                    entry != null ? decodeMeanings(entry.meanings) : 'No dictionary entry.',
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (entry != null) ...[
              const SizedBox(width: 8),
              JlptLevelChip(level: entry.jlptLevel),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewFlashCard extends StatelessWidget {
  const _ReviewFlashCard({required this.entry, required this.isFlipped});

  final MyWordEntry entry;
  final bool isFlipped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dictEntry = entry.entry;

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
          if (dictEntry != null) JlptLevelChip(level: dictEntry.jlptLevel),
          const SizedBox(height: 12),
          Text(
            dictEntry?.reading ?? '',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(entry.userWord.dictionaryForm, style: textTheme.headlineMedium),
          if (isFlipped) ...[
            const SizedBox(height: 20),
            Divider(color: colorScheme.surfaceContainerHighest),
            const SizedBox(height: 12),
            Text(
              dictEntry?.partOfSpeech ?? '',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dictEntry != null ? decodeMeanings(dictEntry.meanings) : 'No dictionary entry.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
