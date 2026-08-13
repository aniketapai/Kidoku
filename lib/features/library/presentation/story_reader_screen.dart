import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/text/kanji_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/jlpt_level_chip.dart';
import '../../decks/application/deck_data_providers.dart';
import '../application/story_providers.dart';
import '../domain/story.dart';
import 'widgets/story_token_text.dart';

class StoryReaderScreen extends ConsumerStatefulWidget {
  const StoryReaderScreen({super.key, required this.storyMeta});

  final StoryMeta storyMeta;

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  bool _showFurigana = false;
  bool _showEnglish = false;

  void _showTextSizeSheet(BuildContext context, double currentScale) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => _TextSizeSheet(initialScale: currentScale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storyAsync = ref.watch(storyProvider(widget.storyMeta.file));
    final fontScale = ref.watch(readerFontScaleProvider).value ?? 1.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // The story's own title header (Japanese + English, right below this
      // bar) replaces an AppBar title — this bar exists only for the back
      // button, so it stays out of the way of that header and the settings
      // row beneath it.
      appBar: AppBar(),
      body: storyAsync.when(
        data: (story) => _StoryBody(
          story: story,
          showFurigana: _showFurigana,
          showEnglish: _showEnglish,
          fontScale: fontScale,
          onToggleFurigana: () => setState(() => _showFurigana = !_showFurigana),
          onToggleEnglish: () => setState(() => _showEnglish = !_showEnglish),
          onOpenTextSize: () => _showTextSizeSheet(context, fontScale),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Could not load this story.', style: TextStyle(color: colorScheme.error)),
        ),
      ),
    );
  }
}

int _clampInt(int value, int min, int max) => value < min ? min : (value > max ? max : value);

/// Renders a story as a sequence of pages sized to whatever actually fits
/// on screen, instead of the fixed page split baked into the story's JSON.
/// A story's sentences are laid out once, offstage, at the real width/font
/// size/furigana/English settings currently in effect; the measured height
/// of each sentence is then greedily packed into pages that fit the visible
/// area, so nothing ever needs scrolling and longer content (or a bigger
/// font, or turning furigana/English on) simply spills onto more pages.
/// Re-measures whenever the story, viewport, font scale, or either toggle
/// changes, and keeps the reader anchored on the same sentence it was
/// showing rather than snapping back to the first page.
class _StoryBody extends ConsumerStatefulWidget {
  const _StoryBody({
    required this.story,
    required this.showFurigana,
    required this.showEnglish,
    required this.fontScale,
    required this.onToggleFurigana,
    required this.onToggleEnglish,
    required this.onOpenTextSize,
  });

  final Story story;
  final bool showFurigana;
  final bool showEnglish;
  final double fontScale;
  final VoidCallback onToggleFurigana;
  final VoidCallback onToggleEnglish;
  final VoidCallback onOpenTextSize;

  @override
  ConsumerState<_StoryBody> createState() => _StoryBodyState();
}

class _StoryBodyState extends ConsumerState<_StoryBody> {
  PageController? _pageController;

  late List<StorySentence> _allSentences;
  late List<GlobalKey> _measureKeys;

  /// Start index (into [_allSentences]) of each computed page.
  List<int>? _pageStarts;

  int _pageIndex = 0;
  bool _resumeApplied = false;
  int? _pendingResumeIndex;

  /// Signature of the inputs the last completed measurement pass used, so
  /// rebuilds that don't actually change layout (e.g. swiping pages) don't
  /// retrigger measurement.
  String? _measuredSignature;

  @override
  void initState() {
    super.initState();
    _initForStory();
  }

