import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/api/api_report.dart';
import 'package:skoring/screens/walikelas/notification.dart';
import 'package:skoring/screens/walikelas/profile.dart';

class LaporanHeaderWidgets {
  static Widget buildIconButtons(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF0083EE), size: 22),
          ),
        ),
      ],
    );
  }

  static Widget buildHeaderContent({
    required bool isLoading,
    required bool hasError,
    required String? errorMessage,
    required Kelas? selectedKelas,
    required int studentCount,
  }) {
    if (isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          ),
          const SizedBox(width: 12),
          Text('Memuat data...', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      );
    }

    if (hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Terjadi Kesalahan',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(errorMessage ?? 'Gagal memuat data',
              style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ],
      );
    }

    if (selectedKelas != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penilaian ${selectedKelas.namaKelas}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            selectedKelas.jurusan.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            '$studentCount siswa • Ganjil 2025/2026',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    return Text('Tidak ada kelas terkait',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600));
  }

  static Widget buildSearchBar({
    required TextEditingController controller,
    required String searchQuery,
    required String selectedView,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF61B8FF), Color(0xFF0083EE)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: selectedView == 'Rekap' ? 'Cari nama murid...' : 'Cari aturan atau poin...',
                hintStyle: GoogleFonts.poppins(color: const Color(0xFF9CA3AF), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1F2937)),
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.clear, color: Color(0xFF9CA3AF), size: 18),
            ),
        ],
      ),
    );
  }

  static Widget buildViewButton({
    required String text,
    required String view,
    required String selectedView,
    required VoidCallback onTap,
  }) {
    final bool isActive = selectedView == view;
    final Map<String, List<Color>> dotColors = {
      'Rekap':     [const Color(0xFF61B8FF), const Color(0xFF0083EE)],
      'Aspek Poin':[const Color(0xFF10B981), const Color(0xFF34D399)],
    };

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
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: dotColors[view] ?? [Colors.white, Colors.white]),
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: isActive ? const Color(0xFF1F2937) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}