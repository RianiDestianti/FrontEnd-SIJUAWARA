import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:skoring/config/api.dart';
import 'package:skoring/models/api/api_student.dart';
import 'detail.dart';
import 'package:skoring/screens/walikelas/notification.dart';
import 'package:skoring/screens/walikelas/profile.dart';
import 'package:skoring/models/api/api_class.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiswaScreen extends StatefulWidget {
  const SiswaScreen({Key? key}) : super(key: key);

  @override
  State<SiswaScreen> createState() => SiswaScreenState();
}

class SiswaScreenState extends State<SiswaScreen>
    with TickerProviderStateMixin {
  int selectedFilter = 0;
  String searchQuery = '';
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  TextEditingController searchController = TextEditingController();
  List<Kelas> kelasList = [];
  List<Student> studentsList = [];
  Kelas? selectedKelas;
  bool isLoadingKelas = true;
  bool isLoadingSiswa = true;
  String? errorMessageKelas;
  String? errorMessageSiswa;
  String? walikelasId;
  String? idKelas;
  bool isRefreshing = false;

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
    animationController.forward();

    loadWalikelasId().then((unused) {
      fetchKelas();
      fetchSiswa();
    });
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> loadWalikelasId() async {
    final prefs = await SharedPreferences.getInstance();
    safeSetState(() {
      walikelasId = prefs.getString('walikelas_id');
      idKelas = prefs.getString('id_kelas');
      print('Loaded walikelasId: $walikelasId, id_kelas: $idKelas');
    });
  }

  Future<void> fetchKelas() async {
    if (walikelasId == null || idKelas == null) {
      safeSetState(() {
        errorMessageKelas = 'Data guru tidak lengkap. Silakan login ulang.';
        isLoadingKelas = false;
      });
      return;
    }

    safeSetState(() {
      isLoadingKelas = true;
      errorMessageKelas = null;
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/kelas?nip=$walikelasId&id_kelas=$idKelas',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('GET $uri -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['success']) {
          List<dynamic> data = jsonData['data'];
          if (data.isNotEmpty) {
            safeSetState(() {
              kelasList = data.map((json) => Kelas.fromJson(json)).toList();
              selectedKelas = kelasList.firstWhere(
                (kelas) => kelas.idKelas == idKelas,
                orElse: () => kelasList.first,
              );
              isLoadingKelas = false;
            });
          } else {
            safeSetState(() {
              errorMessageKelas = 'Tidak ada data kelas ditemukan';
              isLoadingKelas = false;
            });
          }
        } else {
          safeSetState(() {
            errorMessageKelas = jsonData['message'] ?? 'Gagal memuat kelas';
            isLoadingKelas = false;
          });
        }
      } else {
        safeSetState(() {
          errorMessageKelas =
              'Gagal mengambil data kelas (${response.statusCode})';
          isLoadingKelas = false;
        });
      }
    } catch (e) {
      print('Error fetchKelas: $e');
      safeSetState(() {
        errorMessageKelas = 'Terjadi kesalahan: $e';
        isLoadingKelas = false;
      });
    }
  }

  Future<void> fetchSiswa() async {
    if (walikelasId == null || idKelas == null) {
      safeSetState(() {
        errorMessageSiswa = 'Data guru tidak lengkap. Silakan login ulang.';
        isLoadingSiswa = false;
      });
      return;
    }

    safeSetState(() {
      isLoadingSiswa = true;
      errorMessageSiswa = null;
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/siswa?nip=$walikelasId&id_kelas=$idKelas',
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      print('GET $uri -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['success']) {
          List<dynamic> data = jsonData['data'];
          safeSetState(() {
            studentsList = data.map((json) => Student.fromJson(json)).toList();
            isLoadingSiswa = false;
          });
        } else {
          safeSetState(() {
            errorMessageSiswa =
                jsonData['message'] ?? 'Gagal memuat data siswa';
            isLoadingSiswa = false;
          });
        }
      } else {
        safeSetState(() {
          errorMessageSiswa =
              'Gagal mengambil data siswa (${response.statusCode})';
          isLoadingSiswa = false;
        });
      }
    } catch (e) {
      print('Error fetchSiswa: $e');
      safeSetState(() {
        errorMessageSiswa = 'Terjadi kesalahan: $e';
        isLoadingSiswa = false;
      });
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  List<Student> getFilteredStudents() {
    if (selectedKelas == null) return [];

    List<Student> filtered =
        studentsList
            .where((student) => student.idKelas == selectedKelas!.idKelas)
            .toList();

    if (selectedFilter == 1) {
      filtered = filtered.where((s) => (s.poinApresiasi ?? 0) > 0).toList();
    } else if (selectedFilter == 2) {
      filtered = filtered.where((s) => (s.poinPelanggaran ?? 0) > 0).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (s) =>
                    s.namaSiswa.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    s.nis.toString().contains(searchQuery),
              )
              .toList();
    }
    return filtered;
  }

  void navigateToDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DetailScreen(
              student: {
                'name': student.namaSiswa,
                'nis': student.nis.toString(),
                'status': student.status,
                'points': student.points,
                'absent': 0,
                'absen': student.nis,
                'idKelas': student.idKelas,
                'programKeahlian':
                    selectedKelas?.jurusan.toUpperCase() ?? 'Tidak Diketahui',
                'kelas': selectedKelas?.namaKelas ?? 'Tidak Diketahui',
                'poinApresiasi': student.poinApresiasi ?? 0,
                'poinPelanggaran': student.poinPelanggaran ?? 0,
                'spLevel': student.spLevelDisplay,
                'phLevel': student.phLevelDisplay,
              },
            ),
      ),
    );
  }

  Future<void> refreshData() async {
    if (isRefreshing) return;
    safeSetState(() => isRefreshing = true);
    try {
      await Future.wait([fetchKelas(), fetchSiswa()]);
    } finally {
      safeSetState(() => isRefreshing = false);
    }
  }

  Widget buildHeaderContent() {
    final bool isLoading = isLoadingKelas || isLoadingSiswa;
    final bool hasError =
        errorMessageKelas != null || errorMessageSiswa != null;

    if (isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Memuat data...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessageKelas ??
                errorMessageSiswa ??
                'Gagal memuat data dari server',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    if (selectedKelas != null) {
      final studentsInClass =
          studentsList
              .where((student) => student.idKelas == selectedKelas!.idKelas)
              .length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daftar Siswa ${selectedKelas!.namaKelas}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jurusan: ${selectedKelas!.jurusan.toUpperCase()}',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Siswa: $studentsInClass - Semester Ganjil 2025/2026',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Text(
      'Tidak ada kelas terkait',
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = getFilteredStudents();
    final bool isLoading = isLoadingKelas || isLoadingSiswa;
    final bool hasError =
        errorMessageKelas != null || errorMessageSiswa != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth =
                constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: maxWidth,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: refreshData,
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
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  20,
                                  24,
                                  32,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                );
                                              },
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.notifications_rounded,
                                                  color: Colors.white,
                                                  size: 24,
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
                                                );
                                              },
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
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
                                    Container(
                                      width: double.infinity,
                                      child: buildHeaderContent(),
                                    ),
                                    if (!isLoading && !hasError) ...[
                                      const SizedBox(height: 24),
                                      Container(
                                        height: 50,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
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
                                                borderRadius:
                                                    BorderRadius.circular(30),
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
                                                controller: searchController,
                                                onChanged: (value) {
                                                  setState(() {
                                                    searchQuery = value;
                                                  });
                                                },
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Cari nama siswa atau NIS...',
                                                  hintStyle:
                                                      GoogleFonts.poppins(
                                                        color: const Color(
                                                          0xFF9CA3AF,
                                                        ),
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  color: const Color(
                                                    0xFF1F2937,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (searchQuery.isNotEmpty)
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    searchQuery = '';
                                                    searchController.clear();
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  child: const Icon(
                                                    Icons.clear,
                                                    color: Color(0xFF6B7280),
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          buildActionButton('Akumulasi', 0),
                                          const SizedBox(width: 10),
                                          buildActionButton('Penghargaan', 1),
                                          const SizedBox(width: 10),
                                          buildActionButton('Pelanggaran', 2),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                if (hasError)
                                  buildErrorState()
                                else if (isLoading)
                                  buildLoadingState()
                                else ...[
                                  if (filteredStudents.isEmpty &&
                                      selectedKelas != null)
                                    buildEmptyState()
                                  else
                                    Column(
                                      children:
                                          filteredStudents.asMap().entries.map((
                                            entry,
                                          ) {
                                            return buildStudentCard(
                                              entry.value,
                                              entry.key,
                                            );
                                          }).toList(),
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

  Widget buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0083EE)),
          ),
          const SizedBox(height: 24),
          Text(
            'Memuat data siswa...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFFF6B6D),
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Gagal memuat data',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessageKelas ??
                errorMessageSiswa ??
                'Terjadi kesalahan tidak diketahui',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton(String text, int index) {
    bool isActive = selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                isActive
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
                      colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              if (isActive && index == 1)
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
              if (isActive && index == 2)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEA580C), Color(0xFFFF6B6D)],
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
                          isActive
                              ? (index == 0
                                  ? const Color(0xFF1F2937)
                                  : index == 1
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFFEA580C))
                              : Colors.white,
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

  Widget buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget buildStudentCard(Student student, int index) {
    int getDisplayPoints() {
      if (selectedFilter == 1) {
        return (student.poinApresiasi ?? 0);
      }
      if (selectedFilter == 2) {
        return (student.poinPelanggaran ?? 0).abs();
      }
      return student.points;
    }

    String getPointLabel() {
      if (selectedFilter == 1) return 'Penghargaan';
      if (selectedFilter == 2) return 'Pelanggaran';
      return 'Poin';
    }

    Color getPointColor() {
      if (selectedFilter == 1) return const Color(0xFF10B981);
      if (selectedFilter == 2) return const Color(0xFFFF6B6D);
      return student.points >= 0
          ? const Color(0xFF10B981)
          : const Color(0xFFFF6B6D);
    }

    final displayPoints = getDisplayPoints();
    final pointLabel = getPointLabel();
    final pointColor = getPointColor();
    final spLevel = student.spLevelDisplay;
    final phLevel = student.phLevelDisplay;
    final hasSp = spLevel != '-';
    final hasPh = phLevel != '-';

    return GestureDetector(
      onTap: () => navigateToDetail(student),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: getStatusColor(student.status).withOpacity(0.2),
            width: 2,
          ),
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFEDBCC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  student.namaSiswa[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.namaSiswa,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasSp || hasPh)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (hasSp)
                          buildStatusChip(spLevel, const Color(0xFFFF6B6D)),
                        if (hasPh)
                          buildStatusChip(phLevel, const Color(0xFF10B981)),
                      ],
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '$pointLabel: $displayPoints',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pointColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0083EE).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.search_off, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada siswa ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau kata kunci pencarian',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                searchQuery = '';
                searchController.clear();
                selectedFilter = 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0083EE).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Reset Filter',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Aman':
        return const Color(0xFF10B981);
      case 'Bermasalah':
        return const Color(0xFFEA580C);
      case 'Prioritas':
        return const Color(0xFFFF6B6D);
      default:
        return const Color(0xFF0083EE);
    }
  }
}
