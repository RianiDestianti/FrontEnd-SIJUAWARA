import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/chart.dart';

import 'services/chart_service.dart';
import 'utils/chart_colors.dart';
import 'widgets/bar_chart.dart';
import 'widgets/pie_chart.dart';
import 'widgets/line_chart.dart';
import 'widgets/chart_detail_widgets.dart';

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
    with SingleTickerProviderStateMixin {
  int _period = 0;
  int _chartTypeIdx = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  ChartCredentials? _creds;
  List<ChartDataItem> _data = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final creds = await ChartService.loadCredentials();
      if (!creds.isValid) {
        throw Exception('Data guru tidak lengkap. Silakan login ulang.');
      }
      _creds = creds;
      await _fetch();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _fetch() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await ChartService.fetchChartData(
        chartType: widget.chartType,
        selectedPeriod: _period,
        creds: _creds!,
      );
      if (mounted) setState(() { _data = result; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _refresh() async {
    if (_creds == null || !_creds!.isValid) { await _load(); return; }
    await _fetch();
  }

  void _setPeriod(int p) {
    setState(() => _period = p);
    _fetch();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) return _errorScreen();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: ChartColors.surface,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;
            return Center(
              child: SizedBox(
                width: maxW,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        _appBar(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  StatisticsCards(data: _data),
                                  const SizedBox(height: 20),
                                  PeriodSelector(
                                    selected: _period,
                                    chartType: widget.chartType,
                                    onChanged: _setPeriod,
                                  ),
                                  const SizedBox(height: 20),
                                  ChartTypeSelector(
                                    selected: _chartTypeIdx,
                                    onChanged: (i) => setState(() => _chartTypeIdx = i),
                                  ),
                                  const SizedBox(height: 20),
                                  _mainChart(),
                                  const SizedBox(height: 20),
                                  DetailAnalysis(data: _data, chartType: widget.chartType),
                                  const SizedBox(height: 20),
                                  TrendAnalysis(data: _data, chartType: widget.chartType),
                                  const SizedBox(height: 20),
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

  Widget _appBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ChartColors.gradient(widget.chartType),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 30),
        child: Row(
          children: [
            const SizedBox(width: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text(widget.subtitle, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 14)),
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
                widget.chartType == 'apresiasi' ? Icons.trending_up : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChartColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grafik ${widget.title} - ${_periodLabel()}',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: ChartColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: ChartColors.gradient(widget.chartType)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_periodLabel(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_data.isEmpty)
            ChartEmptyState(message: 'Tidak ada data untuk periode ini', chartType: widget.chartType)
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey(_chartTypeIdx),
                child: switch (_chartTypeIdx) {
                  0 => BarChart(data: _data, chartType: widget.chartType),
                  1 => PieChart(data: _data, chartType: widget.chartType),
                  _ => LineChart(data: _data, chartType: widget.chartType),
                },
              ),
            ),
        ],
      ),
    );
  }

  String _periodLabel() => ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'][_period];

  Widget _errorScreen() => Scaffold(
        backgroundColor: ChartColors.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
                ),
                const SizedBox(height: 20),
                Text(_error!, textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: ChartColors.textMuted, fontSize: 14)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('Coba Lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChartColors.base(widget.chartType),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}