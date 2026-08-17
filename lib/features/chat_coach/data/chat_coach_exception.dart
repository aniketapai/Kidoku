/// Thrown when [GEMINI_API_KEY] hasn't been supplied via
/// `--dart-define-from-file=secrets.json` — distinct from
/// [ChatCoachRequestException] so the UI can point at the fix instead of
/// showing a generic error.
class ChatCoachConfigException implements Exception {
  const ChatCoachConfigException();
}

/// Any failure calling or parsing the Gemini API response.
class ChatCoachRequestException implements Exception {
  const ChatCoachRequestException(this.message);
  final String message;
}
