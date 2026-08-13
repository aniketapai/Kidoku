// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AchievementActions)
final achievementActionsProvider = AchievementActionsProvider._();

final class AchievementActionsProvider
    extends $NotifierProvider<AchievementActions, void> {
  AchievementActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'achievementActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$achievementActionsHash();

  @$internal
  @override
  AchievementActions create() => AchievementActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$achievementActionsHash() =>
    r'82c8831d0f30249cb7d1823ca42f11490b24ebf1';

abstract class _$AchievementActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
