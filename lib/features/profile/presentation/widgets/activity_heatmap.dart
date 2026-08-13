import 'package:flutter/material.dart';

import '../../data/activity_repository.dart';

const _kMonthLabels = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _kCellSize = 12.0;
const _kCellGap = 3.0;

/// GitHub-style contribution heatmap over [ActivityStats.days] — one column
/// per week (Sun-first), colored by review volume that day. Scrolls
/// horizontally, anchored to the most recent week by default.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key, required this.days});

  final List<DailyActivity> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (days.isEmpty) {
      return Text(
        'No activity yet — review a word to get started.',
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      );
    }

    final weeks = _bucketIntoWeeks(days);
    final maxCount = days.fold(0, (m, d) => d.total > m ? d.total : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final week in weeks)
                    SizedBox(
                      width: _kCellSize + _kCellGap,
                      child: Text(
                        _monthLabelFor(week),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final week in weeks)
                    Padding(
                      padding: const EdgeInsets.only(right: _kCellGap),
                      child: Column(
                        children: [
                          for (final day in week)
                            Padding(
                              padding: const EdgeInsets.only(bottom: _kCellGap),
                              child: _HeatmapCell(day: day, maxCount: maxCount),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _Legend(colorScheme: colorScheme, textTheme: textTheme),
      ],
    );
  }

  /// Pads to full Sun-Sat weeks, then chunks into 7-day columns.
  static List<List<DailyActivity?>> _bucketIntoWeeks(List<DailyActivity> days) {
    final first = days.first.date;
    // DateTime.weekday: Monday=1 ... Sunday=7. Days to step back to reach
    // the preceding Sunday (0 if already Sunday).
    final leadingPad = first.weekday % 7;
    final last = days.last.date;
    final trailingPad = 6 - (last.weekday % 7);

    final padded = <DailyActivity?>[
      for (var i = 0; i < leadingPad; i++) null,
      ...days,
      for (var i = 0; i < trailingPad; i++) null,
    ];

    return [
      for (var i = 0; i < padded.length; i += 7) padded.sublist(i, i + 7),
    ];
  }

  static String _monthLabelFor(List<DailyActivity?> week) {
    final firstReal = week.firstWhere((d) => d != null, orElse: () => null);
    if (firstReal == null || firstReal.date.day > 7) return '';
    return _kMonthLabels[firstReal.date.month - 1];
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.day, required this.maxCount});

  final DailyActivity? day;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cell = Container(
      width: _kCellSize,
      height: _kCellSize,
      decoration: BoxDecoration(
        color: _colorFor(colorScheme),
        borderRadius: BorderRadius.circular(3),
      ),
    );

    if (day == null || day!.total == 0) return cell;

    final date = day!.date;
    final message =
        '${_kMonthLabels[date.month - 1]} ${date.day}: ${day!.total} review${day!.total == 1 ? '' : 's'}';
    return Tooltip(message: message, child: cell);
  }

  Color _colorFor(ColorScheme colorScheme) {
    if (day == null) return Colors.transparent;
    final count = day!.total;
    if (count == 0) return colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final ratio = maxCount == 0 ? 1.0 : (count / maxCount).clamp(0.0, 1.0);
    // Quantize to 4 steps so single extra reviews don't jitter the shade.
    final step = ratio <= 0.25 ? 0.35 : (ratio <= 0.5 ? 0.55 : (ratio <= 0.75 ? 0.75 : 1.0));
    return colorScheme.primary.withValues(alpha: step);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colorScheme, required this.textTheme});

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Less',
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        const SizedBox(width: 6),
        for (final alpha in [0.0, 0.35, 0.55, 0.75, 1.0])
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: _kCellSize,
              height: _kCellSize,
              decoration: BoxDecoration(
                color: alpha == 0.0
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                    : colorScheme.primary.withValues(alpha: alpha),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const SizedBox(width: 3),
        Text(
          'More',
          style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}
