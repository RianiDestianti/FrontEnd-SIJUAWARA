import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/chart.dart';
import '../utils/chart_colors.dart';

// ─── Statistics Cards ─────────────────────────────────────────────────────────

class StatisticsCards extends StatelessWidget {
  final List<ChartDataItem> data;

  const StatisticsCards({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.fold(0.0, (s, i) => s + i.value);
    final avg = data.isNotEmpty ? total / data.length : 0.0;
    final max = data.isNotEmpty
        ? data.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total', value: total.toInt().toString(), icon: Icons.analytics_outlined, color: ChartColors.statBlue)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Rata-rata', value: avg.toInt().toString(), icon: Icons.trending_up, color: ChartColors.statGreen)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Tertinggi', value: max.toInt().toString(), icon: Icons.north, color: ChartColors.statGold)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChartColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: ChartColors.textPrimary)),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: ChartColors.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Period Selector ──────────────────────────────────────────────────────────

class PeriodSelector extends StatelessWidget {
  final int selected;
  final String chartType;
  final ValueChanged<int> onChanged;

  const PeriodSelector({
    super.key,
    required this.selected,
    required this.chartType,
    required this.onChanged,
  });

  static const _labels = ['Minggu', 'Bulan', 'Tahun'];

  @override
  Widget build(BuildContext context) {
    return _SelectorContainer(
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: active
                      ? LinearGradient(colors: ChartColors.gradient(chartType))
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: active ? Colors.white : ChartColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Chart Type Selector ──────────────────────────────────────────────────────

class ChartTypeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const ChartTypeSelector({super.key, required this.selected, required this.onChanged});

  static const _types = [
    (name: 'Bar', icon: Icons.bar_chart),
    (name: 'Pie', icon: Icons.pie_chart),
    (name: 'Line', icon: Icons.show_chart),
  ];

  @override
  Widget build(BuildContext context) {
    return _SelectorContainer(
      child: Row(
        children: List.generate(_types.length, (i) {
          final active = selected == i;
          final t = _types[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF3F4F6) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 18, color: active ? ChartColors.textPrimary : ChartColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      t.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? ChartColors.textPrimary : ChartColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Shared Selector Container ────────────────────────────────────────────────

class _SelectorContainer extends StatelessWidget {
  final Widget child;
  const _SelectorContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ChartColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

// ─── Trend Analysis ───────────────────────────────────────────────────────────

class TrendAnalysis extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;

  const TrendAnalysis({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final isIncreasing = data.length > 1 && data.last.value > data.first.value;
    final changePct = data.length > 1 && data.first.value != 0
        ? ((data.last.value - data.first.value) / data.first.value * 100).abs()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ChartColors.gradient(chartType),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.insights, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Analisis Tren', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _TrendCard(title: 'Status Tren', value: isIncreasing ? 'Meningkat' : 'Menurun', icon: isIncreasing ? Icons.trending_up : Icons.trending_down)),
            const SizedBox(width: 12),
            Expanded(child: _TrendCard(title: 'Perubahan', value: '${changePct.toInt()}%', icon: isIncreasing ? Icons.north : Icons.south)),
          ]),
          const SizedBox(height: 16),
          _RecommendationBox(chartType: chartType, isIncreasing: isIncreasing),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _TrendCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(title, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RecommendationBox extends StatelessWidget {
  final String chartType;
  final bool isIncreasing;

  const _RecommendationBox({required this.chartType, required this.isIncreasing});

  String get _text {
    if (chartType == 'apresiasi') {
      return isIncreasing
          ? 'Tren positif! Pertahankan program apresiasi yang sedang berjalan dan tingkatkan variasi penghargaan untuk memotivasi siswa.'
          : 'Perlu peningkatan program apresiasi. Pertimbangkan untuk menambah kegiatan motivasi dan sistem penghargaan yang lebih menarik.';
    } else {
      return isIncreasing
          ? 'Perlu perhatian khusus! Tingkatkan pengawasan dan buat program pencegahan pelanggaran yang lebih efektif.'
          : 'Tren menurun sangat baik! Pertahankan sistem pengawasan dan terus tingkatkan program kedisiplinan.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rekomendasi', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Text(_text, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4)),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class ChartEmptyState extends StatelessWidget {
  final String message;
  final String chartType;

  const ChartEmptyState({super.key, required this.message, required this.chartType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: ChartColors.gradient(chartType)),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Icon(
              chartType == 'apresiasi' ? Icons.star : Icons.warning,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: ChartColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Analysis Card ────────────────────────────────────────────────────

class DetailAnalysis extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;

  const DetailAnalysis({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
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
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: ChartColors.gradient(chartType)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Analisis Detail', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: ChartColors.textPrimary)),
          ]),
          const SizedBox(height: 16),
          if (data.isEmpty)
            ChartEmptyState(message: 'Tidak ada data untuk analisis', chartType: chartType)
          else
            ...data.map((item) => _DetailItem(item: item, chartType: chartType)),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final ChartDataItem item;
  final String chartType;

  const _DetailItem({required this.item, required this.chartType});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChartColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChartColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: ChartColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: ChartColors.gradient(chartType)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${item.value.toInt()}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.detail, style: GoogleFonts.poppins(fontSize: 12, color: ChartColors.textMuted)),
        ],
      ),
    );
  }
}