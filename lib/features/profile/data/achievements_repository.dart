import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/database/tables/achievements_table.dart';

part 'achievements_repository.g.dart';

class AchievementsRepository {
  AchievementsRepository(this._db);
  final AppDatabase _db;

  Stream<List<Achievement>> watchAll() => _db.watchAchievements();

  Future<void> add({
    required CertificateType type,
    required String level,
    required DateTime earnedAt,
    String? note,
    String? imagePath,
  }) {
    return _db.addAchievement(
      type: type,
      level: level,
      earnedAt: earnedAt,
      note: note,
      imagePath: imagePath,
    );
  }

  Future<void> delete(int id) => _db.deleteAchievement(id);
}

@riverpod
AchievementsRepository achievementsRepository(Ref ref) {
  return AchievementsRepository(ref.watch(appDatabaseProvider));
}
