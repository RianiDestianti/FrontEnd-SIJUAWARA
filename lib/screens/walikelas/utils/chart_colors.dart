import 'package:flutter/material.dart';

class ChartColors {

  static const List<Color> apresiasiGradient = [Color(0xFF61B8FF), Color(0xFF0083EE)];
  static const List<Color> apresiasiPie = [
    Color(0xFF61B8FF), Color(0xFF0083EE), Color(0xFF3B82F6),
    Color(0xFF1E40AF), Color(0xFF1E3A8A),
  ];


  static const List<Color> pelanggaranGradient = [Color(0xFFFF6B6D), Color(0xFFFF8E8F)];
  static const List<Color> pelanggaranPie = [
    Color(0xFFFF6B6D), Color(0xFFFF8E8F), Color(0xFFEF4444),
    Color(0xFFDC2626), Color(0xFFB91C1C),
  ];

  static const Color textPrimary   = Color(0xFF1F2937);
  static const Color textMuted     = Color(0xFF6B7280);
  static const Color textFaint     = Color(0xFF9CA3AF);
  static const Color surface       = Color(0xFFF8FAFC);
  static const Color card          = Colors.white;
  static const Color border        = Color(0xFFE5E7EB);
  static const Color cardBg        = Color(0xFFF8FAFC);


  static const Color statBlue      = Color(0xFF0083EE);
  static const Color statGreen     = Color(0xFF10B981);
  static const Color statGold      = Color(0xFFFFD700);

  static List<Color> gradient(String chartType) =>
      chartType == 'apresiasi' ? apresiasiGradient : pelanggaranGradient;

  static List<Color> pieColors(String chartType) =>
      chartType == 'apresiasi' ? apresiasiPie : pelanggaranPie;

  static Color base(String chartType) =>
      chartType == 'apresiasi' ? const Color(0xFF0083EE) : const Color(0xFFFF6B6D);
}