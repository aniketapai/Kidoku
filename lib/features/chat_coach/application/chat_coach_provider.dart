import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/gemini_chat_coach_service.dart';

part 'chat_coach_provider.g.dart';

@riverpod
GeminiChatCoachService geminiChatCoachService(Ref ref) {
  final service = GeminiChatCoachService();
  ref.onDispose(service.dispose);
  return service;
}
