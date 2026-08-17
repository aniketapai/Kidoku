import 'chat_coach_result.dart';
import 'chat_register.dart';

/// One item in the chat coach conversation, in the order it happened —
/// either something the learner sent or something the coach sent back.
/// Kept as a sealed hierarchy (rather than one struct with nullable
/// fields) so the UI and the service's history-replay logic can switch
/// on it exhaustively.
sealed class ChatCoachTurn {
  const ChatCoachTurn();
}

class UserChatTurn extends ChatCoachTurn {
  const UserChatTurn({required this.text, required this.register});

  final String text;
  final ChatRegister register;
}

class CoachChatTurn extends ChatCoachTurn {
  const CoachChatTurn(this.result);

  final ChatCoachResult result;
}

class PendingChatTurn extends ChatCoachTurn {
  const PendingChatTurn();
}

class ErrorChatTurn extends ChatCoachTurn {
  const ErrorChatTurn(this.message);

  final String message;
}
