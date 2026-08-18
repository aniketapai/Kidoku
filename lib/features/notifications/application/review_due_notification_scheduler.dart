import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../decks/application/deck_data_providers.dart';
import 'notification_providers.dart';

/// Keeps the single "reviews are due" OS notification in sync with SRS
/// progress: whenever deck-card due dates or notification settings change,
/// this recomputes the *next* time a card falls due and (re)schedules a
/// one-shot notification for that moment — or cancels it if there's
/// nothing upcoming or the setting is off.
///
/// Deliberately ignores cards that are due right now (rather than in the
/// future) — those are already surfaced by the Decks/Review screens, and
/// notifying for them on every progress write would mean a fresh
/// notification firing seconds after every single card graded during an
/// active session. The daily study reminder covers "come back and check".
///
/// Watched once, kept alive for the app's lifetime, from the app root (see
/// app.dart) — deckCardProgressProvider is `.autoDispose`, so without a
/// permanent listener it would tear down (and stop scheduling) whenever no
/// review screen is on screen.
final reviewDueNotificationSchedulerProvider = Provider<void>((ref) {
  void recompute() {
    final progress = ref.read(deckCardProgressProvider).value;
    final settings = ref.read(notificationSettingsProvider).value;
    if (progress == null || settings == null) return;

    final service = ref.read(notificationServiceProvider);
    if (!settings.notificationsEnabled || !settings.reviewDueRemindersEnabled) {
      service.cancelReviewDueReminder();
      return;
    }

    final now = DateTime.now();
    final upcoming =
        progress.values
            .where((p) => p.dueAt != null && p.dueAt!.isAfter(now))
            .toList()
          ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    if (upcoming.isEmpty) {
      service.cancelReviewDueReminder();
      return;
    }

    final nextDue = upcoming.first.dueAt!;
    final countAtNextDue = upcoming.where((p) => p.dueAt == nextDue).length;
    service.scheduleReviewDueReminder(dueAt: nextDue, dueCount: countAtNextDue);
  }

  ref.listen(
    deckCardProgressProvider,
    (_, _) => recompute(),
    fireImmediately: true,
  );
  ref.listen(notificationSettingsProvider, (_, _) => recompute());
});
