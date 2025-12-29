import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'detail.dart';
import 'package:skoring/screens/walikelas/notification.dart';
import 'package:skoring/screens/profile.dart';
import 'package:skoring/models/api/api_kelas.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Student {
  final int nis;
  final String idKelas;
  final String namaSiswa;
  final int? poinApresiasi;
  final int? poinPelanggaran;
  final int? poinTotal;
  final String createdAt;
  final String updatedAt;
  final String? spLevel;
  final String? phLevel;

  Student({
    required this.nis,
    required this.idKelas,
    required this.namaSiswa,
    this.poinApresiasi,
    this.poinPelanggaran,
    this.poinTotal,
    required this.createdAt,
    required this.updatedAt,
    this.spLevel,
    this.phLevel,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      nis: int.tryParse(json['nis']?.toString() ?? '') ?? 0,
      idKelas: json['id_kelas']?.toString() ?? '',
      namaSiswa: json['nama_siswa']?.toString() ?? '',
      poinApresiasi:
          int.tryParse(json['poin_apresiasi']?.toString() ?? ''),
      poinPelanggaran:
          int.tryParse(json['poin_pelanggaran']?.toString() ?? ''),
      poinTotal: int.tryParse(json['poin_total']?.toString() ?? ''),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      spLevel: json['sp_level']?.toString(),
      phLevel: json['ph_level']?.toString(),
    );
  }

  String get status {
    int totalPoints = poinTotal ?? 0;
    if (totalPoints >= 0) {
      return 'Aman';
    } else if (totalPoints >= -20) {
      return 'Bermasalah';
    } else {
      return 'Prioritas';
    }
  }

  int get points => poinTotal ?? 0;

  String get spLevelDisplay {
    final sp = spLevel?.trim();
    if (sp != null && sp.isNotEmpty) {
      return sp;
    }
    final totalPoints = poinTotal ?? 0;
    if (totalPoints <= -76) return 'SP3';
    if (totalPoints <= -51) return 'SP2';
    if (totalPoints <= -25) return 'SP1';
    return '-';
  }

  String get phLevelDisplay {
    final totalPoints = poinTotal ?? 0;
    if (totalPoints <= -25) return '-';
    final ph = phLevel?.trim();
    if (ph != null && ph.isNotEmpty) {
      return ph;
    }
    if (totalPoints >= 151) return 'PH3';
    if (totalPoints >= 126) return 'PH2';
    if (totalPoints >= 100) return 'PH1';
    return '-';
  }
}

class SiswaScreen extends StatefulWidget {
  const SiswaScreen({Key? key}) : super(key: key);

  @override
  State<SiswaScreen> createState() => _SiswaScreenState();
}

