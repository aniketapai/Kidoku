import 'package:flutter/material.dart';

import '../../data/activity_repository.dart';

const _kBarChartHeight = 110.0;
const _kWeekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// Stacked bar chart of the last 14 days' review volume, split into correct
/// (solid) vs. missed (muted) — the "graph" companion to [ActivityHeatmap],
/// showing recent trend rather than a full year at a glance.
class ActivityGraph extends StatelessWidget {
  const ActivityGraph({super.key, required this.days});

  final List<DailyActivity> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recent = days.length > 14 ? days.sublist(days.length - 14) : days;

    if (recent.every((d) => d.total == 0)) {
      return Text(
        'Review some words this week to see your trend here.',
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      );
    }

    final maxTotal = recent.fold(1, (m, d) => d.total > m ? d.total : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _kBarChartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in recent)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _Bar(day: day, maxTotal: maxTotal, colorScheme: colorScheme),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final day in recent)
              Expanded(
                child: Text(
                  _kWeekdayLabels[day.date.weekday % 7],
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendDot(color: colorScheme.primary),
            const SizedBox(width: 6),
            Text('Correct',
                style: textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(width: 16),
            _LegendDot(color: colorScheme.error.withValues(alpha: 0.55)),
            const SizedBox(width: 6),
            Text('Missed',
                style: textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.maxTotal, required this.colorScheme});

  final DailyActivity day;
  final int maxTotal;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (day.total == 0) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    final missed = day.total - day.correct;
    final totalHeight = _kBarChartHeight * (day.total / maxTotal).clamp(0.08, 1.0);
    final correctHeight = day.correct == 0 ? 0.0 : totalHeight * (day.correct / day.total);
    final missedHeight = totalHeight - correctHeight;

    return Tooltip(
      message: '${day.total} review${day.total == 1 ? '' : 's'} · ${day.correct} correct'
          '${missed > 0 ? ' · $missed missed' : ''}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (missedHeight > 0)
            Container(
              height: missedHeight,
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.55),
                borderRadius: correctHeight == 0
                    ? const BorderRadius.vertical(top: Radius.circular(3))
                    : null,
              ),
            ),
          if (correctHeight > 0)
            Container(
              height: correctHeight,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
