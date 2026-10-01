import 'package:flutter/material.dart';

/// Token warna desain baru (seruma.pen). Semua layar mengambil warna dari sini.
class AppColors {
  AppColors._();

  // Teks
  static const Color ink = Color(0xFF15201D);
  static const Color muted = Color(0xFF5B6864);
  static const Color faint = Color(0xFF8A9793);

  // Aksen per pilar: jade untuk urusan dan uang, amber untuk peringatan, rose untuk Kita.
  // Pasangan "Soft" adalah pastel solid untuk latar ikon, chip, dan sorotan.
  static const Color jade = Color(0xFF2C6B5A);
  static const Color jadeSoft = Color(0xFFDDF0E6);
  static const Color amber = Color(0xFFC06E28);
  static const Color amberSoft = Color(0xFFFCE6D2);
  static const Color rose = Color(0xFFB9536B);
  static const Color roseSoft = Color(0xFFFADFE6);

  // Pastel tambahan supaya tiap amplop dan dompet punya warnanya sendiri.
  static const Color lilac = Color(0xFF6E58B5);
  static const Color lilacSoft = Color(0xFFE8E2F8);
  static const Color sky = Color(0xFF3A72A8);
  static const Color skySoft = Color(0xFFDCEBFA);
  static const Color butter = Color(0xFF9A7414);
  static const Color butterSoft = Color(0xFFFBEFC8);

  // Permukaan kaca
  static const Color glass = Color(0xA8FFFFFF);
  static const Color glassStrong = Color(0xD9FFFFFF);
  static const Color glassEdge = Color(0xE6FFFFFF);
  static const Color hairline = Color(0x1415201D);
  static const Color track = Color(0x1215201D);
  static const Color fieldFill = Color(0x0815201D);

  // Latar
  static const Color background = Color(0xFFF1F2EC);
  static const Color blobMint = Color(0xFFCFE8DC);
  static const Color blobPeach = Color(0xFFF6DCCB);
  static const Color blobLilac = Color(0xFFE4DDF1);

  // Gradasi kartu utama
  static const List<Color> jadeGradient = [Color(0xFF1F5446), Color(0xFF2C6B5A), Color(0xFF3D8270)];
  static const List<Color> roseGradient = [Color(0xFF8E3F52), Color(0xFFB9536B)];
  static const List<Color> amberGradient = [Color(0xFFB8702C), Color(0xFFD9934F)];
  static const List<Color> warmGradient = [Color(0xFFF7E3D2), Color(0xFFF3D9DF)];
}
