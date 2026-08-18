import 'package:flutter/material.dart';

/// The "Again" / "Good" grading row shown once a flashcard is fully
/// revealed, and the "tap to reveal" hint shown before that — swapped
/// between with a fade so the bottom of the card never just pops.
class ReviewGradeArea extends StatelessWidget {
  const ReviewGradeArea({
    super.key,
    required this.revealed,
    required this.onAgain,
    required this.onGood,
  });

  final bool revealed;
  final VoidCallback onAgain;
  final VoidCallback onGood;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: revealed
          ? _ReviewGradeButtons(key: const ValueKey('buttons'), onAgain: onAgain, onGood: onGood)
          : const _ReviewTapHint(key: ValueKey('hint')),
    );
  }
}

class _ReviewGradeButtons extends StatelessWidget {
  const _ReviewGradeButtons({super.key, required this.onAgain, required this.onGood});

  final VoidCallback onAgain;
  final VoidCallback onGood;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAgain,
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onGood,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Good'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewTapHint extends StatelessWidget {
  const _ReviewTapHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            'Tap the card to reveal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
