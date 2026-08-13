// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievements_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(achievementsRepository)
final achievementsRepositoryProvider = AchievementsRepositoryProvider._();

final class AchievementsRepositoryProvider
    extends
        $FunctionalProvider<
          AchievementsRepository,
          AchievementsRepository,
          AchievementsRepository
        >
    with $Provider<AchievementsRepository> {
  AchievementsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AchievementsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AchievementsRepository create(Ref ref) {
    return achievementsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AchievementsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AchievementsRepository>(value),
    );
  }
}

String _$achievementsRepositoryHash() =>
    r'9bb57cb9f5a4ba5a3a4a44f57c1a2207cd16f031';
