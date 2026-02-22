import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/walikelas/services/login_service.dart';
import '../screens/walikelas/services/biometric_service.dart';
import 'nav_widgets.dart';

class LoginOverlay extends StatelessWidget {
  final AnimationController loginController;
  final Animation<double> loginFadeAnimation;
  final Animation<Offset> loginSlideAnimation;
  final VoidCallback onClose;

  const LoginOverlay({
    super.key,
    required this.loginController,
    required this.loginFadeAnimation,
    required this.loginSlideAnimation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loginController,
      builder: (context, _) => Stack(
        children: [
          FadeTransition(
            opacity: loginFadeAnimation,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
              ),
            ),
          ),
          SlideTransition(
            position: loginSlideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LoginForm(onClose: onClose),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login sheet ──────────────────────────────────────────────────────────────

class LoginForm extends StatefulWidget {
  final VoidCallback onClose;

  const LoginForm({super.key, required this.onClose});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _nipCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _pwdVisible = false;
  bool _biometricAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    BiometricService.isAvailable()
        .then((v) => mounted ? setState(() => _biometricAvailable = v) : null);
  }

  @override
  void dispose() {
    _nipCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _handleLogin({String? nip, String? password}) async {
    final resolvedNip = nip ?? _nipCtrl.text.trim();
    final resolvedPwd = password ?? _pwdCtrl.text.trim();

    if (resolvedNip.isEmpty || resolvedPwd.isEmpty) {
      _snack('Harap isi NIP dan password');
      return;
    }

    setState(() => _isLoading = true);
    final result = await LoginService.login(resolvedNip, resolvedPwd);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      _snack(result.message ?? 'Gagal masuk');
      return;
    }

    _navigateByRole(result.role ?? '');
  }

  Future<void> _handleBiometricLogin() async {
    final creds = await LoginService.getSavedCredentials();
    if (creds == null) {
      _snack('Belum ada data login tersimpan. Masuk manual dulu.');
      return;
    }

    final didAuth = await BiometricService.authenticate();
    if (!didAuth || !mounted) return;

    await _handleLogin(nip: creds.nip, password: creds.password);
  }

  void _navigateByRole(String role) {
    if (!mounted) return;
    if (role == '3') {
      Navigator.pushNamedAndRemoveUntil(context, '/walikelas', (_) => false);
    } else if (role == '4') {
      Navigator.pushNamedAndRemoveUntil(context, '/kaprog', (_) => false);
    } else {
      _snack('Role tidak dikenali');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = screenWidth > 800;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isWeb ? 500 : double.infinity,
        maxHeight: screenHeight * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HandleBar(onTap: widget.onClose),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 32.0 : 24.0),
              child: Column(
                children: [
                  SizedBox(height: isWeb ? 32 : 20),
                  LoginHeader(isWeb: isWeb),
                  SizedBox(height: isWeb ? 48 : 40),
                  LoginTextField(
                    hintText: 'Masukkan NIP anda',
                    icon: Icons.person_outline,
                    controller: _nipCtrl,
                    isWeb: isWeb,
                  ),
                  SizedBox(height: isWeb ? 24 : 20),
                  LoginTextField(
                    hintText: 'Masukkan password anda',
                    icon: Icons.lock_outline,
                    obscureText: !_pwdVisible,
                    suffixIcon: _pwdVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    controller: _pwdCtrl,
                    isWeb: isWeb,
                    onSuffixIconTap: () =>
                        setState(() => _pwdVisible = !_pwdVisible),
                  ),
                  SizedBox(height: isWeb ? 32 : 24),
                  if (_biometricAvailable) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          backgroundColor: const Color(0xFFE0F2FE),
                          foregroundColor: const Color(0xFF1D4ED8),
                        ),
                        icon: const Icon(Icons.fingerprint, size: 20),
                        label: Text(
                          'Masuk dengan Sidik Jari',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: isWeb ? 15 : 14),
                        ),
                        onPressed: _handleBiometricLogin,
                      ),
                    ),
                    SizedBox(height: isWeb ? 20 : 16),
                  ],
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: CircularProgressIndicator(),
                    )
                  else
                    GradientButton(
                      text: 'Masuk',
                      onTap: () => _handleLogin(),
                      isWeb: isWeb,
                    ),
                  SizedBox(height: isWeb ? 24 : 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Handle bar (drag indicator) ─────────────────────────────────────────────

class HandleBar extends StatelessWidget {
  final VoidCallback onTap;

  const HandleBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 50,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─── Login sheet header ───────────────────────────────────────────────────────

class LoginHeader extends StatelessWidget {
  final bool isWeb;

  const LoginHeader({super.key, required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isWeb ? 120 : 100,
          height: isWeb ? 120 : 100,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Image.asset('assets/smkn.png', fit: BoxFit.contain),
          ),
        ),
        SizedBox(width: isWeb ? 24 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang Kembali',
                style: GoogleFonts.poppins(
                  fontSize: isWeb ? 26 : 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: isWeb ? 12 : 8),
              Text(
                'Yuk, lanjutkan aktivitasmu di SIJUWARA (SISTEM JURNAL SISWA AKTIF)!',
                style: GoogleFonts.poppins(
                  fontSize: isWeb ? 16 : 13,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Styled text field ────────────────────────────────────────────────────────

class LoginTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final IconData? suffixIcon;
  final TextEditingController? controller;
  final bool isWeb;
  final VoidCallback? onSuffixIconTap;

  const LoginTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.controller,
    required this.isWeb,
    this.onSuffixIconTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
              fontSize: isWeb ? 16 : 14, color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          suffixIcon: suffixIcon != null
              ? GestureDetector(
                  onTap: onSuffixIconTap,
                  child: Icon(suffixIcon, color: Colors.grey[400]),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isWeb ? 20 : 16,
          ),
        ),
      ),
    );
  }
}