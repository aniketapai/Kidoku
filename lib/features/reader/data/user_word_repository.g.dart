// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_word_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userWordRepository)
final userWordRepositoryProvider = UserWordRepositoryProvider._();

final class UserWordRepositoryProvider
    extends
        $FunctionalProvider<
          UserWordRepository,
          UserWordRepository,
          UserWordRepository
        >
    with $Provider<UserWordRepository> {
  UserWordRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userWordRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userWordRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserWordRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserWordRepository create(Ref ref) {
    return userWordRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserWordRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserWordRepository>(value),
    );
  }
}

String _$userWordRepositoryHash() =>
    r'a227be80d4c0efc6f2448e3fdedf70eb5af46fb8';
