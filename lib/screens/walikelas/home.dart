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

          final classStudents =
              siswaData.map((siswa) {
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
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x200083EE),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24,
                                MediaQuery.of(context).padding.top + 20,
                                24,
                                32,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 40, height: 40),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const NotifikasiScreen(),
                                                ),
                                              ).then((unused) {
                                                addLocalActivity(
                                                  'Navigasi',
                                                  'Notifikasi',
                                                  'Mengakses halaman notifikasi',
                                                );
                                              });
                                            },
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2,),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.notifications_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          const ProfileScreen(),
                                                ),
                                              ).then((unused) {
                                                addLocalActivity(
                                                  'Navigasi',
                                                  'Profil',
                                                  'Mengakses halaman profil',
                                                );
                                              });
                                            },
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: Color(0xFF0083EE),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
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
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Semoga harimu penuh berkah dan menyenangkan',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withValues(alpha: 0.9,),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF61B8FF),
                                                Color(0xFF0083EE),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.search,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            onChanged: filterSiswa,
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Cari siswa, kelas, atau aktivitas...',
                                              hintStyle: GoogleFonts.poppins(
                                                color: const Color(0xFF9CA3AF),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      buildActionButton('Umum', 0),
                                      const SizedBox(width: 10),
                                      buildActionButton('PH', 2),
                                      const SizedBox(width: 10),
                                      buildActionButton('SP', 3),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                if (selectedTab == 2) ...[
                                  buildSiswaTerbaikSection(),
                                  const SizedBox(height: 20),
                                ] else if (selectedTab == 3) ...[
                                  buildSiswaBeratSection(),
                                  const SizedBox(height: 20),
                                ] else ...[
                                  buildEnhancedChartCard(
                                    'Grafik Apresiasi Siswa',
                                    'Pencapaian positif minggu ini',
                                    Icons.trending_up,
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF61B8FF),
                                        Color(0xFF0083EE),
                                      ],
                                    ),
                                    buildBarChart(
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
                                  ),
                                  const SizedBox(height: 20),
                                  buildEnhancedChartCard(
                                    'Grafik Pelanggaran Siswa',
                                    'Monitoring pelanggaran minggu ini',
                                    Icons.warning_amber_rounded,
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFFF2D6D7),
                                        Color(0xFFFF6B6D),
                                      ],
                                    ),
                                    buildBarChart(
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
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const ActivityScreen(),
                                        ),
                                      ).then((unused) {
                                        addLocalActivity(
                                          'Navigasi',
                                          'Aktivitas',
                                          'Mengakses halaman aktivitas',
                                        );
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06,),
                                            blurRadius: 20,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF61B8FF),
                                                          Color(0xFF0083EE),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.history,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Aktivitas Terkini',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Color(
                                                              0xFF1F2937,
                                                            ),
                                                          ),
                                                    ),
                                                    Text(
                                                      'Update terbaru dari aktivitas skoring',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            color: Color(
                                                              0xFF6B7280,
                                                            ),
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFF8FAFC),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 14,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          if (activityData.isEmpty)
                                            Text(
                                              'Belum ada aktivitas skoring.',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: const Color(0xFF9CA3AF),
                                              ),
                                            )
                                          else
                                            ...activityData
                                                .take(3)
                                                .map(
                                                  (activity) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                    child:
                                                        buildEnhancedActivityItem(
                                                          activity,
                                                        ),
                                                  ),
                                                ),
                                        ],
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
    );
  }

  Widget buildSiswaTerbaikSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PH (Penghargaan)',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Siswa dengan status PH1–PH3',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children:
                  filteredSiswaTerbaik.isEmpty
                      ? [
                        Text(
                          'Tidak ada hasil ditemukan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ]
                      : filteredSiswaTerbaik.asMap().entries.map((entry) {
                        int index = entry.key;
                        Student siswa = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index < filteredSiswaTerbaik.length - 1
                                    ? 16
                                    : 0,
                          ),
                          child: buildSiswaTerbaikItem(siswa),
                        );
                      }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSiswaBeratSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SP (Pelanggaran)',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Siswa dengan status SP1–SP3',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children:
                  filteredSiswaBerat.isEmpty
                      ? [
                        Text(
                          'Tidak ada hasil ditemukan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ]
                      : filteredSiswaBerat.asMap().entries.map((entry) {
                        int index = entry.key;
                        Student siswa = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index < filteredSiswaBerat.length - 1 ? 16 : 0,
                          ),
                          child: buildSiswaBeratItem(siswa),
                        );
                      }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSiswaTerbaikItem(Student siswa) {
    Color rankColor = getRankColor(siswa.rank);
    IconData rankIcon = getRankIcon(siswa.rank);

    return GestureDetector(
      onTap: () => navigateToDetailScreen(siswa),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rankColor.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: rankColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      siswa.rank <= 3
                          ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                          : [const Color(0xFF61B8FF), const Color(0xFF0083EE)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 24),
                  if (siswa.rank <= 3)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(rankIcon, color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: rankColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${siswa.rank}',
                          style: GoogleFonts.poppins(
                            color: rankColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          siswa.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0083EE).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          siswa.kelas,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0083EE),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${siswa.poin} poin',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    siswa.prestasi,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.trending_up, color: rankColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSiswaBeratItem(Student siswa) {
    Color rankColor = getRankColor(siswa.rank);

    return GestureDetector(
      onTap: () => navigateToDetailScreen(siswa),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rankColor.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: rankColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 24),
                  if (siswa.rank <= 3)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          getRankIcon(siswa.rank),
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: rankColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#${siswa.rank}',
                          style: GoogleFonts.poppins(
                            color: rankColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          siswa.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0083EE).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          siswa.kelas,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF0083EE),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF6B6D),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${siswa.poin} poin',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF6B6D),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    siswa.prestasi,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.trending_down, color: rankColor, size: 20),
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
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                      color: isActive ? const Color(0xFF1F2937) : Colors.white,
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

  Widget buildEnhancedChartCard(
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    Widget chart,
    int selectedTab,
    Function(int) onTabChanged,
    bool isFirst,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
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
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => GrafikScreen(
                          chartType: isFirst ? 'apresiasi' : 'pelanggaran',
                          title: title,
                          subtitle: subtitle,
                        ),
                  ),
                ).then((unused) {
                  addLocalActivity(
                    'Navigasi',
                    'Grafik ${isFirst ? 'Apresiasi' : 'Pelanggaran'}',
                    'Mengakses grafik ${isFirst ? 'apresiasi' : 'pelanggaran'}',
                  );
                });
              },
              child: chart,
            ),
          ),
        ],
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
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
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
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
    double maxValue =
        data.isNotEmpty
            ? data
                .map((e) => (e['value'] as double?) ?? 0.0)
                .reduce((a, b) => a > b ? a : b)
            : 1.0;

    return Container(
      height: 160,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${maxValue.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.75).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.5).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.25).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '0',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children:
                        data.map((item) {
                          double value = (item['value'] as double?) ?? 0.0;
                          double height =
                              maxValue > 0 ? (value / maxValue) * 120 : 0;
                          return Container(
                            width: 24,
                            height: height,
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
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
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      data.map((item) {
                        return Text(
                          (item['label'] as String?) ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
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

  Widget buildEnhancedActivityItem(Activity activity) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        ).then((unused) {
          addLocalActivity(
            'Navigasi',
            'Aktivitas',
            'Mengakses halaman aktivitas dari item',
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: activity.gradient),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(activity.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${activity.time} • ${activity.date}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: activity.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activity.statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    activity.status,
                    style: GoogleFonts.poppins(
                      color: activity.statusColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
}
