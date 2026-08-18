import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../domain/motivational_messages.dart';

/// Payloads attached to scheduled notifications — read back in
/// [NotificationService._onNotificationTapped] to decide where a tap
/// should navigate.
abstract final class _Payload {
  static const studyReminder = 'study_reminder';
  static const reviewDue = 'review_due';
  static const motivational = 'motivational';
}

/// Fixed notification ids. Motivational uses one id per weekday
/// ([_motivationalId]) since each day of the week carries its own message
/// (see [MotivationalMessages]) and is scheduled as its own repeating
/// zonedSchedule.
abstract final class _NotificationId {
  static const studyReminder = 1001;
  static const reviewDue = 1002;
  static const motivationalBase = 2000;
}

int _motivationalId(int weekday) => _NotificationId.motivationalBase + weekday;

/// Wraps flutter_local_notifications: local, on-device scheduling for
/// study reminders, review-due nudges, and motivational messages. No
/// server/push component — everything here is scheduled ahead of time by
/// the OS, so notifications fire even while the app is closed.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _androidDetails = AndroidNotificationDetails(
    'yomu_reminders',
    'Study reminders',
    channelDescription:
        'Study reminders, review-due nudges, and motivational messages.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Sets up timezone data (needed for [tz.TZDateTime]-based scheduling)
  /// and the plugin itself. Safe to call more than once — later calls are
  /// no-ops.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));
    } catch (_) {
      // Falls back to UTC — scheduled times will be off from the user's
      // wall clock, but notifications still fire rather than crashing.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Routes a notification tap to the relevant screen. Handles the
  /// foreground/background-but-alive case; a cold-start tap is handled by
  /// [routeToLaunchNotification] instead.
  void _onNotificationTapped(NotificationResponse response) =>
      _route(response.payload);

  void _route(String? payload) {
    switch (payload) {
      case _Payload.reviewDue:
        appRouter.go(AppRoutes.review);
      case _Payload.studyReminder:
        appRouter.go(AppRoutes.library);
      case _Payload.motivational:
        appRouter.go(AppRoutes.library);
    }
  }

  /// Call once at startup, after the router exists, to route if the app
  /// was launched (cold start) by tapping a notification.
  Future<void> routeToLaunchNotification() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _route(details!.notificationResponse?.payload);
    }
  }

  /// Requests OS notification permission (Android 13+, iOS, macOS — no-op
  /// on older Android). Returns whether permission is granted.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? true;
    }
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isMacOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled ?? true;
    }
    return true;
  }

  /// Deep-links to this app's OS notification settings — the way out for a
  /// user who denied the permission prompt and needs to flip it back on
  /// manually.
  Future<void> openAppSettings() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    } else if (Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.openAppNotificationSettings();
    }
  }

  /// A daily nudge to open the app, repeating at [hour]:[minute] local
  /// time every day.
  Future<void> scheduleStudyReminder({required int hour, required int minute}) {
    return _plugin.zonedSchedule(
      id: _NotificationId.studyReminder,
      title: 'Time to study 📖',
      body:
          "You haven't reviewed today — a few minutes keeps your progress going.",
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _Payload.studyReminder,
    );
  }

  Future<void> cancelStudyReminder() =>
      _plugin.cancel(id: _NotificationId.studyReminder);

  /// One-shot nudge for when deck cards next fall due. Callers are
  /// expected to re-call this (or [cancelReviewDueReminder]) whenever due
  /// dates change — see ReviewDueNotificationScheduler, which watches
  /// review progress and keeps this in sync automatically.
  Future<void> scheduleReviewDueReminder({
    required DateTime dueAt,
    required int dueCount,
  }) {
    // dueAt may already be in the past (cards are due right now) — fire
    // shortly instead of scheduling into the past, which the plugin
    // rejects.
    final fireAt = dueAt.isAfter(DateTime.now())
        ? dueAt
        : DateTime.now().add(const Duration(seconds: 5));
    final cardWord = dueCount == 1 ? 'card' : 'cards';

    return _plugin.zonedSchedule(
      id: _NotificationId.reviewDue,
      title: 'Reviews are due 🔁',
      body: '$dueCount $cardWord ready for review.',
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _Payload.reviewDue,
    );
  }

  Future<void> cancelReviewDueReminder() =>
      _plugin.cancel(id: _NotificationId.reviewDue);

  /// Schedules one repeating notification per weekday, each carrying its
  /// own message from [MotivationalMessages.weekly] — a cheap way to rotate
  /// content without needing to reschedule daily.
  Future<void> scheduleMotivational({
    required int hour,
    required int minute,
  }) async {
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.zonedSchedule(
        id: _motivationalId(weekday),
        title: 'Kidoku',
        body: MotivationalMessages.weekly[weekday - DateTime.monday],
        scheduledDate: _nextInstanceOfWeekdayTime(weekday, hour, minute),
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: _Payload.motivational,
      );
    }
  }

  Future<void> cancelMotivational() async {
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      await _plugin.cancel(id: _motivationalId(weekday));
    }
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(
    int weekday,
    int hour,
    int minute,
  ) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @visibleForTesting
  Future<List<PendingNotificationRequest>> pendingNotifications() =>
      _plugin.pendingNotificationRequests();
}
