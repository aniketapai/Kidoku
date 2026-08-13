// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_review_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dueReviewCount)
final dueReviewCountProvider = DueReviewCountProvider._();

final class DueReviewCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  DueReviewCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dueReviewCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dueReviewCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return dueReviewCount(ref);
  }
}

String _$dueReviewCountHash() => r'ebe900b9280e5d3dc250b3d75edf77ad15d9b531';
