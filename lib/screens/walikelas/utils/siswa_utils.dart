import 'package:flutter/material.dart';
import 'package:skoring/models/api/api_student.dart';
import 'package:skoring/models/api/api_class.dart';

class SiswaUtils {
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Aman':
        return const Color(0xFF10B981);
      case 'Bermasalah':
        return const Color(0xFFEA580C);
      case 'Prioritas':
        return const Color(0xFFFF6B6D);
      default:
        return const Color(0xFF0083EE);
    }
  }

  static List<Student> filterStudents({
    required List<Student> students,
    required Kelas? selectedKelas,
    required int selectedFilter,
    required String searchQuery,
  }) {
    if (selectedKelas == null) return [];

    List<Student> filtered = students
        .where((s) => s.idKelas == selectedKelas.idKelas)
        .toList();

    if (selectedFilter == 1) {
      filtered = filtered.where((s) => (s.poinApresiasi ?? 0) > 0).toList();
    } else if (selectedFilter == 2) {
      filtered = filtered.where((s) => (s.poinPelanggaran ?? 0) > 0).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.namaSiswa.toLowerCase().contains(q) ||
            s.nis.toString().contains(searchQuery);
      }).toList();
    }

    return filtered;
  }

  static int getDisplayPoints(Student student, int selectedFilter) {
    if (selectedFilter == 1) return student.poinApresiasi ?? 0;
    if (selectedFilter == 2) return (student.poinPelanggaran ?? 0).abs();
    return student.points;
  }

  static String getPointLabel(int selectedFilter) {
    if (selectedFilter == 1) return 'Penghargaan';
    if (selectedFilter == 2) return 'Pelanggaran';
    return 'Poin';
  }

  static Color getPointColor(Student student, int selectedFilter) {
    if (selectedFilter == 1) return const Color(0xFF10B981);
    if (selectedFilter == 2) return const Color(0xFFFF6B6D);
    return student.points >= 0
        ? const Color(0xFF10B981)
        : const Color(0xFFFF6B6D);
  }
}