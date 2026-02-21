import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/api/api_detail.dart';
import '../utils/detail_colors.dart';

class AkumulasiCard extends StatelessWidget {
  final AccumulationHistory item;

  const AkumulasiCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: 16),
          _statRow(),
          const SizedBox(height: 14),
          _progressBar(),
        ],
      ),
    );
  }

  Widget _header() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.periode,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.date,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );

  Widget _statRow() => Row(
        children: [
          _statBox(
            label: 'Pelanggaran',
            value: '-${item.pelanggaran}',
            color: AppColors.danger,
            icon: Icons.trending_down_rounded,
          ),
          const SizedBox(width: 10),
          _statBox(
            label: 'Apresiasi',
            value: '+${item.apresiasi}',
            color: AppColors.success,
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(width: 10),
          _statBox(
            label: 'Total',
            value: '${item.total > 0 ? '+' : ''}${item.total}',
            color: AppColors.primary,
            icon: Icons.calculate_rounded,
          ),
        ],
      );

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _progressBar() {
    final total = item.apresiasi + item.pelanggaran;
    final redFrac = total > 0 ? item.pelanggaran / total : 0.0;
    final greenFrac = total > 0 ? item.apresiasi / total : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 8,
        color: AppColors.bgLight,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: redFrac * c.maxWidth,
                height: 8,
                color: AppColors.danger,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  width: greenFrac * c.maxWidth,
                  height: 8,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}