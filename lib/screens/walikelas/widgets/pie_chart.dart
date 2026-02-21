import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skoring/models/types/chart.dart';
import '../utils/chart_colors.dart';
import 'chart_painters.dart';

class PieChart extends StatefulWidget {
  final List<ChartDataItem> data;
  final String chartType;

  const PieChart({super.key, required this.data, required this.chartType});

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold(0.0, (s, i) => s + i.value);
    final colors = ChartColors.pieColors(widget.chartType);
    final accent = ChartColors.base(widget.chartType);
    final accentLight = accent.withOpacity(0.1);
    final maxVal = widget.data.isNotEmpty
        ? widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final avg = widget.data.isNotEmpty ? total / widget.data.length : 0.0;

    // Only show items with value > 0 in legend to avoid clutter
    final nonZero = widget.data.asMap().entries.where((e) => e.value.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary chips
        Row(children: [
          _chip('Total', total.toInt().toString(), accent, accentLight),
          const SizedBox(width: 8),
          _chip('Tertinggi', maxVal.toInt().toString(), accent, accentLight),
          const SizedBox(width: 8),
          _chip('Rata-rata', avg.toStringAsFixed(1), accent, accentLight),
        ]),
        const SizedBox(height: 20),

        // Donut + legend — legend only shows non-zero items
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Donut
            SizedBox(
              width: 130,
              height: 130,
              child: GestureDetector(
                onTap: () => setState(() => _selected = null),
                child: CustomPaint(
                  painter: PieChartPainter(
                    data: widget.data,
                    total: total,
                    colors: colors,
                    highlightIndex: _selected,
                  ),
                  child: Center(
                    child: _selected != null
                        ? _centerLabel(widget.data[_selected!], total, accent)
                        : _centerTotal(total.toInt(), accent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Legend — only non-zero months, compact
            Expanded(
              child: nonZero.isEmpty
                  ? Center(
                      child: Text('Semua nilai 0',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: ChartColors.textMuted)),
                    )
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: nonZero.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final pct = total > 0
                            ? (item.value / total * 100).toInt()
                            : 0;
                        final color = colors[i % colors.length];
                        final isSelected = _selected == i;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selected = isSelected ? null : i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? color.withOpacity(0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(item.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? color
                                          : ChartColors.textPrimary,
                                    )),
                                const SizedBox(width: 4),
                                Text('$pct%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: isSelected
                                          ? color
                                          : ChartColors.textMuted,
                                    )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, String value, Color color, Color bg) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: color.withOpacity(0.6),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: color,
                      fontWeight: FontWeight.w700,
                      height: 1.0)),
            ],
          ),
        ),
      );

  Widget _centerTotal(int total, Color accent) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$total',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: accent)),
          Text('total',
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: ChartColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _centerLabel(ChartDataItem item, double total, Color accent) {
    final pct = total > 0 ? (item.value / total * 100).toInt() : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$pct%',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
        Text(item.label,
            style: GoogleFonts.poppins(
                fontSize: 9,
                color: ChartColors.textMuted,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
      ],
    );
  }
}