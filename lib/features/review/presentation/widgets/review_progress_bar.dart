import 'package:flutter/material.dart';

/// Slim animated progress bar + counter + optional trailing actions, shown
/// above the flashcard in every review mode's active session. Replaces a
/// bare "n of total" text label so progress reads at a glance.
class ReviewProgressBar extends StatelessWidget {
  const ReviewProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.trailing,
  });

  final int current;
  final int total;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$current of $total',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(height: 6, color: colorScheme.surfaceContainerHighest),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          height: 6,
                          width: constraints.maxWidth * fraction,
                          color: colorScheme.primary,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Small pill badge used where a fixed total isn't known upfront (e.g. the
/// Decks queue, which can grow as cards become due) — just a count and a
/// label rather than a progress fraction.
class ReviewCountBadge extends StatelessWidget {
  const ReviewCountBadge({super.key, required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon button used for header-row actions (revert, end session)
/// next to a [ReviewProgressBar] or [ReviewCountBadge].
class ReviewIconButton extends StatelessWidget {
  const ReviewIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null
                ? colorScheme.onSurface.withValues(alpha: 0.3)
                : colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
