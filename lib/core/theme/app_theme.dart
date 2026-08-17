import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? AppColors.primaryLight : AppColors.primaryDark,
      onPrimary: isLight ? AppColors.onPrimaryLight : AppColors.onPrimaryDark,
      secondary: isLight ? AppColors.secondaryLight : AppColors.secondaryDark,
      onSecondary: isLight ? AppColors.onPrimaryLight : AppColors.onPrimaryDark,
      surface: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
      onSurface: isLight ? AppColors.backgroundDark : AppColors.backgroundLight,
      surfaceContainerHighest:
          isLight ? AppColors.surfaceVariantLight : AppColors.surfaceVariantDark,
      error: const Color(0xFFC4514C),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.backgroundLight : AppColors.backgroundDark,
      textTheme: buildAppTextTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      // Material 3's default Android transition (ZoomPageTransitionsBuilder)
      // fades/scales pages in and out, which reads as a "fade" on back
      // navigation. Use the plain slide transition on every platform
      // instead, so pushing/popping (e.g. out of Settings) just slides.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
