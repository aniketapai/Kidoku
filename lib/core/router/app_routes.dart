abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const library = '/library';
  static const review = '/review';
  static const vocabulary = '/vocabulary';
  static const dictionary = '/dictionary';
  static const cameraTranslate = '/camera-translate';
  static const profile = '/profile';
  static const settings = '/settings';
  static const notificationSettings = '/settings/notifications';
  static const storyReader = '/story';

  // Not wired into the router — Reels is out of the app for now, but its
  // screens are kept buildable (see reel_library_screen.dart) in case the
  // feature comes back.
  static const reelPlayer = '/reels/player';
}
