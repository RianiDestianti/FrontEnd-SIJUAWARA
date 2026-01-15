import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skoring/config/api_config.dart';
import 'package:skoring/models/walikelas/chartdataitem.dart';

class GrafikScreen extends StatefulWidget {
  final String chartType;
  final String title;
  final String subtitle;

  const GrafikScreen({
    Key? key,
    required this.chartType,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  State<GrafikScreen> createState() => _GrafikScreenState();
}

class _GrafikScreenState extends State<GrafikScreen>
    with TickerProviderStateMixin {
  int _selectedPeriod = 0;
  int _selectedChartType = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _teacherClassId = '';
  String _nipWalikelas = '';
  List<ChartDataItem> _chartData = [];
  bool isLoading = true;
  String? errorMessage;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _teacherClassId = prefs.getString('id_kelas') ?? '';
        _nipWalikelas = prefs.getString('walikelas_id') ?? '';
      });

      if (_teacherClassId.isEmpty || _nipWalikelas.isEmpty) {
        setState(() {
          errorMessage = 'Data guru tidak lengkap. Silakan login ulang.';
          isLoading = false;
        });
        return;
      }

      await _fetchChartData();
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchChartData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final isApresiasi = widget.chartType == 'apresiasi';
      final primaryEndpoint =
          isApresiasi ? 'skoring_penghargaan' : 'skoring_pelanggaran';
      final fallbackEndpoint = isApresiasi ? null : 'skoring_2pelanggaran';

      Future<http.Response> _doRequest(String endpoint) {
        final uri = Uri.parse(
          '${ApiConfig.baseUrl}/$endpoint?nip=$_nipWalikelas&id_kelas=$_teacherClassId',
        );
        return http.get(uri, headers: {'Accept': 'application/json'});
      }

      http.Response response = await _doRequest(primaryEndpoint);
      if (response.statusCode != 200 && fallbackEndpoint != null) {
        final retry = await _doRequest(fallbackEndpoint);
        if (retry.statusCode == 200) {
          response = retry;
        }
      }

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final penilaianDataRaw =
            (jsonData['penilaian']?['data'] as List<dynamic>? ?? []);
        final siswaData =
            (jsonData['siswa'] as List<dynamic>? ?? [])
                .map((e) => e as Map<String, dynamic>)
                .toList();

        if (penilaianDataRaw.isEmpty) {
          setState(() {
            errorMessage = jsonData['message'] ?? 'Gagal memuat data';
            isLoading = false;
          });
          return;
        }

        final penilaianData =
            penilaianDataRaw
                .where(
                  (item) => siswaData.any(
                    (s) =>
                        s['nis'].toString() == item['nis'].toString() &&
                        s['id_kelas'].toString() == _teacherClassId,
                  ),
                )
                .toList();

        Map<String, double> weeklyData = {};
        Map<String, double> monthlyData = {};
        Map<String, double> yearlyData = {};

        for (var item in penilaianData) {
          final createdAt = (item as Map<String, dynamic>)['created_at'];
          if (createdAt == null) continue;
          final date = DateTime.tryParse(createdAt.toString());
          if (date == null) continue;

          final weekKey =
              '${date.year}-W${((date.day + 6) / 7).ceil().toString().padLeft(2, '0')}';
          final monthKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          final yearKey = date.year.toString();

          weeklyData[weekKey] = (weeklyData[weekKey] ?? 0) + 1;
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
          yearlyData[yearKey] = (yearlyData[yearKey] ?? 0) + 1;
        }

