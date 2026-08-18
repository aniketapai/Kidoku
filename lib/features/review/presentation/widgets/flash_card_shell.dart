import 'package:flutter/material.dart';

/// Shared visual chrome for every flashcard across Review's three modes
/// (My Words, Decks, Free Review) so they read as one consistent, elevated
/// surface instead of each screen drawing its own bordered box.
///
/// [cardKey] identifies the *content* currently shown (e.g. a card id plus
/// direction) — changing it cross-fades and slides the whole card, so
/// moving on to the next word reads as a transition instead of an instant
/// swap. [accentColor] tints the top edge and shadow (typically the word's
/// JLPT level color) to give each card a little visual identity.
class FlashCardShell extends StatelessWidget {
  const FlashCardShell({
    super.key,
    required this.cardKey,
    required this.accentColor,
    required this.child,
  });

  final Object cardKey;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(cardKey),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 260),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.surfaceContainerHighest),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 5, color: accentColor.withValues(alpha: 0.7)),
            Padding(padding: const EdgeInsets.fromLTRB(28, 26, 28, 30), child: child),
          ],
        ),
      ),
    );
  }
}

/// Fades (and, via the surrounding `AnimatedSize`, grows) a newly-revealed
/// section of a flashcard into place instead of having it pop in instantly.
class RevealFadeIn extends StatelessWidget {
  const RevealFadeIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
