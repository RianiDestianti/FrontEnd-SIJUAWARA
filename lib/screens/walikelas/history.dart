import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skoring/config/api_config.dart';
import 'package:skoring/models/walikelas/historyitem.dart';

class HistoryScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const HistoryScreen({Key? key, required this.student}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedFilter = 'Semua';
  String _selectedTimeFilter = 'Semua';
  bool _showOnlyNew = false;
  List<HistoryItem> allHistory = [];
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> aspekPenilaianData = [];

  String _nipWalikelas = '';
  String _idKelas = '';

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nipWalikelas = prefs.getString('walikelas_id') ?? '';
      _idKelas = prefs.getString('id_kelas') ?? '';
    });

    if (_nipWalikelas.isEmpty || _idKelas.isEmpty) {
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchAspekPenilaian() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/aspekpenilaian?nip=$_nipWalikelas&id_kelas=$_idKelas',
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
        '${ApiConfig.baseUrl}/skoring_penghargaan?nis=$nis&nip=$_nipWalikelas&id_kelas=$_idKelas',
      );
      var skoringPelanggaranUri = Uri.parse(
        '${ApiConfig.baseUrl}/skoring_pelanggaran?nis=$nis&nip=$_nipWalikelas&id_kelas=$_idKelas',
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
          '${ApiConfig.baseUrl}/skoring_2pelanggaran?nis=$nis&nip=$_nipWalikelas&id_kelas=$_idKelas',
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

  Future<void> _refreshData() async {
    await fetchAspekPenilaian();
  }

  void _sortHistory() {
    allHistory.sort((a, b) {
      if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  List<HistoryItem> _getFilteredHistory() {
    List<HistoryItem> filtered = List.from(allHistory);

    if (_selectedFilter != 'Semua') {
      if (_selectedFilter == 'Apresiasi') {
        filtered = filtered.where((item) => !item.isPelanggaran).toList();
      } else if (_selectedFilter == 'Pelanggaran') {
        filtered = filtered.where((item) => item.isPelanggaran).toList();
      }
    }

    if (_selectedTimeFilter != 'Semua') {
      DateTime now = DateTime.now();
      DateTime filterDate;

      switch (_selectedTimeFilter) {
        case '7 Hari':
          filterDate = now.subtract(const Duration(days: 7));
          break;
        case '30 Hari':
          filterDate = now.subtract(const Duration(days: 30));
          break;
        case '3 Bulan':
          filterDate = now.subtract(const Duration(days: 90));
          break;
        default:
          filterDate = DateTime.fromMillisecondsSinceEpoch(0);
      }

      filtered =
          filtered.where((item) => item.createdAt.isAfter(filterDate)).toList();
    }

    if (_showOnlyNew) {
      filtered = filtered.where((item) => item.isNew).toList();
    }

    _sortHistory();
    return filtered;
  }

  void _showFilterBottomSheet() {
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
                            bool isSelected = _selectedFilter == filter;
                            return GestureDetector(
                              onTap: () {
                                setBottomSheetState(() {
                                  _selectedFilter = filter;
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
                          ['Semua', '7 Hari', '30 Hari', '3 Bulan'].map((
                            filter,
                          ) {
                            bool isSelected = _selectedTimeFilter == filter;
                            return GestureDetector(
                              onTap: () {
                                setBottomSheetState(() {
                                  _selectedTimeFilter = filter;
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
                          value: _showOnlyNew,
                          onChanged: (value) {
                            setBottomSheetState(() {
                              _showOnlyNew = value;
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

  void _showSearchBottomSheet() {
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
                                return _buildSearchResultCard(
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

  Widget _buildSearchResultCard(HistoryItem item) {
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
              color: item.color.withOpacity(0.1),
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
    List<HistoryItem> filteredHistory = _getFilteredHistory();
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
                  opacity: _fadeAnimation,
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
                                          color: Colors.white.withOpacity(0.9),
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
                                    color: Colors.white.withOpacity(0.2),
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
                                    onTap: _showSearchBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
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
                                    onTap: _showFilterBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
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
                      if (_selectedFilter != 'Semua' ||
                          _selectedTimeFilter != 'Semua' ||
                          _showOnlyNew)
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0083EE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0083EE).withOpacity(0.2),
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
                                  'Filter aktif: ${_selectedFilter}${_selectedTimeFilter != 'Semua' ? ', $_selectedTimeFilter' : ''}${_showOnlyNew ? ', Data Terbaru' : ''}',
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
                                    _selectedFilter = 'Semua';
                                    _selectedTimeFilter = 'Semua';
                                    _showOnlyNew = false;
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
                          onRefresh: _refreshData,
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
                                                        .withOpacity(0.2),
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
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
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
                                                        .withOpacity(0.2),
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
                                          ...newItems
                                              .map(
                                                (item) =>
                                                    _buildHistoryCard(item),
                                              )
                                              .toList(),
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
                                                        .withOpacity(0.2),
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
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
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
                                                        .withOpacity(0.2),
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
                                          ...oldItems
                                              .map(
                                                (item) =>
                                                    _buildHistoryCard(item),
                                              )
                                              .toList(),
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

  Widget _buildHistoryCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
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
                          height: 1.4,
                        ),
                        maxLines: 2,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: item.color.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${item.points > 0 ? '+' : '-'}${item.points.abs()}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.date} • ${item.time}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.isPelanggaran
                        ? 'Pelapor: ${item.pelapor ?? 'Tidak diketahui'}'
                        : 'Oleh: ${item.pemberi ?? 'Tidak diketahui'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (item.isPelanggaran && item.pelanggaranKe != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.warning, size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Pelanggaran ke: ${item.pelanggaranKe}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
