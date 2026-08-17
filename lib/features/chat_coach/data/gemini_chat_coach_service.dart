import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/chat_coach_result.dart';
import '../domain/chat_coach_turn.dart';
import '../domain/chat_register.dart';
import 'chat_coach_exception.dart';

/// Key is supplied at build/run time via `--dart-define-from-file=secrets.json`
/// (see README) — never hardcoded, never committed.
const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

// A specific stable version, not the "-latest" alias — that alias currently
// routes to a bleeding-edge preview tier that 503s under load far more than
// a settled release does.
const _model = 'gemini-3.5-flash';
const _endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

// Recent turns are enough for "make that more casual"-style follow-ups;
// sending the whole history forever would just bloat every request.
const _maxHistoryTurns = 20;

const _systemInstruction =
    'You are "Coach", a friendly Japanese-phrasing chat assistant embedded '
    'in a JLPT graded-reader app. You are having a real back-and-forth '
    'conversation with a learner, not filling out a form — use the '
    'conversation history for context, e.g. "make that more casual" or '
    '"why?" refers to your previous reply.\n\n'
    'The learner may write in English, Japanese (kana/kanji), or romaji, '
    'and may freely mix them in one message — e.g. an English instruction '
    'about a Japanese phrase, or a whole message in romaji. Work out their '
    'intent from whichever language(s) they used. Treat romaji as '
    'phonetic input and convert it to proper Japanese; never echo romaji '
    'back as the answer.\n\n'
    'Figure out which of these three things they want from context:\n'
    '1. Phrase something — they describe what they want to say. Give the '
    'phrasing directly; leave "context" empty.\n'
    '2. Reply to a message someone else sent them — recognizable because '
    'they paste a chunk of Japanese (or ask "how do I reply to this") '
    'rather than describing their own intent. Put a short, plain-English '
    'gist of what that message says in "context", then a natural reply to '
    'it in "japanese"/"reading". Do not assume what they want to say back '
    'unless they tell you — a generic but appropriate reply is fine if '
    'they did not specify one.\n'
    '3. Check their own draft — they wrote a Japanese sentence themselves '
    'and want feedback (e.g. "how is this?", "does this sound right?"). '
    'Give a corrected/more natural version in "japanese"/"reading" and say '
    'what changed in "explanation"; leave "context" empty.\n\n'
    '"japanese" and "reading" are always ready to paste straight into a '
    'chat with another person — no notes, brackets, or alternatives mixed '
    'in. "explanation" and "context" must both be short, crisp, and '
    'simple: one plain sentence, no jargon, never padded out to hit a '
    'length. Leave a field empty rather than stretching it.';

/// Calls the Gemini API to phrase [message] in Japanese at the requested
/// [register].
class GeminiChatCoachService {
  GeminiChatCoachService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<ChatCoachResult> coach({
    required String message,
    required ChatRegister register,
    List<ChatCoachTurn> history = const [],
  }) async {
    if (!isConfigured) throw const ChatCoachConfigException();

    final recentHistory = history.length > _maxHistoryTurns
        ? history.sublist(history.length - _maxHistoryTurns)
        : history;

    final uri = Uri.parse('$_endpoint?key=$_apiKey');
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemInstruction},
        ],
      },
      'contents': [
        for (final turn in recentHistory)
          if (turn case UserChatTurn(:final text, :final register))
            {
              'role': 'user',
              'parts': [
                {'text': _userTurnText(text, register)},
              ],
            }
          else if (turn case CoachChatTurn(:final result))
            {
              'role': 'model',
              'parts': [
                {'text': jsonEncode(_resultToJson(result))},
              ],
            },
        {
          'role': 'user',
          'parts': [
            {'text': _userTurnText(message, register)},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'japanese': {'type': 'STRING'},
            'reading': {'type': 'STRING'},
            'explanation': {'type': 'STRING'},
            'context': {'type': 'STRING'},
          },
          'required': ['japanese', 'reading', 'explanation', 'context'],
        },
      },
    });

    final response = await _postWithRetry(uri, body);
    if (response.statusCode != 200) {
      throw ChatCoachRequestException(
        'Gemini returned ${response.statusCode}: ${_extractErrorMessage(response.body)}',
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const ChatCoachRequestException(
          'Gemini returned no candidates (the request may have been blocked).',
        );
      }
      final parts = (candidates.first as Map<String, dynamic>)['content']?['parts'] as List<dynamic>?;
      final text = (parts != null && parts.isNotEmpty)
          ? parts.first['text'] as String?
          : null;
      if (text == null || text.isEmpty) {
        throw const ChatCoachRequestException('Gemini returned an empty response.');
      }
      return ChatCoachResult.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } on ChatCoachRequestException {
      rethrow;
    } catch (e) {
      throw ChatCoachRequestException('Couldn\'t parse Gemini\'s response: $e');
    }
  }

  String _userTurnText(String message, ChatRegister register) =>
      'Message: "$message"\nTarget register: ${register.promptDescription}';

  Map<String, String> _resultToJson(ChatCoachResult result) => {
    'japanese': result.japanese,
    'reading': result.reading,
    'explanation': result.explanation,
    'context': result.context,
  };

  // Gemini's flash models return a transient 503 under demand spikes fairly
  // often — one retry with a short backoff clears most of them without
  // making the user tap "Get phrasing" again.
  Future<http.Response> _postWithRetry(Uri uri, String body) async {
    for (var attempt = 0; ; attempt++) {
      try {
        final response = await _client
            .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 45));
        if (response.statusCode == 503 && attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        return response;
      } catch (e) {
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        throw ChatCoachRequestException('Couldn\'t reach Gemini: $e');
      }
    }
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      return (decoded['error'] as Map<String, dynamic>?)?['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

  void dispose() => _client.close();
}
