import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/profile.dart';
import 'services/profile_service.dart';
import 'widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _btnCtrl;
  late final Animation<double> _fadeAnim;

  Profile? _profile;
  bool _isLoading = true;
  String? _error;

  // ─── Fields to display ────────────────────────────────────────────────────

  static const _fields = [
    _ProfileField(label: 'NIP', icon: Icons.badge_outlined, key: 'nip'),
    _ProfileField(label: 'Nama Pengguna', icon: Icons.person_outline, key: 'username'),
    _ProfileField(label: 'Email', icon: Icons.email_outlined, key: 'email'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ProfileService.loadProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat profil: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LogoutDialog(onLogout: _onLoggedOut),
    );
  }

  void _onLoggedOut() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!,
              style: GoogleFonts.poppins(color: Colors.white)));
    }
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          ProfileAppBar(onBack: () => Navigator.pop(context)),
          if (_profile != null)
            Expanded(child: _ProfileSheet(
              profile: _profile!,
              fields: _fields,
              onLogoutTap: _showLogoutDialog,
              btnCtrl: _btnCtrl,
            )),
        ],
      ),
    );
  }
}

// ─── White sheet with scrollable content ─────────────────────────────────────

class _ProfileSheet extends StatelessWidget {
  final Profile profile;
  final List<_ProfileField> fields;
  final VoidCallback onLogoutTap;
  final AnimationController btnCtrl;

  const _ProfileSheet({
    required this.profile,
    required this.fields,
    required this.onLogoutTap,
    required this.btnCtrl,
  });

  String _value(_ProfileField field) => switch (field.key) {
        'nip' => profile.nip,
        'username' => profile.username,
        'email' => profile.email,
        'joinDate' => profile.joinDate,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).size.width * 0.07;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
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
                  children: fields
                      .asMap()
                      .entries
                      .map((e) => ProfileFieldCard(
                            label: e.value.label,
                            value: _value(e.value),
                            icon: e.value.icon,
                            index: e.key,
                          ))
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: padding * 0.8),
            LogoutButton(onTap: onLogoutTap, controller: btnCtrl),
          ],
        ),
      ),
    );
  }
}

// ─── Field descriptor (replaces public ProfileField to keep it internal) ─────

class _ProfileField {
  final String label;
  final IconData icon;
  final String key;
  const _ProfileField({required this.label, required this.icon, required this.key});
}