const _kMonthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Aug 17, 2026, 3:04 PM" — no `intl` dependency in this project, so this
/// mirrors the manual month-abbreviation approach already used by
/// profile_header_card.dart/activity_heatmap.dart.
String formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour < 12 ? 'AM' : 'PM';
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_kMonthAbbreviations[local.month - 1]} ${local.day}, ${local.year}, $hour12:$minute $period';
}
