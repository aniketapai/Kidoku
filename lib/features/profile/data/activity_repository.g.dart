// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activityRepository)
final activityRepositoryProvider = ActivityRepositoryProvider._();

final class ActivityRepositoryProvider
    extends
        $FunctionalProvider<
          ActivityRepository,
          ActivityRepository,
          ActivityRepository
        >
    with $Provider<ActivityRepository> {
  ActivityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityRepositoryHash();

  @$internal
  @override
  $ProviderElement<ActivityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ActivityRepository create(Ref ref) {
    return activityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityRepository>(value),
    );
  }
}

String _$activityRepositoryHash() =>
    r'ad38b760ad2bd2486c8c3ca2eaf724a3d38d8e61';

@ProviderFor(activityStats)
final activityStatsProvider = ActivityStatsProvider._();

final class ActivityStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ActivityStats>,
          ActivityStats,
          Stream<ActivityStats>
        >
    with $FutureModifier<ActivityStats>, $StreamProvider<ActivityStats> {
  ActivityStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityStatsHash();

  @$internal
  @override
  $StreamProviderElement<ActivityStats> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ActivityStats> create(Ref ref) {
    return activityStats(ref);
  }
}

String _$activityStatsHash() => r'3d5a0c96002b692ff87a29ec21d82f2855c4ff31';
