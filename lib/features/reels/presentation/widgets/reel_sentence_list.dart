import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/reel_sync.dart';
import '../../domain/reel.dart';

/// The scrolling transcript panel beneath a reel's video: auto-centers on
/// whichever sentence is currently being spoken (Spotify-lyrics style) and
/// highlights the current word within it as playback advances. Still
/// user-draggable to re-read earlier lines — see [ReelPlayerPage] for the
/// known risk of this competing with the feed's own vertical swipe.
class ReelSentenceList extends StatefulWidget {
  const ReelSentenceList({
    super.key,
    required this.reel,
    required this.positionMs,
    required this.showFurigana,
    required this.onTokenTap,
  });

  final Reel reel;

  /// The active reel page's current playback position, in milliseconds —
  /// owned by [ReelPlayerPage] and fed by the YouTube player's position
  /// stream (~10Hz while playing).
  final ValueListenable<int> positionMs;

  final bool showFurigana;

  /// Called with a tapped token's dictionary form — [ReelPlayerPage] pauses
  /// the video for the lookup and resumes it once the popup closes.
  final ValueChanged<String> onTokenTap;

  @override
  State<ReelSentenceList> createState() => _ReelSentenceListState();
}

class _ReelSentenceListState extends State<ReelSentenceList> {
  final _scrollController = ScrollController();
  late final List<GlobalKey> _sentenceKeys;
  int _lastAutoScrolledIndex = -1;
  int _lastSentenceIndex = -1;
  int _lastTokenIndex = -1;

  @override
  void initState() {
    super.initState();
    _sentenceKeys = List.generate(widget.reel.sentences.length, (_) => GlobalKey());
    widget.positionMs.addListener(_onPositionChanged);
  }

  @override
  void didUpdateWidget(covariant ReelSentenceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positionMs != widget.positionMs) {
      oldWidget.positionMs.removeListener(_onPositionChanged);
      widget.positionMs.addListener(_onPositionChanged);
    }
  }

  @override
  void dispose() {
    widget.positionMs.removeListener(_onPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPositionChanged() {
    final position = locateReelPosition(widget.reel, widget.positionMs.value);
    if (!position.isNone && position.sentenceIndex != _lastAutoScrolledIndex) {
      _lastAutoScrolledIndex = position.sentenceIndex;
      final sentenceContext = _sentenceKeys[position.sentenceIndex].currentContext;
      if (sentenceContext != null) {
        Scrollable.ensureVisible(
          sentenceContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.4,
        );
      }
    }
    // The YouTube player reports position ~10x/sec, but the highlighted
    // sentence/token only actually changes every second or so — rebuilding
    // (and re-laying-out) every visible sentence block on every one of
    // those ticks regardless was eating enough frame budget that the
    // ensureVisible scroll above stopped animating smoothly and instead
    // visibly snapped between positions. Skipping the rebuild when nothing
    // highlighted actually moved fixes that.
    if (position.sentenceIndex == _lastSentenceIndex && position.tokenIndex == _lastTokenIndex) {
      return;
    }
    _lastSentenceIndex = position.sentenceIndex;
    _lastTokenIndex = position.tokenIndex;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final position = locateReelPosition(widget.reel, widget.positionMs.value);
    return ListView(
      controller: _scrollController,
      // Non-bouncy: Scrollable.ensureVisible below clamps its target to the
      // list's scroll extent, and with ListView.builder's lazily-estimated
      // extents that clamp target used to shift as more items got laid out
      // mid-animation, reading as a bounce/snap on every sentence change.
      // Building every sentence eagerly (below) gives Flutter the real
      // extent up front, and BouncingScrollPhysics' own overscroll-then-
      // spring-back at the list edges was the other half of that same
      // visible bounce, so both are switched off together.
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      children: [
        for (var index = 0; index < widget.reel.sentences.length; index++)
          Padding(
            key: _sentenceKeys[index],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _ReelSentenceBlock(
              sentence: widget.reel.sentences[index],
              isCurrent: index == position.sentenceIndex,
              currentTokenIndex: index == position.sentenceIndex ? position.tokenIndex : -1,
              showFurigana: widget.showFurigana,
              onTokenTap: widget.onTokenTap,
            ),
          ),
      ],
    );
  }
}

class _ReelSentenceBlock extends StatelessWidget {
  const _ReelSentenceBlock({
    required this.sentence,
    required this.isCurrent,
    required this.currentTokenIndex,
    required this.showFurigana,
    required this.onTokenTap,
  });

  final ReelSentence sentence;
  final bool isCurrent;
  final int currentTokenIndex;
  final bool showFurigana;
  final ValueChanged<String> onTokenTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isCurrent ? 1 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.secondaryDark.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          // Border is always present (just transparent when not current),
          // never `null` — Container silently adds the border's stroke
          // width as extra padding whenever a border exists (so the child
          // doesn't get overlapped by it), so toggling the border in and
          // out on isCurrent grew/shrank this block by ~2px right as the
          // list auto-scrolled to it, shoving every other block and
          // reading as the whole screen bouncing.
          border: Border.all(
            color: isCurrent
                ? AppColors.secondaryDark.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < sentence.tokens.length; i++)
                  _ReelTokenChip(
                    token: sentence.tokens[i],
                    showFurigana: showFurigana,
                    onTap: onTokenTap,
                    state: !isCurrent
                        ? _TokenHighlight.upcoming
                        : i < currentTokenIndex
                        ? _TokenHighlight.spoken
                        : i == currentTokenIndex
                        ? _TokenHighlight.current
                        : _TokenHighlight.upcoming,
                  ),
              ],
            ),
            // Rendered whenever a translation exists — not just while
            // isCurrent — so a sentence's height stays constant as
            // playback moves on/off it. Toggling this in and out on
            // isCurrent used to change that block's height right as the
            // list auto-scrolled to it, shoving every other block and
            // reading as the whole screen jumping.
            if (sentence.en != null) ...[
              const SizedBox(height: 4),
              Text(
                sentence.en!,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryDark.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _TokenHighlight { spoken, current, upcoming }

class _ReelTokenChip extends StatelessWidget {
  const _ReelTokenChip({
    required this.token,
    required this.state,
    required this.showFurigana,
    required this.onTap,
  });

  final ReelToken token;
  final _TokenHighlight state;
  final bool showFurigana;
  final ValueChanged<String> onTap;

  static const _fontSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final hasReading = showFurigana && token.reading != null && token.reading!.isNotEmpty;
    final color = switch (state) {
      _TokenHighlight.current => AppColors.secondaryDark,
      _TokenHighlight.spoken => AppColors.primaryDark,
      _TokenHighlight.upcoming => Colors.white.withValues(alpha: 0.55),
    };

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showFurigana)
          SizedBox(
            height: _fontSize * 0.6,
            child: hasReading
                ? Text(
                    token.reading!,
                    style: TextStyle(fontSize: _fontSize * 0.4, height: 1, color: color.withValues(alpha: 0.8)),
                  )
                : null,
          ),
        Text(
          token.surface,
          style: TextStyle(fontSize: _fontSize, height: 1.6, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );

    if (!token.isTappable) return Padding(padding: const EdgeInsets.only(bottom: 2), child: text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onTap(token.dictionaryForm!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: state == _TokenHighlight.current
                ? AppColors.secondaryDark.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: text,
        ),
      ),
    );
  }
}