        setState(() {
          if (_selectedPeriod == 0) {
            final weekly =
                weeklyData.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));
            _chartData =
                weekly
                    .map(
                      (e) => ChartDataItem(
                        value: e.value,
                        label: e.key.split('-W')[1],
                        detail: 'Total: ${e.value.toInt()} kasus',
                      ),
                    )
                    .toList();
          } else if (_selectedPeriod == 1) {
            final monthly =
                monthlyData.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));
            _chartData =
                monthly
                    .map(
                      (e) => ChartDataItem(
                        value: e.value,
                        label: _getMonthName(int.parse(e.key.split('-')[1])),
                        detail: 'Total: ${e.value.toInt()} kasus',
                      ),
                    )
                    .toList();
          } else {
            final yearly =
                yearlyData.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));
            _chartData =
                yearly
                    .map(
                      (e) => ChartDataItem(
                        value: e.value,
                        label: e.key,
                        detail: 'Total: ${e.value.toInt()} kasus',
                      ),
                    )
                    .toList();
          }

          isLoading = false;
        });
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

  Future<void> _refreshData() async {
    if (_teacherClassId.isEmpty || _nipWalikelas.isEmpty) {
      await _loadTeacherData();
      return;
    }
    await _fetchChartData();
  }

  String _getMonthName(int month) {
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

  String _getPeriodLabel() {
    return ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'][_selectedPeriod];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
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
              ElevatedButton(
                onPressed: _loadTeacherData,
                child: Text('Coba Lagi', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

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
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildAppBar(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildStatisticsCards(),
                                  const SizedBox(height: 20),
                                  _buildPeriodSelector(),
                                  const SizedBox(height: 20),
                                  _buildChartTypeSelector(),
                                  const SizedBox(height: 20),
                                  _buildMainChart(),
                                  const SizedBox(height: 20),
                                  _buildDetailedAnalysis(),
                                  const SizedBox(height: 20),
                                  _buildTrendAnalysis(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              widget.chartType == 'apresiasi'
                  ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
                  : [const Color(0xFFFF6B6D), const Color(0xFFFF8E8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 20,
          20,
          30,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 40, height: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.chartType == 'apresiasi'
                        ? Icons.trending_up
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    double total = _chartData.fold(0.0, (sum, item) => sum + item.value);
    double average = _chartData.isNotEmpty ? total / _chartData.length : 0.0;
    double max =
        _chartData.isNotEmpty
            ? _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b)
            : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            total.toInt().toString(),
            Icons.analytics_outlined,
            const Color(0xFF0083EE),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Rata-rata',
            average.toInt().toString(),
            Icons.trending_up,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tertinggi',
            max.toInt().toString(),
            Icons.north,
            const Color(0xFFFFD700),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children:
            ['Minggu', 'Bulan', 'Tahun'].asMap().entries.map((entry) {
              int index = entry.key;
              String period = entry.value;
              bool isActive = _selectedPeriod == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = index;
                      _fetchChartData();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient:
                          isActive
                              ? LinearGradient(
                                colors:
                                    widget.chartType == 'apresiasi'
                                        ? [
                                          const Color(0xFF61B8FF),
                                          const Color(0xFF0083EE),
                                        ]
                                        : [
                                          const Color(0xFFFF6B6D),
                                          const Color(0xFFFF8E8F),
                                        ],
                              )
                              : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      period,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color:
                            isActive ? Colors.white : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children:
            [
              {'name': 'Bar', 'icon': Icons.bar_chart},
              {'name': 'Pie', 'icon': Icons.pie_chart},
              {'name': 'Line', 'icon': Icons.show_chart},
            ].asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> chartType = entry.value;
              bool isActive = _selectedChartType == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChartType = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFF3F4F6) : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          chartType['icon'],
                          color:
                              isActive
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFF6B7280),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chartType['name'],
                          style: GoogleFonts.poppins(
                            color:
                                isActive
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildMainChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  'Grafik ${widget.title} - ${_getPeriodLabel()}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        widget.chartType == 'apresiasi'
                            ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
                            : [
                              const Color(0xFFFF6B6D),
                              const Color(0xFFFF8E8F),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPeriodLabel(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_chartData.isEmpty)
            _buildEmptyState('Tidak ada data untuk periode ini')
          else if (_selectedChartType == 0)
            _buildBarChart()
          else if (_selectedChartType == 1)
            _buildPieChart()
          else
            _buildLineChart(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    double maxValue =
        _chartData.isNotEmpty
            ? _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b)
            : 1.0;

    return Container(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${maxValue.toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.75).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.5).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        '${(maxValue * 0.25).toInt()}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        '0',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
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
                        _chartData.map((item) {
                          double value = item.value;
                          double height = (value / maxValue) * 150;
                          return Container(
                            width: 32,
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    widget.chartType == 'apresiasi'
                                        ? [
                                          const Color(0xFF61B8FF),
                                          const Color(0xFF0083EE),
                                        ]
                                        : [
                                          const Color(0xFFFF6B6D),
                                          const Color(0xFFFF8E8F),
                                        ],
                              ),
                              borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 52),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      _chartData.map((item) {
                        return Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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

  Widget _buildPieChart() {
    double total = _chartData.fold(0.0, (sum, item) => sum + item.value);

    return Container(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomPaint(
              size: const Size(150, 150),
              painter: PieChartPainter(
                data: _chartData,
                total: total,
                colors:
                    widget.chartType == 'apresiasi'
                        ? [
                          const Color(0xFF61B8FF),
                          const Color(0xFF0083EE),
                          const Color(0xFF3B82F6),
                          const Color(0xFF1E40AF),
                          const Color(0xFF1E3A8A),
                        ]
                        : [
                          const Color(0xFFFF6B6D),
                          const Color(0xFFFF8E8F),
                          const Color(0xFFEF4444),
                          const Color(0xFFDC2626),
                          const Color(0xFFB91C1C),
                        ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  _chartData.asMap().entries.map((entry) {
                    int index = entry.key;
                    ChartDataItem item = entry.value;
                    double percentage =
                        total > 0 ? (item.value / total) * 100 : 0;
                    Color color =
                        widget.chartType == 'apresiasi'
                            ? [
                              const Color(0xFF61B8FF),
                              const Color(0xFF0083EE),
                              const Color(0xFF3B82F6),
                              const Color(0xFF1E40AF),
                              const Color(0xFF1E3A8A),
                            ][index % 5]
                            : [
                              const Color(0xFFFF6B6D),
                              const Color(0xFFFF8E8F),
                              const Color(0xFFEF4444),
                              const Color(0xFFDC2626),
                              const Color(0xFFB91C1C),
                            ][index % 5];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  '${percentage.toInt()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    double maxValue =
        _chartData.isNotEmpty
            ? _chartData.map((e) => e.value).reduce((a, b) => math.max(a, b))
            : 1.0;
    if (maxValue <= 0) maxValue = 1.0;

    final baseColor =
        widget.chartType == 'apresiasi'
            ? const Color(0xFF0083EE)
            : const Color(0xFFFF6B6D);

    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        maxValue.toInt().toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        (maxValue * 0.75).toInt().toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        (maxValue * 0.5).toInt().toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        (maxValue * 0.25).toInt().toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      Text(
                        '0',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomPaint(
                    painter: LineChartPainter(
                      data: _chartData,
                      maxValue: maxValue,
                      lineColor: baseColor,
                      fillColor: baseColor.withOpacity(0.15),
                      pointColor: baseColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 52),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      _chartData.map((item) {
                        return Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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

  Widget _buildDetailedAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        widget.chartType == 'apresiasi'
                            ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
                            : [
                              const Color(0xFFFF6B6D),
                              const Color(0xFFFF8E8F),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Analisis Detail',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_chartData.isEmpty)
            _buildEmptyState('Tidak ada data untuk analisis')
          else
            ..._chartData.map((item) => _buildDetailItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailItem(ChartDataItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        widget.chartType == 'apresiasi'
                            ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
                            : [
                              const Color(0xFFFF6B6D),
                              const Color(0xFFFF8E8F),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.value.toInt()}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.detail,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    double total = _chartData.fold(0.0, (sum, item) => sum + item.value);
    double average = _chartData.isNotEmpty ? total / _chartData.length : 0.0;

    bool isIncreasing =
        _chartData.length > 1 && _chartData.last.value > _chartData.first.value;
    double changePercentage =
        _chartData.length > 1
            ? ((_chartData.last.value - _chartData.first.value) /
                    _chartData.first.value *
                    100)
                .abs()
            : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              widget.chartType == 'apresiasi'
                  ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
                  : [const Color(0xFFFF6B6D), const Color(0xFFFF8E8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Analisis Tren',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendCard(
                  'Status Tren',
                  isIncreasing ? 'Meningkat' : 'Menurun',
                  isIncreasing ? Icons.trending_up : Icons.trending_down,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendCard(
                  'Perubahan',
                  '${changePercentage.toInt()}%',
                  isIncreasing ? Icons.north : Icons.south,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.chartType == 'apresiasi'
                      ? isIncreasing
                          ? 'Tren positif! Pertahankan program apresiasi yang sedang berjalan dan tingkatkan variasi penghargaan untuk memotivasi siswa.'
                          : 'Perlu peningkatan program apresiasi. Pertimbangkan untuk menambah kegiatan motivasi dan sistem penghargaan yang lebih menarik.'
                      : isIncreasing
                      ? 'Perlu perhatian khusus! Tingkatkan pengawasan dan buat program pencegahan pelanggaran yang lebih efektif.'
                      : 'Tren menurun sangat baik! Pertahankan sistem pengawasan dan terus tingkatkan program kedisiplinan.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    String title,
    String value,
    IconData icon,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
              gradient: LinearGradient(
                colors:
                    widget.chartType == 'apresiasi'
                        ? [const Color(0xFF61B8FF), const Color(0xFF0083EE)]
                        : [const Color(0xFFFF6B6D), const Color(0xFFFF8E8F)],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              widget.chartType == 'apresiasi' ? Icons.star : Icons.warning,
              color: Colors.white,
              size: 40,
            ),
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

class PieChartPainter extends CustomPainter {
  final List<ChartDataItem> data;
  final double total;
  final List<Color> colors;

  PieChartPainter({
    required this.data,
    required this.total,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    double startAngle = -90 * (3.14159 / 180);

    for (int i = 0; i < data.length; i++) {
      double sweepAngle = total > 0 ? (data[i].value / total) * 2 * 3.14159 : 0;

      final paint =
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      startAngle += sweepAngle;
    }

    canvas.drawCircle(
      center,
      radius * 0.4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<ChartDataItem> data;
  final double maxValue;
  final Color lineColor;
  final Color fillColor;
  final Color pointColor;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.lineColor,
    required this.fillColor,
    required this.pointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double topPadding = 10;
    final double bottomPadding = 20;
    final double chartHeight = size.height - topPadding - bottomPadding;
    final int pointCount = data.length;
    final double stepX =
        pointCount > 1 ? size.width / (pointCount - 1) : size.width;
    final double safeMax = maxValue <= 0 ? 1 : maxValue;

    final gridPaint =
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final double y = topPadding + (chartHeight / 4 * i);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (int i = 0; i < pointCount; i++) {
      final value = data[i].value;
      final double x = stepX * i;
      final double y =
          topPadding + chartHeight - (value / safeMax * chartHeight);
      points.add(Offset(x, y));
    }

    final fillPath =
        Path()..moveTo(points.first.dx, size.height - bottomPadding);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height - bottomPadding);
    fillPath.close();

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [fillColor, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final pointPaint =
        Paint()
          ..color = pointColor
          ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 4, pointPaint);
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = pointColor.withOpacity(0.2)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