class _SiswaScreenState extends State<SiswaScreen>
    with TickerProviderStateMixin {
  int _selectedFilter = 0;
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  TextEditingController _searchController = TextEditingController();
  List<Kelas> kelasList = [];
  List<Student> studentsList = [];
  Kelas? selectedKelas;
  bool isLoadingKelas = true;
  bool isLoadingSiswa = true;
  String? errorMessageKelas;
  String? errorMessageSiswa;
  String? walikelasId;
  String? idKelas;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _loadWalikelasId().then((_) {
      fetchKelas();
      fetchSiswa();
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadWalikelasId() async {
    final prefs = await SharedPreferences.getInstance();
    _safeSetState(() {
      walikelasId = prefs.getString('walikelas_id');
      idKelas = prefs.getString('id_kelas');
      print('Loaded walikelasId: $walikelasId, id_kelas: $idKelas');
    });
  }

Future<void> fetchKelas() async {
  if (walikelasId == null || idKelas == null) {
    _safeSetState(() {
      errorMessageKelas = 'Data guru tidak lengkap. Silakan login ulang.';
      isLoadingKelas = false;
    });
    return;
  }

  _safeSetState(() {
    isLoadingKelas = true;
    errorMessageKelas = null;
  });

  try {
    final uri = Uri.parse(
      'http://sijuwara.student.smkn11bdg.sch.id/api/kelas?nip=$walikelasId&id_kelas=$idKelas',
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    print('GET $uri -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData['success']) {
        List<dynamic> data = jsonData['data'];
        if (data.isNotEmpty) {
          _safeSetState(() {
            kelasList = data.map((json) => Kelas.fromJson(json)).toList();
            selectedKelas = kelasList.firstWhere(
              (kelas) => kelas.idKelas == idKelas,
              orElse: () => kelasList.first,
            );
            isLoadingKelas = false;
          });
        } else {
          _safeSetState(() {
            errorMessageKelas = 'Tidak ada data kelas ditemukan';
            isLoadingKelas = false;
          });
        }
      } else {
        _safeSetState(() {
          errorMessageKelas = jsonData['message'] ?? 'Gagal memuat kelas';
          isLoadingKelas = false;
        });
      }
    } else {
      _safeSetState(() {
        errorMessageKelas = 'Gagal mengambil data kelas (${response.statusCode})';
        isLoadingKelas = false;
      });
    }
  } catch (e) {
    print('Error fetchKelas: $e');
    _safeSetState(() {
      errorMessageKelas = 'Terjadi kesalahan: $e';
      isLoadingKelas = false;
    });
  }
}

Future<void> fetchSiswa() async {
  if (walikelasId == null || idKelas == null) {
    _safeSetState(() {
      errorMessageSiswa = 'Data guru tidak lengkap. Silakan login ulang.';
      isLoadingSiswa = false;
    });
    return;
  }

  _safeSetState(() {
    isLoadingSiswa = true;
    errorMessageSiswa = null;
  });

  try {
    final uri = Uri.parse(
      'http://sijuwara.student.smkn11bdg.sch.id/api/siswa?nip=$walikelasId&id_kelas=$idKelas',
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    print('GET $uri -> ${response.statusCode}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData['success']) {
        List<dynamic> data = jsonData['data'];
        _safeSetState(() {
          studentsList = data.map((json) => Student.fromJson(json)).toList();
          isLoadingSiswa = false;
        });
      } else {
        _safeSetState(() {
          errorMessageSiswa = jsonData['message'] ?? 'Gagal memuat data siswa';
          isLoadingSiswa = false;
        });
      }
    } else {
      _safeSetState(() {
        errorMessageSiswa = 'Gagal mengambil data siswa (${response.statusCode})';
        isLoadingSiswa = false;
      });
    }
  } catch (e) {
    print('Error fetchSiswa: $e');
    _safeSetState(() {
      errorMessageSiswa = 'Terjadi kesalahan: $e';
      isLoadingSiswa = false;
    });
  }
}

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Student> getFilteredStudents() {
    if (selectedKelas == null) return [];

    List<Student> filtered =
        studentsList
            .where((student) => student.idKelas == selectedKelas!.idKelas)
            .toList();

    if (_selectedFilter == 1) {
      filtered =
          filtered.where((s) => (s.poinApresiasi ?? 0) > 0).toList();
    } else if (_selectedFilter == 2) {
      filtered =
          filtered
              .where((s) => (s.poinPelanggaran ?? 0) > 0)
              .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (s) =>
                    s.namaSiswa.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    s.nis.toString().contains(_searchQuery),
              )
              .toList();
    }
    return filtered;
  }

  void _navigateToDetail(Student student) {
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

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    _safeSetState(() => _isRefreshing = true);
    try {
      await Future.wait([fetchKelas(), fetchSiswa()]);
    } finally {
      _safeSetState(() => _isRefreshing = false);
    }
  }

  Widget _buildHeaderContent() {
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
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
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
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
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
                                  Container(
                                    width: double.infinity,
                                    child: _buildHeaderContent(),
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
                                        borderRadius: BorderRadius.circular(25),
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
                                              controller: _searchController,
                                              onChanged: (value) {
                                                setState(() {
                                                  _searchQuery = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Cari nama siswa atau NIS...',
                                                hintStyle: GoogleFonts.poppins(
                                                  color: const Color(
                                                    0xFF9CA3AF,
                                                  ),
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
                                          if (_searchQuery.isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _searchQuery = '';
                                                  _searchController.clear();
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
                                        _buildActionButton('Akumulasi', 0),
                                        const SizedBox(width: 10),
                                        _buildActionButton('Penghargaan', 1),
                                        const SizedBox(width: 10),
                                        _buildActionButton('Pelanggaran', 2),
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
                                _buildErrorState()
                              else if (isLoading)
                                _buildLoadingState()
                              else ...[
                                if (filteredStudents.isEmpty &&
                                    selectedKelas != null)
                                  _buildEmptyState()
                                else
                                  Column(
                                    children:
                                        filteredStudents.asMap().entries.map((
                                          entry,
                                        ) {
                                          return _buildStudentCard(
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

  Widget _buildLoadingState() {
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

  Widget _buildErrorState() {
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

  Widget _buildActionButton(String text, int index) {
    bool isActive = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
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

  Widget _buildStatusChip(String label, Color color) {
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

  Widget _buildStudentCard(Student student, int index) {
    int _getDisplayPoints() {
      if (_selectedFilter == 1) {
        return (student.poinApresiasi ?? 0);
      }
      if (_selectedFilter == 2) {
        return (student.poinPelanggaran ?? 0).abs();
      }
      return student.points;
    }

    String _getPointLabel() {
      if (_selectedFilter == 1) return 'Penghargaan';
      if (_selectedFilter == 2) return 'Pelanggaran';
      return 'Poin';
    }

    Color _getPointColor() {
      if (_selectedFilter == 1) return const Color(0xFF10B981);
      if (_selectedFilter == 2) return const Color(0xFFFF6B6D);
      return student.points >= 0
          ? const Color(0xFF10B981)
          : const Color(0xFFFF6B6D);
    }

    final displayPoints = _getDisplayPoints();
    final pointLabel = _getPointLabel();
    final pointColor = _getPointColor();
    final spLevel = student.spLevelDisplay;
    final phLevel = student.phLevelDisplay;
    final hasSp = spLevel != '-';
    final hasPh = phLevel != '-';

    return GestureDetector(
      onTap: () => _navigateToDetail(student),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getStatusColor(student.status).withOpacity(0.2),
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
                          _buildStatusChip(
                            spLevel,
                            const Color(0xFFFF6B6D),
                          ),
                        if (hasPh)
                          _buildStatusChip(
                            phLevel,
                            const Color(0xFF10B981),
                          ),
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

  Widget _buildEmptyState() {
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
                _searchQuery = '';
                _searchController.clear();
                _selectedFilter = 0;
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

  Color _getStatusColor(String status) {
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
