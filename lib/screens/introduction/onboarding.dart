import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoring/models/types/introduction.dart';
import 'package:skoring/widgets/page_widgets.dart';
import 'package:skoring/widgets/nav_widgets.dart';
import 'package:skoring/widgets/login_widgets.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen>
    with TickerProviderStateMixin {
  // ─── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;
  late final AnimationController _loginCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _loginSlideAnim;
  late final Animation<double> _loginFadeAnim;

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _showLogin = false;

 
  double _swipeStartY = 0;
  bool _swipeDetected = false;


  static final _pages = [
    PageData(
      image: 'assets/batang.png',
      title: 'Selamat Datang di Sistem Skoring!',
      description:
          'Kelola pencatatan, penilaian, hingga laporan dalam satu aplikasi praktis. '
          'Nikmati kemudahan mengelola penilaian secara cepat.',
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
      title: 'SIJUWARA',
      description:
          'Geser ke atas untuk masuk ke SIJUWARA (SISTEM JURNAL SISWA AKTIF) '
          'dan kelola penilaian siswa dengan mudah!',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _pageCtrl.addListener(_onPageScroll);
    _animCtrl.forward();
  }

  void _initAnimations() {
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loginCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _loginSlideAnim =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _loginCtrl, curve: Curves.easeOutCubic),
    );

    _loginFadeAnim = Tween<double>(begin: 0.0, end: 0.5)
        .animate(CurvedAnimation(parent: _loginCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _loginCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ─── Page navigation ──────────────────────────────────────────────────────────

  void _onPageScroll() =>
      setState(() => _currentPage = _pageCtrl.page?.round() ?? 0);

  void _nextPage() {
    if (!_isLastPage) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToFinal() {
    _pageCtrl.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // ─── Login overlay ────────────────────────────────────────────────────────────

  void _showLoginOverlay() {
    setState(() => _showLogin = true);
    _loginCtrl.forward();
  }

  void _hideLoginOverlay() {
    _loginCtrl.reverse().then((_) {
      if (mounted) setState(() => _showLogin = false);
    });
  }

  // ─── Swipe gesture (final page) ───────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    _swipeStartY = d.globalPosition.dy;
    _swipeDetected = false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_swipeDetected && _swipeStartY - d.globalPosition.dy > 50) {
      _swipeDetected = true;
      _showLoginOverlay();
    }
  }

  void _onPanEnd(DragEndDetails _) => _swipeDetected = false;

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _isLastPage ? const Color(0xFF1E6BB8) : Colors.white,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _pages.length,
                    itemBuilder: (context, i) => i == _pages.length - 1
                        ? FinalPage(
                            pageData: _pages[i],
                            scaleAnimation: _scaleAnim,
                            fadeAnimation: _fadeAnim,
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                          )
                        : RegularPage(
                            pageData: _pages[i],
                            fadeAnimation: _fadeAnim,
                            slideAnimation: _slideAnim,
                            scaleAnimation: _scaleAnim,
                          ),
                  ),
                ),
                if (!_isLastPage)
                  BottomNavigation(
                    currentPage: _currentPage,
                    pagesLength: _pages.length,
                    onNext: _nextPage,
                  ),
              ],
            ),
            if (!_isLastPage) SkipButton(onSkip: _skipToFinal),
            if (_showLogin)
              LoginOverlay(
                loginController: _loginCtrl,
                loginFadeAnimation: _loginFadeAnim,
                loginSlideAnimation: _loginSlideAnim,
                onClose: _hideLoginOverlay,
              ),
          ],
        ),
      ),
    );
  }
}