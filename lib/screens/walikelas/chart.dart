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
  int _period = 0;       // 0 = Minggu, 1 = Bulan (matches ChartUtils + HomeScreen)
  int _chartTypeIdx = 0; // 0 = Bar, 1 = Pie, 2 = Line

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
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
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
      if (!creds.isValid) throw Exception('Data guru tidak lengkap. Silakan login ulang.');
      _creds = creds;
      await _fetch();
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
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
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  children: [
                    _appBar(context),
                    Expanded(
                      child: _isLoading
                          ? _loadingView()
                          : _error != null
                              ? _errorView()
                              : _body(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  Widget _appBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ChartColors.gradient(widget.chartType),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: ChartColors.base(widget.chartType).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(widget.subtitle,
                        style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.85), fontSize: 13)),
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
                      ? Icons.trending_up_rounded
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _body() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: ChartColors.base(widget.chartType),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              children: [
                // Period + chart type selectors side-by-side on same row
                Row(
                  children: [
                    Expanded(
                      child: PeriodSelector(
                        selected: _period,
                        chartType: widget.chartType,
                        onChanged: _setPeriod,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChartTypeSelector(
                        selected: _chartTypeIdx,
                        chartType: widget.chartType,
                        onChanged: (i) => setState(() => _chartTypeIdx = i),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main chart card
                _mainChartCard(),
                const SizedBox(height: 16),

                // Detail breakdown
                DetailAnalysis(data: _data, chartType: widget.chartType),
                const SizedBox(height: 16),

                // Trend card (only when enough data)
                TrendAnalysis(data: _data, chartType: widget.chartType),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChartColors.card,
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
          // Card header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700, color: ChartColors.textPrimary)),
                    Text(_periodLabel(),
                        style: GoogleFonts.poppins(fontSize: 12, color: ChartColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: ChartColors.gradient(widget.chartType)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.chartType == 'apresiasi' ? Icons.trending_up_rounded : Icons.warning_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(_chartTypeName(),
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart
          if (_data.isEmpty)
            ChartEmptyState(
              message: 'Tidak ada data untuk $_periodLabel()',
              chartType: widget.chartType,
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
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

  // ─── Loading / Error ───────────────────────────────────────────────────────

  Widget _loadingView() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ChartColors.base(widget.chartType)),
            const SizedBox(height: 16),
            Text('Memuat data…',
                style: GoogleFonts.poppins(fontSize: 13, color: ChartColors.textMuted)),
          ],
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
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
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _periodLabel() => ['Minggu Ini', 'Bulan Ini'][_period];
  String _chartTypeName() => ['Bar', 'Pie', 'Line'][_chartTypeIdx];
}