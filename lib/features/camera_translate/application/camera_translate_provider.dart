import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/ocr_translation_service.dart';
import '../domain/translated_text_block.dart';

part 'camera_translate_provider.g.dart';

@riverpod
OcrTranslationService ocrTranslationService(Ref ref) {
  final service = OcrTranslationService();
  ref.onDispose(service.dispose);
  return service;
}

// Hand-written (not @riverpod codegen) — see dictionaryLookupProvider for
// why: autoDispose.family keyed by the picked photo's path, a one-shot async
// call per photo rather than a long-lived watched value.
final cameraTranslateProvider = FutureProvider.autoDispose
    .family<List<TranslatedTextBlock>, String>((ref, imagePath) {
      return ref.watch(ocrTranslationServiceProvider).translateImage(imagePath);
    });
