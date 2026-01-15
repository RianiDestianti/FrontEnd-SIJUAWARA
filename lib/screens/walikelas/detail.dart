import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/api/api_detail.dart';
import 'point.dart';
import 'note.dart';
import 'history.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const DetailScreen({Key? key, required this.student}) : super(key: key);

  @override
  State<DetailScreen> createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  static const int maxHistoryPreview = 5;
  int selectedTab = 0;
  late Student detailedStudent;
  List<ViolationHistory> pelanggaranHistory = [];
  List<AppreciationHistory> apresiasiHistory = [];
  List<AccumulationHistory> akumulasiHistory = [];
  bool isLoadingAppreciations = true;
  bool isLoadingViolations = true;
  bool isLoadingStudent = true;
  String? errorMessageAppreciations;
  String? errorMessageViolations;
  String? errorMessageStudent;
  List<dynamic> aspekPenilaianData = [];
  String nipWalikelas = '';
  String idKelas = '';

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );
    animationController.forward();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nipWalikelas = prefs.getString('walikelas_id') ?? '';
      idKelas = prefs.getString('id_kelas') ?? '';
    });

    if (nipWalikelas.isEmpty || idKelas.isEmpty) {
      setState(() {
        errorMessageStudent = 'Data guru tidak lengkap. Silakan login ulang.';
        isLoadingStudent = false;
      });
      return;
    }

    await fetchAspekPenilaian();
    initializeStudentData();
  }

  Future<void> refreshData() async {
    await loadUserData();
  }

  void initializeStudentData() {
    setState(() {
      isLoadingStudent = true;
      errorMessageStudent = null;
    });

    try {
      final data = widget.student;
      final poinTotal = int.tryParse(data['points']?.toString() ?? '') ?? 0;
      final spLevelRaw = data['spLevel'] ?? data['sp_level'];
      final phLevelRaw = data['phLevel'] ?? data['ph_level'];
      final spLevel = resolveSpLevel(spLevelRaw?.toString(), poinTotal);
      final phLevel = resolvePhLevel(phLevelRaw?.toString(), poinTotal);

      detailedStudent = Student(
        name: data['name'] ?? 'Unknown',
        nis: data['nis'] ?? '0',
        programKeahlian: data['programKeahlian'] ?? data['kelas'] ?? 'Unknown',
        kelas: data['kelas'] ?? 'Unknown',
        poinApresiasi: data['poinApresiasi'] ?? 0,
        poinPelanggaran: (data['poinPelanggaran'] ?? 0).abs(),
        poinTotal: poinTotal,
        spLevel: spLevel,
        phLevel: phLevel,
      );

      setState(() => isLoadingStudent = false);
      fetchAppreciations(data['nis']);
      fetchViolations(data['nis']);
    } catch (e) {
      setState(() {
        errorMessageStudent = 'Gagal memuat detail siswa: $e';
        isLoadingStudent = false;
      });
    }
  }

  String resolveSpLevel(String? spLevel, int poinTotal) {
    final sp = spLevel?.trim();
    if (sp != null && sp.isNotEmpty) {
      return sp;
    }
    if (poinTotal <= -76) return 'SP3';
    if (poinTotal <= -51) return 'SP2';
    if (poinTotal <= -25) return 'SP1';
    return '-';
  }

  String resolvePhLevel(String? phLevel, int poinTotal) {
    if (poinTotal <= -25) return '-';
    final ph = phLevel?.trim();
    if (ph != null && ph.isNotEmpty) {
      return ph;
    }
    if (poinTotal >= 151) return 'PH3';
    if (poinTotal >= 126) return 'PH2';
    if (poinTotal >= 100) return 'PH1';
    return '-';
  }

  Future<void> fetchAspekPenilaian() async {
    setState(() {
      errorMessageStudent = null;
    });
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/aspekpenilaian?nip=$nipWalikelas&id_kelas=$idKelas',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['success']) {
          setState(() {
            aspekPenilaianData = jsonData['data'];
          });
        } else {
          setState(() {
            errorMessageStudent =
                jsonData['message'] ?? 'Gagal memuat aspek penilaian';
          });
        }
      } else {
        setState(() {
          errorMessageStudent = 'Gagal mengambil data (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        errorMessageStudent = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> fetchAppreciations(String nis) async {
    setState(() {
      isLoadingAppreciations = true;
      errorMessageAppreciations = null;
    });
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/skoring_penghargaan?nip=$nipWalikelas&id_kelas=$idKelas',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        setState(() {
          errorMessageAppreciations =
              'Gagal mengambil penilaian (${response.statusCode})';
          isLoadingAppreciations = false;
        });
        return;
      }

      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> evaluations =
          (jsonData['penilaian']?['data'] as List<dynamic>? ?? [])
              .where((e) => e['nis'].toString() == nis)
              .toList();

      final historiesWithDate =
          evaluations.map<Map<String, dynamic>>((eval) {
              final aspek = aspekPenilaianData.firstWhere(
                (a) =>
                    a['id_aspekpenilaian'].toString() ==
                    eval['id_aspekpenilaian'].toString(),
                orElse:
                    () => {
                      'uraian': 'Apresiasi',
                      'indikator_poin': 0,
                      'kategori': 'Umum',
                      'jenis_poin': 'Apresiasi',
                    },
              );
              final createdAt =
                  DateTime.tryParse(eval['created_at'] ?? '') ?? DateTime.now();
              return {
                'createdAt': createdAt,
                'history': AppreciationHistory(
                  type: aspek['kategori']?.toString() ?? 'Apresiasi',
                  description: aspek['uraian']?.toString() ?? 'Apresiasi',
                  date: DateFormat('dd MMM yyyy').format(createdAt),
                  time: DateFormat('HH:mm').format(createdAt),
                  points:
                      ((aspek['indikator_poin'] as num? ?? 0).abs()).toInt(),
                  icon: Icons.star,
                  color: const Color(0xFF10B981),
                  kategori: aspek['kategori'] ?? 'Umum',
                ),
              };
            }).toList()
            ..sort(
              (a, b) => (b['createdAt'] as DateTime).compareTo(
                a['createdAt'] as DateTime,
              ),
            );

      setState(() {
        apresiasiHistory =
            historiesWithDate
                .map<AppreciationHistory>(
                  (e) => e['history'] as AppreciationHistory,
                )
                .toList();
        isLoadingAppreciations = false;
        calculateAccumulations();
      });
    } catch (e) {
      setState(() {
        errorMessageAppreciations = 'Terjadi kesalahan: $e';
        isLoadingAppreciations = false;
      });
    }
  }

  Future<void> fetchViolations(String nis) async {
    setState(() {
      isLoadingViolations = true;
      errorMessageViolations = null;
    });

    try {
      Future<http.Response> loadPelanggaran() {
        return http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/skoring_pelanggaran?nip=$nipWalikelas&id_kelas=$idKelas',
          ),
          headers: {'Accept': 'application/json'},
        );
      }

      var response = await loadPelanggaran();
      if (response.statusCode != 200) {
        response = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/skoring_2pelanggaran?nip=$nipWalikelas&id_kelas=$idKelas',
          ),
          headers: {'Accept': 'application/json'},
        );
      }

      if (response.statusCode != 200) {
        setState(() {
          errorMessageViolations =
              'Gagal mengambil penilaian (${response.statusCode})';
          isLoadingViolations = false;
        });
        return;
      }

      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> evaluations =
          (jsonData['penilaian']?['data'] as List<dynamic>? ?? [])
              .where((e) => e['nis'].toString() == nis)
              .toList();

      final historiesWithDate =
          evaluations.map<Map<String, dynamic>>((eval) {
              final aspek = aspekPenilaianData.firstWhere(
                (a) =>
                    a['id_aspekpenilaian'].toString() ==
                    eval['id_aspekpenilaian'].toString(),
                orElse:
                    () => {
                      'uraian': 'Pelanggaran',
                      'indikator_poin': 0,
                      'kategori': 'Umum',
                      'jenis_poin': 'Pelanggaran',
                    },
              );

              final createdAt =
                  DateTime.tryParse(eval['created_at'] ?? '') ?? DateTime.now();
              return {
                'createdAt': createdAt,
                'history': ViolationHistory(
                  type: aspek['kategori']?.toString() ?? 'Pelanggaran',
                  description: aspek['uraian']?.toString() ?? 'Pelanggaran',
                  date: DateFormat('dd MMM yyyy').format(createdAt),
                  time: DateFormat('HH:mm').format(createdAt),
                  points:
                      ((aspek['indikator_poin'] as num? ?? 0).abs()).toInt(),
                  icon: Icons.warning,
                  color: const Color(0xFFFF6B6D),
                  pelanggaranKe: null,
                  kategori: aspek['kategori'] ?? 'Umum',
                ),
              };
            }).toList()
            ..sort(
              (a, b) => (b['createdAt'] as DateTime).compareTo(
                a['createdAt'] as DateTime,
              ),
            );

      setState(() {
        pelanggaranHistory =
            historiesWithDate
                .map<ViolationHistory>((e) => e['history'] as ViolationHistory)
                .toList();
        isLoadingViolations = false;
        calculateAccumulations();
      });
    } catch (e) {
      setState(() {
        errorMessageViolations = 'Terjadi kesalahan: $e';
        isLoadingViolations = false;
      });
    }
  }

  void calculateAccumulations() {
    try {
      final totalApresiasiPoints = apresiasiHistory.fold<int>(
        0,
        (sum, item) => sum + item.points,
      );
      final totalPelanggaranPoints = pelanggaranHistory.fold<int>(
        0,
        (sum, item) => sum + item.points,
      );

      final totalPoints = totalApresiasiPoints - totalPelanggaranPoints;

      setState(() {
        akumulasiHistory = [
          AccumulationHistory(
            periode: 'Total Keseluruhan',
            pelanggaran: totalPelanggaranPoints,
            apresiasi: totalApresiasiPoints,
            total: totalPoints,
            date: 'Sampai ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          ),
        ];
      });
    } catch (e) {
      setState(() {
        errorMessageAppreciations =
            'Terjadi kesalahan dalam menghitung akumulasi: $e';
      });
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingStudent) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (errorMessageStudent != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessageStudent!,
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              ElevatedButton(
                onPressed: () => initializeStudentData(),
                child: Text('Coba Lagi', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    const backgroundGradient = [Color(0xFF61B8FF), Color(0xFF0083EE)];
    const shadowColor = Color(0x200083EE);

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
                    onRefresh: refreshData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: backgroundGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).padding.top,
                                  ),
                                  const SizedBox(height: 32),
                                  SlideTransition(
                                    position: slideAnimation,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEDBCC),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFEA580C,
                                                  ).withOpacity(0.2),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                detailedStudent.name[0]
                                                    .toUpperCase(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(
                                                    0xFFEA580C,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            detailedStudent.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${detailedStudent.kelas} - ${detailedStudent.programKeahlian}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    showPointPopup(
                                                      context,
                                                      detailedStudent.name,
                                                      detailedStudent.nis,
                                                      detailedStudent.kelas,
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
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
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFF0083EE,
                                                          ).withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Icon(
                                                          Icons.star_outline,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Berikan Poin',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    showBKNotePopup(
                                                      context,
                                                      detailedStudent.name,
                                                      detailedStudent.nis,
                                                      detailedStudent.kelas,
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 14,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFFFF6B6D),
                                                              Color(0xFFEA580C),
                                                            ],
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFFFF6B6D,
                                                          ).withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Icon(
                                                          Icons
                                                              .note_add_outlined,
                                                          color: Colors.white,
                                                          size: 18,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Penanganan',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Biodata Siswa',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  buildBiodataRow(
                                    'NIS',
                                    detailedStudent.nis,
                                    Icons.badge,
                                  ),
                                  buildBiodataRow(
                                    'Program Keahlian',
                                    detailedStudent.programKeahlian,
                                    Icons.school,
                                  ),
                                  buildBiodataRow(
                                    'Kelas',
                                    detailedStudent.kelas,
                                    Icons.class_,
                                  ),
                                  buildBiodataRow(
                                    'Poin Apresiasi',
                                    '+${detailedStudent.poinApresiasi}',
                                    Icons.star,
                                  ),
                                  buildBiodataRow(
                                    'Poin Pelanggaran',
                                    '-${detailedStudent.poinPelanggaran.abs()}',
                                    Icons.warning,
                                  ),
                                  buildBiodataRow(
                                    'Poin Total',
                                    '${detailedStudent.poinTotal > 0 ? '+' : ''}${detailedStudent.poinTotal}',
                                    Icons.calculate,
                                  ),
                                  buildBiodataRow(
                                    'Status SP',
                                    detailedStudent.spLevel,
                                    Icons.report,
                                  ),
                                  buildBiodataRow(
                                    'Status PH',
                                    detailedStudent.phLevel,
                                    Icons.emoji_events,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  buildTabButton('Pelanggaran', 0),
                                  buildTabButton('Apresiasi', 1),
                                  buildTabButton('Akumulasi', 2),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: buildTabContent(),
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

  Widget buildBiodataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0083EE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF0083EE)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabButton(String text, int index) {
    bool isActive = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 50,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0083EE) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTabContent() {
    switch (selectedTab) {
      case 0:
        return buildPelanggaranContent();
      case 1:
        return buildApresiasiContent();
      case 2:
        return buildAkumulasiContent();
      default:
        return buildPelanggaranContent();
    }
  }

  Widget buildPelanggaranContent() {
    final displayed =
        pelanggaranHistory.length > maxHistoryPreview
            ? pelanggaranHistory.take(maxHistoryPreview).toList()
            : pelanggaranHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histori Poin Pelanggaran',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        if (isLoadingViolations)
          const Center(child: CircularProgressIndicator())
        else if (errorMessageViolations != null)
          buildEmptyState(errorMessageViolations!, Icons.error)
        else if (pelanggaranHistory.isEmpty)
          buildEmptyState('Belum ada riwayat pelanggaran', Icons.warning)
        else ...[
          ...displayed.map(
            (item) => buildHistoryCard(item, isPelanggaran: true),
          ),
          if (pelanggaranHistory.length > maxHistoryPreview)
            buildSeeAllButton(),
        ],
      ],
    );
  }

  Widget buildApresiasiContent() {
    final displayed =
        apresiasiHistory.length > maxHistoryPreview
            ? apresiasiHistory.take(maxHistoryPreview).toList()
            : apresiasiHistory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histori Poin Apresiasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        if (isLoadingAppreciations)
          const Center(child: CircularProgressIndicator())
        else if (errorMessageAppreciations != null)
          buildEmptyState(errorMessageAppreciations!, Icons.error)
        else if (apresiasiHistory.isEmpty)
          buildEmptyState('Belum ada riwayat apresiasi', Icons.star)
        else ...[
          ...displayed.map(
            (item) => buildHistoryCard(item, isPelanggaran: false),
          ),
          if (apresiasiHistory.length > maxHistoryPreview) buildSeeAllButton(),
        ],
      ],
    );
  }

  Widget buildAkumulasiContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histori Akumulasi Poin',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        if (isLoadingAppreciations || isLoadingViolations)
          const Center(child: CircularProgressIndicator())
        else if (errorMessageAppreciations != null ||
            errorMessageViolations != null)
          buildEmptyState(
            (errorMessageAppreciations ?? errorMessageViolations)!,
            Icons.error,
          )
        else if (akumulasiHistory.isEmpty)
          buildEmptyState('Belum ada riwayat akumulasi', Icons.calculate)
        else
          ...akumulasiHistory.map((item) => buildAkumulasiCard(item)).toList(),
      ],
    );
  }

  Widget buildHistoryCard(dynamic item, {required bool isPelanggaran}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryScreen(student: widget.student),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: item.color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        'Kategori: ${item.kategori}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isPelanggaran ? '-${item.points}' : '+${item.points}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: item.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.date} - ${item.time}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSeeAllButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryScreen(student: widget.student),
              ),
            );
          },
          icon: const Icon(Icons.history, color: Color(0xFF0083EE)),
          label: Text(
            'Lihat semua riwayat',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0083EE),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF0083EE)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAkumulasiCard(AccumulationHistory item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.periode,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B6D).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: const Color(0xFFFF6B6D),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pelanggaran',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '-${item.pelanggaran}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF6B6D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: const Color(0xFF10B981),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Apresiasi',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '+${item.apresiasi}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0083EE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0083EE).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calculate,
                        color: const Color(0xFF0083EE),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '${item.total > 0 ? '+' : ''}${item.total}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0083EE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int totalPoints = item.apresiasi + item.pelanggaran;
                double redFraction =
                    totalPoints > 0 ? item.pelanggaran / totalPoints : 0;
                double greenFraction =
                    totalPoints > 0 ? item.apresiasi / totalPoints : 0;
                return Stack(
                  children: [
                    Container(
                      width: redFraction * constraints.maxWidth,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: greenFraction * constraints.maxWidth,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0083EE).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
