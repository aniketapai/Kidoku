// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_coach_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(geminiChatCoachService)
final geminiChatCoachServiceProvider = GeminiChatCoachServiceProvider._();

final class GeminiChatCoachServiceProvider
    extends
        $FunctionalProvider<
          GeminiChatCoachService,
          GeminiChatCoachService,
          GeminiChatCoachService
        >
    with $Provider<GeminiChatCoachService> {
  GeminiChatCoachServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiChatCoachServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiChatCoachServiceHash();

  @$internal
  @override
  $ProviderElement<GeminiChatCoachService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GeminiChatCoachService create(Ref ref) {
    return geminiChatCoachService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeminiChatCoachService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeminiChatCoachService>(value),
    );
  }
}

String _$geminiChatCoachServiceHash() =>
    r'99482e32eed2e17d66bcfe56249d2d90edae88ad';
