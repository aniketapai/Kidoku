import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.dart';

part 'providers.g.dart';

/// Overridden with a live instance built in main() once seeding completes.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main()');
}
