import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/api/api_report.dart';

class LaporanCardWidgets {
  static Widget buildStudentCard({
    required Student student,
    required VoidCallback onTap,
  }) {
    final double total = (student.apresiasi + student.pelanggaran).toDouble();
    final double apresiasiRatio = total > 0 ? student.apresiasi / total : 0;
    final double pelanggaranRatio = total > 0 ? student.pelanggaran / total : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: student.isPositive
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : const Color(0xFFFF6B6D).withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFFEDBCC), borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: Text(student.avatar,
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('A: ${student.apresiasi}',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
                      Text('  •  ', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFD1D5DB))),
                      Text('P: ${student.pelanggaran}',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFFF6B6D))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 5,
                      color: const Color(0xFFF3F4F6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: (apresiasiRatio * 100).toInt().clamp(0, 100),
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          Expanded(
                            flex: (pelanggaranRatio * 100).toInt().clamp(0, 100),
                            child: Container(color: const Color(0xFFFF6B6D)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${student.totalPoin}',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: student.color)),
                Text('Total Poin',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937))),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  static Widget buildProgressCard({
    required String title,
    required String percentage,
    required double progress,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
              ),
              const SizedBox(width: 8),
              Text(percentage,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 8,
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildFilterAndDownloadRow({
    required String filterLabel,
    required VoidCallback onFilter,
    required VoidCallback onExport,
    required BoxConstraints constraints,
  }) {
    final isCompact = constraints.maxWidth < 360;

    final filterButton = GestureDetector(
      onTap: onFilter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(filterLabel, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );

    final downloadButton = GestureDetector(
      onTap: onExport,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Icon(Icons.download_rounded, color: Color(0xFF374151), size: 20),
      ),
    );

    final title = Text('Hasil Akumulasi', maxLines: 1, overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)));

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 12),
          Row(children: [Expanded(child: filterButton), const SizedBox(width: 8), downloadButton]),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
          child: filterButton,
        ),
        const SizedBox(width: 8),
        downloadButton,
      ],
    );
  }

  static Widget buildStudentDetailSheet({
    required Student student,
    required String? kelasName,
    required VoidCallback onClose,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: const Color(0xFFFEDBCC), borderRadius: BorderRadius.circular(18)),
                child: Center(
                  child: Text(student.avatar,
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937))),
                    Text(kelasName ?? '',
                        style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: student.isPositive
                  ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)])
                  : const LinearGradient(colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('${student.totalPoin}', 'Total Poin'),
                Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
                _statItem('${student.apresiasi}', 'Apresiasi'),
                Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
                _statItem('${student.pelanggaran}', 'Pelanggaran'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withValues(alpha: 0.9))),
      ],
    );
  }

  static Widget buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0083EE))),
          const SizedBox(height: 20),
          Text('Memuat data...',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
        ],
      ),
    );
  }

  static Widget buildErrorState(String? message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6D).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Color(0xFFFF6B6D), size: 36),
          ),
          const SizedBox(height: 16),
          Text('Gagal memuat data',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(message ?? 'Terjadi kesalahan tidak diketahui',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }

  static Widget buildEmptyState({
    required String title,
    required String subtitle,
    required VoidCallback onReset,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF0083EE).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF61B8FF), Color(0xFF0083EE)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF0083EE).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.person_search_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937))),
          const SizedBox(height: 6),
          SizedBox(
            width: 200,
            child: Text(subtitle, textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.6)),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF61B8FF), Color(0xFF0083EE)]),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0083EE).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 8),
                  Text('Reset Filter',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}