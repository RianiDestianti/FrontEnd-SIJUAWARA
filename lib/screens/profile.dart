import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:skoring/models/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  Profile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadProfile().then((_) => _animationController.forward());
  }

Future<void> _loadProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final nip = prefs.getString('walikelas_id') ?? 'Unknown';
    final role = prefs.getString('role') ?? 'Unknown';
    final name = prefs.getString('name') ?? 'Unknown';
    final email = prefs.getString('email') ?? 'Unknown';
    final joinDate = prefs.getString('joinDate') ?? 'Unknown';

    String roleLabel = role == '3'
        ? 'Wali Kelas'
        : role == '4'
            ? 'Kaprog'
            : 'Unknown';

    setState(() {
      _profile = Profile(
        name: name,
        role: roleLabel,
        nip: nip,
        username: name,
        email: email,
        joinDate: joinDate,
      );
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Gagal memuat profil: $e';
      _isLoading = false;
    });
  }
}
  @override
  void dispose() {
    _animationController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) =>
          LogoutDialog(
            onLogout: _handleLogoutSuccess,
            parentContext: context, 
          ),
    );
  }

  void _handleLogoutSuccess() {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0083EE)),
            )
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    top: true,
                    bottom: false,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          HeaderSection(onBack: () => Navigator.pop(context)),
                          if (_profile != null)
                            Expanded(
                              child: ProfileContentSection(
                                profile: _profile!,
                                profileFields: _getProfileFields(_profile!.role),
                                onLogoutTap: _showLogoutDialog,
                                buttonController: _buttonController,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  List<ProfileField> _getProfileFields(String role) {
    return [
      ProfileField(label: 'NIP', icon: Icons.badge_outlined, key: 'nip'),
      ProfileField(
        label: 'Nama Pengguna',
        icon: Icons.person_outline,
        key: 'username',
      ),
      ProfileField(label: 'Email', icon: Icons.email_outlined, key: 'email'),
    ];
  }
}

class HeaderSection extends StatelessWidget {
  final VoidCallback onBack;
  const HeaderSection({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05;
    final iconSize = screenWidth * 0.11;
    final fontSize = screenWidth * 0.05;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(iconSize * 0.36),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: iconSize * 0.45,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Profil Saya',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: fontSize,
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

class ProfileContentSection extends StatelessWidget {
  final Profile profile;
  final List<ProfileField> profileFields;
  final VoidCallback onLogoutTap;
  final AnimationController buttonController;

  const ProfileContentSection({
    super.key,
    required this.profile,
    required this.profileFields,
    required this.onLogoutTap,
    required this.buttonController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.07;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            ProfileHeader(profile: profile),
            SizedBox(height: padding * 0.8),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: profileFields.asMap().entries.map((entry) {
                    int index = entry.key;
                    ProfileField field = entry.value;
                    return ProfileFieldCard(
                      label: field.label,
                      value: _getFieldValue(field.key, profile),
                      icon: field.icon,
                      index: index,
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: padding * 0.8),
            LogoutButton(
              onTap: onLogoutTap,
              buttonController: buttonController,
            ),
          ],
        ),
      ),
    );
  }

  String _getFieldValue(String key, Profile profile) {
    switch (key) {
      case 'nip':
        return profile.nip;
      case 'username':
        return profile.username;
      case 'email':
        return profile.email;
      case 'joinDate':
        return profile.joinDate;
      default:
        return '';
    }
  }
}

class ProfileHeader extends StatelessWidget {
  final Profile profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarSize = screenWidth * 0.2;
    final fontSize = screenWidth * 0.055;
    final roleFontSize = screenWidth * 0.032;
    final padding = screenWidth * 0.06;

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
        border: Border.all(
          color: const Color(0xFF61B8FF).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(avatarSize * 0.25),
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
                    profile.name.isNotEmpty ? profile.name[0] : 'U',
                    style: GoogleFonts.poppins(
                      fontSize: avatarSize * 0.35,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: avatarSize * 0.35,
                  height: avatarSize * 0.35,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(avatarSize * 0.175),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: avatarSize * 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: padding * 0.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: padding * 0.2),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 0.4,
                    vertical: padding * 0.2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                    ),
                    borderRadius: BorderRadius.circular(padding * 0.4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0083EE).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    profile.role,
                    style: GoogleFonts.poppins(
                      fontSize: roleFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05;
    final iconSize = screenWidth * 0.12;
    final fontSize = screenWidth * 0.04;
    final valueFontSize = screenWidth * 0.045;

    return Container(
      margin: EdgeInsets.only(bottom: padding * 0.4),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 600 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, animationValue, child) {
          return Opacity(
            opacity: animationValue,
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(padding * 0.9),
                border: Border.all(
                  color: const Color(0xFF61B8FF).withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0083EE).withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF61B8FF).withOpacity(0.1),
                          const Color(0xFF0083EE).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(iconSize * 0.3),
                      border: Border.all(
                        color: const Color(0xFF61B8FF).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF0083EE),
                      size: iconSize * 0.46,
                    ),
                  ),
                  SizedBox(width: padding * 0.4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: padding * 0.15),
                        Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            letterSpacing: 0.2,
                          ),
                        ),
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
                    child: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController buttonController;

  const LogoutButton({
    super.key,
    required this.onTap,
    required this.buttonController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenWidth * 0.14;
    final padding = screenWidth * 0.06;
    final fontSize = screenWidth * 0.04;
    final iconSize = screenWidth * 0.05;

    return GestureDetector(
      onTapDown: (_) => buttonController.forward(),
      onTapUp: (_) => buttonController.reverse(),
      onTapCancel: () => buttonController.reverse(),
      child: AnimatedBuilder(
        animation: buttonController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (buttonController.value * 0.05),
            child: Container(
              width: double.infinity,
              height: buttonHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B).withOpacity(0.1),
                    const Color(0xFFFF8E8E).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(padding * 0.5),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  width: 2,
                ),
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
                            color: const Color(0xFFFF6B6B), size: iconSize * 1.3),
                        SizedBox(width: padding * 0.3),
                        Text(
                          'Keluar',
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFF6B6B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LogoutDialog extends StatefulWidget {
  final VoidCallback onLogout;
  final BuildContext parentContext; 

  const LogoutDialog({
    super.key,
    required this.onLogout,
    required this.parentContext,
  });

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  bool _isLoggingOut = false;

Future<void> _logout() async {
  setState(() => _isLoggingOut = true);
  final prefs = await SharedPreferences.getInstance();
  final nip = prefs.getString('walikelas_id') ?? '';

  if (nip.isEmpty) {
    _showErrorSnackbar(widget.parentContext, 'Data guru tidak ditemukan.');
    if (mounted) setState(() => _isLoggingOut = false);
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://sijuwara.student.smkn11bdg.sch.id/api/logout?nip=$nip'),
      headers: {
        'Accept': 'application/json',
      },
    );

    print('Logout response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        await prefs.clear();
        widget.onLogout();
      } else {
        _showErrorSnackbar(
          widget.parentContext,
          data['message'] ?? 'Gagal keluar.',
        );
      }
    } else {
      final data = json.decode(response.body);
      _showErrorSnackbar(
        widget.parentContext,
        data['message'] ?? 'Gagal keluar.',
      );
    }
  } catch (e) {
    print('Logout error: $e');
    _showErrorSnackbar(widget.parentContext, 'Terjadi kesalahan: $e');
  } finally {
    if (mounted) setState(() => _isLoggingOut = false);
  }
}

  void _showErrorSnackbar(BuildContext parentContext, String message) {
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Konfirmasi Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: Text('Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins()),
      actions: [
        TextButton(
          onPressed: _isLoggingOut ? null : () => Navigator.pop(context),
          child: Text('Batal',
              style: GoogleFonts.poppins(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: _isLoggingOut ? null : _logout,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoggingOut
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Keluar',
                  style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }
}

class ProfileField {
  final String label;
  final IconData icon;
  final String key;
  ProfileField({required this.label, required this.icon, required this.key});
}
