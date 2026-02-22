import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/profile.dart';
import '../services/profile_service.dart';

// ─── Top app bar ──────────────────────────────────────────────────────────────

class ProfileAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const ProfileAppBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final iconSize = w * 0.11;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, 16, w * 0.05, 32),
      child: Row(
        children: [
          _BackButton(size: iconSize, onTap: onBack),
          const Spacer(),
          Text(
            'Profil Saya',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: w * 0.05,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          SizedBox(width: iconSize),
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
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: size * 0.45,
          ),
        ),
      );
}

// ─── Avatar + name + role badge ───────────────────────────────────────────────

class ProfileHeader extends StatelessWidget {
  final Profile profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final avatarSize = w * 0.2;
    final padding = w * 0.06;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF61B8FF).withOpacity(0.05),
            const Color(0xFF0083EE).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(padding * 0.75),
        border: Border.all(color: const Color(0xFF61B8FF).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _Avatar(size: avatarSize, name: profile.name),
          SizedBox(width: padding * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: GoogleFonts.poppins(
                    fontSize: w * 0.055,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: padding * 0.2),
                _RoleBadge(role: profile.role, padding: padding),
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
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0] : 'U',
                style: GoogleFonts.poppins(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(size * 0.175),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.check_rounded,
                  color: Colors.white, size: size * 0.2),
            ),
          ),
        ],
      );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final double padding;
  const _RoleBadge({required this.role, required this.padding});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: padding * 0.4, vertical: padding * 0.2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF61B8FF), Color(0xFF0083EE)]),
          borderRadius: BorderRadius.circular(padding * 0.4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0083EE).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          role,
          style: GoogleFonts.poppins(
            fontSize: MediaQuery.of(context).size.width * 0.032,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      );
}

// ─── Individual info card ─────────────────────────────────────────────────────

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
    final padding = w * 0.05;
    final iconSize = w * 0.12;

    return Container(
      margin: EdgeInsets.only(bottom: padding * 0.4),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 600 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, v, _) => Opacity(
          opacity: v,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(padding * 0.9),
              border: Border.all(
                  color: const Color(0xFF61B8FF).withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _FieldIcon(size: iconSize, icon: icon),
                SizedBox(width: padding * 0.4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.poppins(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          )),
                      SizedBox(height: padding * 0.15),
                      Text(value,
                          style: GoogleFonts.poppins(
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          )),
                    ],
                  ),
                ),
                Container(
                  width: iconSize * 0.67,
                  height: iconSize * 0.67,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(iconSize * 0.2),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldIcon extends StatelessWidget {
  final double size;
  final IconData icon;
  const _FieldIcon({required this.size, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF61B8FF).withOpacity(0.1),
              const Color(0xFF0083EE).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(
              color: const Color(0xFF61B8FF).withOpacity(0.1)),
        ),
        child: Icon(icon, color: const Color(0xFF0083EE), size: size * 0.46),
      );
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
    final w = MediaQuery.of(context).size.width;
    final padding = w * 0.06;

    return GestureDetector(
      onTapDown: (_) => controller.forward(),
      onTapUp: (_) => controller.reverse(),
      onTapCancel: () => controller.reverse(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Transform.scale(
          scale: 1.0 - (controller.value * 0.05),
          child: Container(
            width: double.infinity,
            height: w * 0.14,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.1),
                  const Color(0xFFFF8E8E).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(padding * 0.5),
              border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(padding * 0.5),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: const Color(0xFFFF6B6B), size: w * 0.065),
                      SizedBox(width: padding * 0.3),
                      Text('Keluar',
                          style: GoogleFonts.poppins(
                            fontSize: w * 0.04,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                            letterSpacing: 0.5,
                          )),
                    ],
                  ),
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
    Navigator.pop(context); // close dialog
    widget.onLogout();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Konfirmasi Keluar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin keluar?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text('Batal',
                style: GoogleFonts.poppins(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Keluar',
                    style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      );
}