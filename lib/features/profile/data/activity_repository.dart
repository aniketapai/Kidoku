import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';

part 'activity_repository.g.dart';

/// Review counts for a single calendar day (local time).
class DailyActivity {
  const DailyActivity({required this.date, required this.total, required this.correct});

  final DateTime date;
  final int total;
  final int correct;

  double get accuracy => total == 0 ? 0 : correct / total;
}

class ActivityStats {
  const ActivityStats({
    required this.days,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalReviews,
    required this.overallAccuracy,
  });

  /// One entry per day covering the heatmap window, oldest first.
  final List<DailyActivity> days;
  final int currentStreak;
  final int longestStreak;
  final int totalReviews;
  final double overallAccuracy;

  static const empty = ActivityStats(
    days: [],
    currentStreak: 0,
    longestStreak: 0,
    totalReviews: 0,
    overallAccuracy: 0,
  );
}

class ActivityRepository {
  ActivityRepository(this._db);
  final AppDatabase _db;

  /// GitHub-style contribution graph convention: 53 weeks so the grid always
  /// spans a few days past a full year, however today's weekday falls.
  static const heatmapWeeks = 53;

  Stream<ActivityStats> watchStats() {
    final today = _dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: heatmapWeeks * 7 - 1));
    return _db.watchReviewEventsSince(start).map((events) => _computeStats(events, start, today));
  }

  ActivityStats _computeStats(List<ReviewEvent> events, DateTime start, DateTime today) {
    final totals = <DateTime, int>{};
    final corrects = <DateTime, int>{};
    for (final e in events) {
      final day = _dateOnly(e.occurredAt);
      totals[day] = (totals[day] ?? 0) + 1;
      if (e.correct) corrects[day] = (corrects[day] ?? 0) + 1;
    }

    final days = <DailyActivity>[
      for (var i = 0; i <= today.difference(start).inDays; i++)
        () {
          final day = start.add(Duration(days: i));
          return DailyActivity(
            date: day,
            total: totals[day] ?? 0,
            correct: corrects[day] ?? 0,
          );
        }(),
    ];

    var currentStreak = 0;
    var cursor = today;
    if ((totals[cursor] ?? 0) == 0) {
      // Today hasn't been studied yet — that alone shouldn't zero the
      // streak, so look for an unbroken run ending yesterday instead.
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while ((totals[cursor] ?? 0) > 0) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var longestStreak = 0;
    var running = 0;
    for (final d in days) {
      running = d.total > 0 ? running + 1 : 0;
      if (running > longestStreak) longestStreak = running;
    }

    final totalReviews = events.length;
    final totalCorrect = events.where((e) => e.correct).length;

    return ActivityStats(
      days: days,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalReviews: totalReviews,
      overallAccuracy: totalReviews == 0 ? 0 : totalCorrect / totalReviews,
    );
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

@riverpod
ActivityRepository activityRepository(Ref ref) {
  return ActivityRepository(ref.watch(appDatabaseProvider));
}

@riverpod
Stream<ActivityStats> activityStats(Ref ref) {
  return ref.watch(activityRepositoryProvider).watchStats();
}
