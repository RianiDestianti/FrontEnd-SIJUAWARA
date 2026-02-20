import 'package:flutter/material.dart';
import 'package:skoring/models/api/api_report.dart';

class LaporanUtils {
  static List<Student> filterAndSort({
    required List<Student> students,
    required Kelas? selectedKelas,
    required String selectedFilter,
    required String searchQuery,
  }) {
    if (selectedKelas == null) return [];

    List<Student> filtered = students.where((student) {
      if (student.idKelas != selectedKelas.idKelas) return false;
      if (!student.name.toLowerCase().contains(searchQuery.toLowerCase())) return false;

      final poin = student.totalPoin;
      switch (selectedFilter) {
        case '0-50':   return poin >= 0 && poin <= 50;
        case '51-100': return poin >= 51 && poin <= 100;
        case '101+':   return poin > 100;
        case 'Negatif': return poin < 0;
        default:       return true;
      }
    }).toList();

    filtered.sort((a, b) => b.totalPoin.compareTo(a.totalPoin));
    return filtered;
  }

  static double averageApresiasi(List<Student> students) {
    if (students.isEmpty) return 0;
    return students.fold(0.0, (sum, s) => sum + s.apresiasi) / students.length;
  }

  static double apresiasiPercentage(List<Student> students) {
    if (students.isEmpty) return 0;
    final totalA = students.fold<int>(0, (sum, s) => sum + s.apresiasi);
    final totalP = students.fold<int>(0, (sum, s) => sum + s.pelanggaran.abs());
    final total = totalA + totalP;
    return total == 0 ? 0 : totalA / total;
  }

  static double pelanggaranPercentage(List<Student> students) {
    if (students.isEmpty) return 0;
    final totalA = students.fold<int>(0, (sum, s) => sum + s.apresiasi);
    final totalP = students.fold<int>(0, (sum, s) => sum + s.pelanggaran.abs());
    final total = totalA + totalP;
    return total == 0 ? 0 : totalP / total;
  }

  static String filterDisplayLabel(String filter) {
    switch (filter) {
      case 'Negatif': return 'Nilai Negatif';
      case '101+':    return '101 ke atas';
      default:        return filter;
    }
  }

  static List<Map<String, dynamic>> mappedStudentsForExport(List<Student> students) {
    return students.map((s) => {
      'name': s.name,
      'nis': s.nis,
      'totalPoin': s.totalPoin,
      'apresiasi': s.apresiasi,
      'pelanggaran': s.pelanggaran,
      'isPositive': s.isPositive,
      'color': s.color,
      'avatar': s.avatar,
      'scores': s.scores.map((score) => {
        'keterangan': score.keterangan,
        'tanggal': score.tanggal,
        'poin': score.poin,
        'type': score.type,
      }).toList(),
    }).toList();
  }

  static Map<String, dynamic> spStatus(Student student) {
    final p = student.pelanggaran;
    if (p >= 76) return {'label': 'SP3 (>=76)',  'color': const Color(0xFF991B1B), 'bg': const Color(0xFFFEE2E2)};
    if (p >= 51) return {'label': 'SP2 (51-75)', 'color': const Color(0xFFB45309), 'bg': const Color(0xFFFDE68A)};
    if (p >= 25) return {'label': 'SP1 (25-50)', 'color': const Color(0xFF92400E), 'bg': const Color(0xFFF5D0FE)};
    return      {'label': 'Aman (<25)',   'color': const Color(0xFF047857), 'bg': const Color(0xFFD1FAE5)};
  }

  static Map<String, dynamic>? apresiasiBadge(Student student) {
    final a = student.apresiasi;
    if (a >= 151) return {'label': 'Anugerah Waluya Utama 151+', 'color': const Color(0xFF1D4ED8), 'bg': const Color(0xFFDBEAFE)};
    if (a >= 126) return {'label': 'Sertifikat+Hadiah 126-150',  'color': const Color(0xFF1D4ED8), 'bg': const Color(0xFFE0F2FE)};
    if (a >= 100) return {'label': 'Sertifikat 100-125',         'color': const Color(0xFF2563EB), 'bg': const Color(0xFFE0F2FE)};
    return null;
  }
}