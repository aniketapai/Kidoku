import 'package:flutter/material.dart';

/// "Ai to Shu" (indigo & vermillion) palette — see steps.md section 0.
abstract final class AppColors {
  static const primaryLight = Color(0xFF2D3E63);
  static const primaryDark = Color(0xFF8FA8D8);

  static const onPrimaryLight = Color(0xFFFFFFFF);
  static const onPrimaryDark = Color(0xFF0F1729);

  static const secondaryLight = Color(0xFFE6553D);
  static const secondaryDark = Color(0xFFFF7A61);

  static const backgroundLight = Color(0xFFF7F3EA);
  static const backgroundDark = Color(0xFF15151A);

  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1E24);

  static const surfaceVariantLight = Color(0xFFEDE7D9);
  static const surfaceVariantDark = Color(0xFF26262E);
}

/// JLPT level tag colors, same across light/dark per spec.
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
