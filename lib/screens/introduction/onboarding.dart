import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/introduction.dart';
import 'package:skoring/screens/introduction/swipeup.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:skoring/firebase/tokenfcm.dart';
import 'package:skoring/config/api.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => IntroductionScreenState();
}

class IntroductionScreenState extends State<IntroductionScreen>
    with TickerProviderStateMixin {
  late final AnimationController animationController;
  late final AnimationController swipeController;
  late final AnimationController loginController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;
  late final Animation<double> scaleAnimation;
  late final Animation<double> swipeAnimation;
  late final Animation<Offset> loginSlideAnimation;
  late final Animation<double> loginFadeAnimation;
  final PageController pageController = PageController();
  int currentPage = 0;
  double swipeOffset = 0.0;
  bool showLoginOverlay = false;

  final List<PageData> pages = [
    PageData(
      image: 'assets/batang.png',
      title: 'Selamat Datang di Sistem Skoring!',
      description:
          'Kelola pencatatan, penilaian, hingga laporan dalam satu aplikasi praktis.Nikmati kemudahan mengelola penilaian secara cepat.',
    ),
    PageData(
      image: 'assets/lingkaran.png',
      title: 'Penilaian Lebih Cepat & Akurat',
      description:
          'Tidak perlu hitung manual. Sistem kami memproses penilaian secara otomatis dan real-time.',
    ),
    PageData(
      image: 'assets/apk.png',
      title: 'Laporan Lengkap di Ujung Jari',
      description:
          'Pantau perkembangan, pelanggaran, dan apresiasi siswa melalui laporan interaktif yang mudah dibaca.',
    ),
    PageData(
      image: 'assets/backpack.png',
      title: 'SIJUAWARA',
      description:
          'Geser ke atas untuk masuk ke SIJUAWARA (SISTEM INFORMASI JURNAL SISWA AKTIF) dan kelola penilaian siswa dengan mudah!',
    ),
  ];

  @override
  void initState() {
    super.initState();
    initializeAnimations();
    pageController.addListener(updateCurrentPage);
    animationController.forward();
  }

  void initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    loginController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );
    scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic),
    );
    swipeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: swipeController, curve: Curves.easeOut));
    loginSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: loginController, curve: Curves.easeOutCubic),
    );
    loginFadeAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: loginController, curve: Curves.easeInOut),
    );
  }

  void updateCurrentPage() {
    setState(() {
      currentPage = pageController.page?.round() ?? 0;
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    swipeController.dispose();
    loginController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (currentPage < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipToFinalPage() {
    pageController.animateToPage(
      pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void showLogin() {
    setState(() => showLoginOverlay = true);
    loginController.forward();
  }

  void hideLogin() {
    loginController.reverse().then((unused) {
      setState(() => showLoginOverlay = false);
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    setState(() {
      if (details.delta.dy < 0) {
        swipeOffset += details.delta.dy;
      } else {
        swipeOffset = swipeOffset * 0.9;
      }
      swipeOffset = swipeOffset.clamp(-100.0, 0.0);
    });
  }

  void onPanEnd(DragEndDetails details) {
    if (swipeOffset < -50) {
      swipeController.forward().then((unused) {
        showLogin();
        swipeController.reset();
        setState(() => swipeOffset = 0.0);
      });
    } else {
      swipeController.reverse();
      setState(() => swipeOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor:
          currentPage == pages.length - 1
              ? const Color(0xFF1E6BB8)
              : Colors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: pages.length,
                    itemBuilder:
                        (context, index) =>
                            index == pages.length - 1
                                ? FinalPage(
                                  pageData: pages[index],
                                  scaleAnimation: scaleAnimation,
                                  fadeAnimation: fadeAnimation,
                                  swipeAnimation: swipeAnimation,
                                  swipeOffset: swipeOffset,
                                  onPanUpdate: onPanUpdate,
                                  onPanEnd: onPanEnd,
                                )
                                : RegularPage(
                                  pageData: pages[index],
                                  fadeAnimation: fadeAnimation,
                                  slideAnimation: slideAnimation,
                                  scaleAnimation: scaleAnimation,
                                ),
                  ),
                ),
                if (currentPage != pages.length - 1)
                  BottomNavigation(
                    currentPage: currentPage,
                    pagesLength: pages.length,
                    onNext: nextPage,
                  ),
              ],
            ),
            if (currentPage != pages.length - 1)
              SkipButton(onSkip: skipToFinalPage),
            if (showLoginOverlay)
              LoginOverlay(
                loginController: loginController,
                loginFadeAnimation: loginFadeAnimation,
                loginSlideAnimation: loginSlideAnimation,
                onClose: hideLogin,
                onLogin: () {},
              ),
          ],
        ),
      ),
    );
  }
}

class RegularPage extends StatelessWidget {
  final PageData pageData;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;

  const RegularPage({
    required this.pageData,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    isWeb ? screenWidth * 0.1 : 24.0,
                    MediaQuery.of(context).padding.top + 20,
                    isWeb ? screenWidth * 0.1 : 24.0,
                    24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.05),
                      ScaleTransition(
                        scale: scaleAnimation,
                        child: LayeredImage(
                          image: pageData.image!,
                          size: isWeb ? 400 : screenWidth * 0.85,
                        ),
                      ),
                      SizedBox(height: isWeb ? 60 : 40),
                      Text(
                        pageData.title,
                        style: GoogleFonts.poppins(
                          fontSize: isWeb ? 32 : screenWidth * 0.07,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isWeb ? 24 : 16),
                      DescriptionBox(
                        description: pageData.description,
                        isWeb: isWeb,
                        screenWidth: screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FinalPage extends StatelessWidget {
  final PageData pageData;
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;
  final Animation<double> swipeAnimation;
  final double swipeOffset;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;

  const FinalPage({
    required this.pageData,
    required this.scaleAnimation,
    required this.fadeAnimation,
    required this.swipeAnimation,
    required this.swipeOffset,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [Color(0xFF4A90E2), Color(0xFF1E6BB8), Color(0xFF0F4A8C)],
          stops: [0.3, 0.7, 1.0],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  isWeb ? screenWidth * 0.1 : 24.0,
                  MediaQuery.of(context).padding.top + 20,
                  isWeb ? screenWidth * 0.1 : 24.0,
                  24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    ScaleTransition(
                      scale: scaleAnimation,
                      child: LayeredImage(
                        image: pageData.image!,
                        size: isWeb ? 400 : screenWidth * 0.85,
                      ),
                    ),
                    SizedBox(height: isWeb ? 60 : 40),
                    FadeTransition(
                      opacity: fadeAnimation,
                      child: Text(
                        pageData.title,
                        style: GoogleFonts.poppins(
                          fontSize: isWeb ? 36 : screenWidth * 0.08,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isWeb ? 32 : 20),
                    FadeTransition(
                      opacity: fadeAnimation,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 600 : double.infinity,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          pageData.description,
                          style: GoogleFonts.poppins(
                            fontSize: isWeb ? 18 : 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: isWeb ? 80 : 60),
                    SwipeUpButton(
                      swipeOffset: swipeOffset,
                      swipeAnimation: swipeAnimation,
                      onPanUpdate: onPanUpdate,
                      onPanEnd: onPanEnd,
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LayeredImage extends StatelessWidget {
  final String image;
  final double size;

  const LayeredImage({required this.image, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.07),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: Container(
          margin: EdgeInsets.all(size * 0.07),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.25),
          ),
          child: Center(
            child: Image.asset(
              image,
              width: size * 0.6,
              height: size * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class DescriptionBox extends StatelessWidget {
  final String description;
  final bool isWeb;
  final double screenWidth;

  const DescriptionBox({
    required this.description,
    required this.isWeb,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 32 : 20,
        vertical: isWeb ? 20 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF61B8FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF61B8FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: isWeb ? 18 : 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF6B7280),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  final int currentPage;
  final int pagesLength;
  final VoidCallback onNext;

  const BottomNavigation({
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
            children: List.generate(pagesLength, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: currentPage == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      currentPage == index
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

class SkipButton extends StatelessWidget {
  final VoidCallback onSkip;

  const SkipButton({required this.onSkip});

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
              width: 1,
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

class LoginOverlay extends StatelessWidget {
  final AnimationController loginController;
  final Animation<double> loginFadeAnimation;
  final Animation<Offset> loginSlideAnimation;
  final VoidCallback onClose;
  final VoidCallback onLogin;

  const LoginOverlay({
    required this.loginController,
    required this.loginFadeAnimation,
    required this.loginSlideAnimation,
    required this.onClose,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loginController,
      builder: (context, child) {
        return Stack(
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
                child: LoginForm(onClose: onClose, onLogin: onLogin),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LoginForm extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onLogin;

  const LoginForm({required this.onClose, required this.onLogin});

  @override
  State<LoginForm> createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final TextEditingController nipController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;
  final LocalAuthentication localAuth = LocalAuthentication();
  bool canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    checkBiometrics();
  }

  Future<void> checkBiometrics() async {
    try {
      final canCheck = await localAuth.canCheckBiometrics;
      setState(() => canCheckBiometrics = canCheck);
    } catch (error) {
      setState(() => canCheckBiometrics = false);
    }
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void handleLogin() async {
    String nip = nipController.text.trim();
    String password = passwordController.text.trim();
    if (nip.isEmpty || password.isEmpty) {
      showSnackBar(context, "Harap isi NIP dan password");
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        body: {"nip": nip, "password": password},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final prefs = await SharedPreferences.getInstance();

        // Simpan data user (TANPA TOKEN)
        await prefs.setString(
          'walikelas_id',
          data['detail']['nip_walikelas']?.toString() ?? '',
        );
        await prefs.setString('role', data['role'].toString());
        await prefs.setString(
          'name',
          data['detail']['nama_walikelas'] ?? data['user']['username'],
        );
        await prefs.setString('email', data['user']['email'] ?? 'Unknown');
        await prefs.setString('phone', 'Unknown');
        await prefs.setString(
          'joinDate',
          data['detail']['created_at'] ?? 'Unknown',
        );
        await prefs.setString(
          'id_kelas',
          data['detail']['id_kelas'] ?? 'Unknown',
        );
        await prefs.setString(
          'jurusan',
          data['detail']['jurusan'] ?? 'Unknown',
        );
        // Simpan kredensial untuk login biometrik cepat (non-token)
        await prefs.setString('biometric_nip', nip);
        await prefs.setString('biometric_password', password);
        await FcmTokenService.instance.syncToken();

        // Cek role dan navigasi
        String role = data['role'].toString();
        if (role == '3') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/walikelas',
            (route) => false,
          );
        } else if (role == '4') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/kaprog',
            (route) => false,
          );
        } else {
          showSnackBar(context, "Role tidak dikenali");
        }
      } else {
        showSnackBar(context, data['message'] ?? 'Gagal masuk');
      }
    } catch (e) {
      showSnackBar(context, "Terjadi kesalahan: $e");
    }
    widget.onLogin();
  }

  @override
  void dispose() {
    nipController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleBiometricLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNip = prefs.getString('biometric_nip') ?? '';
      final savedPassword = prefs.getString('biometric_password') ?? '';
      if (savedNip.isEmpty || savedPassword.isEmpty) {
        showSnackBar(
          context,
          "Belum ada data login tersimpan. Masuk manual dulu.",
        );
        return;
      }

      final didAuth = await localAuth.authenticate(
        localizedReason: 'Autentikasi dengan sidik jari untuk login cepat',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!didAuth) return;

      nipController.text = savedNip;
      passwordController.text = savedPassword;
      handleLogin();
    } catch (e) {
      showSnackBar(context, "Biometrik gagal: $e");
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
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
                    controller: nipController,
                    isWeb: isWeb,
                  ),
                  SizedBox(height: isWeb ? 24 : 20),
                  LoginTextField(
                    hintText: 'Masukkan password anda',
                    icon: Icons.lock_outline,
                    obscureText: !isPasswordVisible,
                    suffixIcon:
                        isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                    controller: passwordController,
                    isWeb: isWeb,
                    onSuffixIconTap: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  SizedBox(height: isWeb ? 32 : 24),
                  if (canCheckBiometrics)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: const Color(0xFFE0F2FE),
                          foregroundColor: const Color(0xFF1D4ED8),
                        ),
                        icon: const Icon(Icons.fingerprint, size: 20),
                        label: Text(
                          'Masuk dengan Sidik Jari',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isWeb ? 15 : 14,
                          ),
                        ),
                        onPressed: handleBiometricLogin,
                      ),
                    ),
                  SizedBox(height: isWeb ? 20 : 16),
                  GradientButton(
                    text: 'Masuk',
                    onTap: handleLogin,
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

class HandleBar extends StatelessWidget {
  final VoidCallback onTap;

  const HandleBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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

class LoginHeader extends StatelessWidget {
  final bool isWeb;

  const LoginHeader({required this.isWeb});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 24.0 : 20.0),
      child: Row(
        children: [
          Container(
            width: isWeb ? 120 : 100,
            height: isWeb ? 120 : 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
                  'Yuk, lanjutkan aktivitasmu di SIJUAWARA (SISTEM INFORMASI JURNAL SISWA AKTIF)!',
                  style: GoogleFonts.poppins(
                    fontSize: isWeb ? 16 : 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
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

class LoginTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final IconData? suffixIcon;
  final TextEditingController? controller;
  final bool isWeb;
  final VoidCallback? onSuffixIconTap;

  const LoginTextField({
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
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: isWeb ? 16 : 14,
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          suffixIcon:
              suffixIcon != null
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

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isWeb;

  const GradientButton({
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
