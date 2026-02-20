import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skoring/models/api/api_student.dart';
import 'package:skoring/models/api/api_class.dart';
import 'package:skoring/screens/walikelas/detail.dart';
import 'package:skoring/screens/walikelas/notification.dart';
import 'package:skoring/screens/walikelas/profile.dart';
import 'package:skoring/screens/walikelas/services/siswa_data_services.dart';
import 'package:skoring/screens/walikelas/utils/siswa_utils.dart';
import 'package:skoring/screens/walikelas/widgets/siswa_header_widgets.dart';
import 'package:skoring/screens/walikelas/widgets/siswa_card_widgets.dart';

class SiswaScreen extends StatefulWidget {
  const SiswaScreen({Key? key}) : super(key: key);

  @override
  State<SiswaScreen> createState() => SiswaScreenState();
}

class SiswaScreenState extends State<SiswaScreen> with TickerProviderStateMixin {
  int selectedFilter = 0;
  String searchQuery = '';
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  final TextEditingController searchController = TextEditingController();

  List<Kelas> kelasList = [];
  List<Student> studentsList = [];
  Kelas? selectedKelas;

  bool isLoadingKelas = true;
  bool isLoadingSiswa = true;
  bool isRefreshing = false;

  String? errorMessageKelas;
  String? errorMessageSiswa;
  String? walikelasId;
  String? idKelas;

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
    _loadCredentialsThenFetch();
  }

  @override
  void dispose() {
    animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadCredentialsThenFetch() async {
    final creds = await SiswaDataService.loadCredentials();
    safeSetState(() {
      walikelasId = creds['walikelasId'];
      idKelas = creds['idKelas'];
    });
    await Future.wait([_fetchKelas(), _fetchSiswa()]);
  }

  Future<void> _fetchKelas() async {
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
      final list = await SiswaDataService.fetchKelas(
        walikelasId: walikelasId!,
        idKelas: idKelas!,
      );
      safeSetState(() {
        kelasList = list;
        selectedKelas = kelasList.firstWhere(
          (k) => k.idKelas == idKelas,
          orElse: () => kelasList.first,
        );
        isLoadingKelas = false;
      });
    } catch (e) {
      safeSetState(() {
        errorMessageKelas = 'Terjadi kesalahan: $e';
        isLoadingKelas = false;
      });
    }
  }

  Future<void> _fetchSiswa() async {
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
      final list = await SiswaDataService.fetchSiswa(
        walikelasId: walikelasId!,
        idKelas: idKelas!,
      );
      safeSetState(() {
        studentsList = list;
        isLoadingSiswa = false;
      });
    } catch (e) {
      safeSetState(() {
        errorMessageSiswa = 'Terjadi kesalahan: $e';
        isLoadingSiswa = false;
      });
    }
  }

  Future<void> refreshData() async {
    if (isRefreshing) return;
    safeSetState(() => isRefreshing = true);
    try {
      await Future.wait([_fetchKelas(), _fetchSiswa()]);
    } finally {
      safeSetState(() => isRefreshing = false);
    }
  }

  void navigateToDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          student: {
            'name': student.namaSiswa,
            'nis': student.nis.toString(),
            'status': student.status,
            'points': student.points,
            'absent': 0,
            'absen': student.nis,
            'idKelas': student.idKelas,
            'programKeahlian': selectedKelas?.jurusan.toUpperCase() ?? 'Tidak Diketahui',
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

  @override
  Widget build(BuildContext context) {
    final bool isLoading = isLoadingKelas || isLoadingSiswa;
    final bool hasError = errorMessageKelas != null || errorMessageSiswa != null;
    final filteredStudents = SiswaUtils.filterStudents(
      students: studentsList,
      selectedKelas: selectedKelas,
      selectedFilter: selectedFilter,
      searchQuery: searchQuery,
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
                final maxWidth = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              children: [
                                _buildHeader(isLoading, hasError),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: _buildBody(
                                    isLoading: isLoading,
                                    hasError: hasError,
                                    filteredStudents: filteredStudents,
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildHeader(bool isLoading, bool hasError) {
    return Container(
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SiswaHeaderWidgets.buildHeaderContent(
                    isLoading: isLoading,
                    hasError: hasError,
                    errorMessage: errorMessageKelas ?? errorMessageSiswa,
                    selectedKelas: selectedKelas,
                    studentsList: studentsList,
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF0083EE), size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isLoading && !hasError) ...[
              const SizedBox(height: 24),
              SiswaHeaderWidgets.buildSearchBar(
                controller: searchController,
                searchQuery: searchQuery,
                onChanged: (v) => setState(() => searchQuery = v),
                onClear: () => setState(() {
                  searchQuery = '';
                  searchController.clear();
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SiswaHeaderWidgets.buildFilterButton(
                    text: 'Akumulasi',
                    index: 0,
                    selectedFilter: selectedFilter,
                    onTap: () => setState(() => selectedFilter = 0),
                  ),
                  const SizedBox(width: 10),
                  SiswaHeaderWidgets.buildFilterButton(
                    text: 'Penghargaan',
                    index: 1,
                    selectedFilter: selectedFilter,
                    onTap: () => setState(() => selectedFilter = 1),
                  ),
                  const SizedBox(width: 10),
                  SiswaHeaderWidgets.buildFilterButton(
                    text: 'Pelanggaran',
                    index: 2,
                    selectedFilter: selectedFilter,
                    onTap: () => setState(() => selectedFilter = 2),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required bool hasError,
    required List<Student> filteredStudents,
  }) {
    if (hasError) return SiswaCardWidgets.buildErrorState(errorMessageKelas ?? errorMessageSiswa);
    if (isLoading) return SiswaCardWidgets.buildLoadingState();
    if (filteredStudents.isEmpty && selectedKelas != null) {
      return SiswaCardWidgets.buildEmptyState(
        onReset: () => setState(() {
          searchQuery = '';
          searchController.clear();
          selectedFilter = 0;
        }),
      );
    }

    return Column(
      children: filteredStudents.map((student) {
        return SiswaCardWidgets.buildStudentCard(
          student: student,
          selectedFilter: selectedFilter,
          onTap: () => navigateToDetail(student),
        );
      }).toList(),
    );
  }
}