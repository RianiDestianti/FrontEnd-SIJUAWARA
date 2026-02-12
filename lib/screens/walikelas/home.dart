import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/types/student.dart';
import '../../navigation/walikelas.dart';
import 'student.dart';
import 'report.dart';
import 'notification.dart';
import 'package:skoring/screens/walikelas/profile.dart';
import 'package:skoring/screens/walikelas/chart.dart';
import 'package:skoring/screens/walikelas/activity.dart';
import 'package:skoring/models/api/api_activity.dart';
import 'detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalikelasMainScreen extends StatefulWidget {
  const WalikelasMainScreen({Key? key}) : super(key: key);

  @override
  State<WalikelasMainScreen> createState() => WalikelasMainScreenState();
}

class WalikelasMainScreenState extends State<WalikelasMainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    const HomeScreen(),
    const SiswaScreen(),
    const LaporanScreen(),
  ];

  void onNavigationTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: screens[currentIndex],
      ),
      bottomNavigationBar: WalikelasNavigation(
        currentIndex: currentIndex,
        onTap: onNavigationTap,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

  Future<void> updateActivityTimeline({
    Map<String, dynamic>? apresiasiJson,
    Map<String, dynamic>? pelanggaranJson,
  }) async {
    if (teacherClassId.isEmpty) {
      safeSetState(() {
        activityData = [];
      });
      return;
    }

    final activities = <Activity>[];
    if (apresiasiJson != null) {
      activities.addAll(
        mapActivityLogsFromJson(
          json: apresiasiJson,
          category: 'Apresiasi',
          classId: teacherClassId,
        ),
      );
    }
    if (pelanggaranJson != null) {
      activities.addAll(
        mapActivityLogsFromJson(
          json: pelanggaranJson,
          category: 'Pelanggaran',
          classId: teacherClassId,
        ),
      );
    }

    activities.sort((a, b) => b.fullDate.compareTo(a.fullDate));
    safeSetState(() {
      activityData = activities;
    });
  }

  Future<void> addLocalActivity(
    String type,
    String title,
    String subtitle,
  ) async {}

  Future<void> fetchData({bool force = false}) async {
    if (isRefreshing && !force) return;
    try {
      Map<String, dynamic>? penghargaanJson;
      Map<String, dynamic>? pelanggaranJson;
      Map<String, String> kelasMap = {};
      Map<String, String> jurusanMap = {};

      final kelasResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/kelas'),
      );
      if (kelasResponse.statusCode == 200) {
        final kelasJson = jsonDecode(kelasResponse.body);
        kelasData = List<Map<String, dynamic>>.from(kelasJson['data']);
        kelasMap = {
          for (var kelas in kelasData)
            kelas['id_kelas'].toString(): kelas['nama_kelas'].toString(),
        };
        jurusanMap = {
          for (var kelas in kelasData)
            kelas['id_kelas'].toString(): kelas['jurusan'].toString(),
        };
      }

      if (walikelasId.isNotEmpty && teacherClassId.isNotEmpty) {
        final siswaResponse = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/siswa?nip=$walikelasId&id_kelas=$teacherClassId',
          ),
        );
        if (siswaResponse.statusCode == 200) {
          final siswaJson = jsonDecode(siswaResponse.body);
          final siswaData = List<Map<String, dynamic>>.from(
            siswaJson['data'] ?? [],
          );

          final classStudents = siswaData.map((siswa) {
            final idKelas = siswa['id_kelas']?.toString() ?? '';
            final poin =
                int.tryParse(siswa['poin_total']?.toString() ?? '') ?? 0;
            final spLevel = resolveSpLevel(
              poin,
              siswa['sp_level']?.toString(),
            );
            final phLevel = resolvePhLevel(
              poin,
              siswa['ph_level']?.toString(),
            );
            final status =
                poin >= 0
                    ? 'Aman'
                    : (poin <= -20 ? 'Prioritas' : 'Bermasalah');

            return Student(
              name: siswa['nama_siswa']?.toString() ?? 'Unknown',
              kelas: kelasMap[idKelas] ?? idKelas,
              programKeahlian:
                  jurusanMap[idKelas] ??
                  siswa['program_keahlian']?.toString() ??
                  'Unknown',
              poin: poin,
              prestasi: '-',
              avatar: Icons.person,
              rank: 0,
              status: status,
              nis: int.tryParse(siswa['nis']?.toString() ?? '') ?? 0,
              spLevel: spLevel,
              phLevel: phLevel,
            );
          }).toList();

          final phStudents =
              classStudents.where((s) => s.phLevel != null).toList()
                ..sort((a, b) => b.poin.compareTo(a.poin));
          final spStudents =
              classStudents.where((s) => s.spLevel != null).toList()
                ..sort((a, b) => a.poin.compareTo(b.poin));

          siswaTerbaik = rankAndLabel(phStudents, isPh: true);
          siswaBerat = rankAndLabel(spStudents, isPh: false);

          filteredSiswaTerbaik = siswaTerbaik;
          filteredSiswaBerat = siswaBerat;

          await addLocalActivity(
            'Sistem',
            'Data Diperbarui',
            'Melakukan refresh data siswa dan kelas',
          );
        } else {
          siswaTerbaik = [];
          siswaBerat = [];
          filteredSiswaTerbaik = [];
          filteredSiswaBerat = [];
        }
      } else {
        siswaTerbaik = [];
        siswaBerat = [];
        filteredSiswaTerbaik = [];
        filteredSiswaBerat = [];
      }

      if (walikelasId.isNotEmpty && teacherClassId.isNotEmpty) {
        final penghargaanResponse = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/skoring_penghargaan?nip=$walikelasId&id_kelas=$teacherClassId',
          ),
        );
        if (penghargaanResponse.statusCode == 200) {
          penghargaanJson = Map<String, dynamic>.from(
            jsonDecode(penghargaanResponse.body),
          );
          final siswaData = (penghargaanJson['siswa'] as List<dynamic>? ?? []);
          final penilaianData =
              (penghargaanJson['penilaian']['data'] as List<dynamic>? ?? [])
                  .where(
                    (item) => siswaData.any(
                      (siswa) =>
                          siswa['nis'].toString() == item['nis'].toString() &&
                          siswa['id_kelas'].toString() == teacherClassId,
                    ),
                  )
                  .toList();
          apresiasiRawData = List<Map<String, dynamic>>.from(penilaianData);
        } else {
          apresiasiRawData = [];
        }

        var pelanggaranResponse = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/skoring_pelanggaran?nip=$walikelasId&id_kelas=$teacherClassId',
          ),
        );
        if (pelanggaranResponse.statusCode != 200) {
          pelanggaranResponse = await http.get(
            Uri.parse(
              '${ApiConfig.baseUrl}/skoring_2pelanggaran?nip=$walikelasId&id_kelas=$teacherClassId',
            ),
          );
        }
        if (pelanggaranResponse.statusCode == 200) {
          pelanggaranJson = Map<String, dynamic>.from(
            jsonDecode(pelanggaranResponse.body),
          );
          final siswaData = (pelanggaranJson['siswa'] as List<dynamic>? ?? []);
          final penilaianData =
              (pelanggaranJson['penilaian']['data'] as List<dynamic>? ?? [])
                  .where(
                    (item) => siswaData.any(
                      (siswa) =>
                          siswa['nis'].toString() == item['nis'].toString() &&
                          siswa['id_kelas'].toString() == teacherClassId,
                    ),
                  )
                  .toList();
          pelanggaranRawData = List<Map<String, dynamic>>.from(penilaianData);
        } else {
          pelanggaranRawData = [];
        }
      } else {
        apresiasiRawData = [];
        pelanggaranRawData = [];
        activityData = [];
      }

      await updateActivityTimeline(
        apresiasiJson: penghargaanJson,
        pelanggaranJson: pelanggaranJson,
      );
      safeSetState(() {});
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

  List<Map<String, dynamic>> aggregateChartData(
    List<Map<String, dynamic>> data,
    int selectedTab, {
    String dateField = 'created_at',
  }) {
    Map<String, double> weeklyData = {};
    Map<String, double> monthlyData = {};

    for (var item in data) {
      final rawDate = item[dateField];
      if (rawDate == null) continue;
      DateTime date = DateTime.parse(rawDate.toString());
      String weekKey =
          '${date.year}-W${((date.day + 6) / 7).ceil().toString().padLeft(2, '0')}';
      String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      weeklyData[weekKey] = (weeklyData[weekKey] ?? 0) + 1;
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
    }

    if (selectedTab == 0) {
      final weeklyEntries =
          weeklyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      return weeklyEntries
          .map((e) => {'label': e.key.split('-W')[1], 'value': e.value})
          .toList();
    }

    final monthlyEntries =
        monthlyData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return monthlyEntries
        .map(
          (e) => {
            'label': getMonthName(int.parse(e.key.split('-')[1])),
            'value': e.value,
          },
        )
        .toList();
  }

  String getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[month - 1];
  }

  void filterSiswa(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSiswaTerbaik = siswaTerbaik;
        filteredSiswaBerat = siswaBerat;
      } else {
        final searchLower = query.toLowerCase();
        filteredSiswaTerbaik = siswaTerbaik.where((siswa) {
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
        filteredSiswaBerat = siswaBerat.where((siswa) {
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
        builder: (context) => DetailScreen(
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
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing based on screen height
    final isSmallScreen = screenHeight < 700;
    final headerPadding = isSmallScreen ? 16.0 : 20.0;
    final cardPadding = isSmallScreen ? 14.0 : 16.0;
    final sectionSpacing = isSmallScreen ? 12.0 : 16.0;

    final apresiasiChartData = aggregateChartData(
      apresiasiRawData,
      apresiasiChartTab,
    );
    final pelanggaranChartData = aggregateChartData(
      pelanggaranRawData,
      pelanggaranChartTab,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth;
            if (maxWidth > 600) maxWidth = 600;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: manualRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          // Compact Header
                          Container(
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
                                MediaQuery.of(context).padding.top +
                                    (isSmallScreen ? 12 : 16),
                                headerPadding,
                                isSmallScreen ? 20 : 24,
                              ),
                              child: Column(
                                children: [
                                  // Top icons row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 36, height: 36),
                                      Row(
                                        children: [
                                          _buildCompactIconButton(
                                            Icons.notifications_rounded,
                                            () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const NotifikasiScreen(),
                                                ),
                                              );
                                            },
                                            isSmallScreen,
                                          ),
                                          SizedBox(
                                              width: isSmallScreen ? 6 : 8),
                                          _buildCompactProfileButton(
                                            () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ProfileScreen(),
                                                ),
                                              );
                                            },
                                            isSmallScreen,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  // Greeting
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello, $teacherName! 👋',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 20 : 24,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                        ),
                                        SizedBox(height: isSmallScreen ? 4 : 6),
                                        Text(
                                          'Semoga harimu penuh berkah',
                                          style: GoogleFonts.poppins(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: isSmallScreen ? 12 : 13,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  // Compact Search Bar
                                  _buildCompactSearchBar(isSmallScreen),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      buildActionButton('Umum', 0),
                                      const SizedBox(width: 8),
                                      buildActionButton('PH', 2),
                                      const SizedBox(width: 8),
                                      buildActionButton('SP', 3),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Content sections
                          Padding(
                            padding: EdgeInsets.all(headerPadding),
                            child: Column(
                              children: [
                                if (selectedTab == 2) ...[
                                  buildCompactSiswaTerbaikSection(
                                      isSmallScreen, cardPadding),
                                  SizedBox(height: sectionSpacing),
                                ] else if (selectedTab == 3) ...[
                                  buildCompactSiswaBeratSection(
                                      isSmallScreen, cardPadding),
                                  SizedBox(height: sectionSpacing),
                                ] else ...[
                                  buildCompactChartCard(
                                    'Grafik Apresiasi Siswa',
                                    'Pencapaian positif',
                                    Icons.trending_up,
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF61B8FF),
                                        Color(0xFF0083EE)
                                      ],
                                    ),
                                    buildBarChart(
                                      apresiasiChartData,
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFF61B8FF),
                                          Color(0xFF0083EE)
                                        ],
                                      ),
                                    ),
                                    apresiasiChartTab,
                                    (index) => setState(
                                        () => apresiasiChartTab = index),
                                    true,
                                    isSmallScreen,
                                    cardPadding,
                                  ),
                                  SizedBox(height: sectionSpacing),
                                  buildCompactChartCard(
                                    'Grafik Pelanggaran Siswa',
                                    'Monitoring pelanggaran',
                                    Icons.warning_amber_rounded,
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFFF2D6D7),
                                        Color(0xFFFF6B6D)
                                      ],
                                    ),
                                    buildBarChart(
                                      pelanggaranChartData,
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFFFF6B6D),
                                          Color(0xFFFF8E8F)
                                        ],
                                      ),
                                    ),
                                    pelanggaranChartTab,
                                    (index) => setState(
                                        () => pelanggaranChartTab = index),
                                    false,
                                    isSmallScreen,
                                    cardPadding,
                                  ),
                                  SizedBox(height: sectionSpacing),
                                  buildCompactActivityCard(
                                      isSmallScreen, cardPadding),
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
    );
  }

  // Helper widgets for compact layout
  Widget _buildCompactIconButton(
      IconData icon, VoidCallback onTap, bool isSmall) {
    final size = isSmall ? 36.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: isSmall ? 20 : 22,
        ),
      ),
    );
  }

  Widget _buildCompactProfileButton(VoidCallback onTap, bool isSmall) {
    final size = isSmall ? 36.0 : 40.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.person_rounded,
          color: const Color(0xFF0083EE),
          size: isSmall ? 20 : 22,
        ),
      ),
    );
  }

  Widget _buildCompactSearchBar(bool isSmall) {
    return Container(
      height: isSmall ? 44 : 48,
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 6 : 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search,
              color: Colors.white,
              size: isSmall ? 16 : 17,
            ),
          ),
          SizedBox(width: isSmall ? 10 : 12),
          Expanded(
            child: TextField(
              onChanged: filterSiswa,
              decoration: InputDecoration(
                hintText: 'Cari siswa atau kelas...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                  fontSize: isSmall ? 13 : 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 13 : 14,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompactSiswaTerbaikSection(bool isSmall, double padding) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmall ? 16 : 18),
                topRight: Radius.circular(isSmall ? 16 : 18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: isSmall ? 20 : 22,
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PH (Penghargaan)',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Siswa dengan status PH1–PH3',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: filteredSiswaTerbaik.isEmpty
                  ? [
                      Text(
                        'Tidak ada hasil ditemukan',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 12 : 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ]
                  : filteredSiswaTerbaik.asMap().entries.map((entry) {
                      int index = entry.key;
                      Student siswa = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < filteredSiswaTerbaik.length - 1
                              ? (isSmall ? 10 : 12)
                              : 0,
                        ),
                        child: buildCompactSiswaTerbaikItem(siswa, isSmall),
                      );
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompactSiswaBeratSection(bool isSmall, double padding) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmall ? 16 : 18),
                topRight: Radius.circular(isSmall ? 16 : 18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: isSmall ? 20 : 22,
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SP (Pelanggaran)',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Siswa dengan status SP1–SP3',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: filteredSiswaBerat.isEmpty
                  ? [
                      Text(
                        'Tidak ada hasil ditemukan',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 12 : 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ]
                  : filteredSiswaBerat.asMap().entries.map((entry) {
                      int index = entry.key;
                      Student siswa = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < filteredSiswaBerat.length - 1
                              ? (isSmall ? 10 : 12)
                              : 0,
                        ),
                        child: buildCompactSiswaBeratItem(siswa, isSmall),
                      );
                    }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompactSiswaTerbaikItem(Student siswa, bool isSmall) {
    Color rankColor = getRankColor(siswa.rank);
    IconData rankIcon = getRankIcon(siswa.rank);
    final avatarSize = isSmall ? 42.0 : 46.0;

    return GestureDetector(
      onTap: () => navigateToDetailScreen(siswa),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          border: Border.all(color: rankColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: siswa.rank <= 3
                      ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                      : [const Color(0xFF61B8FF), const Color(0xFF0083EE)],
                ),
                borderRadius: BorderRadius.circular(avatarSize / 2),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.person,
                      color: Colors.white, size: isSmall ? 20 : 22),
                  if (siswa.rank <= 3)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: isSmall ? 16 : 18,
                        height: isSmall ? 16 : 18,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(rankIcon,
                            color: Colors.white, size: isSmall ? 8 : 9),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 6 : 7,
                          vertical: isSmall ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: rankColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${siswa.rank}',
                          style: GoogleFonts.poppins(
                            color: rankColor,
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Expanded(
                        child: Text(
                          siswa.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 13 : 14,
                            color: const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 3 : 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 5 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0083EE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          siswa.kelas,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0083EE),
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Icon(
                        Icons.star,
                        color: const Color(0xFFFFD700),
                        size: isSmall ? 12 : 13,
                      ),
                      SizedBox(width: isSmall ? 3 : 4),
                      Text(
                        '${siswa.poin} poin',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Container(
              padding: EdgeInsets.all(isSmall ? 6 : 7),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.trending_up,
                  color: rankColor, size: isSmall ? 16 : 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCompactSiswaBeratItem(Student siswa, bool isSmall) {
    Color rankColor = getRankColor(siswa.rank);
    final avatarSize = isSmall ? 42.0 : 46.0;

    return GestureDetector(
      onTap: () => navigateToDetailScreen(siswa),
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          border: Border.all(color: rankColor.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rankColor.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                ),
                borderRadius: BorderRadius.circular(avatarSize / 2),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.person,
                      color: Colors.white, size: isSmall ? 20 : 22),
                  if (siswa.rank <= 3)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: isSmall ? 16 : 18,
                        height: isSmall ? 16 : 18,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Icon(
                          getRankIcon(siswa.rank),
                          color: Colors.white,
                          size: isSmall ? 8 : 9,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 6 : 7,
                          vertical: isSmall ? 2 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: rankColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${siswa.rank}',
                          style: GoogleFonts.poppins(
                            color: rankColor,
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Expanded(
                        child: Text(
                          siswa.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 13 : 14,
                            color: const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmall ? 3 : 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 5 : 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0083EE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          siswa.kelas,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0083EE),
                            fontSize: isSmall ? 9 : 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmall ? 6 : 8),
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFFF6B6D),
                        size: isSmall ? 12 : 13,
                      ),
                      SizedBox(width: isSmall ? 3 : 4),
                      Text(
                        '${siswa.poin} poin',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF6B6D),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Container(
              padding: EdgeInsets.all(isSmall ? 6 : 7),
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.trending_down,
                  color: rankColor, size: isSmall ? 16 : 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCompactChartCard(
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    Widget chart,
    int selectedTab,
    Function(int) onTabChanged,
    bool isFirst,
    bool isSmall,
    double padding,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSmall ? 16 : 18),
                topRight: Radius.circular(isSmall ? 16 : 18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 8 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: isSmall ? 20 : 22),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 14 : 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmall ? 10 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                buildSwipeableChartButtons(selectedTab, onTabChanged),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GrafikScreen(
                      chartType: isFirst ? 'apresiasi' : 'pelanggaran',
                      title: title,
                      subtitle: subtitle,
                    ),
                  ),
                );
              },
              child: chart,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompactActivityCard(bool isSmall, double padding) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isSmall ? 16 : 18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmall ? 9 : 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Colors.white,
                    size: isSmall ? 18 : 19,
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas Terkini',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Update terbaru',
                        style: GoogleFonts.poppins(
                          fontSize: isSmall ? 10 : 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(isSmall ? 6 : 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: isSmall ? 12 : 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmall ? 14 : 16),
            if (activityData.isEmpty)
              Text(
                'Belum ada aktivitas skoring.',
                style: GoogleFonts.poppins(
                  fontSize: isSmall ? 11 : 12,
                  color: const Color(0xFF9CA3AF),
                ),
              )
            else
              ...activityData.take(3).map(
                    (activity) => Padding(
                      padding: EdgeInsets.only(bottom: isSmall ? 10 : 12),
                      child: buildCompactActivityItem(activity, isSmall),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget buildCompactActivityItem(Activity activity, bool isSmall) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isSmall ? 12 : 14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: isSmall ? 40 : 44,
              height: isSmall ? 40 : 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: activity.gradient),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(activity.icon,
                  color: Colors.white, size: isSmall ? 20 : 22),
            ),
            SizedBox(width: isSmall ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: isSmall ? 13 : 14,
                      color: const Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmall ? 2 : 3),
                  Text(
                    activity.subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontSize: isSmall ? 10 : 11,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmall ? 8 : 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${activity.time}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9CA3AF),
                    fontSize: isSmall ? 9 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isSmall ? 4 : 5),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 6 : 7,
                    vertical: isSmall ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: activity.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: activity.statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    activity.status,
                    style: GoogleFonts.poppins(
                      color: activity.statusColor,
                      fontSize: isSmall ? 7 : 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF0083EE);
    }
  }

  String? resolvePhLevel(int points, String? rawLevel) {
    if (points <= -25) return null;
    final ph = rawLevel?.trim();
    if (ph != null && ph.isNotEmpty && ph != '-') {
      return ph;
    }
    if (points >= 151) return 'PH3';
    if (points >= 126) return 'PH2';
    if (points >= 100) return 'PH1';
    return null;
  }

  String? resolveSpLevel(int points, String? rawLevel) {
    final sp = rawLevel?.trim();
    if (sp != null && sp.isNotEmpty && sp != '-') {
      return sp;
    }
    if (points <= -76) return 'SP3';
    if (points <= -51) return 'SP2';
    if (points <= -25) return 'SP1';
    return null;
  }

  List<Student> rankAndLabel(List<Student> students, {required bool isPh}) {
    return students.asMap().entries.map((entry) {
      final siswa = entry.value;
      final level = isPh ? siswa.phLevel : siswa.spLevel;
      return Student(
        name: siswa.name,
        kelas: siswa.kelas,
        programKeahlian: siswa.programKeahlian,
        poin: siswa.poin,
        prestasi: level != null ? 'Level $level' : siswa.prestasi,
        avatar: siswa.avatar,
        rank: entry.key + 1,
        status: siswa.status,
        nis: siswa.nis,
        spLevel: siswa.spLevel,
        phLevel: siswa.phLevel,
      );
    }).toList();
  }

  IconData getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.looks_one;
      case 2:
        return Icons.looks_two;
      case 3:
        return Icons.looks_3;
      default:
        return Icons.star;
    }
  }

  Widget buildActionButton(String text, int index) {
    bool isActive = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedTab = index);
          addLocalActivity('Navigasi', 'Tab $text', 'Berpindah ke tab $text');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive && index == 0)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive && index == 2)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive && index == 3)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color:
                          isActive ? const Color(0xFF1F2937) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSwipeableChartButtons(
    int selectedTab,
    Function(int) onTabChanged,
  ) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dx > 5) {
          if (selectedTab > 0) {
            onTabChanged(selectedTab - 1);
            addLocalActivity(
              'Navigasi',
              'Tab Grafik',
              'Berpindah ke tab ${selectedTab == 0 ? 'Bulan' : 'Minggu'}',
            );
          }
        } else if (details.delta.dx < -5) {
          if (selectedTab < 1) {
            onTabChanged(selectedTab + 1);
            addLocalActivity(
              'Navigasi',
              'Tab Grafik',
              'Berpindah ke tab ${selectedTab == 0 ? 'Bulan' : 'Minggu'}',
            );
          }
        }
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildChartButton('Minggu', selectedTab == 0, () => onTabChanged(0)),
            buildChartButton('Bulan', selectedTab == 1, () => onTabChanged(1)),
          ],
        ),
      ),
    );
  }

  Widget buildChartButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: isActive ? const Color(0xFF1F2937) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBarChart(List<Map<String, dynamic>> data, Gradient gradient) {
    double maxValue = data.isNotEmpty
        ? data
            .map((e) => (e['value'] as double?) ?? 0.0)
            .reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      height: 140,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${maxValue.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.75).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.5).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.25).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '0',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((item) {
                      double value = (item['value'] as double?) ?? 0.0;
                      double height =
                          maxValue > 0 ? (value / maxValue) * 100 : 0;
                      return Container(
                        width: 20,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 38),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: data.map((item) {
                    return Text(
                      (item['label'] as String?) ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}