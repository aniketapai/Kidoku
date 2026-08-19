import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Poppins for English UI text; Noto Sans JP is kept only as a glyph
/// fallback so Japanese words (kanji/kana) still render correctly wherever
/// they appear (dictionary, decks, review).
TextTheme buildAppTextTheme() {
  return GoogleFonts.poppinsTextTheme().apply(
    bodyColor: AppColors.onBackground,
    displayColor: AppColors.onBackground,
    fontFamilyFallback: [GoogleFonts.notoSansJp().fontFamily!],
  );
}
