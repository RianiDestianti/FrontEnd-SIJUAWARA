import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/student.dart';
import 'package:skoring/models/api/api_activity.dart';
import 'package:skoring/navigation/walikelas.dart';
import 'package:skoring/screens/walikelas/detail.dart';
import 'package:skoring/screens/walikelas/services/walikelas_data_service.dart';
import 'package:skoring/screens/walikelas/utils/chart_utils.dart';
import 'package:skoring/screens/walikelas/widgets/chart_widgets.dart';
import 'package:skoring/screens/walikelas/widgets/header_widgets.dart';
import 'package:skoring/screens/walikelas/widgets/section_widgets.dart';
import 'package:skoring/screens/walikelas/notification.dart';
import 'package:skoring/screens/walikelas/profile.dart';
import 'package:skoring/screens/walikelas/chart.dart';
import 'package:skoring/screens/walikelas/activity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/screens/walikelas/report.dart';
import 'package:skoring/screens/walikelas/student.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      const HomeScreenContent(),
      const SiswaScreen(),
      const LaporanScreen(),
    ];
  }

  void onNavigationTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: WalikelasNavigation(
        currentIndex: currentIndex,
        onTap: onNavigationTap,
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  State<HomeScreenContent> createState() => HomeScreenContentState();
}

class HomeScreenContentState extends State<HomeScreenContent>
    with TickerProviderStateMixin {
  int selectedTab = 0;
  int apresiasiChartTab = 0;
  int pelanggaranChartTab = 0;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  List<Student> filteredSiswaTerbaik = [];
  List<Student> filteredSiswaBerat = [];
  List<Student> siswaTerbaik = [];
  List<Student> siswaBerat = [];
  List<Map<String, dynamic>> apresiasiRawData = [];
  List<Map<String, dynamic>> pelanggaranRawData = [];
  List<Map<String, dynamic>> kelasData = [];
  List<Activity> activityData = [];
  String teacherName = 'Teacher';
  String teacherClassId = '';
  String walikelasId = '';
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    animationController.forward();
    loadTeacherData();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    safeSetState(() {
      teacherName = prefs.getString('name') ?? 'Teacher';
      teacherClassId = prefs.getString('id_kelas') ?? '';
      walikelasId = prefs.getString('walikelas_id') ?? '';
    });
    await fetchData();
  }

  Future<void> fetchData({bool force = false}) async {
    if (isRefreshing && !force) return;
    try {
      final data = await WalikelasDataService.fetchAllData(
        walikelasId: walikelasId,
        teacherClassId: teacherClassId,
      );
      safeSetState(() {
        siswaTerbaik = data['siswaTerbaik'] as List<Student>;
        siswaBerat = data['siswaBerat'] as List<Student>;
        filteredSiswaTerbaik = siswaTerbaik;
        filteredSiswaBerat = siswaBerat;
        apresiasiRawData =
            data['apresiasiRawData'] as List<Map<String, dynamic>>;
        pelanggaranRawData =
            data['pelanggaranRawData'] as List<Map<String, dynamic>>;
        activityData = data['activityData'] as List<Activity>;
        kelasData = data['kelasData'] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> manualRefresh() async {
    if (isRefreshing) return;
    safeSetState(() => isRefreshing = true);
    await fetchData(force: true);
    safeSetState(() => isRefreshing = false);
  }

  Future<void> addLocalActivity(
    String type,
    String title,
    String subtitle,
  ) async {}

  void filterSiswa(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSiswaTerbaik = siswaTerbaik;
        filteredSiswaBerat = siswaBerat;
      } else {
        final searchLower = query.toLowerCase();
        filteredSiswaTerbaik =
            siswaTerbaik.where((siswa) {
              final namaLower = siswa.name.toLowerCase();
              final kelasLower = siswa.kelas.toLowerCase();
              final prestasiLower = siswa.prestasi.toLowerCase();
              final statusLower = siswa.status.toLowerCase();
              final nisString = siswa.nis.toString();
              return namaLower.contains(searchLower) ||
                  kelasLower.contains(searchLower) ||
                  prestasiLower.contains(searchLower) ||
                  statusLower.contains(searchLower) ||
                  nisString.contains(searchLower);
            }).toList();
        filteredSiswaBerat =
            siswaBerat.where((siswa) {
              final namaLower = siswa.name.toLowerCase();
              final kelasLower = siswa.kelas.toLowerCase();
              final prestasiLower = siswa.prestasi.toLowerCase();
              final statusLower = siswa.status.toLowerCase();
              final nisString = siswa.nis.toString();
              return namaLower.contains(searchLower) ||
                  kelasLower.contains(searchLower) ||
                  prestasiLower.contains(searchLower) ||
                  statusLower.contains(searchLower) ||
                  nisString.contains(searchLower);
            }).toList();
      }
    });

    if (query.isNotEmpty) {
      addLocalActivity(
        'Pencarian',
        'Pencarian Siswa',
        'Melakukan pencarian: $query',
      );
    }
  }

  void navigateToDetailScreen(Student siswa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DetailScreen(
              student: {
                'name': siswa.name,
                'status': siswa.status,
                'nis': siswa.nis.toString(),
                'kelas': siswa.kelas,
                'programKeahlian': siswa.kelas,
                'poinApresiasi': siswa.poin > 0 ? siswa.poin : 0,
                'poinPelanggaran': siswa.poin < 0 ? siswa.poin.abs() : 0,
                'points': siswa.poin,
              },
            ),
      ),
    ).then((unused) {
      addLocalActivity(
        'Navigasi',
        'Detail Siswa',
        'Mengakses detail siswa: ${siswa.name}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final headerPadding = isSmallScreen ? 16.0 : 20.0;
    final cardPadding = isSmallScreen ? 14.0 : 16.0;
    final sectionSpacing = isSmallScreen ? 12.0 : 16.0;

    final apresiasiChartData = ChartUtils.aggregateChartData(
      apresiasiRawData,
      apresiasiChartTab,
    );
    final pelanggaranChartData = ChartUtils.aggregateChartData(
      pelanggaranRawData,
      pelanggaranChartTab,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),

      child: Material(
        color: const Color(0xFF0083EE),
      
        child: SafeArea(
          bottom: false,
          child: Material(
            color: const Color(0xFFF8FAFC),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth = constraints.maxWidth;
                if (maxWidth > 600) maxWidth = 600;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: manualRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              _buildHeader(isSmallScreen, headerPadding),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  headerPadding,
                                  headerPadding,
                                  headerPadding,
                                  100,
                                ),
                                child: Column(
                                  children: [
                                    if (selectedTab == 2) ...[
                                      SectionWidgets.buildCompactSiswaTerbaikSection(
                                        isSmallScreen,
                                        cardPadding,
                                        filteredSiswaTerbaik,
                                        navigateToDetailScreen,
                                      ),
                                    ] else if (selectedTab == 3) ...[
                                      SectionWidgets.buildCompactSiswaBeratSection(
                                        isSmallScreen,
                                        cardPadding,
                                        filteredSiswaBerat,
                                        navigateToDetailScreen,
                                      ),
                                    ] else ...[
                                      SectionWidgets.buildCompactChartCard(
                                        'Grafik Apresiasi Siswa',
                                        'Pencapaian positif',
                                        Icons.trending_up,
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF61B8FF),
                                            Color(0xFF0083EE),
                                          ],
                                        ),
                                        ChartWidgets.buildBarChart(
                                          apresiasiChartData,
                                          const LinearGradient(
                                            colors: [
                                              Color(0xFF61B8FF),
                                              Color(0xFF0083EE),
                                            ],
                                          ),
                                        ),
                                        apresiasiChartTab,
                                        (index) => setState(
                                          () => apresiasiChartTab = index,
                                        ),
                                        true,
                                        isSmallScreen,
                                        cardPadding,
                                        ChartWidgets.buildSwipeableChartButtons(
                                          apresiasiChartTab,
                                          (index) => setState(
                                            () => apresiasiChartTab = index,
                                          ),
                                          addLocalActivity,
                                        ),
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => GrafikScreen(
                                                  chartType: 'apresiasi',
                                                  title:
                                                      'Grafik Apresiasi Siswa',
                                                  subtitle:
                                                      'Pencapaian positif',
                                                ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: sectionSpacing),
                                      SectionWidgets.buildCompactChartCard(
                                        'Grafik Pelanggaran Siswa',
                                        'Monitoring pelanggaran',
                                        Icons.warning_amber_rounded,
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFFF2D6D7),
                                            Color(0xFFFF6B6D),
                                          ],
                                        ),
                                        ChartWidgets.buildBarChart(
                                          pelanggaranChartData,
                                          const LinearGradient(
                                            colors: [
                                              Color(0xFFFF6B6D),
                                              Color(0xFFFF8E8F),
                                            ],
                                          ),
                                        ),
                                        pelanggaranChartTab,
                                        (index) => setState(
                                          () => pelanggaranChartTab = index,
                                        ),
                                        false,
                                        isSmallScreen,
                                        cardPadding,
                                        ChartWidgets.buildSwipeableChartButtons(
                                          pelanggaranChartTab,
                                          (index) => setState(
                                            () => pelanggaranChartTab = index,
                                          ),
                                          addLocalActivity,
                                        ),
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => GrafikScreen(
                                                  chartType: 'pelanggaran',
                                                  title:
                                                      'Grafik Pelanggaran Siswa',
                                                  subtitle:
                                                      'Monitoring pelanggaran',
                                                ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: sectionSpacing),
                                      SectionWidgets.buildCompactActivityCard(
                                        isSmallScreen,
                                        cardPadding,
                                        activityData,
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const ActivityScreen(),
                                          ),
                                        ),
                                        (activity, isSmall) =>
                                            SectionWidgets.buildCompactActivityItem(
                                              activity,
                                              isSmall,
                                              () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const ActivityScreen(),
                                                ),
                                              ),
                                            ),
                                      ),
                                    ],
                                  ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, double headerPadding) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x200083EE),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          headerPadding,
          isSmallScreen ? 12 : 16,
          headerPadding,
          isSmallScreen ? 20 : 24,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $teacherName! 👋',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        'Semoga harimu penuh berkah',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: isSmallScreen ? 8 : 12),

                Row(
                  children: [
                    HeaderWidgets.buildCompactIconButton(
                      Icons.notifications_rounded,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotifikasiScreen(),
                        ),
                      ),
                      isSmallScreen,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    HeaderWidgets.buildCompactProfileButton(
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ),
                      isSmallScreen,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            if (selectedTab == 2 || selectedTab == 3) ...[
              HeaderWidgets.buildCompactSearchBar(isSmallScreen, filterSiswa),
              SizedBox(height: isSmallScreen ? 12 : 16),
            ],
            Row(
              children: [
                HeaderWidgets.buildActionButton('Umum', 0, selectedTab, () {
                  setState(() => selectedTab = 0);
                  addLocalActivity(
                    'Navigasi',
                    'Tab Umum',
                    'Berpindah ke tab Umum',
                  );
                }),
                const SizedBox(width: 8),
                HeaderWidgets.buildActionButton('PH', 2, selectedTab, () {
                  setState(() => selectedTab = 2);
                  addLocalActivity('Navigasi', 'Tab PH', 'Berpindah ke tab PH');
                }),
                const SizedBox(width: 8),
                HeaderWidgets.buildActionButton('SP', 3, selectedTab, () {
                  setState(() => selectedTab = 3);
                  addLocalActivity('Navigasi', 'Tab SP', 'Berpindah ke tab SP');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
