import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/profile.dart';
import '../services/profile_service.dart';

// ─── App bar ──────────────────────────────────────────────────────────────────

class ProfileAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const ProfileAppBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final iconSize = w * 0.11;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, 12, w * 0.05, 24),
      child: Row(
        children: [
          _BackButton(size: iconSize, onTap: onBack),
          Expanded(
            child: Text(
              'Profil Saya',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: w * 0.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: iconSize), // balance spacer
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  const _BackButton({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(size * 0.36),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: size * 0.42),
        ),
      );
}

// ─── Profile header card ──────────────────────────────────────────────────────

class ProfileHeader extends StatelessWidget {
  final Profile profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final avatarSize = w * 0.18;
    final p = w * 0.04;

    return Container(
      padding: EdgeInsets.all(p),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF61B8FF).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          _Avatar(size: avatarSize, name: profile.name),
          SizedBox(width: p),
          // Expanded prevents long names from overflowing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                _RoleBadge(role: profile.role),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final double size;
  final String name;
  const _Avatar({required this.size, required this.name});

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.25),
              gradient: const LinearGradient(
                colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0083EE).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: GoogleFonts.poppins(
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -3,
            right: -3,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: Icon(Icons.check_rounded,
                  color: Colors.white, size: size * 0.18),
            ),
          ),
        ],
      );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF61B8FF), Color(0xFF0083EE)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          role,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
}

// ─── Info field card ──────────────────────────────────────────────────────────

class ProfileFieldCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int index;

  const ProfileFieldCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      color: const Color(0xFF0083EE), size: 20),
                ),
                const SizedBox(width: 14),
                // Label + value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          )),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: w * 0.038,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lock icon — fixed size, not inside a container
                const Icon(Icons.lock_outline,
                    color: Color(0xFFD1D5DB), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController controller;

  const LogoutButton({
    super.key,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) => controller.reverse(),
      onTapCancel: () => controller.reverse(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Transform.scale(
          scale: 1.0 - (controller.value * 0.04),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.4), width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: const Color(0xFFFF6B6B).withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded,
                        color: Color(0xFFFF4444), size: 20),
                    const SizedBox(width: 8),
                    Text('Keluar',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF4444),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logout confirmation dialog ───────────────────────────────────────────────

class LogoutDialog extends StatefulWidget {
  final VoidCallback onLogout;
  const LogoutDialog({super.key, required this.onLogout});

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    await ProfileService.logout();
    if (!mounted) return;
    Navigator.pop(context);
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Konfirmasi Keluar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?',
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.poppins(
                    color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Keluar',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      );
}