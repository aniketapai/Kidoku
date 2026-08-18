/// Rotating pool for the weekly motivational reminder — one message per
/// day of the week (index 0 = Monday, matching [DateTime.weekday]) so a
/// user who keeps the reminder on for a while doesn't see the exact same
/// line every day. See NotificationService.scheduleMotivational.
abstract final class MotivationalMessages {
  static const weekly = [
    'A few minutes of Japanese today keeps your streak alive. 頑張って！',
    'Your words are waiting. Even five minutes of review moves the needle.',
    "Halfway through the week — don't let your reading streak slip now.",
    'Small daily reps beat cramming. Open Kidoku for a quick review.',
    'Almost the weekend — one more review session and you earn it.',
    'Weekend reading session? Your library has stories waiting for you.',
    'New week, new words. Start it off with a quick review.',
  ];
}
