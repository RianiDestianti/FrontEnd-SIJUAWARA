import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Page dot indicators + Next button ───────────────────────────────────────

class BottomNavigation extends StatelessWidget {
  final int currentPage;
  final int pagesLength;
  final VoidCallback onNext;

  const BottomNavigation({
    super.key,
    required this.currentPage,
    required this.pagesLength,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Container(
      padding: EdgeInsets.all(isWeb ? 40.0 : 24.0),
      constraints: BoxConstraints(maxWidth: isWeb ? 400 : double.infinity),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pagesLength, (i) {
              final active = currentPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF0083EE)
                      : const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          SizedBox(height: isWeb ? 32 : 24),
          GradientButton(text: 'Lanjut', onTap: onNext, isWeb: isWeb),
        ],
      ),
    );
  }
}

// ─── Skip button (top-right overlay) ─────────────────────────────────────────

class SkipButton extends StatelessWidget {
  final VoidCallback onSkip;

  const SkipButton({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Positioned(
      top: MediaQuery.of(context).padding.top + (isWeb ? 24 : 16),
      right: isWeb ? 40 : 16,
      child: GestureDetector(
        onTap: onSkip,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 20 : 16,
            vertical: isWeb ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF61B8FF).withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0083EE).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Lewati',
            style: GoogleFonts.poppins(
              fontSize: isWeb ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0083EE),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable gradient CTA button ────────────────────────────────────────────

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isWeb;

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.isWeb,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isWeb ? 20 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0083EE).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}