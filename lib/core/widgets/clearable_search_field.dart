import 'package:flutter/material.dart';

/// The search bar used on the Dictionary and Vocabulary/Kanji screens: a
/// rounded, filled [TextField] that shows a clear ("x") button once there's
/// text to clear, and — since the point of a search box is scanning results
/// as you type, not admiring the caret — keeps the cursor solid instead of
/// blinking ([EditableText.cursorOpacityAnimates]).
class ClearableSearchField extends StatefulWidget {
  const ClearableSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.autofocus = false,
    this.textInputAction,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool autofocus;
  final TextInputAction? textInputAction;

  @override
  State<ClearableSearchField> createState() => _ClearableSearchFieldState();
}

class _ClearableSearchFieldState extends State<ClearableSearchField> {
  late final TextEditingController _controller = widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      cursorOpacityAnimates: false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                splashRadius: 18,
                onPressed: _clear,
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      onChanged: widget.onChanged,
    );
  }
}
