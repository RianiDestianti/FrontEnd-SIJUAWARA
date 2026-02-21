import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/detail_colors.dart';

class StudentProfileHeader extends StatelessWidget {
  final String name;
  final String kelas;
  final String programKeahlian;
  final VoidCallback onBeriPoin;
  final VoidCallback onPenanganan;

  const StudentProfileHeader({
    Key? key,
    required this.name,
    required this.kelas,
    required this.programKeahlian,
    required this.onBeriPoin,
    required this.onPenanganan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _avatar(),
          const SizedBox(height: 16),
          _nameSection(),
          const SizedBox(height: 20),
          _actionButtons(),
        ],
      ),
    );
  }

  Widget _avatar() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.avatarBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.avatarFg.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.avatarFg,
            ),
          ),
        ),
      );

  Widget _nameSection() => Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$kelas · $programKeahlian',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      );

  Widget _actionButtons() => Row(
        children: [
          Expanded(
            child: _GradientButton(
              label: 'Berikan Poin',
              icon: Icons.star_outline_rounded,
              colors: const [AppColors.primaryLight, AppColors.primary],
              shadowColor: AppColors.primary,
              onTap: onBeriPoin,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GradientButton(
              label: 'Penanganan',
              icon: Icons.note_add_outlined,
              colors: const [AppColors.danger, AppColors.dangerDark],
              shadowColor: AppColors.danger,
              onTap: onPenanganan,
            ),
          ),
        ],
      );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final Color shadowColor;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}