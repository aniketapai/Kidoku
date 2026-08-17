// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_translate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ocrTranslationService)
final ocrTranslationServiceProvider = OcrTranslationServiceProvider._();

final class OcrTranslationServiceProvider
    extends
        $FunctionalProvider<
          OcrTranslationService,
          OcrTranslationService,
          OcrTranslationService
        >
    with $Provider<OcrTranslationService> {
  OcrTranslationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ocrTranslationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ocrTranslationServiceHash();

  @$internal
  @override
  $ProviderElement<OcrTranslationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OcrTranslationService create(Ref ref) {
    return ocrTranslationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OcrTranslationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OcrTranslationService>(value),
    );
  }
}

String _$ocrTranslationServiceHash() =>
    r'58d2649496895d7c7f9c4fe713793d824c31f21f';
