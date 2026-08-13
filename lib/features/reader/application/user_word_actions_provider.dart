import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/user_word_repository.dart';

part 'user_word_actions_provider.g.dart';

@riverpod
class UserWordActions extends _$UserWordActions {
  @override
  void build() {}

  Future<void> save(String dictionaryForm) {
    return ref.read(userWordRepositoryProvider).save(dictionaryForm);
  }

  Future<void> markKnown(String dictionaryForm) {
    return ref.read(userWordRepositoryProvider).markKnown(dictionaryForm);
  }

  Future<void> gradeReview(String dictionaryForm, {required bool correct}) {
    return ref.read(userWordRepositoryProvider).gradeReview(dictionaryForm, correct: correct);
  }
}
