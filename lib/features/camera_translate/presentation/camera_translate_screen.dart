import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../application/camera_translate_provider.dart';
import 'widgets/translation_block_overlay.dart';

/// Take (or pick) a photo of Japanese text and see it translated to English
/// — reached from the profile drawer, pushed on top of the shell like
/// Dictionary/Vocabulary.
class CameraTranslateScreen extends ConsumerStatefulWidget {
  const CameraTranslateScreen({super.key});

  @override
  ConsumerState<CameraTranslateScreen> createState() =>
      _CameraTranslateScreenState();
}

class _CameraTranslateScreenState extends ConsumerState<CameraTranslateScreen> {
  File? _image;
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;
      setState(() => _image = File(picked.path));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: image == null
            ? _EmptyState(
                picking: _picking,
                onTakePhoto: () => _pick(ImageSource.camera),
                onPickGallery: () => _pick(ImageSource.gallery),
              )
            : _ResultView(
                image: image,
                onRetake: () => setState(() => _image = null),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.picking,
    required this.onTakePhoto,
    required this.onPickGallery,
  });

  final bool picking;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Photograph Japanese text — signs, menus, book pages —\nand get an instant English translation.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: picking ? null : onTakePhoto,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Take Photo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: picking ? null : onPickGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose from Gallery'),
          ),
          if (picking) ...[
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.image, required this.onRetake});

  final File image;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocksAsync = ref.watch(cameraTranslateProvider(image.path));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: blocksAsync.when(
              data: (blocks) => blocks.isEmpty
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(image),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Japanese text detected in this photo.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    )
                  : TranslationBlockOverlay(image: image, blocks: blocks),
              loading: () => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(image),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text('Reading text…', style: textTheme.bodyMedium),
                ],
              ),
              error: (error, stackTrace) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(image),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Couldn\'t translate this photo. Please try again.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Another Photo'),
        ),
      ],
    );
  }
}
