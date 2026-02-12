import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:skoring/screens/walikelas/notification.dart';
import 'package:skoring/screens/walikelas/profile.dart';
import 'package:skoring/widgets/exports/pdf.dart';
import 'package:skoring/widgets/exports/excel.dart';
import 'package:skoring/widgets/faq.dart';
import 'package:skoring/firebase/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/api/api_report.dart';
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
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  List<Student> studentsList = [];
  List<Kelas> kelasList = [];
  Map<String, FAQItem> faqData = {};
  Kelas? selectedKelas;
  bool isLoadingStudents = true;
  bool isLoadingKelas = true;
  bool isLoadingAspek = true;
  String? errorMessageStudents;
  String? errorMessageKelas;
  String? errorMessageAspek;
  String? walikelasId;
  String? idKelas;
  bool isRefreshing = false;
  Map<String, dynamic> aspekPenilaianData = {};

  Map<String, dynamic> spStatus(Student student) {
    final p = student.pelanggaran;
    if (p >= 76) {
      return {
        'label': 'SP3 (>=76)',
        'color': const Color(0xFF991B1B),
        'bg': const Color(0xFFFEE2E2),
      };
    }
    if (p >= 51) {
      return {
        'label': 'SP2 (51-75)',
        'color': const Color(0xFFB45309),
        'bg': const Color(0xFFFDE68A),
      };
    }
    if (p >= 25) {
      return {
        'label': 'SP1 (25-50)',
        'color': const Color(0xFF92400E),
        'bg': const Color(0xFFF5D0FE),
      };
    }
    return {
      'label': 'Aman (<25)',
      'color': const Color(0xFF047857),
      'bg': const Color(0xFFD1FAE5),
    };
  }

  Map<String, dynamic>? apresiasiBadge(Student student) {
    final a = student.apresiasi;
    if (a >= 151) {
      return {
        'label': 'Anugerah Waluya Utama 151+',
        'color': const Color(0xFF1D4ED8),
        'bg': const Color(0xFFDBEAFE),
      };
    }
    if (a >= 126) {
      return {
        'label': 'Sertifikat+Hadiah 126-150',
        'color': const Color(0xFF1D4ED8),
        'bg': const Color(0xFFE0F2FE),
      };
    }
    if (a >= 100) {
      return {
        'label': 'Sertifikat 100-125',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFE0F2FE),
      };
    }
    return null;
  }

  Widget statusChip(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  final Map<String, bool> expandedSections = {};

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

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
      refreshData();
    });
  }

  Future<void> loadWalikelasId() async {
    final prefs = await SharedPreferences.getInstance();
    safeSetState(() {
      walikelasId = prefs.getString('walikelas_id');
      idKelas = prefs.getString('id_kelas');
    });
  }

  Future<void> refreshData() async {
    await Future.wait([fetchKelas(), fetchSiswa(), fetchAspekPenilaian()]);
  }

  Future<void> manualRefresh() async {
    if (isRefreshing) return;
    safeSetState(() => isRefreshing = true);
    await refreshData();
    safeSetState(() => isRefreshing = false);
  }

  List<Map<String, dynamic>> mappedStudentsForExport() {
    return filteredAndSortedStudents
        .map(
          (s) => {
            'name': s.name,
            'nis': s.nis,
            'totalPoin': s.totalPoin,
            'apresiasi': s.apresiasi,
            'pelanggaran': s.pelanggaran,
            'isPositive': s.isPositive,
            'color': s.color,
            'avatar': s.avatar,
            'scores':
                s.scores
                    .map(
                      (score) => {
                        'keterangan': score.keterangan,
                        'tanggal': score.tanggal,
                        'poin': score.poin,
                        'type': score.type,
                      },
                    )
                    .toList(),
          },
        )
        .toList();
  }

  Future<void> exportToPdf(String filterLabel) async {
    if (!await ensureStoragePermission()) return;
    final fileName =
        'Laporan_Siswa_${selectedKelas?.namaKelas ?? 'Unknown'}.pdf';
    final savedPath = await PdfExport.exportToPDF(
      mappedStudentsForExport(),
      fileName,
      kelas: selectedKelas?.namaKelas,
      filterLabel: filterLabel,
      searchQuery: searchQuery,
    );
    if (mounted) {
      final message =
          savedPath != null && savedPath.isNotEmpty
              ? 'PDF tersimpan di $savedPath'
              : 'PDF berhasil dibuat';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      await NotificationService.instance.showDownloadNotification(
        title: 'Unduhan selesai',
        body:
            savedPath != null && savedPath.isNotEmpty
                ? '$fileName\nTersimpan di: $savedPath'
                : fileName,
      );
    }
  }

  Future<void> exportToExcel(String filterLabel) async {
    if (!await ensureStoragePermission()) return;
    final fileName =
        'Laporan_Siswa_${selectedKelas?.namaKelas ?? 'Unknown'}.xlsx';
    final savedPath = await ExcelExport.exportToExcel(
      mappedStudentsForExport(),
      fileName,
      kelas: selectedKelas?.namaKelas,
      filterLabel: filterLabel,
      searchQuery: searchQuery,
    );
    if (mounted) {
      final message =
          savedPath != null && savedPath.isNotEmpty
              ? 'Excel tersimpan di $savedPath'
              : 'Excel berhasil dibuat';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      await NotificationService.instance.showDownloadNotification(
        title: 'Unduhan selesai',
        body:
            savedPath != null && savedPath.isNotEmpty
                ? '$fileName\nTersimpan di: $savedPath'
                : fileName,
      );
    }
  }

  Future<bool> ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isPermanentlyDenied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (manageStatus.isPermanentlyDenied && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Izin penyimpanan ditolak permanen. Buka pengaturan untuk mengizinkan.',
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
    } catch (error) {}

    return true;
  }

  Future<void> fetchKelas() async {
    if (walikelasId == null) {
      safeSetState(() {
        errorMessageKelas = 'ID walikelas tidak ditemukan';
        isLoadingKelas = false;
      });
      return;
    }

    safeSetState(() {
      isLoadingKelas = true;
      errorMessageKelas = null;
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/kelas'))
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success']) {
          List<dynamic> data = jsonData['data'];
          safeSetState(() {
            kelasList = data.map((json) => Kelas.fromJson(json)).toList();
            selectedKelas =
                idKelas != null
                    ? kelasList.firstWhere(
                      (kelas) => kelas.idKelas == idKelas,
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
            if (selectedKelas?.idKelas.isEmpty ?? true) {
              errorMessageKelas = 'Kelas terkait tidak ditemukan';
            }
          });
        } else {
          safeSetState(() {
            errorMessageKelas = jsonData['message'];
            isLoadingKelas = false;
          });
        }
      } else {
        safeSetState(() {
          errorMessageKelas =
              'Gagal mengambil data kelas: ${response.statusCode}';
          isLoadingKelas = false;
        });
      }
    } catch (e) {
      safeSetState(() {
        errorMessageKelas = 'Terjadi kesalahan: $e';
        isLoadingKelas = false;
      });
    }
  }

  Future<void> fetchSiswa() async {
    if (walikelasId == null || idKelas == null) {
      safeSetState(() {
        errorMessageStudents = 'Data guru tidak lengkap. Silakan login ulang.';
        isLoadingStudents = false;
      });
      return;
    }

    safeSetState(() {
      isLoadingStudents = true;
      errorMessageStudents = null;
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/siswa?nip=$walikelasId&id_kelas=$idKelas',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['success']) {
          List<dynamic> data = jsonData['data'];
          final students =
              data
                  .map((studentJson) => Student.fromJson(studentJson, const []))
                  .toList();
          safeSetState(() {
            studentsList = students;
            isLoadingStudents = false;
          });
        } else {
          safeSetState(() {
            errorMessageStudents = jsonData['message'];
            isLoadingStudents = false;
          });
        }
      } else {
        safeSetState(() {
          errorMessageStudents =
              'Gagal mengambil data siswa: ${response.statusCode}';
          isLoadingStudents = false;
        });
      }
    } catch (e) {
      safeSetState(() {
        errorMessageStudents = 'Terjadi kesalahan: $e';
        isLoadingStudents = false;
      });
    }
  }

  Future<List<StudentScore>> fetchStudentScores(String nis) async {
    if (nis.isEmpty) return [];
    List<StudentScore> scores = [];
    try {
      final penghargaanResponse = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/skoring_penghargaan?nis=$nis&nip=$walikelasId&id_kelas=$idKelas',
            ),
          )
          .timeout(Duration(seconds: 10));
      if (penghargaanResponse.statusCode == 200) {
        final jsonData = jsonDecode(penghargaanResponse.body);
        if (jsonData['penilaian']['data'].isNotEmpty) {
          final appreciationsResponse = await http
              .get(Uri.parse('${ApiConfig.baseUrl}/Penghargaan'))
              .timeout(Duration(seconds: 10));
          if (appreciationsResponse.statusCode == 200) {
            final appreciationsData = jsonDecode(appreciationsResponse.body);
            if (appreciationsData['success']) {
              List<dynamic> appreciations = appreciationsData['data'];
              List<dynamic> studentEvaluations =
                  jsonData['penilaian']['data']
                      .where((eval) => eval['nis'].toString() == nis)
                      .toList();

              for (var eval in studentEvaluations) {
                final aspek =
                    aspekPenilaianData[eval['id_aspekpenilaian']?.toString()];
                if (aspek == null ||
                    aspek['jenis_poin']?.toString() != 'Apresiasi')
                  continue;

                final appreciation = appreciations.firstWhere((a) {
                  if (eval['created_at'] == null ||
                      a['tanggal_penghargaan'] == null)
                    return false;
                  try {
                    return DateTime.parse(
                          a['tanggal_penghargaan'],
                        ).isAtSameMomentAs(
                          DateTime.parse(eval['created_at'].substring(0, 10)),
                        ) ||
                        a['alasan'].toLowerCase().contains(
                          aspek['uraian'].toLowerCase(),
                        );
                  } catch (e) {
                    return false;
                  }
                }, orElse: () => null);

                if (appreciation != null) {
                  scores.add(
                    StudentScore.fromPenghargaan(
                      appreciation,
                      aspek['indikator_poin'] ??
                          (appreciation['level_penghargaan'] == 'PH1'
                              ? 10
                              : appreciation['level_penghargaan'] == 'PH2'
                              ? 20
                              : 30),
                    ),
                  );
                }
              }
            }
          }
        }
      }

      final peringatanResponse = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/skoring_pelanggaran?nis=$nis&nip=$walikelasId&id_kelas=$idKelas',
            ),
          )
          .timeout(Duration(seconds: 10));
      if (peringatanResponse.statusCode == 200) {
        final jsonData = jsonDecode(peringatanResponse.body);
        if (jsonData['penilaian']['data'].isNotEmpty) {
          final violationsResponse = await http
              .get(Uri.parse('${ApiConfig.baseUrl}/peringatan'))
              .timeout(Duration(seconds: 10));
          if (violationsResponse.statusCode == 200) {
            final violationsData = jsonDecode(violationsResponse.body);
            if (violationsData['success']) {
              List<dynamic> violations = violationsData['data'];
              List<dynamic> studentEvaluations =
                  jsonData['penilaian']['data']
                      .where((eval) => eval['nis'].toString() == nis)
                      .toList();

              for (var eval in studentEvaluations) {
                final aspek =
                    aspekPenilaianData[eval['id_aspekpenilaian']?.toString()];
                if (aspek == null ||
                    aspek['jenis_poin']?.toString() != 'Pelanggaran')
                  continue;

                final violation = violations.firstWhere((v) {
                  if (eval['created_at'] == null || v['tanggal_sp'] == null)
                    return false;
                  try {
                    return DateTime.parse(v['tanggal_sp']).isAtSameMomentAs(
                          DateTime.parse(eval['created_at'].substring(0, 10)),
                        ) ||
                        v['alasan'].toLowerCase().contains(
                          aspek['uraian'].toLowerCase(),
                        );
                  } catch (e) {
                    return false;
                  }
                }, orElse: () => null);

                if (violation != null) {
                  scores.add(
                    StudentScore.fromPeringatan(
                      violation,
                      aspek['indikator_poin'] ??
                          (violation['level_sp'] == 'SP1'
                              ? 5
                              : violation['level_sp'] == 'SP2'
                              ? 10
                              : 20),
                    ),
                  );
                }
              }
            }
          }
        }
      }
    } catch (e) {}
    return scores;
  }

  Future<List<StudentScore>> loadStudentScores(String nis) async {
    if (aspekPenilaianData.isEmpty) {
      await fetchAspekPenilaian();
    }
    return fetchStudentScores(nis);
  }

  Future<void> fetchAspekPenilaian() async {
    safeSetState(() {
      isLoadingAspek = true;
      errorMessageAspek = null;
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/aspekpenilaian'))
          .timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['success']) {
          List<dynamic> data = jsonData['data'];
          Map<String, FAQItem> tempFaqData = {};
          Map<String, dynamic> tempAspekData = {};
          for (var item in data) {
            String key =
                item['id_aspekpenilaian']?.toString() ??
                'A${data.indexOf(item)}';
            tempFaqData[key] = FAQItem.fromJson(item);
            tempAspekData[key] = item;
            expandedSections[key] = false;
          }
          safeSetState(() {
            faqData = tempFaqData;
            aspekPenilaianData = tempAspekData;
            isLoadingAspek = false;
          });
        } else {
          safeSetState(() {
            errorMessageAspek = jsonData['message'];
            isLoadingAspek = false;
          });
        }
      } else {
        safeSetState(() {
          errorMessageAspek =
              'Gagal mengambil data aspek penilaian: ${response.statusCode}';
          isLoadingAspek = false;
        });
      }
    } catch (e) {
      safeSetState(() {
        errorMessageAspek = 'Terjadi kesalahan: $e';
        isLoadingAspek = false;
      });
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  double get averageApresiasi {
    if (filteredAndSortedStudents.isEmpty) return 0;
    double total = filteredAndSortedStudents.fold(
      0,
      (sum, student) => sum + student.apresiasi,
    );
    return total / filteredAndSortedStudents.length;
  }

  double get apresiasiPercentage {
    if (filteredAndSortedStudents.isEmpty) return 0;
    final totalApresiasi = filteredAndSortedStudents.fold<int>(
      0,
      (sum, student) => sum + student.apresiasi,
    );
    final totalPelanggaran = filteredAndSortedStudents.fold<int>(
      0,
      (sum, student) => sum + student.pelanggaran.abs(),
    );
    final total = totalApresiasi + totalPelanggaran;
    if (total == 0) return 0;
    return totalApresiasi / total;
  }

  double get pelanggaranPercentage {
    if (filteredAndSortedStudents.isEmpty) return 0;
    final totalApresiasi = filteredAndSortedStudents.fold<int>(
      0,
      (sum, student) => sum + student.apresiasi,
    );
    final totalPelanggaran = filteredAndSortedStudents.fold<int>(
      0,
      (sum, student) => sum + student.pelanggaran.abs(),
    );
    final total = totalApresiasi + totalPelanggaran;
    if (total == 0) return 0;
    return totalPelanggaran / total;
  }

  List<Student> get filteredAndSortedStudents {
    if (selectedKelas == null) return [];

    List<Student> filtered =
        studentsList.where((student) {
          bool matchesClass = student.idKelas == selectedKelas!.idKelas;
          bool matchesSearch = student.name.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
          if (!matchesClass || !matchesSearch) return false;

          int poin = student.totalPoin;
          switch (selectedFilter) {
            case '0-50':
              return poin >= 0 && poin <= 50;
            case '51-100':
              return poin >= 51 && poin <= 100;
            case '101+':
              return poin > 100;
            case 'Negatif':
              return poin < 0;
            case 'Semua':
            default:
              return true;
          }
        }).toList();

    filtered.sort((a, b) => b.totalPoin.compareTo(a.totalPoin));
    return filtered;
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Berdasarkan Nilai',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              ...['Semua', '0-50', '51-100', '101+', 'Negatif'].map((filter) {
                String displayText = filter;
                if (filter == 'Negatif') displayText = 'Nilai Negatif';
                if (filter == '101+') displayText = '101 ke atas';

                return ListTile(
                  title: Text(
                    displayText,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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
                      setState(() {
                        selectedFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                    activeColor: const Color(0xFF0083EE),
                  ),
                  onTap: () {
                    setState(() {
                      selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Ekspor Data',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih format ekspor untuk ${filteredAndSortedStudents.length} siswa dengan filter $selectedFilter:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('PDF', style: GoogleFonts.poppins(fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  final filterLabel =
                      selectedFilter == 'Negatif'
                          ? 'Nilai Negatif'
                          : selectedFilter == '101+'
                          ? '101 ke atas'
                          : selectedFilter;
                  exportToPdf(filterLabel);
                },
              ),
              ListTile(
                title: Text('Excel', style: GoogleFonts.poppins(fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  final filterLabel =
                      selectedFilter == 'Negatif'
                          ? 'Nilai Negatif'
                          : selectedFilter == '101+'
                          ? '101 ke atas'
                          : selectedFilter;
                  exportToExcel(filterLabel);
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
                  fontSize: 14,
                  color: const Color(0xFF0083EE),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildHeaderContent() {
    final bool isLoading =
        isLoadingKelas || isLoadingStudents || isLoadingAspek;
    final bool hasError =
        errorMessageKelas != null ||
        errorMessageStudents != null ||
        errorMessageAspek != null;

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
                errorMessageStudents ??
                errorMessageAspek ??
                'Gagal memuat data dari server',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    if (selectedKelas != null) {
      final studentsInClass = filteredAndSortedStudents.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penilaian Siswa ${selectedKelas!.namaKelas}',
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
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Siswa: $studentsInClass • Semester Ganjil 2025/2026',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.8),
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
    final bool isLoading =
        isLoadingKelas || isLoadingStudents || isLoadingAspek;
    final bool hasError =
        errorMessageKelas != null ||
        errorMessageStudents != null ||
        errorMessageAspek != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double maxWidth =
                  constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: maxWidth,
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
                                  colors: [
                                    Color(0xFF61B8FF),
                                    Color(0xFF0083EE),
                                  ],
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
                                                );
                                              },
                                              child: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
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
                                                      BorderRadius.circular(30),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(alpha: 0.1),
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
                                    Align(
                                      alignment: Alignment.centerLeft,
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
                                              color: Colors.black.withValues(alpha: 0.08,),
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
                                                      selectedView == 'Rekap'
                                                          ? 'Cari nama murid...'
                                                          : 'Cari aturan atau poin...',
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
                                                    searchController.clear();
                                                    searchQuery = '';
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  child: const Icon(
                                                    Icons.clear,
                                                    color: Color(0xFF9CA3AF),
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          buildViewButton('Rekap', 'Rekap'),
                                          const SizedBox(width: 10),
                                          buildViewButton(
                                            'Aspek Poin',
                                            'Aspek Poin',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasError)
                                    buildErrorState()
                                  else if (isLoading)
                                    buildLoadingState()
                                  else if (selectedView == 'Rekap') ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: buildStatCard(
                                            '${filteredAndSortedStudents.length}',
                                            'Total Siswa',
                                            Icons.people_outline,
                                            const LinearGradient(
                                              colors: [
                                                Color(0xFF61B8FF),
                                                Color(0xFF0083EE),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: buildStatCard(
                                            '${averageApresiasi.toInt()}',
                                            'Rata-rata\nApresiasi',
                                            Icons.check_circle_outline,
                                            const LinearGradient(
                                              colors: [
                                                Color(0xFF10B981),
                                                Color(0xFF34D399),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: buildProgressCard(
                                            'Apresiasi',
                                            '${(apresiasiPercentage * 100).toInt()}%',
                                            apresiasiPercentage,
                                            const LinearGradient(
                                              colors: [
                                                Color(0xFF10B981),
                                                Color(0xFF34D399),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: buildProgressCard(
                                            'Pelanggaran',
                                            '${(pelanggaranPercentage * 100).toInt()}%',
                                            pelanggaranPercentage,
                                            const LinearGradient(
                                              colors: [
                                                Color(0xFFFF6B6D),
                                                Color(0xFFFF8E8F),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06,),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isCompact =
                                              constraints.maxWidth < 360;
                                          final filterLabel =
                                              selectedFilter == 'Negatif'
                                                  ? 'Nilai Negatif'
                                                  : selectedFilter == '101+'
                                                  ? '101 ke atas'
                                                  : selectedFilter;
                                          final filterButton = GestureDetector(
                                            onTap: showFilterBottomSheet,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F4F6),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE5E7EB,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      filterLabel,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: const Color(
                                                              0xFF374151,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: 16,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                          final downloadButton =
                                              GestureDetector(
                                                onTap: showExportDialog,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF3F4F6,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE5E7EB,
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.download_rounded,
                                                    color: Color(0xFF374151),
                                                    size: 20,
                                                  ),
                                                ),
                                              );

                                          if (isCompact) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Hasil Akumulasi',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF1F2937,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: filterButton,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    downloadButton,
                                                  ],
                                                ),
                                              ],
                                            );
                                          }

                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Hasil Akumulasi',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF1F2937,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Row(
                                                children: [
                                                  ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth:
                                                          constraints.maxWidth *
                                                          0.5,
                                                    ),
                                                    child: filterButton,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  downloadButton,
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    if (filteredAndSortedStudents.isEmpty &&
                                        searchQuery.isNotEmpty)
                                      buildEmptyState(
                                        'Tidak ada siswa ditemukan',
                                        'Coba ubah kata kunci pencarian atau filter',
                                      )
                                    else if (filteredAndSortedStudents.isEmpty)
                                      buildEmptyState(
                                        'Tidak ada siswa dalam range ini',
                                        'Coba pilih filter lain',
                                      )
                                    else
                                      ...List.generate(
                                        filteredAndSortedStudents.length,
                                        (index) => buildStudentCard(
                                          filteredAndSortedStudents[index],
                                          index,
                                        ),
                                      ),
                                  ] else ...[
                                    FaqWidget(
                                      faqData: faqData.map(
                                        (key, value) => MapEntry(key, {
                                          'title': value.title,
                                          'type': value.jenisPoin,
                                          'items': value.items,
                                        }),
                                      ),
                                      expandedSections: expandedSections,
                                      searchQuery: searchQuery,
                                      onExpansionChanged: (code, expanded) {
                                        setState(() {
                                          expandedSections[code] = expanded;
                                        });
                                      },
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
    );
  }

  Widget buildViewButton(String text, String view) {
    bool isActive = selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedView = view;
            searchController.clear();
            searchQuery = '';
          });
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
              if (isActive && view == 'Rekap')
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
              if (isActive && view == 'Aspek Poin')
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: isActive ? const Color(0xFF1F2937) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatCard(
    String value,
    String label,
    IconData icon,
    Gradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProgressCard(
    String title,
    String percentage,
    double progress,
    Gradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  percentage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStudentCard(Student student, int index) {
    double totalPoints = (student.apresiasi + student.pelanggaran).toDouble();
    double apresiasiRatio =
        totalPoints > 0 ? student.apresiasi / totalPoints : 0;
    double pelanggaranRatio =
        totalPoints > 0 ? student.pelanggaran / totalPoints : 0;

    return GestureDetector(
      onTap: () => showStudentDetail(student),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                student.isPositive
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFFFF6B6D).withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                  student.avatar,
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
                    student.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Apresiasi: ${student.apresiasi} | ',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        'Pelanggaran: ${student.pelanggaran}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFF6B6D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (apresiasiRatio * 100).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(3),
                                bottomLeft: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (pelanggaranRatio * 100).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6D),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(3),
                                bottomRight: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  '${student.totalPoin}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: student.color,
                  ),
                ),
                Text(
                  'Total Poin',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
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
            'Memuat data...',
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
              color: const Color(0xFFFF6B6D).withValues(alpha: 0.1),
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
                errorMessageStudents ??
                errorMessageAspek ??
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

  Widget buildEmptyState(String title, String subtitle) {
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
                  color: const Color(0xFF0083EE).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.search_off, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
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
                selectedFilter = 'Semua';
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
                    color: const Color(0xFF0083EE).withValues(alpha: 0.3),
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

  void showStudentDetail(Student student) {
    final scoresFuture = loadStudentScores(student.nis);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEDBCC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        student.avatar,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
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
                          student.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          selectedKelas?.namaKelas ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient:
                      student.isPositive
                          ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          )
                          : const LinearGradient(
                            colors: [Color(0xFFFF6B6D), Color(0xFFFF8E8F)],
                          ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${student.totalPoin}',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Total Poin',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Column(
                      children: [
                        Text(
                          '${student.apresiasi}',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Apresiasi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    Column(
                      children: [
                        Text(
                          '${student.pelanggaran}',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Pelanggaran',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
