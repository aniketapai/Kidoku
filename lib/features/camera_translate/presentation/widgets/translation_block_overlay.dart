import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/translated_text_block.dart';
import 'translation_block_sheet.dart';

/// Displays [image] at its native aspect ratio with a tappable highlight box
/// over each detected [blocks] entry. Boxes are positioned from each block's
/// normalized (0..1) bounding box, so they land correctly regardless of how
/// large the image is rendered.
class TranslationBlockOverlay extends StatelessWidget {
  const TranslationBlockOverlay({
    super.key,
    required this.image,
    required this.blocks,
  });

  final File image;
  final List<TranslatedTextBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageInfo>(
      future: _resolveImageInfo(image),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) {
          return const AspectRatio(aspectRatio: 1, child: SizedBox.shrink());
        }
        final aspectRatio = info.image.width / info.image.height;
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.fill),
                    for (final block in blocks)
                      Positioned(
                        left: block.boundingBox.left * width,
                        top: block.boundingBox.top * height,
                        width: block.boundingBox.width * width,
                        height: block.boundingBox.height * height,
                        child: _HighlightBox(
                          onTap: () =>
                              showTranslationBlockSheet(context, block),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<ImageInfo> _resolveImageInfo(File file) {
    final completer = Completer<ImageInfo>();
    final stream = FileImage(file).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronous) {
        completer.complete(info);
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        completer.completeError(error, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondary.withValues(alpha: 0.22),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.secondary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
