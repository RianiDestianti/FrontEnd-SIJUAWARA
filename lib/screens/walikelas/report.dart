import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/api/api_report.dart';
import 'package:skoring/widgets/exports/pdf.dart';
import 'package:skoring/widgets/exports/excel.dart';
import 'package:skoring/widgets/faq.dart';
import 'package:skoring/firebase/notification.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skoring/screens/walikelas/services/laporan_data_services.dart';
import 'package:skoring/screens/walikelas/utils/laporan_utils.dart';
import 'package:skoring/screens/walikelas/widgets/laporan_header_widgets.dart';
import 'package:skoring/screens/walikelas/widgets/laporan_card_widgets.dart';
import 'dart:io';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanScreen> createState() => LaporanScreenState();
}

class LaporanScreenState extends State<LaporanScreen>
    with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  String selectedFilter = 'Semua';
  String selectedView = 'Rekap';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  List<Student> studentsList = [];
  List<Kelas> kelasList = [];
  Map<String, FAQItem> faqData = {};
  Kelas? selectedKelas;

  bool isLoadingStudents = true;
  bool isLoadingKelas = true;
  bool isLoadingAspek = true;
  bool isRefreshing = false;

  String? errorMessageStudents;
  String? errorMessageKelas;
  String? errorMessageAspek;
  String? walikelasId;
  String? idKelas;

  Map<String, dynamic> aspekPenilaianData = {};
  final Map<String, bool> expandedSections = {};

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
    final creds = await LaporanDataService.loadCredentials();
    safeSetState(() {
      walikelasId = creds['walikelasId'];
      idKelas = creds['idKelas'];
    });
    await _refreshData();
  }

  Future<void> _refreshData() async {
    await Future.wait([_fetchKelas(), _fetchSiswa(), _fetchAspekPenilaian()]);
  }

  Future<void> manualRefresh() async {
    if (isRefreshing) return;
    safeSetState(() => isRefreshing = true);
    await _refreshData();
    safeSetState(() => isRefreshing = false);
  }

  Future<void> _fetchKelas() async {
    safeSetState(() {
      isLoadingKelas = true;
      errorMessageKelas = null;
    });
    try {
      final list = await LaporanDataService.fetchKelas();
      safeSetState(() {
        kelasList = list;
        selectedKelas =
            idKelas != null
                ? kelasList.firstWhere(
                  (k) => k.idKelas == idKelas,
                  orElse:
                      () =>
                          kelasList.isNotEmpty
                              ? kelasList.first
                              : Kelas(
                                idKelas: '',
                                namaKelas: 'Unknown',
                                jurusan: 'Unknown',
                              ),
                )
                : kelasList.isNotEmpty
                ? kelasList.first
                : null;
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
        errorMessageStudents = 'Data guru tidak lengkap.';
        isLoadingStudents = false;
      });
      return;
    }
    safeSetState(() {
      isLoadingStudents = true;
      errorMessageStudents = null;
    });
    try {
      final list = await LaporanDataService.fetchSiswa(
        walikelasId: walikelasId!,
        idKelas: idKelas!,
      );
      safeSetState(() {
        studentsList = list;
        isLoadingStudents = false;
      });
    } catch (e) {
      safeSetState(() {
        errorMessageStudents = 'Terjadi kesalahan: $e';
        isLoadingStudents = false;
      });
    }
  }

  Future<void> _fetchAspekPenilaian() async {
    safeSetState(() {
      isLoadingAspek = true;
      errorMessageAspek = null;
    });
    try {
      final aspekMap = await LaporanDataService.fetchAspekPenilaian();
      final Map<String, FAQItem> tempFaq = {};
      for (var entry in aspekMap.entries) {
        tempFaq[entry.key] = FAQItem.fromJson(entry.value);
        expandedSections[entry.key] = false;
      }
      safeSetState(() {
        faqData = tempFaq;
        aspekPenilaianData = aspekMap;
        isLoadingAspek = false;
      });
    } catch (e) {
      safeSetState(() {
        errorMessageAspek = 'Terjadi kesalahan: $e';
        isLoadingAspek = false;
      });
    }
  }

  List<Student> get _filteredStudents => LaporanUtils.filterAndSort(
    students: studentsList,
    selectedKelas: selectedKelas,
    selectedFilter: selectedFilter,
    searchQuery: searchQuery,
  );

  Future<void> _exportToPdf() async {
    if (!await _ensureStoragePermission()) return;
    final fileName =
        'Laporan_Siswa_${selectedKelas?.namaKelas ?? 'Unknown'}.pdf';
    final savedPath = await PdfExport.exportToPDF(
      LaporanUtils.mappedStudentsForExport(_filteredStudents),
      fileName,
      kelas: selectedKelas?.namaKelas,
      filterLabel: LaporanUtils.filterDisplayLabel(selectedFilter),
      searchQuery: searchQuery,
    );
    _showExportSnackbar(savedPath, fileName);
  }

  Future<void> _exportToExcel() async {
    if (!await _ensureStoragePermission()) return;
    final fileName =
        'Laporan_Siswa_${selectedKelas?.namaKelas ?? 'Unknown'}.xlsx';
    final savedPath = await ExcelExport.exportToExcel(
      LaporanUtils.mappedStudentsForExport(_filteredStudents),
      fileName,
      kelas: selectedKelas?.namaKelas,
      filterLabel: LaporanUtils.filterDisplayLabel(selectedFilter),
      searchQuery: searchQuery,
    );
    _showExportSnackbar(savedPath, fileName);
  }

  void _showExportSnackbar(String? savedPath, String fileName) {
    if (!mounted) return;
    final message =
        savedPath != null && savedPath.isNotEmpty
            ? 'File tersimpan di $savedPath'
            : 'File berhasil dibuat';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    NotificationService.instance.showDownloadNotification(
      title: 'Unduhan selesai',
      body:
          savedPath != null && savedPath.isNotEmpty
              ? '$fileName\nTersimpan di: $savedPath'
              : fileName,
    );
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        final manage = await Permission.manageExternalStorage.request();
        if (manage.isPermanentlyDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Izin penyimpanan ditolak. Buka pengaturan untuk mengizinkan.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              action: SnackBarAction(
                label: 'Pengaturan',
                textColor: Colors.white,
                onPressed: openAppSettings,
              ),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (_) {}
    return true;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewPadding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Berdasarkan Nilai',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                ...['Semua', '0-50', '51-100', '101+', 'Negatif'].map(
                  (filter) => ListTile(
                    title: Text(
                      LaporanUtils.filterDisplayLabel(filter),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            selectedFilter == filter
                                ? const Color(0xFF0083EE)
                                : const Color(0xFF1F2937),
                      ),
                    ),
                    leading: Radio<String>(
                      value: filter,
                      groupValue: selectedFilter,
                      onChanged: (value) {
                        setState(() => selectedFilter = value!);
                        Navigator.pop(context);
                      },
                      activeColor: const Color(0xFF0083EE),
                    ),
                    onTap: () {
                      setState(() => selectedFilter = filter);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Ekspor Data',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih format ekspor untuk ${_filteredStudents.length} siswa:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text('PDF', style: GoogleFonts.poppins(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    _exportToPdf();
                  },
                ),
                ListTile(
                  title: Text(
                    'Excel',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportToExcel();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF0083EE),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showStudentDetail(Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => LaporanCardWidgets.buildStudentDetailSheet(
            student: student,
            kelasName: selectedKelas?.namaKelas,
            onClose: () => Navigator.pop(context),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        isLoadingKelas || isLoadingStudents || isLoadingAspek;
    final bool hasError =
        errorMessageKelas != null ||
        errorMessageStudents != null ||
        errorMessageAspek != null;
    final String? errorMessage =
        errorMessageKelas ?? errorMessageStudents ?? errorMessageAspek;
    final students = _filteredStudents;

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
                final maxWidth =
                    constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
                return Center(
                  child: SizedBox(
                    width: maxWidth,
                    child: FadeTransition(
                      opacity: fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: manualRefresh,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 20,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              children: [
                                _buildHeader(
                                  isLoading,
                                  hasError,
                                  students.length,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    20,
                                    20,
                                    100,
                                  ),
                                  child: _buildBody(
                                    isLoading: isLoading,
                                    hasError: hasError,
                                    errorMessage: errorMessage,
                                    students: students,
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

  Widget _buildHeader(bool isLoading, bool hasError, int studentCount) {
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LaporanHeaderWidgets.buildHeaderContent(
                    isLoading: isLoading,
                    hasError: hasError,
                    errorMessage:
                        errorMessageKelas ??
                        errorMessageStudents ??
                        errorMessageAspek,
                    selectedKelas: selectedKelas,
                    studentCount: studentCount,
                  ),
                ),
                const SizedBox(width: 12),
                LaporanHeaderWidgets.buildIconButtons(context),
              ],
            ),
            if (!isLoading && !hasError) ...[
              const SizedBox(height: 20),
              LaporanHeaderWidgets.buildSearchBar(
                controller: searchController,
                searchQuery: searchQuery,
                selectedView: selectedView,
                onChanged: (v) => setState(() => searchQuery = v),
                onClear:
                    () => setState(() {
                      searchQuery = '';
                      searchController.clear();
                    }),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  LaporanHeaderWidgets.buildViewButton(
                    text: 'Rekap',
                    view: 'Rekap',
                    selectedView: selectedView,
                    onTap:
                        () => setState(() {
                          selectedView = 'Rekap';
                          searchQuery = '';
                          searchController.clear();
                        }),
                  ),
                  const SizedBox(width: 10),
                  LaporanHeaderWidgets.buildViewButton(
                    text: 'Aspek Poin',
                    view: 'Aspek Poin',
                    selectedView: selectedView,
                    onTap:
                        () => setState(() {
                          selectedView = 'Aspek Poin';
                          searchQuery = '';
                          searchController.clear();
                        }),
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
    required String? errorMessage,
    required List<Student> students,
  }) {
    if (hasError) return LaporanCardWidgets.buildErrorState(errorMessage);
    if (isLoading) return LaporanCardWidgets.buildLoadingState();

    if (selectedView == 'Aspek Poin') {
      return FaqWidget(
        faqData: faqData.map(
          (key, value) => MapEntry(key, {
            'title': value.title,
            'type': value.jenisPoin,
            'items': value.items,
          }),
        ),
        expandedSections: expandedSections,
        searchQuery: searchQuery,
        onExpansionChanged:
            (code, expanded) =>
                setState(() => expandedSections[code] = expanded),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LaporanCardWidgets.buildStatCard(
                value: '${students.length}',
                label: 'Total Siswa',
                icon: Icons.people_outline,
                gradient: const LinearGradient(
                  colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LaporanCardWidgets.buildStatCard(
                value: '${LaporanUtils.averageApresiasi(students).toInt()}',
                label: 'Rata-rata\nApresiasi',
                icon: Icons.check_circle_outline,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LaporanCardWidgets.buildProgressCard(
                title: 'Apresiasi',
                percentage:
                    '${(LaporanUtils.apresiasiPercentage(students) * 100).toInt()}%',
                progress: LaporanUtils.apresiasiPercentage(students),
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LaporanCardWidgets.buildProgressCard(
                title: 'Pelanggaran',
                percentage:
                    '${(LaporanUtils.pelanggaranPercentage(students) * 100).toInt()}%',
                progress: LaporanUtils.pelanggaranPercentage(students),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder:
                (context, constraints) =>
                    LaporanCardWidgets.buildFilterAndDownloadRow(
                      filterLabel: LaporanUtils.filterDisplayLabel(
                        selectedFilter,
                      ),
                      onFilter: _showFilterBottomSheet,
                      onExport: _showExportDialog,
                      constraints: constraints,
                    ),
          ),
        ),
        const SizedBox(height: 16),
        if (students.isEmpty)
          LaporanCardWidgets.buildEmptyState(
            title:
                searchQuery.isNotEmpty
                    ? 'Siswa tidak ditemukan'
                    : 'Tidak ada siswa dalam range ini',
            subtitle:
                searchQuery.isNotEmpty
                    ? 'Coba ubah kata kunci pencarian'
                    : 'Coba pilih filter lain',
            onReset:
                () => setState(() {
                  searchQuery = '';
                  searchController.clear();
                  selectedFilter = 'Semua';
                }),
          )
        else
          ...students.map(
            (student) => LaporanCardWidgets.buildStudentCard(
              student: student,
              onTap: () => _showStudentDetail(student),
            ),
          ),
      ],
    );
  }
}
