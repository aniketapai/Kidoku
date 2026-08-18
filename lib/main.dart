import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/auth/auth_repository.dart';
import 'core/database/app_database.dart';
import 'core/database/providers.dart';
import 'core/database/seed/seed_loader.dart';
import 'features/notifications/application/notification_providers.dart';
import 'features/notifications/data/notification_service.dart';
import 'features/reader/data/user_word_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = AppDatabase();
  await SeedLoader.run(db);

  // Built directly (not read from a ProviderContainer, which doesn't exist
  // yet) and handed to ProviderScope below via override so every provider
  // that watches flutterLocalNotificationsPluginProvider shares this same,
  // already-initialized instance.
  final notificationPlugin = FlutterLocalNotificationsPlugin();
  await NotificationService(notificationPlugin).init();

  final authRepository = AuthRepository(FirebaseAuth.instance);
  final user = authRepository.currentUser;
  if (user != null && !user.isAnonymous) {
    try {
      await UserWordRepository(
        db,
        FirebaseFirestore.instance,
        authRepository,
      ).pullFromRemote();
    } catch (_) {
      // No network on launch, etc. — app still works locally; sync
      // features degrade gracefully until connectivity is back.
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(authRepository),
        flutterLocalNotificationsPluginProvider.overrideWithValue(
          notificationPlugin,
        ),
      ],
      child: const KidokuApp(),
    ),
  );
}
