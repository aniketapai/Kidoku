import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../data/notification_service.dart';

/// Single plugin instance for the app's lifetime.
final flutterLocalNotificationsPluginProvider =
    Provider<FlutterLocalNotificationsPlugin>((ref) {
      return FlutterLocalNotificationsPlugin();
    });

/// Wraps [flutterLocalNotificationsPluginProvider] — call
/// [NotificationService.init] once at startup (see main.dart) before
/// scheduling anything through this.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(flutterLocalNotificationsPluginProvider),
  );
});

/// This device's saved notification preferences — see
/// [AppDatabase.watchNotificationSettings]. Read this to render toggles;
/// write through [notificationSettingsActionsProvider].
final notificationSettingsProvider = StreamProvider<NotificationSettingsData>((
  ref,
) {
  return ref.watch(appDatabaseProvider).watchNotificationSettings();
});

/// Persists notification-preference changes and keeps the OS-scheduled
/// notifications in sync with them. The review-due reminder is handled
/// separately by ReviewDueNotificationScheduler, which reacts to review
/// progress rather than a direct toggle flip.
class NotificationSettingsActions {
  NotificationSettingsActions(this._db, this._service);

  final AppDatabase _db;
  final NotificationService _service;

  /// The UserSettings row's column defaults declare every notification
  /// type "on", but that's just what a fresh install *would* show if the
  /// user opened Notification Settings — nothing is actually scheduled
  /// with the OS until a write happens through this class. Call once at
  /// startup (see app.dart) so a first-time user gets the permission
  /// prompt and their default schedule applied without having to visit
  /// Settings first. A no-op on every later launch, once a settings row
  /// exists — whether the user changed something or just accepted these
  /// same defaults via [setNotificationsEnabled].
  Future<void> applyFirstRunDefaultsIfNeeded() async {
    final existingRow = await _db.getUserSettingsRow();
    if (existingRow == null) {
      await setNotificationsEnabled(true);
    }
  }

  Future<bool> setNotificationsEnabled(bool value) async {
    if (value) {
      final granted = await _service.requestPermission();
      if (!granted) return false;
    } else {
      await _service.cancelStudyReminder();
      await _service.cancelReviewDueReminder();
      await _service.cancelMotivational();
    }
    await _db.writeNotificationsEnabled(value);
    if (value) {
      final settings = await _db.watchNotificationSettings().first;
      await _applyAll(settings);
    }
    return true;
  }

  Future<void> setStudyReminderEnabled(bool value) async {
    await _db.writeStudyReminderEnabled(value);
    final settings = await _db.watchNotificationSettings().first;
    if (!settings.notificationsEnabled) return;
    if (value) {
      await _service.scheduleStudyReminder(
        hour: settings.studyReminderHour,
        minute: settings.studyReminderMinute,
      );
    } else {
      await _service.cancelStudyReminder();
    }
  }

  Future<void> setStudyReminderTime(int hour, int minute) async {
    await _db.writeStudyReminderTime(hour, minute);
    final settings = await _db.watchNotificationSettings().first;
    if (settings.notificationsEnabled && settings.studyReminderEnabled) {
      await _service.scheduleStudyReminder(hour: hour, minute: minute);
    }
  }

  Future<void> setReviewDueRemindersEnabled(bool value) async {
    await _db.writeReviewDueRemindersEnabled(value);
    if (!value) await _service.cancelReviewDueReminder();
    // Re-scheduling when turned back on is handled by
    // ReviewDueNotificationScheduler reacting to this setting change.
  }

  Future<void> setMotivationalRemindersEnabled(bool value) async {
    await _db.writeMotivationalRemindersEnabled(value);
    final settings = await _db.watchNotificationSettings().first;
    if (!settings.notificationsEnabled) return;
    if (value) {
      await _service.scheduleMotivational(
        hour: settings.studyReminderHour,
        minute: _kMotivationalMinute,
      );
    } else {
      await _service.cancelMotivational();
    }
  }

  Future<void> _applyAll(NotificationSettingsData settings) async {
    if (settings.studyReminderEnabled) {
      await _service.scheduleStudyReminder(
        hour: settings.studyReminderHour,
        minute: settings.studyReminderMinute,
      );
    }
    if (settings.motivationalRemindersEnabled) {
      await _service.scheduleMotivational(
        hour: settings.studyReminderHour,
        minute: _kMotivationalMinute,
      );
    }
    // Review-due reminder is left to ReviewDueNotificationScheduler, which
    // is already watching progress and will (re)schedule it shortly.
  }
}

/// Motivational messages piggyback on the study reminder's hour but land
/// 30 minutes later — there's no separate time picker for them, and firing
/// at the exact same minute as the study reminder would mean two
/// notifications landing together instead of one nudge now, one later.
const _kMotivationalMinute = 30;

final notificationSettingsActionsProvider =
    Provider<NotificationSettingsActions>((ref) {
      return NotificationSettingsActions(
        ref.watch(appDatabaseProvider),
        ref.watch(notificationServiceProvider),
      );
    });
