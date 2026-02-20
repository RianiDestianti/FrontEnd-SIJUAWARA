import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/api/api_class.dart';
import 'package:skoring/models/api/api_student.dart';

class SiswaHeaderWidgets {
  static Widget buildHeaderContent({
    required bool isLoading,
    required bool hasError,
    required String? errorMessage,
    required Kelas? selectedKelas,
    required List<Student> studentsList,
  }) {
    if (isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Memuat data...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Gagal memuat data dari server',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    if (selectedKelas != null) {
      final studentsInClass = studentsList
          .where((s) => s.idKelas == selectedKelas.idKelas)
          .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Siswa ${selectedKelas.namaKelas}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${selectedKelas.jurusan.toUpperCase()}',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$studentsInClass siswa • Ganjil 2025/2026',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      'Tidak ada kelas terkait',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static Widget buildSearchBar({
    required TextEditingController controller,
    required String searchQuery,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama siswa atau NIS...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 16),
              ),
            ),
        ],
      ),
    );
  }

  static Widget buildFilterButton({
    required String text,
    required int index,
    required int selectedFilter,
    required VoidCallback onTap,
  }) {
    final bool isActive = selectedFilter == index;

    final dotGradients = [
      const [Color(0xFF61B8FF), Color(0xFF0083EE)],
      const [Color(0xFFFFD700), Color(0xFFFFA500)],
      const [Color(0xFFEA580C), Color(0xFFFF6B6D)],
    ];

    final activeTextColors = [
      const Color(0xFF1F2937),
      const Color(0xFFB45309),
      const Color(0xFFEA580C),
    ];

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: dotGradients[index]),
                    shape: BoxShape.circle,
                  ),
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isActive ? activeTextColors[index] : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildTopBar({
    required VoidCallback onNotificationTap,
    required VoidCallback onProfileTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40, height: 40),
        Row(
          children: [
            GestureDetector(
              onTap: onNotificationTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF0083EE),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}