import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/chat_coach_provider.dart';
import '../data/chat_coach_exception.dart';
import '../domain/chat_coach_result.dart';
import '../domain/chat_coach_turn.dart';
import '../domain/chat_register.dart';

const _kMissingKeyMessage =
    'No Gemini API key configured. Add one to secrets.json and run with '
    '--dart-define-from-file=secrets.json (see README).';

/// Reached from the drawer: a real back-and-forth chat with "Coach" — say what you
/// want in Japanese, English, or romaji (mixed freely) and get natural
/// phrasing back at your chosen politeness register, with the conversation
/// remembered turn to turn.
class ChatCoachScreen extends ConsumerStatefulWidget {
  const ChatCoachScreen({super.key});

  @override
  ConsumerState<ChatCoachScreen> createState() => _ChatCoachScreenState();
}

class _ChatCoachScreenState extends ConsumerState<ChatCoachScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<ChatCoachTurn> _turns = [];
  ChatRegister _register = ChatRegister.semiFormal;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _submit([String? presetText]) async {
    final message = (presetText ?? _controller.text).trim();
    if (message.isEmpty || _loading) return;
    final register = _register;
    final history = List<ChatCoachTurn>.of(_turns);
    _controller.clear();
    setState(() {
      _turns
        ..add(UserChatTurn(text: message, register: register))
        ..add(const PendingChatTurn());
    });
    _scrollToBottom();
    await _runCoach(
      message: message,
      register: register,
      history: history,
      resultIndex: _turns.length - 1,
    );
  }

  Future<void> _retry(int errorIndex) async {
    if (_loading || errorIndex == 0) return;
    final userTurn = _turns[errorIndex - 1];
    if (userTurn is! UserChatTurn) return;
    final history = _turns.sublist(0, errorIndex - 1);
    setState(() => _turns[errorIndex] = const PendingChatTurn());
    _scrollToBottom();
    await _runCoach(
      message: userTurn.text,
      register: userTurn.register,
      history: history,
      resultIndex: errorIndex,
    );
  }

  Future<void> _runCoach({
    required String message,
    required ChatRegister register,
    required List<ChatCoachTurn> history,
    required int resultIndex,
  }) async {
    setState(() => _loading = true);
    try {
      final result = await ref
          .read(geminiChatCoachServiceProvider)
          .coach(message: message, register: register, history: history);
      if (!mounted) return;
      setState(() => _turns[resultIndex] = CoachChatTurn(result));
    } on ChatCoachConfigException {
      if (!mounted) return;
      setState(() => _turns[resultIndex] = const ErrorChatTurn(_kMissingKeyMessage));
    } on ChatCoachRequestException catch (e) {
      if (!mounted) return;
      setState(() => _turns[resultIndex] = ErrorChatTurn(e.message));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavClearance = 64 + MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _ChatHeader(
            hasMessages: _turns.isNotEmpty,
            onClear: () {
              HapticFeedback.selectionClick();
              setState(_turns.clear);
            },
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _turns.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _WelcomeBubble();
                }
                final turnIndex = index - 1;
                final turn = _turns[turnIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: switch (turn) {
                    UserChatTurn t => _UserBubble(turn: t),
                    CoachChatTurn t => _CoachBubble(result: t.result),
                    PendingChatTurn() => const _TypingBubble(),
                    ErrorChatTurn t => _ErrorBubble(
                      message: t.message,
                      onRetry: turnIndex > 0 && _turns[turnIndex - 1] is UserChatTurn
                          ? () => _retry(turnIndex)
                          : null,
                    ),
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            focusNode: _focusNode,
            register: _register,
            loading: _loading,
            onRegisterChanged: (r) => setState(() => _register = r),
            onSubmit: _submit,
          ),
          SizedBox(height: bottomNavClearance),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.hasMessages, required this.onClear});

  final bool hasMessages;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.surfaceContainerHighest)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Japanese phrasing helper',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (hasMessages)
            IconButton(
              tooltip: 'New conversation',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

class _WelcomeBubble extends StatelessWidget {
  const _WelcomeBubble();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoachAvatar(colorScheme: colorScheme),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                "Hey! Tell me what you want to say, paste something a "
                "friend sent you and ask how to reply, or drop your own "
                "sentence and ask how it sounds. Japanese, English, or "
                "romaji all work.",
                style: textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 16,
    backgroundColor: colorScheme.secondary.withValues(alpha: 0.16),
    child: Icon(Icons.auto_awesome_rounded, size: 16, color: colorScheme.secondary),
  );
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.turn});

  final UserChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                turn.text,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              turn.register.label,
              style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.result});

  final ChatCoachResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CoachAvatar(colorScheme: colorScheme),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.74),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.context.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            result.context,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(result.japanese, style: textTheme.titleLarge),
                      ),
                      if (result.japanese.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: result.japanese));
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text('Copied'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (result.reading.isNotEmpty)
                    Text(
                      result.reading,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  if (result.explanation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(result.explanation, style: textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotOpacity(double t, int index) {
    final phase = (t - index * 0.2) % 1.0;
    final wave = (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0);
    return 0.3 + wave * 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CoachAvatar(colorScheme: colorScheme),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _Dot(
                    opacity: _dotOpacity(_controller.value, i),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.opacity, required this.color});

  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
  );
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.errorContainer,
          child: Icon(Icons.error_outline_rounded, size: 16, color: colorScheme.onErrorContainer),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.74),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onRetry,
                      child: Text(
                        'Tap to retry',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.register,
    required this.loading,
    required this.onRegisterChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ChatRegister register;
  final bool loading;
  final ValueChanged<ChatRegister> onRegisterChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.surfaceContainerHighest)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in ChatRegister.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: r == register,
                  onSelected: (_) => onRegisterChanged(r),
                  visualDensity: VisualDensity.compact,
                  labelStyle: TextStyle(
                    color: r == register ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  selectedColor: colorScheme.primary,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSubmit(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      hintText: 'Japanese, English, or romaji…',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(loading: loading, onPressed: onSubmit),
            ],
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.arrow_upward_rounded, color: colorScheme.onPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
