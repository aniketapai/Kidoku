import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/meanings_codec.dart';
import '../../../../core/database/tables/user_words_table.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/jlpt_level_chip.dart';
import '../../../reader/application/user_word_actions_provider.dart';
import '../../../reader/presentation/widgets/lookup_bottom_sheet.dart';
import '../../application/my_words_provider.dart';
import 'flash_card_shell.dart';
import 'review_empty_state.dart';
import 'review_grade_buttons.dart';
import 'review_progress_bar.dart';

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
/// Snapshot of the review queue taken right before a grade, so "revert"
/// can restore it exactly — see [_MyWordsSectionState._grade] / [_revert].
class _MyWordsHistoryEntry {
  const _MyWordsHistoryEntry({
    required this.queueBefore,
    required this.gradedCountBefore,
    required this.totalEverBefore,
  });

  final List<MyWordEntry> queueBefore;
  final int gradedCountBefore;
  final int totalEverBefore;
}

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
  int _stage = 0;
  final List<_MyWordsHistoryEntry> _history = [];

  void _startReview(List<MyWordEntry> saved) {
    if (saved.isEmpty) return;
    final shuffled = List.of(saved)..shuffle(Random());
    setState(() {
      _reviewQueue = shuffled;
      _uniqueCount = shuffled.length;
      _totalEver = shuffled.length;
      _gradedCount = 0;
      _stage = 0;
      _history.clear();
    });
  }

  void _endReview() {
    setState(() {
      _reviewQueue = null;
      _stage = 0;
      _history.clear();
    });
  }

  /// Session-local only — never writes to the word's saved/known status.
  /// "Again" requeues the card later in this session; "Good" just drops it
  /// from the queue. Either way the word stays exactly as saved/known as
  /// it was before the review started.
  void _grade({required bool correct}) {
    setState(() {
      final queue = _reviewQueue!;
      _history.add(
        _MyWordsHistoryEntry(
          queueBefore: List.of(queue),
          gradedCountBefore: _gradedCount,
          totalEverBefore: _totalEver,
        ),
      );
      final card = queue.removeAt(0);
      _gradedCount++;
      if (!correct) {
        final offset = _kAgainMinGap + Random().nextInt(_kAgainJitter);
        queue.insert(min(offset, queue.length), card);
        _totalEver++;
      }
      _stage = 0;
    });
  }

  /// Undoes the most recent grade, restoring the queue exactly as it was
  /// beforehand. Calling it repeatedly walks back through the whole
  /// session, all the way to the first word graded.
  void _revert() {
    if (_history.isEmpty) return;
    setState(() {
      final entry = _history.removeLast();
      _reviewQueue = entry.queueBefore;
      _gradedCount = entry.gradedCountBefore;
      _totalEver = entry.totalEverBefore;
      _stage = 0;
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
                        ? const ReviewEmptyState(
                            icon: Icons.bookmark_outline_rounded,
                            title: 'No saved words yet',
                            message:
                                'Save words you don\'t know from the dictionary lookup '
                                'sheet in the reader.',
                          )
                        : _SavedTab(words: saved, onStartReview: () => _startReview(saved)),
                    known.isEmpty
                        ? const ReviewEmptyState(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'No known words yet',
                            message:
                                'Mark words you already know from the dictionary lookup '
                                'sheet.',
                          )
                        : _KnownTab(words: known),
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
    final queue = _reviewQueue!;

    if (queue.isEmpty) {
      return ReviewEmptyState(
        icon: Icons.check_circle_rounded,
        title: 'Review complete',
        message: 'Reviewed $_uniqueCount word${_uniqueCount == 1 ? '' : 's'}.',
        action: FilledButton(onPressed: _endReview, child: const Text('Back to My Words')),
      );
    }

    final card = queue.first;
    final maxStage = _ReviewFlashCard.maxStage(card);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ReviewProgressBar(current: _gradedCount + 1, total: _totalEver),
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
                tooltip: 'End review',
                onPressed: _endReview,
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
                child: _ReviewFlashCard(entry: card, revealStage: _stage),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ReviewGradeArea(
            revealed: _stage >= maxStage,
            onAgain: () => _grade(correct: false),
            onGood: () => _grade(correct: true),
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

class _KnownTab extends StatelessWidget {
  const _KnownTab({required this.words});

  final List<MyWordEntry> words;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: SizedBox(
            // Matches the FilledButton.icon height in _SavedTab's header row,
            // so the gap above the first word item is the same in both tabs.
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${words.length} known', style: Theme.of(context).textTheme.labelLarge),
            ),
          ),
        ),
        Expanded(child: _WordList(words: words)),
      ],
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
/// Known / Save buttons that move a word between Saved and Known. The
/// trailing delete button instead removes the word from My Words entirely.
class _WordTile extends ConsumerWidget {
  const _WordTile({required this.word});

  final MyWordEntry word;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final dictionaryForm = word.userWord.dictionaryForm;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete word?'),
        content: Text('"$dictionaryForm" will be removed from My Words.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(userWordActionsProvider.notifier).delete(dictionaryForm);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final entry = word.entry;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => showLookupBottomSheet(context, word.userWord.dictionaryForm),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
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
            IconButton(
              onPressed: () => _confirmDelete(context, ref),
              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.onSurface.withValues(alpha: 0.5)),
              tooltip: 'Delete word',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

/// Progressive reveal: kanji/expression first, then (on tap) the kana
/// reading, then (on tap) the English meaning — mirrors [DeckFlashCard]'s
/// JP → EN order, since My Words review is always word → meaning recall.
class _ReviewFlashCard extends StatelessWidget {
  const _ReviewFlashCard({required this.entry, required this.revealStage});

  final MyWordEntry entry;
  final int revealStage;

  static int maxStage(MyWordEntry entry) =>
      (entry.entry?.reading.isNotEmpty ?? false) ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dictEntry = entry.entry;
    final hasKana = dictEntry?.reading.isNotEmpty ?? false;
    final kanaStage = hasKana ? 1 : 0;
    final finalStage = maxStage(entry);
    final showKana = hasKana && revealStage >= kanaStage;
    final showFinal = revealStage >= finalStage;
    final accentColor = JlptColors.forLevel(dictEntry?.jlptLevel);

    return FlashCardShell(
      cardKey: entry.userWord.dictionaryForm,
      accentColor: accentColor,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dictEntry != null) ...[
              JlptLevelChip(level: dictEntry.jlptLevel),
              const SizedBox(height: 12),
            ],
            Text(
              entry.userWord.dictionaryForm,
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (showKana)
              RevealFadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    dictEntry!.reading,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (showFinal)
              RevealFadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        width: 48,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dictEntry?.partOfSpeech ?? '',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dictEntry != null ? decodeMeanings(dictEntry.meanings) : 'No dictionary entry.',
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
