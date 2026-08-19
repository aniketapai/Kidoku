import 'package:flutter/material.dart';

/// Dark-only fintech-inspired palette (near-black + warm cream accent +
/// mint green). The app has no light mode, so there's a single set of
/// colors rather than light/dark pairs.
abstract final class AppColors {
  static const primary = Color(0xFFEAE3CC);
  static const onPrimary = Color(0xFF17171A);

  static const secondary = Color(0xFF8FE3C0);
  static const onSecondary = Color(0xFF0F1F1A);

  static const background = Color(0xFF17171A);
  static const onBackground = Color(0xFFF5F4EF);

  static const surface = Color(0xFF201F24);
  static const surfaceVariant = Color(0xFF2B2A30);

  static const error = Color(0xFFE2554A);
}

/// JLPT level tag colors — a separate accent system for badges, unrelated
/// to the app's primary/secondary theme colors.
abstract final class JlptColors {
  static const n5 = Color(0xFF4C9A6E);
  static const n4 = Color(0xFF5B8FD4);
  static const n3 = Color(0xFFD4A64C);
  static const n2 = Color(0xFFD47A4C);
  static const n1 = Color(0xFFC4514C);

  static const _byLevel = {
    'N5': n5,
    'N4': n4,
    'N3': n3,
    'N2': n2,
    'N1': n1,
  };

  static Color forLevel(String? level) =>
      _byLevel[level] ?? const Color(0xFF9E9E9E);
}
