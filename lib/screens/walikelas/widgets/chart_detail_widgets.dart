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

    return Row(children: [
      Expanded(child: _StatCard(label: 'Total', value: total.toInt().toString(), icon: Icons.analytics_outlined, color: ChartColors.statBlue)),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(label: 'Rata-rata', value: avg.toStringAsFixed(1), icon: Icons.show_chart, color: ChartColors.statGreen)),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(label: 'Tertinggi', value: max.toInt().toString(), icon: Icons.north, color: ChartColors.statGold)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ChartColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: ChartColors.textPrimary)),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: ChartColors.textMuted, fontWeight: FontWeight.w500)),
        ]),
      );
}

// ─── Period Selector ──────────────────────────────────────────────────────────

class PeriodSelector extends StatelessWidget {
  final int selected;
  final String chartType;
  final ValueChanged<int> onChanged;

  const PeriodSelector({super.key, required this.selected, required this.chartType, required this.onChanged});

  static const _labels = ['Minggu', 'Bulan'];

  @override
  Widget build(BuildContext context) => _Selector(
        children: List.generate(_labels.length, (i) {
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: active ? LinearGradient(colors: ChartColors.gradient(chartType)) : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active
                      ? [BoxShadow(color: ChartColors.base(chartType).withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(_labels[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: active ? Colors.white : ChartColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
              ),
            ),
          );
        }),
      );
}

// ─── Chart Type Selector ──────────────────────────────────────────────────────

class ChartTypeSelector extends StatelessWidget {
  final int selected;
  final String chartType;
  final ValueChanged<int> onChanged;

  const ChartTypeSelector({super.key, required this.selected, required this.chartType, required this.onChanged});

  static const _types = [
    (name: 'Bar',  icon: Icons.bar_chart_rounded),
    (name: 'Pie',  icon: Icons.pie_chart_rounded),
    (name: 'Line', icon: Icons.show_chart_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = ChartColors.base(chartType);
    return _Selector(
      children: List.generate(_types.length, (i) {
        final active = selected == i;
        final t = _types[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? accent.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(11),
              ),
              // icon + text stacked vertically — avoids horizontal overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 16, color: active ? accent : ChartColors.textMuted),
                  const SizedBox(height: 2),
                  Text(t.name,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? accent : ChartColors.textMuted,
                      )),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Selector extends StatelessWidget {
  final List<Widget> children;
  const _Selector({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ChartColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: children),
      );
}

// ─── Trend Analysis ───────────────────────────────────────────────────────────

class TrendAnalysis extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;
  const TrendAnalysis({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox.shrink();
    final isIncreasing = data.last.value > data.first.value;
    final changePct = data.first.value != 0
        ? ((data.last.value - data.first.value) / data.first.value * 100).abs()
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: ChartColors.gradient(chartType),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.insights, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Analisis Tren',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _TrendCard(title: 'Tren', value: isIncreasing ? 'Meningkat' : 'Menurun', icon: isIncreasing ? Icons.trending_up : Icons.trending_down)),
            const SizedBox(width: 10),
            Expanded(child: _TrendCard(title: 'Perubahan', value: '${changePct.toInt()}%', icon: isIncreasing ? Icons.north : Icons.south)),
          ]),
          const SizedBox(height: 14),
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(title, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ]),
      );
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
    }
    return isIncreasing
        ? 'Perlu perhatian khusus! Tingkatkan pengawasan dan buat program pencegahan pelanggaran yang lebih efektif.'
        : 'Tren menurun sangat baik! Pertahankan sistem pengawasan dan terus tingkatkan program kedisiplinan.';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rekomendasi', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(_text, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.5)),
        ]),
      );
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class ChartEmptyState extends StatelessWidget {
  final String message;
  final String chartType;
  const ChartEmptyState({super.key, required this.message, required this.chartType});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: ChartColors.gradient(chartType)),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: ChartColors.base(chartType).withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Icon(chartType == 'apresiasi' ? Icons.star_rounded : Icons.warning_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: ChartColors.textMuted)),
        ]),
      );
}

// ─── Detail Analysis ──────────────────────────────────────────────────────────

class DetailAnalysis extends StatelessWidget {
  final List<ChartDataItem> data;
  final String chartType;
  const DetailAnalysis({super.key, required this.data, required this.chartType});

  @override
  Widget build(BuildContext context) {
    // Only show rows with value > 0 to avoid a wall of "0%" rows
    final nonZero = data.where((e) => e.value > 0).toList();
    if (nonZero.isEmpty) return const SizedBox.shrink();

    final total = data.fold(0.0, (s, i) => s + i.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChartColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: ChartColors.gradient(chartType)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Rincian Data',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: ChartColors.textPrimary)),
          ]),
          const SizedBox(height: 14),
          ...nonZero.map((item) => _DetailRow(item: item, total: total, chartType: chartType)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final ChartDataItem item;
  final double total;
  final String chartType;
  const _DetailRow({required this.item, required this.total, required this.chartType});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? item.value / total : 0.0;
    final accent = ChartColors.base(chartType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.label,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: ChartColors.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: ChartColors.gradient(chartType)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${item.value.toInt()}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: ChartColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 3),
        Text('${(pct * 100).toInt()}% dari total',
            style: GoogleFonts.poppins(fontSize: 10, color: ChartColors.textMuted)),
      ]),
    );
  }
}