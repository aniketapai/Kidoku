import 'package:drift/drift.dart';

enum CertificateType { jlpt, natTest }

/// A JLPT or NAT-TEST certificate the user has earned, added manually from
/// the profile screen.
class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => textEnum<CertificateType>()();
  TextColumn get level => text()();
  DateTimeColumn get earnedAt => dateTime()();
  TextColumn get note => text().nullable()();

  /// Path to a photo of the physical certificate, copied into app storage
  /// (see AddAchievementDialog) so it survives past the picker's temp file.
  TextColumn get imagePath => text().nullable()();
}
