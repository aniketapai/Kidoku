import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/deck_cards_table.dart';
import '../../../core/text/romaji_converter.dart';
import '../../../core/widgets/clearable_search_field.dart';
import '../../decks/application/deck_browse_provider.dart';
import '../../decks/application/deck_data_providers.dart';
import 'widgets/deck_card_tile.dart';

const _kLevels = ['N5', 'N4', 'N3'];

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Vocab'),
                Tab(text: 'Kanji'),
                Tab(text: 'Kanji Vocab'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _DeckCardList(type: DeckCardType.vocab),
                  _DeckCardList(type: DeckCardType.kanji),
                  _KanjiVocabList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCardList extends ConsumerStatefulWidget {
  const _DeckCardList({required this.type});

  final DeckCardType type;

  @override
  ConsumerState<_DeckCardList> createState() => _DeckCardListState();
}

class _DeckCardListState extends ConsumerState<_DeckCardList> {
  final Set<String> _expandedLabels = {};

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(filteredDeckCardsProvider(widget.type));
    final filter = ref.watch(deckBrowseFilterProvider(widget.type));
    final notifier = ref.read(deckBrowseFilterProvider(widget.type).notifier);
    final colorScheme = Theme.of(context).colorScheme;

    if (!ref.watch(deckCardsProvider).hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final groups = _groupByCategory(cards);
    // While searching, force every matching group open so results are
    // visible immediately instead of hidden behind a collapsed header.
    final searching = filter.searchText.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: ClearableSearchField(
            hintText: widget.type == DeckCardType.kanji ? 'Search kanji…' : 'Search vocab…',
            onChanged: (value) => notifier.update((s) => s.copyWith(searchText: value)),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _kLevels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final level = _kLevels[index];
              final selected = level == filter.level;
              return ChoiceChip(
                label: Text(level),
                selected: selected,
                onSelected: (_) => notifier.update((s) => s.copyWith(level: level)),
                selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide.none,
                backgroundColor: colorScheme.surfaceContainerHighest,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: cards.isEmpty
              ? Center(child: Text('No matches', style: Theme.of(context).textTheme.bodyMedium))
              : widget.type == DeckCardType.kanji
                  ? _flatList(groups, colorScheme)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                      itemCount: groups.length,
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final expanded = searching || _expandedLabels.contains(group.label);
                        return _DeckGroupSection(
                          key: ValueKey(group.label),
                          group: group,
                          expanded: expanded,
                          locked: searching,
                          onToggle: () => setState(() {
                            if (!_expandedLabels.add(group.label)) {
                              _expandedLabels.remove(group.label);
                            }
                          }),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// Plain flat list (header + tiles), used for kanji where there's no
  /// week-based grouping to collapse — just a handful of level headers.
  Widget _flatList(List<_DeckCardGroup> groups, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      itemCount: groups.fold<int>(0, (n, g) => n + 1 + g.cards.length),
      itemBuilder: (context, index) {
        var remaining = index;
        for (final group in groups) {
          if (remaining == 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                group.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          }
          remaining--;
          if (remaining < group.cards.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DeckCardTile(card: group.cards[remaining]),
            );
          }
          remaining -= group.cards.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

const _kKanjiVocabLevels = ['N5', 'N4', 'N3'];

/// Vocab whose kanji are all covered by the target level or easier — a
/// standing review set, split into flat sets of 50 labeled by the topics
/// they cover (e.g. "Numbers – Time") rather than week/category groupings.
/// Toggles between cumulative N5, N4, and N3 pools (see
/// [kanjiVocabCardsProvider]).
class _KanjiVocabList extends ConsumerStatefulWidget {
  const _KanjiVocabList();

  @override
  ConsumerState<_KanjiVocabList> createState() => _KanjiVocabListState();
}

class _KanjiVocabListState extends ConsumerState<_KanjiVocabList> {
  final Set<String> _expandedKeys = {};
  String _searchText = '';
  String _level = 'N5';

  @override
  Widget build(BuildContext context) {
    final allCards = ref.watch(kanjiVocabCardsProvider(_level));
    final colorScheme = Theme.of(context).colorScheme;

    if (!ref.watch(deckCardsProvider).hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    final needle = _searchText.trim().toLowerCase();
    final kanaNeedle = romajiToHiragana(needle);
    final cards = needle.isEmpty
        ? allCards
        : allCards.where((c) {
            if (_matchesSearch(c, needle)) return true;
            if (kanaNeedle != null && kanaNeedle != needle && _matchesSearch(c, kanaNeedle)) {
              return true;
            }
            return false;
          }).toList();

    final groups = _chunkByTopicRange(cards);
    final searching = needle.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: ClearableSearchField(
            hintText: 'Search kanji vocab…',
            onChanged: (value) => setState(() => _searchText = value),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _kKanjiVocabLevels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final level = _kKanjiVocabLevels[index];
              final selected = level == _level;
              return ChoiceChip(
                label: Text(level),
                selected: selected,
                onSelected: (_) => setState(() => _level = level),
                selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide.none,
                backgroundColor: colorScheme.surfaceContainerHighest,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: cards.isEmpty
              ? Center(child: Text('No matches', style: Theme.of(context).textTheme.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    // Index rather than label — chunk labels are derived
                    // from topic names and aren't guaranteed unique.
                    final key = '$_level:$index';
                    final expanded = searching || _expandedKeys.contains(key);
                    return _DeckGroupSection(
                      key: ValueKey(key),
                      group: group,
                      expanded: expanded,
                      locked: searching,
                      onToggle: () => setState(() {
                        if (!_expandedKeys.add(key)) {
                          _expandedKeys.remove(key);
                        }
                      }),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

bool _matchesSearch(DeckCard card, String needle) {
  return card.expression.contains(needle) ||
      card.reading.contains(needle) ||
      card.meaning.toLowerCase().contains(needle);
}

class _DeckGroupSection extends StatefulWidget {
  const _DeckGroupSection({
    super.key,
    required this.group,
    required this.expanded,
    required this.locked,
    required this.onToggle,
  });

  final _DeckCardGroup group;
  final bool expanded;
  final bool locked;
  final VoidCallback onToggle;

  @override
  State<_DeckGroupSection> createState() => _DeckGroupSectionState();
}

class _DeckGroupSectionState extends State<_DeckGroupSection>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 280);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
    value: widget.expanded ? 1 : 0,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  // While fully collapsed and idle, the card list isn't built at all —
  // only mounted while expanded or mid-animation — so collapsed groups
  // cost nothing during scroll instead of eagerly building every tile.
  late bool _closed = !widget.expanded;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatusChanged);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() => _closed = true);
    }
  }

  @override
  void didUpdateWidget(covariant _DeckGroupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) {
      if (widget.expanded) {
        setState(() => _closed = false);
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final group = widget.group;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.surfaceContainerHighest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.locked ? null : widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        group.label,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${group.cards.length}',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!widget.locked) ...[
                      const SizedBox(width: 8),
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
                        child: Icon(
                          Icons.expand_more,
                          size: 22,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _animation,
              alignment: Alignment.topCenter,
              child: _closed
                  ? const SizedBox.shrink()
                  : FadeTransition(
                      opacity: _animation,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            Divider(height: 1, color: colorScheme.surfaceContainerHighest),
                            const SizedBox(height: 12),
                            for (var i = 0; i < group.cards.length; i++) ...[
                              DeckCardTile(card: group.cards[i]),
                              if (i < group.cards.length - 1) const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckCardGroup {
  _DeckCardGroup({required this.label, required this.cards});

  final String label;
  final List<DeckCard> cards;
}

/// Groups by level + category (vocab subdeck name), preserving each
/// group's first-appearance order rather than sorting alphabetically — so
/// vocab groups stay in original "Week 1.1, Week 1.2, ..." deck order.
List<_DeckCardGroup> _groupByCategory(List<DeckCard> cards) {
  final order = <String>[];
  final byLabel = <String, List<DeckCard>>{};
  for (final card in cards) {
    final label = card.category != null ? '${card.level} · ${card.category}' : card.level;
    if (!byLabel.containsKey(label)) {
      order.add(label);
      byLabel[label] = [];
    }
    byLabel[label]!.add(card);
  }
  return [for (final label in order) _DeckCardGroup(label: label, cards: byLabel[label]!)];
}

final _weekPrefixRegex = RegExp(r'^Week\s+[\d.]+\s+(.+)$');

/// Strips the "Week 1.1 " prefix off a category, leaving just the topic
/// name (e.g. "Numbers"), so chunk labels can read as content rather than
/// deck bookkeeping.
String _topicName(String? category) {
  if (category == null) return '';
  return _weekPrefixRegex.firstMatch(category)?.group(1) ?? category;
}

/// Chunks a list into fixed-size sets, ignoring week boundaries, and labels
/// each chunk by the topics it spans (e.g. "Numbers – Time") rather than a
/// bare index/range — used by the Kanji Vocab tab, which is a flat review
/// pool rather than a week-by-week deck.
List<_DeckCardGroup> _chunkByTopicRange(List<DeckCard> cards, {int size = 50}) {
  final groups = <_DeckCardGroup>[];
  for (var i = 0; i < cards.length; i += size) {
    final end = (i + size < cards.length) ? i + size : cards.length;
    final chunk = cards.sublist(i, end);
    final firstTopic = _topicName(chunk.first.category);
    final lastTopic = _topicName(chunk.last.category);
    final label = firstTopic == lastTopic ? firstTopic : '$firstTopic – $lastTopic';
    groups.add(_DeckCardGroup(label: label, cards: chunk));
  }
  return groups;
}