  @override
  void didUpdateWidget(covariant _StoryBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story.id != widget.story.id) {
      _pageController?.dispose();
      _pageController = null;
      _pageIndex = 0;
      _resumeApplied = false;
      _pendingResumeIndex = null;
      _measuredSignature = null;
      _initForStory();
    }
  }

  void _initForStory() {
    _allSentences = [for (final page in widget.story.pages) ...page.sentences];
    _measureKeys = List.generate(_allSentences.length, (_) => GlobalKey());
    if (_allSentences.isEmpty) {
      _pageStarts = const [0];
      _pageController = PageController();
    } else {
      _pageStarts = null;
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _scheduleMeasurement(double width, double height) {
    if (_allSentences.isEmpty) return;
    final signature = '${widget.story.id}|$width|$height|${widget.fontScale}|'
        '${widget.showFurigana}|${widget.showEnglish}';
    if (signature == _measuredSignature) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(signature, height));
  }

  void _measure(String signature, double budgetHeight) {
    if (!mounted) return;

    final heights = <double>[];
    for (final key in _measureKeys) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) {
        // Offstage layout hasn't caught up yet — try again next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure(signature, budgetHeight));
        return;
      }
      heights.add(box.size.height);
    }

    final wasFirstMeasurement = _pageStarts == null;
    final previousStarts = _pageStarts;
    final previousAnchor = (!wasFirstMeasurement && previousStarts!.isNotEmpty)
        ? previousStarts[_clampInt(_pageIndex, 0, previousStarts.length - 1)]
        : 0;

    final starts = _paginate(heights, budgetHeight);

    setState(() {
      _measuredSignature = signature;
      _pageStarts = starts;

      if (_pendingResumeIndex != null) {
        _pageIndex = _clampInt(_pendingResumeIndex!, 0, starts.length - 1);
        _pendingResumeIndex = null;
      } else if (!wasFirstMeasurement) {
        // Keep showing the same content after a font/toggle change instead
        // of snapping back to the first page.
        var newIndex = 0;
        for (var i = 0; i < starts.length; i++) {
          if (starts[i] <= previousAnchor) newIndex = i;
        }
        _pageIndex = newIndex;
      }

      _pageController ??= PageController(initialPage: _pageIndex);
    });

    if (!wasFirstMeasurement && (_pageController?.hasClients ?? false)) {
      _pageController!.jumpToPage(_pageIndex);
    }
  }

  static List<int> _paginate(List<double> heights, double budget) {
    if (heights.isEmpty) return const [0];
    final starts = <int>[0];
    var acc = 0.0;
    for (var i = 0; i < heights.length; i++) {
      final h = heights[i];
      if (acc > 0 && acc + h > budget) {
        starts.add(i);
        acc = h;
      } else {
        acc += h;
      }
    }
    return starts;
  }

  void _goTo(int index) {
    if (_pageController?.hasClients ?? false) {
      _pageController!.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _pageIndex = index);
    // Only persist the *position* here — completed must stay whatever it
    // already was (true only once the reader taps "Mark Read") so simply
    // swiping to the last page doesn't plant a false checkmark back on the
    // Library card.
    final alreadyCompleted =
        ref.read(storyProgressProvider(widget.story.id)).value?.completed ?? false;
    ref
        .read(storyProgressActionsProvider)
        .savePage(widget.story.id, index, completed: alreadyCompleted);
  }

  void _markRead(int pageCount) {
    ref
        .read(storyProgressActionsProvider)
        .savePage(widget.story.id, pageCount - 1, completed: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Same base size across N5/N4/N3 — level no longer skews it. The
    // reader's own text-size preference (persisted, so it's remembered
    // next time) is the only thing that scales it now.
    final fontSize = 22.0 * widget.fontScale;
    final kanjiLevels = ref.watch(kanjiLevelMapProvider);

    // Resume from the last page read, once, the first time the story loads.
    final progress = ref.watch(storyProgressProvider(widget.story.id)).value;
    if (!_resumeApplied) {
      _resumeApplied = true;
      if (progress != null && progress.lastPageIndex > 0) {
        _pendingResumeIndex = progress.lastPageIndex;
      }
    }

    final pageStarts = _pageStarts;
    final pageCount = pageStarts?.length ?? 1;
    final currentPageIndex = pageStarts == null ? 0 : _clampInt(_pageIndex, 0, pageCount - 1);
    final currentSentences = pageStarts == null
        ? const <StorySentence>[]
        : _allSentences.sublist(
            pageStarts[currentPageIndex],
            currentPageIndex + 1 < pageStarts.length
                ? pageStarts[currentPageIndex + 1]
                : _allSentences.length,
          );
    final pageKanjiCounts = _kanjiLevelCounts(currentSentences, kanjiLevels);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.story.title,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.story.titleEn,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              JlptLevelChip(level: widget.story.level),
            ],
          ),
        ),
        Divider(height: 1, color: colorScheme.surfaceContainerHighest),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPadding = 40.0; // 20 + 20
              const verticalPadding = 48.0; // 24 + 24
              final measureWidth = (constraints.maxWidth - horizontalPadding).clamp(
                0.0,
                double.infinity,
              );
              final measureHeight = (constraints.maxHeight - verticalPadding).clamp(
                0.0,
                double.infinity,
              );
              _scheduleMeasurement(measureWidth, measureHeight);

              return Stack(
                children: [
                  _Measurer(
                    width: measureWidth,
                    sentences: _allSentences,
                    keys: _measureKeys,
                    fontSize: fontSize,
                    showFurigana: widget.showFurigana,
                    showEnglish: widget.showEnglish,
                  ),
                  if (pageStarts == null || _pageController == null)
                    const Center(child: CircularProgressIndicator())
                  else
                    PageView.builder(
                      controller: _pageController,
                      itemCount: pageStarts.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final start = pageStarts[index];
                        final end = index + 1 < pageStarts.length
                            ? pageStarts[index + 1]
                            : _allSentences.length;
                        final sentences = _allSentences.sublist(start, end);
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final sentence in sentences) ...[
                                StorySentenceBlock(
                                  sentence: sentence,
                                  fontSize: fontSize,
                                  showFurigana: widget.showFurigana,
                                  showEnglish: widget.showEnglish,
                                ),
                                const SizedBox(height: 18),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
        _KanjiLevelBar(counts: pageKanjiCounts),
        _ReaderSettingsBar(
          showFurigana: widget.showFurigana,
          showEnglish: widget.showEnglish,
          onToggleFurigana: widget.onToggleFurigana,
          onToggleEnglish: widget.onToggleEnglish,
          onOpenTextSize: widget.onOpenTextSize,
        ),
        Divider(height: 1, color: colorScheme.surfaceContainerHighest),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPageIndex > 0 ? () => _goTo(currentPageIndex - 1) : null,
              ),
              Text('${currentPageIndex + 1}/$pageCount', style: textTheme.bodyMedium),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    currentPageIndex < pageCount - 1 ? () => _goTo(currentPageIndex + 1) : null,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _goTo(0),
                  icon: const Icon(Icons.replay),
                  label: const Text('Read again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: colorScheme.secondary),
                  onPressed: () => _markRead(pageCount),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Read'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lays out every sentence of the story off-screen (still fully laid out,
/// just unpainted) at the given width/font settings so [_StoryBodyState]
/// can read each one's real rendered height back out via [keys] — the
/// same widget the real page uses, so the measured height exactly matches
/// what will actually be shown.
class _Measurer extends StatelessWidget {
  const _Measurer({
    required this.width,
    required this.sentences,
    required this.keys,
    required this.fontSize,
    required this.showFurigana,
    required this.showEnglish,
  });

  final double width;
  final List<StorySentence> sentences;
  final List<GlobalKey> keys;
  final double fontSize;
  final bool showFurigana;
  final bool showEnglish;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < sentences.length; i++)
                Padding(
                  key: keys[i],
                  padding: const EdgeInsets.only(bottom: 18),
                  child: StorySentenceBlock(
                    sentence: sentences[i],
                    fontSize: fontSize,
                    showFurigana: showFurigana,
                    showEnglish: showEnglish,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The reader's settings — text size, furigana, English — as a labeled
/// panel sitting just above the page-turn arrows rather than crowded into
/// the app bar or the title header, so neither one competes for space.
class _ReaderSettingsBar extends StatelessWidget {
  const _ReaderSettingsBar({
    required this.showFurigana,
    required this.showEnglish,
    required this.onToggleFurigana,
    required this.onToggleEnglish,
    required this.onOpenTextSize,
  });

  final bool showFurigana;
  final bool showEnglish;
  final VoidCallback onToggleFurigana;
  final VoidCallback onToggleEnglish;
  final VoidCallback onOpenTextSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SettingChip(
            icon: Icons.format_size,
            label: 'Text size',
            active: false,
            onTap: onOpenTextSize,
          ),
          _SettingChip(
            icon: showFurigana ? Icons.text_fields : Icons.text_fields_outlined,
            label: 'Furigana',
            active: showFurigana,
            onTap: onToggleFurigana,
          ),
          _SettingChip(
            icon: showEnglish ? Icons.translate : Icons.translate_outlined,
            label: 'English',
            active: showEnglish,
            onTap: onToggleEnglish,
          ),
        ],
      ),
    );
  }
}

class _SettingChip extends StatelessWidget {
  const _SettingChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: active ? colorScheme.primary.withValues(alpha: 0.12) : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _kKanjiLevelOrder = ['N5', 'N4', 'N3', 'N2', 'N1', 'Other'];

/// Counts every kanji occurrence in [sentences] by JLPT level (using
/// [kanjiLevels], keyed by character), so the reader can show at a glance
/// how much of a page's kanji actually sits outside its story's nominal
/// level — a word can be N5 vocabulary while spelled with non-N5 kanji.
/// Kanji absent from the imported decks fall into "Other". Ordered
/// N5→N1→Other with zero-count levels dropped.
Map<String, int> _kanjiLevelCounts(List<StorySentence> sentences, Map<String, String> kanjiLevels) {
  final counts = <String, int>{};
  for (final sentence in sentences) {
    for (final token in sentence.tokens) {
      for (final ch in extractKanji(token.surface)) {
        final level = kanjiLevels[ch] ?? 'Other';
        counts[level] = (counts[level] ?? 0) + 1;
      }
    }
  }
  return {
    for (final level in _kKanjiLevelOrder)
      if (counts[level] != null) level: counts[level]!,
  };
}

/// Color-coded stacked bar + legend showing the JLPT-level breakdown of
/// kanji on the current page. Hidden entirely on pages with no kanji.
class _KanjiLevelBar extends StatelessWidget {
  const _KanjiLevelBar({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  for (final entry in counts.entries)
                    Expanded(
                      flex: entry.value,
                      child: Container(
                        color: JlptColors.forLevel(entry.key == 'Other' ? null : entry.key),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final entry in counts.entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: JlptColors.forLevel(entry.key == 'Other' ? null : entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${entry.key} kanji · ${entry.value}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Text-size control, persisted via [readerFontScaleProvider] so it applies
/// across every story rather than resetting per session (unlike furigana
/// visibility). Writes on every drag tick rather than only on release — the
/// scale is a single cheap sqlite row, and writing live is what lets the
/// reader page redraw at the new size while the sheet is still open.
class _TextSizeSheet extends ConsumerStatefulWidget {
  const _TextSizeSheet({required this.initialScale});

  final double initialScale;

  @override
  ConsumerState<_TextSizeSheet> createState() => _TextSizeSheetState();
}

class _TextSizeSheetState extends ConsumerState<_TextSizeSheet> {
  late double _scale = widget.initialScale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Text size', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Center(
              child: Text('あ', style: TextStyle(fontSize: 22 * _scale, color: colorScheme.onSurface)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.text_decrease, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                Expanded(
                  child: Slider(
                    value: _scale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    label: '${(_scale * 100).round()}%',
                    onChanged: (value) {
                      setState(() => _scale = value);
                      ref.read(readerFontScaleActionsProvider).setScale(value);
                    },
                  ),
                ),
                Icon(Icons.text_increase, size: 22, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
