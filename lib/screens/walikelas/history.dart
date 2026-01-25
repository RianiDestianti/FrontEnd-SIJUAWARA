import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skoring/config/api.dart';
import 'package:skoring/models/types/history.dart';

class HistoryScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const HistoryScreen({Key? key, required this.student}) : super(key: key);

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  static const int _academicYearStartMonth = 7; // July
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  String selectedFilter = 'Semua';
  String selectedTimeFilter = 'Semua';
  bool showOnlyNew = false;
  DateTimeRange? customDateRange;
  List<HistoryItem> allHistory = [];
  bool isLoading = true;
  String? errorMessage;
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
        errorMessage = 'Data guru tidak lengkap. Silakan login ulang.';
        isLoading = false;
      });
      return;
    }

    fetchAspekPenilaian();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Future<void> fetchAspekPenilaian() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
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
        final jsonData = jsonDecode(response.body);
        if (jsonData['success']) {
          setState(() {
            aspekPenilaianData = jsonData['data'];
          });
          await fetchHistory(widget.student['nis']);
        } else {
          setState(() {
            errorMessage =
                jsonData['message'] ?? 'Gagal mengambil aspek penilaian';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Gagal mengambil data (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchHistory(String nis) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final skoringPenghargaanUri = Uri.parse(
        '${ApiConfig.baseUrl}/skoring_penghargaan?nis=$nis&nip=$nipWalikelas&id_kelas=$idKelas',
      );
      var skoringPelanggaranUri = Uri.parse(
        '${ApiConfig.baseUrl}/skoring_pelanggaran?nis=$nis&nip=$nipWalikelas&id_kelas=$idKelas',
      );

      final skoringPenghargaanResponse = await http.get(
        skoringPenghargaanUri,
        headers: {'Accept': 'application/json'},
      );
      var skoringPelanggaranResponse = await http.get(
        skoringPelanggaranUri,
        headers: {'Accept': 'application/json'},
      );
      if (skoringPelanggaranResponse.statusCode != 200) {
        skoringPelanggaranUri = Uri.parse(
          '${ApiConfig.baseUrl}/skoring_2pelanggaran?nis=$nis&nip=$nipWalikelas&id_kelas=$idKelas',
        );
        skoringPelanggaranResponse = await http.get(
          skoringPelanggaranUri,
          headers: {'Accept': 'application/json'},
        );
      }

      if (skoringPenghargaanResponse.statusCode == 200 &&
          skoringPelanggaranResponse.statusCode == 200) {
        final skoringPenghargaanData = jsonDecode(
          skoringPenghargaanResponse.body,
        );
        final skoringPelanggaranData = jsonDecode(
          skoringPelanggaranResponse.body,
        );

        List<HistoryItem> historyList = [];

        final apresiasiList =
            (skoringPenghargaanData['penilaian']?['data'] as List<dynamic>? ??
                    [])
                .where((eval) => eval['nis'].toString() == nis)
                .toList();

        for (var eval in apresiasiList) {
          final aspek = aspekPenilaianData.firstWhere(
            (a) =>
                a['id_aspekpenilaian'].toString() ==
                eval['id_aspekpenilaian'].toString(),
            orElse: () => null,
          );
          if (aspek == null) continue;
          final createdAt =
              DateTime.tryParse(eval['created_at'] ?? '') ?? DateTime.now();
          historyList.add(
            HistoryItem(
              id:
                  'apr_${eval['id_penilaian'] ?? createdAt.millisecondsSinceEpoch}',
              type: (aspek['kategori'] ?? 'Apresiasi').toString(),
              description: aspek['uraian']?.toString() ?? 'Apresiasi',
              date: createdAt.toIso8601String().substring(0, 10),
              time: createdAt.toIso8601String().substring(11, 16),
              points: ((aspek['indikator_poin'] as num? ?? 0).abs()).toInt(),
              icon: Icons.star,
              color: const Color(0xFF10B981),
              pemberi:
                  eval['nip_wakasek'] != null
                      ? 'Wakasek'
                      : eval['nip_walikelas'] != null
                      ? 'Walikelas'
                      : eval['nip_bk'] != null
                      ? 'BK'
                      : 'Tidak diketahui',
              isNew: DateTime.now().difference(createdAt).inDays < 7,
              isPelanggaran: false,
              createdAt: createdAt,
              pelanggaranKe: aspek['pelanggaran_ke'],
              kategori: aspek['kategori'] ?? 'Umum',
            ),
          );
        }

        final pelanggaranList =
            (skoringPelanggaranData['penilaian']?['data'] as List<dynamic>? ??
                    [])
                .where((eval) => eval['nis'].toString() == nis)
                .toList();

        for (var eval in pelanggaranList) {
          final aspek = aspekPenilaianData.firstWhere(
            (a) =>
                a['id_aspekpenilaian'].toString() ==
                eval['id_aspekpenilaian'].toString(),
            orElse: () => null,
          );
          if (aspek == null) continue;
          final createdAt =
              DateTime.tryParse(eval['created_at'] ?? '') ?? DateTime.now();
          historyList.add(
            HistoryItem(
              id:
                  'pel_${eval['id_penilaian'] ?? createdAt.millisecondsSinceEpoch}',
              type: (aspek['kategori'] ?? 'Pelanggaran').toString(),
              description: aspek['uraian']?.toString() ?? 'Pelanggaran',
              date: createdAt.toIso8601String().substring(0, 10),
              time: createdAt.toIso8601String().substring(11, 16),
              points: ((aspek['indikator_poin'] as num? ?? 0).abs()).toInt(),
              icon: Icons.warning,
              color: const Color(0xFFFF6B6D),
              pelapor:
                  eval['nip_wakasek'] != null
                      ? 'Wakasek'
                      : eval['nip_walikelas'] != null
                      ? 'Walikelas'
                      : eval['nip_bk'] != null
                      ? 'BK'
                      : 'Tidak diketahui',
              isNew: DateTime.now().difference(createdAt).inDays < 7,
              isPelanggaran: true,
              createdAt: createdAt,
              pelanggaranKe: aspek['pelanggaran_ke'],
              kategori: aspek['kategori'] ?? 'Umum',
            ),
          );
        }

        historyList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          allHistory = historyList;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Gagal mengambil data dari server';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  Future<void> refreshData() async {
    await fetchAspekPenilaian();
  }

  void sortHistory() {
    allHistory.sort((a, b) {
      if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  List<HistoryItem> getFilteredHistory() {
    List<HistoryItem> filtered = List.from(allHistory);

    if (selectedFilter != 'Semua') {
      if (selectedFilter == 'Apresiasi') {
        filtered = filtered.where((item) => !item.isPelanggaran).toList();
      } else if (selectedFilter == 'Pelanggaran') {
        filtered = filtered.where((item) => item.isPelanggaran).toList();
      }
    }

    if (selectedTimeFilter != 'Semua') {
      final now = DateTime.now();
      _TimeRange? range;
      if (selectedTimeFilter == 'Rentang Tanggal') {
        if (customDateRange != null) {
          range = _rangeFromCustom(customDateRange!);
        }
      } else {
        range = _resolveTimeRange(now, selectedTimeFilter);
      }
      if (range != null) {
        final activeRange = range;
        filtered =
            filtered
                .where(
                  (item) =>
                      !_isBeforeDay(item.createdAt, activeRange.start) &&
                      item.createdAt.isBefore(activeRange.end),
                )
                .toList();
      }
    }

    if (showOnlyNew) {
      filtered = filtered.where((item) => item.isNew).toList();
    }

    sortHistory();
    return filtered;
  }

  _TimeRange? _resolveTimeRange(DateTime now, String filter) {
    final today = DateTime(now.year, now.month, now.day);
    switch (filter) {
      case 'Mingguan':
        final start = today.subtract(Duration(days: today.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return _TimeRange(start, end);
      case 'Bulanan':
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(today.year, today.month + 1, 1);
        return _TimeRange(start, end);
      case 'Semester':
        final yearStart = _academicYearStartFor(today);
        final semester1Start = DateTime(yearStart, _academicYearStartMonth, 1);
        final semester1End = DateTime(yearStart + 1, 1, 1);
        final semester2Start = semester1End;
        final semester2End =
            DateTime(yearStart + 1, _academicYearStartMonth, 1);
        if (!today.isBefore(semester1Start) && today.isBefore(semester1End)) {
          return _TimeRange(semester1Start, semester1End);
        }
        return _TimeRange(semester2Start, semester2End);
      case 'Tahunan':
        final yearStart = _academicYearStartFor(today);
        final start = DateTime(yearStart, _academicYearStartMonth, 1);
        final end = DateTime(yearStart + 1, _academicYearStartMonth, 1);
        return _TimeRange(start, end);
      default:
        return null;
    }
  }

  _TimeRange _rangeFromCustom(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final endInclusive =
        DateTime(range.end.year, range.end.month, range.end.day);
    final endExclusive = endInclusive.add(const Duration(days: 1));
    return _TimeRange(start, endExclusive);
  }

  int _academicYearStartFor(DateTime date) {
    return date.month >= _academicYearStartMonth ? date.year : date.year - 1;
  }

  bool _isBeforeDay(DateTime value, DateTime day) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.isBefore(day);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Filter Riwayat',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Jenis Data',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children:
                          ['Semua', 'Apresiasi', 'Pelanggaran'].map((filter) {
                            bool isSelected = selectedFilter == filter;
                            return GestureDetector(
                              onTap: () {
                                setBottomSheetState(() {
                                  selectedFilter = filter;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xFF0083EE)
                                          : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF0083EE)
                                            : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Periode Waktu',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            'Semua',
                            'Mingguan',
                            'Bulanan',
                            'Semester',
                            'Tahunan',
                            'Rentang Tanggal',
                          ].map((
                            filter,
                          ) {
                            bool isSelected = selectedTimeFilter == filter;
                            return GestureDetector(
                              onTap: () {
                                setBottomSheetState(() {
                                  selectedTimeFilter = filter;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? const Color(0xFF0083EE)
                                          : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFF0083EE)
                                            : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    if (selectedTimeFilter == 'Rentang Tanggal') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.date_range,
                              size: 18,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customDateRange == null
                                    ? 'Pilih rentang tanggal'
                                    : '${_formatDate(customDateRange!.start)} s/d ${_formatDate(customDateRange!.end)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final now = DateTime.now();
                                final initialRange =
                                    customDateRange ??
                                    DateTimeRange(
                                      start: DateTime(now.year, now.month, 1),
                                      end: DateTime(now.year, now.month, now.day),
                                    );
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(now.year - 5, 1, 1),
                                  lastDate: DateTime(now.year + 1, 12, 31),
                                  initialDateRange: initialRange,
                                  helpText: 'Pilih Rentang Tanggal',
                                );
                                if (picked != null) {
                                  setBottomSheetState(() {
                                    customDateRange = picked;
                                  });
                                }
                              },
                              child: Text(
                                'Pilih',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0083EE),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hanya Data Terbaru',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        Switch(
                          value: showOnlyNew,
                          onChanged: (value) {
                            setBottomSheetState(() {
                              showOnlyNew = value;
                            });
                          },
                          activeColor: const Color(0xFF0083EE),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0083EE),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Terapkan Filter',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showSearchBottomSheet() {
    TextEditingController searchController = TextEditingController();
    List<HistoryItem> searchResults = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF0083EE)),
                      const SizedBox(width: 12),
                      Text(
                        'Cari Riwayat',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan jenis, deskripsi...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6B7280),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0083EE)),
                      ),
                    ),
                    onChanged: (value) {
                      setBottomSheetState(() {
                        if (value.isEmpty) {
                          searchResults = [];
                        } else {
                          searchResults =
                              allHistory
                                  .where(
                                    (item) =>
                                        item.type.toLowerCase().contains(
                                          value.toLowerCase(),
                                        ) ||
                                        item.description.toLowerCase().contains(
                                          value.toLowerCase(),
                                        ) ||
                                        item.kategori.toLowerCase().contains(
                                          value.toLowerCase(),
                                        ),
                                  )
                                  .toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child:
                        searchResults.isEmpty &&
                                searchController.text.isNotEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada hasil ditemukan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : searchResults.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search,
                                    size: 64,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Mulai mengetik untuk mencari',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                return buildSearchResultCard(
                                  searchResults[index],
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSearchResultCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.type,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            '${item.points > 0 ? '+' : '-'}${item.points.abs()}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<HistoryItem> filteredHistory = getFilteredHistory();
    List<HistoryItem> newItems =
        filteredHistory.where((item) => item.isNew).toList();
    List<HistoryItem> oldItems =
        filteredHistory.where((item) => !item.isNew).toList();

    if (isLoading) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchAspekPenilaian,
                child: Text('Coba Lagi', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24).add(
                          EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top,
                          ),
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF61B8FF), Color(0xFF0083EE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x200083EE),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 40, height: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Riwayat Lengkap',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${widget.student['name']}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${filteredHistory.length} Item',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: showSearchBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.search,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cari',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
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
                                    onTap: showFilterBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.filter_list,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Filter',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
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
                      if (selectedFilter != 'Semua' ||
                          selectedTimeFilter != 'Semua' ||
                          showOnlyNew)
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0083EE).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0083EE).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.filter_alt,
                                color: Color(0xFF0083EE),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Filter aktif: ${selectedFilter}${selectedTimeFilter != 'Semua' ? ', $selectedTimeFilter' : ''}${showOnlyNew ? ', Data Terbaru' : ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0083EE),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedFilter = 'Semua';
                                    selectedTimeFilter = 'Semua';
                                    showOnlyNew = false;
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Color(0xFF0083EE),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: refreshData,
                          child:
                              filteredHistory.isEmpty
                                  ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 24),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF61B8FF),
                                                    Color(0xFF0083EE),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color(0x200083EE),
                                                    blurRadius: 20,
                                                    offset: Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.search_off,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              'Tidak ada data yang sesuai dengan filter',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Coba ubah pengaturan filter',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  : SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (newItems.isNotEmpty) ...[
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF0EA5E9),
                                                  Color(0xFF0284C7),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x200EA5E9),
                                                  blurRadius: 15,
                                                  offset: Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.fiber_new_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Data Terbaru',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      Text(
                                                        '${newItems.length} item baru tersedia',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors
                                                                  .white
                                                                  .withValues(alpha: 0.8,),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${newItems.length}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          buildHistoryTable(newItems),
                                        ],
                                        if (oldItems.isNotEmpty) ...[
                                          if (newItems.isNotEmpty)
                                            const SizedBox(height: 24),
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF64748B),
                                                  Color(0xFF475569),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x2064748B),
                                                  blurRadius: 15,
                                                  offset: Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.history_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Data Sebelumnya',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      Text(
                                                        'Riwayat data yang sudah tersimpan',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: Colors
                                                                  .white
                                                                  .withValues(alpha: 0.8,),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${oldItems.length}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          buildHistoryTable(oldItems),
                                        ],
                                      ],
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildHistoryTable(List<HistoryItem> items) {
    final borderColor = const Color(0xFFE5E7EB);
    if (items.isEmpty) {
      return buildEmptyHistoryTable();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0083EE).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    'Tanggal',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                SizedBox(
                  width: 82,
                  child: Text(
                    'Kategori',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keterangan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Poin',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            final isStriped = index.isOdd;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isStriped ? const Color(0xFFF9FAFB) : Colors.white,
                border:
                    isLast ? null : Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.date,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          item.time,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 82,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.kategori,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            item.isPelanggaran ? 'Pelanggaran' : 'Apresiasi',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: item.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.isPelanggaran
                              ? 'Pelapor: ${item.pelapor ?? 'Tidak diketahui'}'
                              : 'Oleh: ${item.pemberi ?? 'Tidak diketahui'}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        if (item.isPelanggaran &&
                            item.pelanggaranKe != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Pelanggaran ke: ${item.pelanggaranKe}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item.color.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${item.points > 0 ? '+' : '-'}${item.points.abs()}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildEmptyHistoryTable() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(
          'Tidak ada data riwayat.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

}

class _TimeRange {
  final DateTime start;
  final DateTime end;

  const _TimeRange(this.start, this.end);
}
