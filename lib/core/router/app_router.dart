import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/camera_translate/presentation/camera_translate_screen.dart';
import '../../features/dictionary/presentation/dictionary_screen.dart';
import '../../features/library/domain/story.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/library/presentation/story_reader_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/vocabulary/presentation/vocabulary_screen.dart';
import 'app_routes.dart';
import 'go_router_refresh_stream.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.signIn,
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    // Anonymous doesn't count — Google sign-in is the only way in.
    final signedIn = user != null && !user.isAnonymous;
    final goingToSignIn = state.matchedLocation == AppRoutes.signIn;

    if (!signedIn && !goingToSignIn) return AppRoutes.signIn;
    if (signedIn && goingToSignIn) return AppRoutes.library;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: AppRoutes.storyReader,
      builder: (context, state) =>
          StoryReaderScreen(storyMeta: state.extra! as StoryMeta),
    ),
    GoRoute(
      path: AppRoutes.dictionary,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Dictionary')),
        body: const DictionaryScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.cameraTranslate,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Camera Translate')),
        body: const CameraTranslateScreen(),
      ),
    ),
    // Reached from the settings button on ProfileScreen — pushed on top of
    // the shell for the same reason as vocabulary/dictionary above.
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.notificationSettings,
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      // Branch order must match YomuBottomBar's item order (index-driven).
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.library,
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.review,
              builder: (context, state) => const ReviewScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.vocabulary,
              builder: (context, state) => const VocabularyScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
