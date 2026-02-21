import 'package:flutter/material.dart';

class NotifColors {
  static const Color primary     = Color(0xFF0083EE);
  static const Color primaryLight = Color(0xFF61B8FF);
  static const Color danger      = Color(0xFFFF6B6D);
  static const Color dangerDark  = Color(0xFFEA580C);
  static const Color success     = Color(0xFF10B981);
  static const Color bk          = Color(0xFF3B82F6);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textMuted   = Color(0xFF6B7280);
  static const Color textFaint   = Color(0xFF9CA3AF);
  static const Color border      = Color(0xFFE5E7EB);
  static const Color surface     = Color(0xFFF8FAFC);
  static const Color card        = Colors.white;

  static List<Color> headerGradient(String status) => status == 'Aman'
      ? [primaryLight, primary]
      : [danger, dangerDark];

  static Color headerShadow(String status) =>
      status == 'Aman' ? const Color(0x200083EE) : const Color(0x20FF6B6D);

  static String resolveStatus(List items) {
    final hasUrgent = items.any((n) => n.statusChange != 'Dalam Bimbingan');
    return hasUrgent ? 'Bermasalah' : 'Aman';
  }
}