import 'package:flutter/material.dart';

import '../../../reader/presentation/widgets/lookup_bottom_sheet.dart';
import '../../domain/story.dart';

/// Renders one paragraph as a flow of tappable, furigana-annotated tokens —
/// the same word-by-word reading interaction the app's lookup sheet already
/// backs, just wrapped as running prose instead of a single dictionary
/// search result.
class StoryParagraphText extends StatelessWidget {
  const StoryParagraphText({super.key, required this.tokens, required this.fontSize});

  final List<StoryToken> tokens;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final token in tokens) _StoryTokenChip(token: token, fontSize: fontSize),
      ],
    );
  }
}

/// One sentence as its own block: the tappable, furigana-annotated Japanese
/// line, with its English gloss directly beneath it. Rendering one sentence
/// at a time (rather than a whole paragraph of running prose) is what lets
/// the translation line up with the exact sentence it belongs to.
///
/// [fontSize] already carries the story's level bump and the reader's
/// text-size preference, so the English caption derives its own size from
/// it (clamped so it stays legible at the smallest reader setting without
/// overwhelming the Japanese at the largest). [showFurigana] and
/// [showEnglish] can each be toggled independently and only ever add or
/// remove space — never resize what's already on screen — so the two
/// toggles can't fight each other.
class StorySentenceBlock extends StatelessWidget {
  const StorySentenceBlock({
    super.key,
    required this.sentence,
    required this.fontSize,
    required this.showFurigana,
    required this.showEnglish,
  });

  final StorySentence sentence;
  final double fontSize;
  final bool showFurigana;
  final bool showEnglish;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final englishSize = (fontSize * 0.45).clamp(13.0, 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoryParagraphText(
          tokens: showFurigana
              ? sentence.tokens
              : [
                  for (final t in sentence.tokens)
                    StoryToken(surface: t.surface, dictionaryForm: t.dictionaryForm),
                ],
          fontSize: fontSize,
        ),
        if (showEnglish) ...[
          const SizedBox(height: 4),
          Text(
            sentence.en,
            style: TextStyle(
              fontSize: englishSize,
              height: 1.3,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

class _StoryTokenChip extends StatelessWidget {
  const _StoryTokenChip({required this.token, required this.fontSize});

  final StoryToken token;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasReading = token.reading != null && token.reading!.isNotEmpty;

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: fontSize * 0.68,
          child: hasReading
              ? Text(
                  token.reading!,
                  style: TextStyle(
                    fontSize: fontSize * 0.46,
                    height: 1,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                )
              : null,
        ),
        Text(
          token.surface,
          style: TextStyle(fontSize: fontSize, height: 1.9, color: colorScheme.onSurface),
        ),
      ],
    );

    if (!token.isTappable) return Padding(padding: const EdgeInsets.only(bottom: 4), child: text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showLookupBottomSheet(context, token.dictionaryForm!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: text,
        ),
      ),
    );
  }
}
