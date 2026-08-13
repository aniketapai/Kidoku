import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/achievements_repository.dart';

// Hand-written (not @riverpod codegen) — Achievement is a Drift-generated
// DataClass declared in a `part` file, which triggers riverpod_generator's
// InvalidTypeException. See dictionary_search_provider.dart for the same
// workaround.
final achievementsProvider = StreamProvider.autoDispose<List<Achievement>>((ref) {
  return ref.watch(achievementsRepositoryProvider).watchAll();
});
