// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reel_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reelRepository)
final reelRepositoryProvider = ReelRepositoryProvider._();

final class ReelRepositoryProvider
    extends $FunctionalProvider<ReelRepository, ReelRepository, ReelRepository>
    with $Provider<ReelRepository> {
  ReelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reelRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reelRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReelRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReelRepository create(Ref ref) {
    return reelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReelRepository>(value),
    );
  }
}

String _$reelRepositoryHash() => r'd92c475fe65be879f26e9b0e1be982488a7066f0';
