import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/tables/achievements_table.dart';
import '../data/achievements_repository.dart';

part 'achievement_actions_provider.g.dart';

@riverpod
class AchievementActions extends _$AchievementActions {
  @override
  void build() {}

  Future<void> add({
    required CertificateType type,
    required String level,
    required DateTime earnedAt,
    String? note,
    String? imagePath,
  }) {
    return ref.read(achievementsRepositoryProvider).add(
          type: type,
          level: level,
          earnedAt: earnedAt,
          note: note,
          imagePath: imagePath,
        );
  }

  Future<void> delete(int id) {
    return ref.read(achievementsRepositoryProvider).delete(id);
  }
}
