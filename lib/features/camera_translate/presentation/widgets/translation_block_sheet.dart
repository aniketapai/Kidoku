import 'package:flutter/material.dart';

import '../../domain/translated_text_block.dart';

/// Bottom sheet showing a single detected block's original Japanese text
/// alongside its English translation. Structured after
/// `showLookupBottomSheet` (rounded surface pulled from `colorScheme`) —
/// unlike that sheet, there's no async resolve step here since the block was
/// already translated before the user could tap it.
Future<void> showTranslationBlockSheet(
  BuildContext context,
  TranslatedTextBlock block,
) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    sheetAnimationStyle: const AnimationStyle(
      curve: Curves.easeOutCubic,
      duration: Duration(milliseconds: 280),
      reverseCurve: Curves.easeInCubic,
      reverseDuration: Duration(milliseconds: 200),
    ),
    builder: (context) => _TranslationBlockSheet(block: block),
  );
}

class _TranslationBlockSheet extends StatelessWidget {
  const _TranslationBlockSheet({required this.block});

  final TranslatedTextBlock block;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(block.original, style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  block.translated,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
