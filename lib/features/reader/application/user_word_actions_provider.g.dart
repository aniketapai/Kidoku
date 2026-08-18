// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_word_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserWordActions)
final userWordActionsProvider = UserWordActionsProvider._();

final class UserWordActionsProvider
    extends $NotifierProvider<UserWordActions, void> {
  UserWordActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userWordActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userWordActionsHash();

  @$internal
  @override
  UserWordActions create() => UserWordActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$userWordActionsHash() => r'682bbe5fa35aefd3141b982e55c180535c118191';

abstract class _$UserWordActions extends $Notifier<void> {
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
