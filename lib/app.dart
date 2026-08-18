import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/application/notification_providers.dart';
import 'features/notifications/application/review_due_notification_scheduler.dart';

class KidokuApp extends ConsumerStatefulWidget {
  const KidokuApp({super.key});

  @override
  ConsumerState<KidokuApp> createState() => _KidokuAppState();
}

class _KidokuAppState extends ConsumerState<KidokuApp> {
  @override
  void initState() {
    super.initState();
    // Routes if the app was cold-started by tapping a notification — a
    // warm tap (app already alive) is handled by NotificationService's
    // onDidReceiveNotificationResponse callback instead.
    ref.read(notificationServiceProvider).routeToLaunchNotification();
    // First-run only — see applyFirstRunDefaultsIfNeeded's doc comment.
    ref
        .read(notificationSettingsActionsProvider)
        .applyFirstRunDefaultsIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps reviewDueNotificationSchedulerProvider alive for the app's
    // whole lifetime — it has no UI of its own, but watching it here (a
    // Provider<void>) is what keeps its underlying deck-progress
    // subscription (otherwise `.autoDispose`) from tearing down whenever
    // no review screen happens to be on screen.
    ref.watch(reviewDueNotificationSchedulerProvider);

    return MaterialApp.router(
      title: 'Kidoku',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
