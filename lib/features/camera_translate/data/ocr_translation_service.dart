import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../domain/translated_text_block.dart';

/// Runs Japanese OCR + on-device JA->EN translation over a photo. Both ML
/// Kit models run entirely on-device — no network round-trip, no API key.
class OcrTranslationService {
  OcrTranslationService()
    : _recognizer = TextRecognizer(script: TextRecognitionScript.japanese),
      _translator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.japanese,
        targetLanguage: TranslateLanguage.english,
      ),
      _modelManager = OnDeviceTranslatorModelManager();

  final TextRecognizer _recognizer;
  final OnDeviceTranslator _translator;
  final OnDeviceTranslatorModelManager _modelManager;
  bool _modelsReady = false;

  Future<List<TranslatedTextBlock>> translateImage(String imagePath) async {
    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    if (recognized.blocks.isEmpty) return const [];

    await _ensureModelsDownloaded();
    final imageSize = await _decodeImageSize(imagePath);

    final blocks = <TranslatedTextBlock>[];
    for (final block in recognized.blocks) {
      final translated = await _translator.translateText(block.text);
      blocks.add(
        TranslatedTextBlock(
          original: block.text,
          translated: translated,
          boundingBox: Rect.fromLTRB(
            block.boundingBox.left / imageSize.width,
            block.boundingBox.top / imageSize.height,
            block.boundingBox.right / imageSize.width,
            block.boundingBox.bottom / imageSize.height,
          ),
        ),
      );
    }
    return blocks;
  }

  // Translation models (~30-40MB each) are downloaded once and cached by the
  // OS-level ML Kit service, not by this app — isWifiRequired is false so a
  // first-time translation still works for someone on cellular only, mirror
  // of how the Google Translate app behaves.
  Future<void> _ensureModelsDownloaded() async {
    if (_modelsReady) return;
    for (final language in [
      TranslateLanguage.japanese,
      TranslateLanguage.english,
    ]) {
      final downloaded = await _modelManager.isModelDownloaded(
        language.bcpCode,
      );
      if (!downloaded) {
        await _modelManager.downloadModel(
          language.bcpCode,
          isWifiRequired: false,
        );
      }
    }
    _modelsReady = true;
  }

  Future<Size> _decodeImageSize(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  Future<void> dispose() async {
    await _recognizer.close();
    await _translator.close();
  }
}
