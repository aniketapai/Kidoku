import 'dart:ui';

/// A block of Japanese text detected in a photo, alongside its on-device
/// English translation.
class TranslatedTextBlock {
  const TranslatedTextBlock({
    required this.original,
    required this.translated,
    required this.boundingBox,
  });

  final String original;
  final String translated;

  /// Normalized 0..1, relative to the source image's width/height — lets the
  /// UI position a highlight box over the displayed image regardless of how
  /// large it's rendered on screen.
  final Rect boundingBox;
}
