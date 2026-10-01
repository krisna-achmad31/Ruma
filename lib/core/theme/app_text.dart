import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Tipografi: Bricolage Grotesque untuk judul dan angka besar, Figtree untuk teks.
class AppText {
  AppText._();

  static TextStyle display(double size, {Color color = AppColors.ink, double letterSpacing = -0.6, double? height}) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double letterSpacing = 0,
    FontStyle? style,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.figtree(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: style,
      decoration: decoration,
    );
  }

  static TextStyle largeTitle = display(34, letterSpacing: -0.8);
  static TextStyle sectionTitle = display(20, letterSpacing: -0.3);
  static TextStyle navTitle = body(16, weight: FontWeight.w700);
  static TextStyle eyebrow(Color color) => body(11, weight: FontWeight.w700, color: color, letterSpacing: 1.2);
}
