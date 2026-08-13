import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Poppins for English UI text; Noto Sans JP is kept only as a glyph
/// fallback so Japanese words (kanji/kana) still render correctly wherever
/// they appear (dictionary, decks, review).
TextTheme buildAppTextTheme(Brightness brightness) {
  final color = brightness == Brightness.light
      ? const Color(0xFF15151A)
      : const Color(0xFFF7F3EA);

  return GoogleFonts.poppinsTextTheme().apply(
    bodyColor: color,
    displayColor: color,
    fontFamilyFallback: [GoogleFonts.notoSansJp().fontFamily!],
  );
}
